// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable.sol";
import "solmate/utils/MerkleProofLib.sol";

error MaxSupplyReached();
error MintIsNotActive();
error AlreadyMinted();
error OnlyEOA();
error InvalidMerkleProof(address receiver, bytes32[] proof);

/// @title Dreambox Contract
/// @author Clique
contract Dreambox is ERC1155, Ownable {
    // The total supply of tokens will be capped at 3000.
    uint256 constant MAX_SUPPLY = 3333;

    // Checks if the mint is active.
    bool _mintActive = false;
    bool _openMintActive = false;

    // Counter for the number of tokens minted.
    uint256 public _totalMinted;

    // The Merkle root of the account addresses that are allowed to mint tokens.
    bytes32 public _root;

    // Mapping of account addresses that have already minted a dreambox.
    mapping(address => bool) public _minters;

    /// @dev Constructs a new Dreambox contract.
    /// @param uri The URI for the token metadata.
    constructor(address receiver, uint256[] memory amounts, string memory uri) ERC1155(uri) {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        _totalMinted += amounts[0];
        _mintBatch(receiver, ids, amounts, "");
    }

    /// @dev Sets the URI.
    /// @param newuri The new URI.
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @dev Sets the Merkle root.
    /// @param root The new Merkle root.
    function setRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    /// @dev Activates the mint.
    function activateMint() public onlyOwner {
        _mintActive = true;
    }

    /// @dev Activates the open mint.
    function activateOpenMint() public onlyOwner {
        _openMintActive = true;
    }

    /// @dev Closes the mint.
    function deactivateMint() public onlyOwner {
        _mintActive = false;
    }

    /// @dev Closes the open mint.
    function deactivateOpenMint() public onlyOwner {
        _openMintActive = false;
    }

    /// @dev Mints a token to the function caller.
    /// @param proof The Merkle proof for the account.
    function mint(bytes32[] calldata proof) external {
        if (!_mintActive) revert MintIsNotActive();
        if (_minters[msg.sender]) revert AlreadyMinted();
        if (_totalMinted >= MAX_SUPPLY) revert MaxSupplyReached();

        if (!_verify(_leaf(msg.sender), proof)) revert InvalidMerkleProof(msg.sender, proof);

        _minters[msg.sender] = true;
        ++_totalMinted;

        _mint(msg.sender, 1, 1, "");
    }

    /// @dev Mints a token to the function caller.
    function openMint() external {
        if (!_openMintActive) revert MintIsNotActive();
        if (_minters[msg.sender]) revert AlreadyMinted();
        if (_totalMinted >= MAX_SUPPLY) revert MaxSupplyReached();

        _minters[msg.sender] = true;
        ++_totalMinted;

        _mint(msg.sender, 1, 1, "");
    }

    /// @dev Constructs a leaf from an account address.
    /// @param account The account address.
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /// @dev Verifies a Merkle proof.
    /// @param leaf The leaf to verify.
    /// @param proof The Merkle proof.
    function _verify(bytes32 leaf, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProofLib.verify(proof, _root, leaf);
    }
}