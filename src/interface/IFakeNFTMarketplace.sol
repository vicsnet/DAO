// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFakeNFTMarketplace{
    function getPrice() external view returns(uint);

    function available(uint _tokenId) external view returns(bool);

    function purchase(uint _tokenId) external payable;


}


interface ICryptoDevsNFT{
    function balanceOf(address owner) external view returns (uint);

    function tokenOfOwnerByIndex(address owner, uint index) external view returns(uint);
}