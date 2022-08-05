// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract FishyFamBait is ERC20, ERC20Pausable, ERC20Capped, Ownable {
    mapping(uint256 => bool) public claimedTokenIds;
    bytes32 public mintlistMerkleRoot;
    mapping(address => bool) public claimedMinters;
    bool public isSaleActive;
    IERC721 public fishyFamContract;

    constructor(uint256 limit, address fishyFamContratAddress) ERC20("Fishy Fam Bait", "BAIT") ERC20Capped(limit) {
      fishyFamContract = IERC721(fishyFamContratAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setIsSaleActive(bool newIsSaleActive) external onlyOwner {
        require(mintlistMerkleRoot != 0, 'FishyFamBait: cannot start if mintlistMerkleRoot is not set');
        isSaleActive = newIsSaleActive;
    }

    function setMintlistMerkleRoot(bytes32 newMintlistMerkleRoot) external onlyOwner {
        mintlistMerkleRoot = newMintlistMerkleRoot;
    }

    function mintOwner(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function claimFromTokens(uint256[] calldata tokenIds) external {
        require(isSaleActive, "FishyFamBait: Sale is not active");
        for (uint256 i; i < tokenIds.length; i++) {
            require(tokenIds[i] <= 9998, "FishyFamBait: invalid token id");
            require(fishyFamContract.ownerOf(tokenIds[i]) == _msgSender(), "FishyFamBait: Caller is not the token owner");
            require(!claimedTokenIds[tokenIds[i]], "FishyFamBait: Token has already claimed");
            claimedTokenIds[tokenIds[i]] = true;
        }
        _mint(_msgSender(), tokenIds.length * (10 ** 18));
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verifyMerkleLeaf(bytes32 merkleLeaf, bytes32 merkleRoot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, merkleLeaf);
    }

    function claimFromMintlist(bytes32[] calldata proof) external {
        require(isSaleActive, "FishyFamBait: Sale is not active");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), mintlistMerkleRoot, proof), "FishyFamBait: invalid proof");
        require(!claimedMinters[_msgSender()], "FishyFamBait: Caller has already claimed");
        claimedMinters[_msgSender()] = true;
        _mint(_msgSender(), 3 * (10 ** 18));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Pausable, ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        super._mint(to, amount);
    }

}