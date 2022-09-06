// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBitToonDAO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SaleBTD is Ownable, ReentrancyGuard {

    IBitToonDAO public bitToonDAO;
    bytes32 public merkleRoot;

    bool public isPrivate;
    bool public isPublic;

    uint256 public privatePrice = 0.065 ether;
    uint256 public publicPrice = 0.085 ether;

    address public teamWallet;

    uint256 public privateTime;
    uint256 public publicTime;

    mapping(address => uint256) public _privateUserMintedAmount;

    constructor(IBitToonDAO _bitToonDAO, address _teamWallet) {

        bitToonDAO = _bitToonDAO;
        teamWallet = _teamWallet;

        isPrivate = false;
        isPublic = false;
}                                                                                   

    function setPublicMint(bool _bool) public onlyOwner {
        isPublic = _bool;
    }

    function setPrivateMint(bool _bool) public onlyOwner {
        isPrivate = _bool;
    }

    function setBitToonDAO(IBitToonDAO _bitToonDAO) public onlyOwner {
        bitToonDAO = _bitToonDAO;
    }

    function setTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSaleTime(uint256 _privateTime, uint256 _publicTime) public onlyOwner {
        privateTime = _privateTime;
        publicTime = _publicTime;
    }

    function privateMint(bytes32[] calldata _proof,uint256 _maxAmount, uint256 _amount) public payable nonReentrant {
        // This is payable function.
        // You can tip BitToonDAO Team if you want.

        require(isPrivate == true, "Private mint is not open.");
        require(block.timestamp >= privateTime, "Private mint is not open.");
        require(getTotalSupply() + _amount <= getMaxSupply(), "Over supply amount.");
        require(privateUserMintedAmount(msg.sender) + _amount <= _maxAmount, "Exceed Whitelist Limit");
        require(privateUserMintedAmount(msg.sender) + _amount <= 2, "Exceed Maximum Limit"); //Just in case Human Error from wl list
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _maxAmount))), "Unauthorized user.");
        require(privatePrice * _amount <= msg.value, "Ether value sent is not correct");

        _privateUserMintedAmount[msg.sender] += _amount;
        bitToonDAO.safeMint(msg.sender,_amount);
    }

    function publicMint(uint256 _amount) public payable nonReentrant {
        // This is payable function.
        // You can tip BitToonDAO Team if you want.
        
        require(isPublic == true, "Public mint is not open.");
        require(block.timestamp >= publicTime, "Public mint is not open.");
        require(tx.origin == msg.sender, "haha Contract can't call me");
        require(_amount <= 10, "Only 10 BTD per tx.");
        require(getTotalSupply() + _amount <= getMaxSupply(), "Over supply amount.");
        require(publicPrice * _amount <= msg.value, "Ether value sent is not correct");

        bitToonDAO.safeMint(msg.sender, _amount);
    }

    function devMint(address _to, uint256 _amount) public onlyOwner {
        require(getTotalSupply() + _amount <= getMaxSupply(), "Over supply amount.");
        bitToonDAO.safeMint(_to, _amount);
    }

    function setPrivatePrice(uint256 _privatePrice) public onlyOwner {
        privatePrice = _privatePrice;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = teamWallet.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

    function privateUserMintedAmount(address _user) public view returns(uint256) {
        return _privateUserMintedAmount[_user];
    }

    function getTotalSupply() public view returns (uint256) {
        return bitToonDAO.totalSupply();
    }

    function getMaxSupply() public view returns (uint256) {
        return bitToonDAO.maxSupply();
    }
}