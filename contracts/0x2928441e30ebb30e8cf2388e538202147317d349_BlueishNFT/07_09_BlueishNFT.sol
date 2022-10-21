// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "forge-std/console2.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IBlueishRenderer.sol";
import "./interfaces/IBlueishMetadata.sol";

error WithdrawFailed();

/// @title blueishNFT
/// @author blueish.eth
/// @notice This contract is a basic on-chain SVG ERC721 template built using Foundry
/// @dev This contract is a beginner level, general purpose smart contract development template, as well as an introduction to the Foundry toolchain for EVM smart contract development. It covers developing and testing smart contracts,specifically using Foundry's Forge testing libraries and Cast deployment/scripting lirbaries. It also covers a basic implementation of on-chain SVG NFT art. The README,  code, and comments are the entirety of documentation for this template. Users and developers are encouraged to mint/interact with the original contract, clone the repo and build and deploy their own NFTs.

contract BlueishNFT is ERC721, Ownable {
    uint256 public currentTokenId;
    IBlueishMetadata public metadata;

    constructor(string memory _name, string memory _symbol, address _metadata)
        ERC721(_name, _symbol)
    {
        metadata = IBlueishMetadata(_metadata);
    }

    function mintTo(address recipient) public payable returns (uint256) {
        uint256 newTokenId = ++currentTokenId;
        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    function setMetadata(address _metadata) public onlyOwner {
       metadata = IBlueishMetadata(_metadata);
    }

    function contractURI() public view returns (string memory) {
        return metadata.contractURI();
      
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return metadata.tokenURI(id);
    }

    function withdrawFunds(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) revert WithdrawFailed();
    }
}