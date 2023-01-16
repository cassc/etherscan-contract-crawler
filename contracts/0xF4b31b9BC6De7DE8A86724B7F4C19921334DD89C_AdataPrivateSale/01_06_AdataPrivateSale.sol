// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract AdataPrivateSale is Ownable, Pausable, ReentrancyGuard {
    address public _tokenAddress;
    bytes32 public _merkleRoot;
    uint256 public _startTime;
    uint256 public _endTime;
    uint256 public _price;
    uint256 public _holdLimit;

    string public _name;
    mapping(address => uint256) private _holds;

    constructor(string memory name_) {
        _pause();
        _name = name_;
        _startTime = 1673884800; // Jan 17, 2022 00:00:00 AM GMT+08:00
        _endTime = 1673971200; // Jan 18, 2022 00:00:00 AM GMT+08:00
        _price = 1 ether;
        _holdLimit = 2;
    }

    function info() public view returns (uint256[] memory) {
        uint256[] memory info_ = new uint256[](3);
        info_[0] = _startTime;
        info_[1] = _endTime;
        info_[2] = _price;
        return info_;
    }

    function remain() public view returns (uint256) {
        return _holdLimit - _holds[msg.sender];
    }

    function buy(bytes32[] calldata proof)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(msg.sender == tx.origin, "Runtime error: contract not allowed");
        require(msg.value >= _price, "Runtime error: ether not enough");
        require(_holds[msg.sender] < _holdLimit, "Runtime error: can't buy anymore");
        require(
            block.timestamp > _startTime,
            "Runtime error: sale not started"
        );
        require(
            block.timestamp < _endTime,
            "Runtime error: sale ends"
        );
        require(
            MerkleProof.verify(proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Runtime error: invalid merkle proof"
        );
        _holds[msg.sender] += 1;
        NFT(_tokenAddress).mint(msg.sender, 1);
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setAuction(
        uint256 startTime_,
        uint256 endTime_,
        uint256 price_,
        uint256 holdLimit_
    ) external onlyOwner {
        _startTime = startTime_;
        _endTime = endTime_;
        _price = price_;
        _holdLimit = holdLimit_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address to) public onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Runtime error: withdraw failed");
    }
}