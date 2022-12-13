//  ________  ________  ___       ___       ___  __    ________  ___       ___
// |\   __  \|\   __  \|\  \     |\  \     |\  \|\  \ |\   __  \|\  \     |\  \
// \ \  \|\  \ \  \|\  \ \  \    \ \  \    \ \  \/  /|\ \  \|\  \ \  \    \ \  \
//  \ \   _  _\ \  \\\  \ \  \    \ \  \    \ \   ___  \ \   __  \ \  \    \ \  \
//   \ \  \\  \\ \  \\\  \ \  \____\ \  \____\ \  \\ \  \ \  \ \  \ \  \____\ \  \____
//    \ \__\\ _\\ \_______\ \_______\ \_______\ \__\\ \__\ \__\ \__\ \_______\ \_______\
//     \|__|\|__|\|_______|\|_______|\|_______|\|__| \|__|\|__|\|__|\|_______|\|_______|
//
// RollKall
//
// by Kitty Kart
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KittyKartRollKall is ERC1155, ERC2981, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public supply;
    string public constant NAME = "KittyKart RollKall";
    string public constant SYMBOL = "RollKall";
    bytes32 public whitelistMerkleRoot;
    bool public isPublicMint = false;

    mapping(address => bool) public hasClaimed;

    constructor() ERC1155("") {
        _setDefaultRoyalty(address(0x032167473a2A2996754481A26c778Ec4570B2d18), 1000);
    }

    /// @dev set tokenURI
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @dev pause contract
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev unpause contract
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev set merkle tree root for whitelisted users
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /// @dev start public mint
    function setIsPublicMint(bool _isPublic) external onlyOwner {
        isPublicMint = _isPublic;
    }

    /// @dev mint rollkall
    function mint(bytes32[] calldata merkleProof) external whenNotPaused {
        require(supply < MAX_SUPPLY, "reached max supply!");
        require(hasClaimed[msg.sender] == false, "can only mint 1 per wallet!");

        if (!isPublicMint) {
            bytes32 node = keccak256(abi.encodePacked(msg.sender));
            bool isWhitelistVerified = MerkleProof.verify(merkleProof, whitelistMerkleRoot, node);
            require(isWhitelistVerified, "whitelisted users only!");
        }

        hasClaimed[msg.sender] = true;
        supply += 1;
        _mint(msg.sender, 0, 1, "");
    }

    /// @dev set royalty receiver and fee
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
}