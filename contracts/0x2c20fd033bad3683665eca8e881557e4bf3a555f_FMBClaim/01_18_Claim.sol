// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FMBClaim is Ownable, ReentrancyGuard {
    mapping(uint256 => bool) public InitMinted;
    mapping(uint256 => uint256) public MissonMinted;

    address public GenesisBirdAddress = 0x679bDD1c961cE28E427BCC2a9BF982C92A99c73A;
    address public FMBAddress = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;
    bytes32 public root;

    event ClaimInit(address player, uint256 amount, uint256 tokenId);
    event ClaimMisson(address player, uint256 amount, uint256 tokenId);

    constructor() {}

    function _release( address holder, uint256 releasedAmount) internal {
        IERC20 token = IERC20(FMBAddress);
        token.transfer( holder, releasedAmount);
    }

    function claimInitToken(uint256 tokenId) external {
        IERC721 GB = IERC721(GenesisBirdAddress);
        require(msg.sender == GB.ownerOf(tokenId), "Not owner");
        require(InitMinted[tokenId] == false, "claimed");
        _release(msg.sender, 1000 ether);
        InitMinted[tokenId] = true;
        emit ClaimInit(msg.sender, 1000 ether, tokenId);
    }

    function claimMissionToken(uint256 tokenId, uint256 amount, bytes32[] calldata proof) external {
        IERC721 GB = IERC721(GenesisBirdAddress);
        require(msg.sender == GB.ownerOf(tokenId), "Not owner");
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, amount));
        bool isValidLeaf = MerkleProof.verify(proof, root, leaf);
        require(isValidLeaf == true, "Not in merkle");
        uint256 claimable = amount - MissonMinted[tokenId];
        _release(msg.sender, claimable);
        MissonMinted[tokenId] += claimable;
        emit ClaimMisson(msg.sender, amount, tokenId);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        _release(owner(), _amount);
    }

    function setRoot(bytes32 merkleroot) external onlyOwner {
        root = merkleroot;
    }

    function setGBAddress(address GB) external onlyOwner {
        GenesisBirdAddress = GB;
    }

    function setFMBAddress(address FMB) external onlyOwner {
        FMBAddress = FMB;
    }
}