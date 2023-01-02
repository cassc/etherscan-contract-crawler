// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "openzeppelin/utils/cryptography/MerkleProof.sol";

interface IFiefdomsKingdom {
    function mintBatch(address to, uint256 amount) external;

    function mint(address to) external;

    function setMinter(address newMinter) external;
}

contract FiefdomsMinter {
    IFiefdomsKingdom public fiefdomsKingdom;
    address public owner;
    bytes32 public merkleRoot;
    bool public isPublicMintable;
    uint256 public maxPerAllowed;
    mapping(address => uint256) public claimed;

    constructor(address addr) {
        owner = msg.sender;
        maxPerAllowed = 7;
        fiefdomsKingdom = IFiefdomsKingdom(addr);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferMinter(address newMinter) external onlyOwner {
        fiefdomsKingdom.setMinter(newMinter);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setAllowedPerMint(uint256 amount) external onlyOwner {
        maxPerAllowed = amount;
    }

    function setPublicMintable(bool isPublic) external onlyOwner {
        isPublicMintable = isPublic;
    }

    function mintAllowList(
        address to,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(
            claimed[to] + amount <= maxPerAllowed,
            "Exceeds max allowed per address"
        );
        require(verify(to, merkleProof), "Invalid proof");
        claimed[to] += amount;
        fiefdomsKingdom.mintBatch(to, amount);
    }

    function mintPublic(address to) external {
        require(isPublicMintable, "Public minting is not allowed");
        fiefdomsKingdom.mint(to);
    }

    function mintPublicBatch(address to, uint256 amount) external {
        require(isPublicMintable, "Public minting is not allowed");
        fiefdomsKingdom.mintBatch(to, amount);
    }

    function verify(address to, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verifyCalldata(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(to))
            );
    }
}