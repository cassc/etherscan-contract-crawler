pragma solidity ^0.8.7;

import "./Base721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KissYourDream is Base721, ReentrancyGuard {
    uint256 public publicPrice;

    uint256 public wlPrice;

    uint256 public wlStartTime;

    uint256 public wlEndTime;

    uint256 public publicStartTime;

    uint256 public publicEndTime;

    bytes32 public wlMintRoot;

    uint256 public wlNum;

    uint256 public publicNum;

    uint256 public maxWlSupply;

    mapping(address => uint256) public wlMinted;

    mapping(address => uint256) public publicMinted;

    constructor() public ERC721A("DissYourDream", "DissYourDream") {
        maxSupply = 3333;
        maxWlSupply = 3333;
        publicPrice = 0.015 ether;
        wlPrice = 0.009 ether;
        publicStartTime = 1679488200;
        publicEndTime = 999999999999;
        wlStartTime = 1679486400;
        wlEndTime = 1679488200;
        wlMintRoot = 0xd541d4a7c3f11c5d36e91d2e9dfa23701c8d22ddd5ac0d4f8a9d49ca4c05919f;
    }

    function wlMint(
        bytes32[] calldata _proof,
        uint256 _num
    ) external payable nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_proof, wlMintRoot, leaf),
            "Merkle verification failed"
        );
        require(
            wlMinted[_msgSender()] + publicMinted[_msgSender()] + _num <= 5,
            " mint must lower than 5"
        );
        require(
            block.timestamp >= wlStartTime && block.timestamp <= wlEndTime,
            "Must in time"
        );
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        require(wlNum + _num <= maxWlSupply, "Must lower than maxWlSupply");
        require(msg.value >= wlPrice * _num, "Must greater than value");
        _mint(_msgSender(), _num);
        wlNum += _num;
        wlMinted[_msgSender()] += _num;
    }

    function publicMint(uint256 _num) external payable nonReentrant {
        require(
            block.timestamp >= publicStartTime &&
                block.timestamp <= publicEndTime,
            "Must in time"
        );
        require(
            wlMinted[_msgSender()] + publicMinted[_msgSender()] + _num <= 5,
            " mint must lower than 5"
        );
        require(msg.value >= publicPrice * _num, "Must greater than value");
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        _mint(_msgSender(), _num);
        publicNum += _num;
        publicMinted[_msgSender()] += _num;
    }

    function setSupply(uint256 _maxWlSupply) external onlyOwner {
        maxWlSupply = _maxWlSupply;
    }

    function setRoot(bytes32 _wlMintRoot) external onlyOwner {
        wlMintRoot = _wlMintRoot;
    }

    function setPrice(
        uint256 _publicPrice,
        uint256 _wlPrice
    ) external onlyOwner {
        publicPrice = _publicPrice;
        wlPrice = _wlPrice;
    }

    function setTime(
        uint256 _publicStartTime,
        uint256 _publicEndTime,
        uint256 _wlStartTime,
        uint256 _wlEndTime
    ) external onlyOwner {
        publicStartTime = _publicStartTime;
        publicEndTime = _publicEndTime;
        wlStartTime = _wlStartTime;
        wlEndTime = _wlEndTime;
    }
}