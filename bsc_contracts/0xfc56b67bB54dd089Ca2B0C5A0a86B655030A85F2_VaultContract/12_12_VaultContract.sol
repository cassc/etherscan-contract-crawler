//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract VaultContract is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  address internal operator;

  mapping(address => uint256) internal _deposits;
  mapping(address => uint256) internal _payments;
  mapping(string => address) internal _fundWallets;

  IERC20Upgradeable internal busd;

  struct UserStatus {
    uint256 deposits;
    uint256 available;
  }

  function initialize(
    address _busd, 
    address _operator
  ) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    operator = _operator;

    busd = IERC20Upgradeable(_busd);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  function getBUSDAllowance(address _wallet) public virtual view returns (uint256) {
    return busd.allowance(_wallet, address(this));
  }

  function setFundWalletAddress(string memory _type, address _address) public onlyOperator returns (bool) {
    _fundWallets[_type] = _address;
    return true;
  }
    
  function deposit(uint256 _amount, string memory _fundType) public virtual returns (bool) {
    require(_amount > 0, "Amount should be more than 0");
    require(getBUSDAllowance(msg.sender) >= _amount, "Approve BUSD before any deposit");

    // perform transfer
    require(busd.transferFrom(msg.sender, address(this), _amount), "BUSD Deposit was failed");

    _deposits[msg.sender] += _amount;

    emit Deposit(msg.sender, _amount, _fundType);

    return true;
  }

  function transferToInvestor(address _who, uint256 _amount) public onlyOperator returns (bool) {
    uint256 _liquidity = _contractLiquidity();

    require(_liquidity >= _amount, "Contract does not have sufficient liquidity");

    require(busd.transfer(_who, _amount), "Payment transaction failed");

    emit Claim(_who, _amount);

    return true;
  }

  function transferFunds(uint256 _amount, string memory _fundType) public onlyOperator returns (bool) {
    uint256 _liquidity = _contractLiquidity();
    require(_amount > 0, "Amount should be more than 0");
    require(_liquidity >= _amount, "Contract does not have sufficient liquidity");

    address wallet = _fundWallets[_fundType];
    require(wallet != address(0), "Invalid wallet");

    require(busd.transfer(wallet, _amount), "BUSD fund was failed");

    return true;
  }

  function userStatus(address who) public virtual view returns (uint256 deposits, uint256 payments) {
    return (_deposits[who], _payments[who]);
  }

  function contractLiquidity() public onlyOperator view returns (uint256) {
    return busd.balanceOf(address(this));
  }

  function _contractLiquidity() internal view returns (uint256) {
    return busd.balanceOf(address(this));
  }

  modifier onlyOperator() {
    require(msg.sender == operator, "Not allowed");
    _;
  }

  event Deposit(address wallet, uint256 amount, string fundType);
  event Claim(address wallet, uint256 amount);
}