//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
import "./GameNFT.sol";

contract NFTGenerator {
    mapping(address => address[]) private _userNFTsERC721;
    mapping(address => address[]) private _userNFTsERC1155;
    address[] private allERC721Tokens;
    address[] private allERC1155Tokens;
    event ERC721CollectionCreated(address _nft);
    event ERC1155CollectionCreated(address _nft);
    address marketplaceAddress;

    constructor(address _marketplaceAddress) {
        marketplaceAddress = _marketplaceAddress;
    }

    function createERC721Collection(
        string memory name,
        string memory symbol
    ) external {
        NFT nft = new NFT(msg.sender, name, symbol, marketplaceAddress);
        _userNFTsERC721[msg.sender].push(address(nft));
        allERC721Tokens.push(address(nft));
        emit ERC721CollectionCreated(address(nft));
    }

    function getMyERC721Tokens()
        external
        view
        returns (address[] memory userTokens)
    {
        userTokens = _userNFTsERC721[msg.sender];
    }

    function getAllERC721Tokens() external view returns (address[] memory) {
        return allERC721Tokens;
    }

    function createERC1155Collection() external {
        GameNFT product = new GameNFT(msg.sender, marketplaceAddress);
        _userNFTsERC1155[msg.sender].push(address(product));
        allERC1155Tokens.push(address(product));
        emit ERC1155CollectionCreated(address(product));
    }

    function getMyERC1155Tokens() external view returns (address[] memory) {
        return _userNFTsERC1155[msg.sender];
    }

    function getAllERC1155Tokens() external view returns (address[] memory) {
        return allERC1155Tokens;
    }
}