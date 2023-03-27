// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IFakeNFTMarketplace, ICryptoDevsNFT} from "./interface/IFakeNFTMarketplace.sol";

contract CryptoDevsDao is Ownable {
    struct Proposal {
        uint nftTokenId;
        uint deadline;
        uint yayVotes;
        uint nayVotes;
        bool executed;
        mapping(uint => bool) voters;
    }

enum Vote{
    YAY,
    NAY
}
    mapping(uint => Proposal) public proposals;

    uint public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    constructor(address _nftMarketplace, address _cryptoDevsNft) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNft);
    }

    modifier nftHolderOnly(){
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    function createProposal(uint _nftTokenId) external nftHolderOnly returns(uint){
        require(nftMarketplace.available(_nftTokenId), "NFT_Not_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;

        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;

    }

    modifier activeProposalOnly(uint proposalIndex){
        require(proposals[proposalIndex].deadline > block.timestamp, "DEADLINE_EXCEED");
        _;
    }

    function voteOnProposal(uint proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];

        uint voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint numVotes = 0;

        // calculate how many nft are owned by the voters
        // that havent been used for voting  on his proposal

        for (uint i =0; i < voterNFTBalance; i++){
            uint tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] ==false){
                numVotes ++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY){
            proposal.yayVotes +=numVotes;
        }else{
            proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint proposalIndex) {
        require(proposals[proposalIndex].deadline <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalIndex].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    function executeProposal(uint proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];

        if(proposal.yayVotes > proposal.nayVotes){
            uint nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
function withdrawEther() external onlyOwner {
    uint256 amount = address(this).balance;
    require(amount > 0, "Nothing to withdraw, contract balance empty");
    (bool sent, ) = payable(owner()).call{value: amount}("");
    require(sent, "FAILED_TO_WITHDRAW_ETHER");
}

receive() external payable {}

fallback() external payable {}
}
