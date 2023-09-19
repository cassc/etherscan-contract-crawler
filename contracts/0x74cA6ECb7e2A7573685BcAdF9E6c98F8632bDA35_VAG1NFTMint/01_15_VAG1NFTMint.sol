// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VhighAvatarGen1.sol";

contract VAG1NFTMint is Ownable, ERC721Holder, Pausable, ReentrancyGuard {
    bytes32[] public proof;
    uint256 public maxMintableAmount;
    uint256 public price;
    uint256 public maxAmountPerTx;

    VhighAvatarGen1 public immutable vag1NFT;

    event Mint(address indexed user, uint256[] tokenIds);

    constructor(address vag1NFTAddress) {
        _pause();

        vag1NFT = VhighAvatarGen1(vag1NFTAddress);
    }

    function mint(uint256 amount) external payable nonReentrant whenNotPaused {
        require(amount > 0, "VAG1NFTMint: Amount must be greater than zero");
        require(
            amount <= maxAmountPerTx,
            "VAG1NFTMint: Amount exceeds max amount per tx"
        );
        require(
            amount <= vag1NFT.MAX_SUPPLY() - vag1NFT.totalSupply(),
            "VAG1NFTMint: Amount exceeds max supply"
        );
        require(msg.value == price * amount, "VAG1NFTMint: Incorrect value");

        vag1NFT.wlMint(amount, proof, maxMintableAmount);

        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = vag1NFT.totalSupply() - amount + i;
        }

        for (uint256 i = 0; i < amount; i++) {
            vag1NFT.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
        }

        emit Mint(_msgSender(), tokenIds);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setProof(bytes32[] calldata newProof) external onlyOwner {
        proof = newProof;
    }

    function setMaxMintableAmount(
        uint256 newMaxMintableAmount
    ) external onlyOwner {
        maxMintableAmount = newMaxMintableAmount;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxAmountPerTx(uint256 newMaxAmountPerTx) external onlyOwner {
        maxAmountPerTx = newMaxAmountPerTx;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        require(success, "VAG1NFTMint: Transfer failed");
    }
}