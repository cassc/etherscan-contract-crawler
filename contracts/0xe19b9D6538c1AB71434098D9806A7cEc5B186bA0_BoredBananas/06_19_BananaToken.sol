// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./BoredBananas.sol";

contract BananaToken is ERC20Burnable, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _cBalance;
  mapping(address => uint256) private _cBlockRef;
  mapping(address => uint256) private _nftBalance;
  uint256 public totalNFTs;
  uint256 public totalBurned;
  uint256 public halvingBlockInterval = 1 << 18; // The interval at the growth rate halves, 1 << 18 = 262144 blocks
  uint256 public startingGrowthRate = 10; // The rate at which new tokens are generated in a Banana owner's wallet, starts at 1 << 10 = 1024 blocks
  uint256 public growthRateFloor = 15; // The lowest growth rate which will not be halved anymore, 1 << 15 = 32768 blocks

  uint256 public startingBlock = 0; // The block from which token generation starts, 0 means that token generation has not been activated yet

  BoredBananas private creator;
  
  constructor(address contractOwner) ERC20("Bored Banana Token", "$BANANA") {
    transferOwnership(contractOwner);
    creator = BoredBananas(msg.sender);
  }

  function boredBananaContractAddress() public view returns (address) {
    return address(creator);
  }

  modifier onlyCreator() {
    require(address(creator) == msg.sender, "Only the parent BoredBananas ERC721 contract can perform this action");
    _;
  }

  function decimals() public pure override returns (uint8) {
    return 0;
  }

  function totalSupply() public view override returns (uint256) {
    // supply = 0 if token generation has not been activated
    if (startingBlock == 0) return 0; 

    return _getGrowthToBlock(startingBlock, block.number).mul(totalNFTs).sub(totalBurned);
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _cBalance[account] + _getGrowthToBlock(_cBlockRef[account], block.number).mul(_nftBalance[account]);
  }

  function _commitBalance(address account) private returns (uint256) {
    if (_nftBalance[account] > 0) {
      _cBalance[account] = balanceOf(account);
    }
    
    _cBlockRef[account] = block.number;

    return _cBalance[account];
  }

  function _getGrowthToBlock(uint256 fromBlock, uint256 toBlock) private view returns (uint256) {
    // 0 growth if token generation has not been activated
    if (startingBlock == 0) return 0;
    if (fromBlock < startingBlock) fromBlock = startingBlock;
    
    uint256 refBlock = startingBlock;
    uint256 rate = startingGrowthRate;
    uint256 total = 0;
    while((fromBlock > (refBlock + halvingBlockInterval)) && (rate < growthRateFloor)) {
      rate++;
      refBlock += halvingBlockInterval;
    }

    // start = last block before fromBlock where growth should occur
    uint256 start = refBlock + (((fromBlock - refBlock) >> rate) << rate); 
    
    // if fromBlock and toBlock are within the same halving interval
    if ((toBlock < (refBlock + halvingBlockInterval)) || (rate == growthRateFloor)) {
      return (toBlock - start) >> rate;
    }

    total += (refBlock + halvingBlockInterval - start) >> rate;
    if (rate < growthRateFloor) rate++;
    refBlock += halvingBlockInterval;

    while ((toBlock > (refBlock + halvingBlockInterval)) && (rate < growthRateFloor)) {
      total += halvingBlockInterval >> rate;
      rate++;
      refBlock += halvingBlockInterval;
    }

    total += (toBlock - refBlock) >> rate;

    return total;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      uint256 senderBalance = _commitBalance(sender);
      uint256 recipientBalance = _commitBalance(recipient);

      require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
      unchecked {
          _cBalance[sender] = senderBalance - amount;
      }
      _cBalance[recipient] = recipientBalance + amount;

      emit Transfer(sender, recipient, amount);
  }

  function _burn(address account, uint256 amount) internal override {
      require(account != address(0), "ERC20: burn from the zero address");

      uint256 accountBalance = _commitBalance(account);
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
      unchecked {
          _cBalance[account] = accountBalance - amount;
      }
      totalBurned += amount;

      emit Transfer(account, address(0), amount);
  }

  function bananaTransferred(address from, address to) public onlyCreator {
    if (from == address(0)) {
      require(startingBlock == 0, "Token generation has already been activated");
      totalNFTs++;
    } else {
      _commitBalance(from);
      _nftBalance[from] -= 1;
    }

    _commitBalance(to);
    _nftBalance[to] += 1;
  }

  function activate() external onlyOwner{
    require(startingBlock == 0, "Already activated");

    startingBlock = block.number;
  }
}