// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

// Kitsune - ERC-721A based NFT contract

pragma solidity ^0.8.7;

import "../lib/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Kitsune is ERC721A, Ownable, ReentrancyGuard {
    uint256 private _maxSupply = 4444;
    uint256 private _maxMintPerTx = 2;
    uint256 private _maxMintPerWallet = 2;
    bool private _mintStatus = false;

    string private _baseTokenURI;
    mapping(address => uint256) private _mints;

    constructor(string memory baseTokenURI, uint256 reservedAmount)
        ERC721A("Kitsune", "KTSN")
    {
        if (reservedAmount > 0) {
            _safeMint(owner(), reservedAmount);
        }
        _baseTokenURI = baseTokenURI;
    }

    function getMaxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function getMaxMintPerTx() external view returns (uint256) {
        return _maxMintPerTx;
    }

    function getMintStatus() external view returns (bool) {
        return _mintStatus;
    }

    function getMintsOfAccount(address account)
        external
        view
        returns (uint256)
    {
        return _mints[account];
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mint(uint256 amount) external nonReentrant callerIsUser {
        if (!_mintStatus) revert("Minting has not started yet.");
        if (amount == 0) revert("The amount must be greater than 0.");
        if (amount > _maxMintPerTx)
            revert("The amount exceeds the limit per tx.");
        if (totalSupply() + amount > _maxSupply)
            revert("The amount exceeds the max supply.");
        if (_mints[msg.sender] + amount > _maxMintPerWallet)
            revert("The amount exceeds the limit per wallet.");
        _safeMint(msg.sender, amount);
        _mints[msg.sender] += amount;
    }

    function mintToAddress(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > _maxSupply)
            revert("The amount exceeds the max supply.");
        _safeMint(to, amount);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function toggleMintStatus() external onlyOwner {
        _mintStatus = !_mintStatus;
    }

    function withdrawAll() external onlyOwner {
        withdraw(owner(), address(this).balance);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}