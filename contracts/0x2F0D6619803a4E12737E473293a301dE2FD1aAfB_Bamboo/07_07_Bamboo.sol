// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Official Bamboo ($BAM) contract
 * @author artpumpkin
 */
contract Bamboo is ERC20Burnable, Ownable {
  uint256 public buyFee;
  uint256 public sellFee;
  address public pair;
  address public devWallet;

  mapping(address => bool) public excludedFromFees;

  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _initialSupply,
    uint8 _buyFee,
    uint8 _sellFee
  ) ERC20(_name, _symbol) {
    _mint(_msgSender(), _initialSupply);

    _setBuyFeePercent(_buyFee);
    _setSellFeePercent(_sellFee);

    emit Deployed(_msgSender(), _name, _symbol);
  }

  /**
   * @notice Gets the ERC20 token decimals
   * @return totalStake The ERC20 token decimals
   */
  function decimals() public view virtual override returns (uint8) {
    return 9;
  }

  /**
   * @notice Excludes or includes a user from paying fees
   * @param user User address
   * @param excluded Excluded boolean value
   */
  function setExcluded(address user, bool excluded) external onlyOwner {
    excludedFromFees[user] = excluded;

    emit ExcludedSet(_msgSender(), user, excluded);
  }

  /**
   * @notice Updates buy fee percentage
   * @param feePercent Buy fee percentage .e.g 5 for 5%
   * @dev Fee can only be reduced so make sure to double check the inputed values
   */
  function setBuyFeePercent(uint8 feePercent) public onlyOwner {
    require(feePercent < buyFee, "Bamboo::setBuyFeePercent: can only reduce buy fee");

    _setBuyFeePercent(feePercent);
  }

  /**
   * @notice Updates buy fee percentage
   * @param feePercent Buy fee percentage .e.g 5 for 5%
   */
  function _setBuyFeePercent(uint8 feePercent) private {
    buyFee = feePercent;

    emit BuyFeeSet(_msgSender(), feePercent);
  }

  /**
   * @notice Updates sell fee percentage
   * @param feePercent Sell fee percentage .e.g 5 for 5%
   * @dev Fee can only be reduced so make sure to double check the inputed values
   */
  function setSellFeePercent(uint8 feePercent) public onlyOwner {
    require(feePercent < sellFee, "Bamboo::setSellFeePercent: can only reduce sell fee");

    _setSellFeePercent(feePercent);
  }

  /**
   * @notice Updates sell fee percentage
   * @param feePercent Sell fee percentage .e.g 5 for 5%
   */
  function _setSellFeePercent(uint8 feePercent) private {
    sellFee = feePercent;

    emit SellFeeSet(_msgSender(), feePercent);
  }

  /**
   * @notice Updates dev wallet address
   * @param _devWallet Dev wallet address to set
   */
  function setDevWallet(address _devWallet) external onlyOwner {
    devWallet = _devWallet;

    emit DevWalletSet(_msgSender(), _devWallet);
  }

  /**
   * @notice Updates pair address
   * @param _pair Pair address to set
   * @dev This is essentially the LP pair address
   */
  function setPair(address _pair) external onlyOwner {
    pair = _pair;

    emit PairSet(_msgSender(), _pair);
  }

  /**
   * @notice Transfers tokens between 2 users
   * @param sender Sender address
   * @param recipient Recipient address
   * @param amount Amount to transfer
   * @dev Make sure to initialze both pair and devWallet addresses
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    require(pair != address(0), "Bamboo::_transfer: pair unitialized");
    require(devWallet != address(0), "Bamboo::_transfer: devWallet unitialized");

    uint256 devAmount = 0;
    if (sender == pair && !excludedFromFees[recipient]) {
      devAmount = (amount * buyFee) / 100;
    } else if (recipient == pair && !excludedFromFees[sender]) {
      devAmount = (amount * sellFee) / 100;
    }

    if (devAmount > 0) {
      amount -= devAmount;
      ERC20._transfer(sender, devWallet, devAmount);
    }

    ERC20._transfer(sender, recipient, amount);
  }

  event Deployed(address indexed sender, string name, string symbol);
  event ExcludedSet(address indexed sender, address user, bool excluded);
  event BuyFeeSet(address indexed sender, uint256 fee);
  event SellFeeSet(address indexed sender, uint256 fee);
  event DevWalletSet(address indexed sender, address devWallet);
  event PairSet(address indexed sender, address pair);
}