// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is Ownable, ERC721Burnable {
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    uint256 public max_supply = 5000;
    uint256 public amountMintPerAccount = 1;
    uint256 public currentToken = 0;

    bytes32 public whitelistRoot;
    bool public publicSaleEnabled;

    event MintSuccessful(address user);

    constructor(bytes32 _whitelistRoot) ERC721("Ore Raid - Else Exchange Ticket", "ELSET") { 
        whitelistRoot = _whitelistRoot;
    }

    function mint(bytes32[] memory _proof) external {
        require(balanceOf(msg.sender) < amountMintPerAccount, 'Each address may only mint x NFTs!');
        require(currentToken < max_supply, 'No more NFT available to mint!');
        require(publicSaleEnabled || isValid(_proof, keccak256(abi.encodePacked(msg.sender))), 'You are not whitelisted');

        currentToken += 1;
        _safeMint(msg.sender, currentToken);
        
        emit MintSuccessful(msg.sender);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), uriSuffix))
            : '';
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmeaA4wbxTHPEp58KSkgvfWs1ZpURSm2crYsW35SWMPwoM/";
    }
    
    function baseTokenURI() public pure returns (string memory) {
        return _baseURI();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmdmSPaNFaBzVR3GSFDfmP7DG9JdahnDu1P94L5H44Y5DR/";
    }

    function setAmountMintPerAccount(uint _amountMintPerAccount) public onlyOwner {
        amountMintPerAccount = _amountMintPerAccount;
    }

    function setPublicSaleEnabled(bool _state) public onlyOwner {
        publicSaleEnabled = _state;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function isValid(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, whitelistRoot, _leaf);
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}