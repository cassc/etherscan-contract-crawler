// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMadMemberPass.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MadMemberPassSellerPrivate is AccessControl, Ownable {
    IMadMemberPass public madMemberPass;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    address public withdrawAddress;

    // SaleInfo
    uint256 public mintCost = 0.05 ether;
    bytes32 merkleRoot;
    mapping(address => uint256) public mintedAmount;

    // Modifier
    modifier enoughEth(uint256 _amount) {
        require(mintCost > 0 && msg.value >= _amount * mintCost, 'Not Enough Eth');
        _;
    }
    modifier withinMaxAmountPerAddress(address _address, uint256 _amount, uint256 _allowedAmount) {
        require(mintedAmount[_address] + _amount <= _allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier validProof(address _address, uint256 _allowedAmount, bytes32[] calldata _merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(_address, _allowedAmount));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }


    // Constructor
    constructor() {
        _grantRole(ADMIN, msg.sender);
        withdrawAddress = msg.sender;
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Mint
    function mint(uint256 _amount, uint _allowedAmount, bytes32[] calldata _merkleProof) external payable
        enoughEth(_amount)
        withinMaxAmountPerAddress(msg.sender, _amount, _allowedAmount)
        validProof(msg.sender, _allowedAmount, _merkleProof)
    {
        mintedAmount[msg.sender] += _amount;
        madMemberPass.mint(msg.sender, _amount);
    }

    // Setter
    function setMadMemberPass(address _address) external onlyRole(ADMIN) {
        madMemberPass = IMadMemberPass(_address);
    }
    function setMerkleRoot(bytes32 _value) external onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // withdraw
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }
}