// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EtchLaunchpad is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MaxAvailable = 1000;
    uint256 public current_index;
    bytes32 public merkleRootHash;

    address payable public recipient;

    uint256 public publicMintStartAfter;
    uint256 public publicMaxMintPerAddress;
    uint256 public publicMintPrice;

    uint256 public whitelistMintStartAfter;
    uint256 public whitelistMaxMintPerAddress;
    uint256 public whitelistMintPrice;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event MerkleRootHashUpdated(bytes32 rootHash);
    event MintInfoUpdated(uint256 time, uint256 mintLimit, uint256 price);

    modifier canPublicMint() {
        require(block.timestamp >= publicMintStartAfter && publicMintStartAfter > 0, "public mint has not started yet");
        _;
    }

    modifier canWhitelistMint() {
        require(
            block.timestamp >= whitelistMintStartAfter && whitelistMintStartAfter > 0,
            "whitelist mint has not started yet"
        );
        _;
    }

    function whitelistMint(uint256 num, bytes32[] calldata merkleProof) external payable canWhitelistMint nonReentrant {
        require(tx.origin == msg.sender, "only EOA");
        require(current_index + num <= MaxAvailable, "exceeds maximum supply limit");
        require(
            MerkleProof.verify(merkleProof, merkleRootHash, keccak256(abi.encodePacked(msg.sender))),
            "invalid merkle proof"
        );
        require(
            whitelistMinted[msg.sender] + num <= whitelistMaxMintPerAddress,
            "exceeded maximum whitelist mint per address"
        );
        require(msg.value == num * whitelistMintPrice, "incorrect payment amount");
        if (msg.value > 0) {
            Address.sendValue(recipient, msg.value);
        }

        whitelistMinted[msg.sender] += num;
        for (uint256 i = 0; i < num; i++) {
            emit Transfer(address(0), msg.sender, current_index);
            current_index++;
        }
    }

    function publicMint(uint256 num) external payable canPublicMint nonReentrant {
        require(tx.origin == msg.sender, "only EOA");
        require(current_index + num <= MaxAvailable, "exceeds maximum supply limit");
        require(publicMinted[msg.sender] + num <= publicMaxMintPerAddress, "exceeded maximum public mint per address");
        require(msg.value == num * publicMintPrice, "incorrect payment amount");

        if (msg.value > 0) {
            Address.sendValue(recipient, msg.value);
        }

        publicMinted[msg.sender] += num;
        for (uint256 i = 0; i < num; i++) {
            emit Transfer(address(0), msg.sender, current_index);
            current_index++;
        }
    }

    function setPublicMint(
        uint256 _publicMintStartAfter,
        uint256 _publicMaxMintPerAddress,
        uint256 _publicMintPrice
    ) external onlyOwner {
        publicMintStartAfter = _publicMintStartAfter;
        publicMaxMintPerAddress = _publicMaxMintPerAddress;
        publicMintPrice = _publicMintPrice;
        emit MintInfoUpdated(publicMintStartAfter, publicMaxMintPerAddress, publicMintPrice);
    }

    function setWhitelistMint(
        uint256 _whitelistMintStartAfter,
        uint256 _whitelistMaxMintPerAddress,
        uint256 _whitelistMintPrice
    ) external onlyOwner {
        whitelistMintStartAfter = _whitelistMintStartAfter;
        whitelistMaxMintPerAddress = _whitelistMaxMintPerAddress;
        whitelistMintPrice = _whitelistMintPrice;
        emit MintInfoUpdated(whitelistMintStartAfter, whitelistMaxMintPerAddress, whitelistMintPrice);
    }

    function setMerkleRootHash(bytes32 rootHash) external onlyOwner {
        merkleRootHash = rootHash;
        emit MerkleRootHashUpdated(merkleRootHash);
    }

    function setRecipient(address payable _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}