// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTCONTRACT {
    function mintNFT(address minter, string memory jsonURI) external;
}

contract roopMint is Ownable {

    address public nftAddress;
    NFTCONTRACT nft = NFTCONTRACT(nftAddress);

    function setAddress(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
    }


    function roopmint(address recipent, string memory URI, uint256 roop) public onlyOwner {
        for (uint256 i = 0; i < roop; i++) {
            nft.mintNFT(recipent, URI);
        }
    }

    function mint(address recipent, string memory URI) public onlyOwner {
        nft.mintNFT(recipent, URI);
    }
}