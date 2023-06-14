// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract NetworkTokenClaim is Ownable, Pausable {
    bytes32 public root;
    IERC20 public tokenAsset;
    mapping(address => bool) public claimed;

    event TokensClaimed(uint256 indexed amount, address indexed claimer);
    event RootUpdated(bytes32 indexed newRoot);
    event AssetAddressUpdated(address indexed newAddress);

    constructor(bytes32 _root) {
        root = _root;
        _pause();
    }

    function claim(bytes32[] memory proof, uint256 amount) public whenNotPaused() {
        require(tokenAsset != IERC20(address(0)), "Asset address not set");
        require(!claimed[_msgSender()], "Already claimed");
        require(
            tokenAsset.balanceOf(address(this)) >= amount,
            "Not enough tokens"
        );

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_msgSender(), amount)))
        );
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");

        claimed[_msgSender()] = true;
        tokenAsset.transfer(_msgSender(), amount);
        emit TokensClaimed(amount, _msgSender());
    }

    function updateRoot(bytes32 _root) public onlyOwner {
        require(root != bytes32(0), "Root can not be null");
        root = _root;
        emit RootUpdated(_root);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function setAssetAddress(address _assetAddress) public onlyOwner {
        tokenAsset = IERC20(_assetAddress);
        emit AssetAddressUpdated(_assetAddress);
    }
}