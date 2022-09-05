// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./roles/AccessOperatable.sol";

interface iCMOC {
  function mint(address to, uint256 quantity) external;

  function totalSupply() external view returns (uint256);
}

contract MetazedSale is AccessOperatable {
  using SafeMath for uint256;
  iCMOC public targetContract;

  mapping(address => uint256) public whitelistRemaining;

  mapping(address => bool) public whitelistUsed;

  uint256 public saleStart;
  uint256 public whitelistSaleStart;

  uint256 public saleEnd = 253404860400;
  uint256 public whitelistSaleEnd = 253404860400;

  uint256 public maxSupply = 3333;
  uint256 public maxByMint = 20;

  uint256 public whitelistSalePrice = 0.015 * 10**18;
  uint256 public salePrice = 0.02 * 10**18;

  bytes32 public merkleRoot;

  constructor(address token_) {
    require(token_ != address(0x0));
    targetContract = iCMOC(token_);
  }

  function mintNFT(uint256 nftNum) external payable {
    require(totalSupply().add(nftNum) <= maxSupply, "Exceeds total supply.");
    require(nftNum <= maxByMint, "Exceed Max by mint.");
    require(nftNum > 0, "The number of purchases is incorrect.");

    require(
      saleStart != 0 && block.timestamp > saleStart,
      "The sale hasn't started yet."
    );
    require(block.timestamp <= saleEnd, "Sale ended");
    require(salePrice.mul(nftNum) == msg.value, "Incorrect eth amount.");

    targetContract.mint(msg.sender, nftNum);
  }

  function whitelistMint(
    uint256 nftNum,
    uint256 totalAllocation,
    bytes32 leaf,
    bytes32[] calldata proof
  ) external payable {
    require(
      whitelistSaleStart != 0 && block.timestamp > whitelistSaleStart,
      "The pre sale hasn't started yet."
    );
    require(block.timestamp <= whitelistSaleEnd, "Sale was finished.");
    require(nftNum <= maxByMint, "Exceed Max by mint.");
    bytes32 solidityLeaf = keccak256(
      abi.encodePacked(msg.sender, totalAllocation)
    );

    if (!whitelistUsed[msg.sender]) {
      require(solidityLeaf == leaf, "Invalid Leaf.");
      require(
        MerkleProof.verify(proof, merkleRoot, leaf),
        "Invalid Merkle Proof."
      );

      whitelistUsed[msg.sender] = true;
      whitelistRemaining[msg.sender] = totalAllocation;
    }

    require(nftNum > 0, "The number of purchases is incorrect.");
    require(
      whitelistSalePrice.mul(nftNum) == msg.value,
      "Incorrect eth amount."
    );
    require(totalSupply().add(nftNum) <= maxSupply, "Exceeds total supply.");
    require(
      whitelistRemaining[msg.sender] >= nftNum,
      "Exceeds remaining whitelist."
    );

    whitelistRemaining[msg.sender] -= nftNum;
    targetContract.mint(msg.sender, nftNum);
  }

  function totalSupply() public view returns (uint256) {
    return targetContract.totalSupply();
  }

  function withdrawAll(address withdrawAddress) public onlyOperator {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(withdrawAddress, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed.");
  }

  // setters
  function setMerkleRoot(bytes32 merkleRoot_) public onlyOperator {
    merkleRoot = merkleRoot_;
  }

  function setWhitelistSaleStart(uint256 whitelistSaleStart_)
    public
    onlyOperator
  {
    whitelistSaleStart = whitelistSaleStart_;
  }

  function setSaleStart(uint256 saleStart_) public onlyOperator {
    saleStart = saleStart_;
  }

  function setWhitelistSaleEnd(uint256 whitelistSaleEnd_) public onlyOperator {
    whitelistSaleEnd = whitelistSaleEnd_;
  }

  function setSaleEnd(uint256 saleEnd_) public onlyOperator {
    saleEnd = saleEnd_;
  }

  function setWhitelistSalePrice(uint256 whitelistSalePrice_)
    public
    onlyOperator
  {
    whitelistSalePrice = whitelistSalePrice_;
  }

  function setSalePrice(uint256 salePrice_) public onlyOperator {
    salePrice = salePrice_;
  }

  function setMaxByMint(uint256 maxByMint_) public onlyOperator {
    maxByMint = maxByMint_;
  }

  function setMaxSupply(uint256 maxSupply_) public onlyOperator {
    maxSupply = maxSupply_;
  }
}