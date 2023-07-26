// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Launchpad is Pausable, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 public token;
  uint256 public tokenDecimals;
  uint256 public saleTokenAmount;
  uint256 public reservedTokenAmount;

  uint256 public poolCreationDate;
  uint256 public minSaleTotal;
  uint256 public maxSaleTotal;
  uint256 public minSaleEnter;
  uint256 public maxSaleEnter;
  uint256 public saleLength;
  uint256 public ethPerToken;

  bool public userAllowedToWithdraw;
  bool public ownerAllowedToWithdraw;
  bool public isClosed;

  address private adminAddress;

  string public _baseTokenURI;

  mapping(address => uint256) public deposits;
  uint256 public depositTotal;

  struct multiWalletMintStruct {
    address wallet;
    uint256 amount;
  }

  constructor(
    address _adminAddress,
    address _token,
    uint256 _tokenDecimals,
    uint256 _minSaleTotal,
    uint256 _minSaleEnter,
    uint256 _maxSaleEnter,
    uint256 _saleLength,
    uint256 _ethPerToken
  ) {
    require(_token != address(0), "Zero address");
    require(_adminAddress != address(0), "Zero address");

    minSaleTotal = _minSaleTotal;
    minSaleEnter = _minSaleEnter;
    maxSaleEnter = _maxSaleEnter;
    saleLength = _saleLength;
    ethPerToken = _ethPerToken;
    poolCreationDate = block.timestamp;

    userAllowedToWithdraw = false;
    ownerAllowedToWithdraw = false;
    isClosed = false;

    token = IERC20(_token);
    tokenDecimals = _tokenDecimals;

    adminAddress = _adminAddress;
  }

  function deposit(uint256 _amount) external whenNotPaused onlyOwner {
    require(!isClosed, "Closed");
    require(_amount > 0, "Invalid amount");

    saleTokenAmount += _amount;
    maxSaleTotal = (ethPerToken * saleTokenAmount) / 10**tokenDecimals;
    require(minSaleTotal < maxSaleTotal, "Exceeded total deposit limit");
    token.safeTransferFrom(msg.sender, address(this), _amount);
    closeIfNeeded();
  }

  function participate() payable external whenNotPaused {
    require(!isClosed && token.balanceOf(address(this)) > 0, "Not allowed to participate");
    require(block.timestamp - poolCreationDate < saleLength, "Sale expired");

    uint256 _depositTotal = depositTotal + msg.value;
    require(_depositTotal <= maxSaleTotal, "Exceeded total deposit limit");

    uint256 _userDepositTotal = deposits[msg.sender] + msg.value;
    require(_userDepositTotal <= maxSaleEnter, "Exceeded deposit limit");
    require(_userDepositTotal >= minSaleEnter, "Invalid amount");

    deposits[msg.sender] += msg.value;
    depositTotal = _depositTotal;
    reservedTokenAmount += getTokenAmount(msg.value);
    closeIfNeeded();
  }

  function userClaim() external nonReentrant {
    require(getUserCanClaim(), "Not allowed to withdraw");
    require(token.balanceOf(address(this)) > 0, "Insufficient balance");

    uint256 userBalance = deposits[msg.sender];
    deposits[msg.sender] = 0;
    depositTotal -= userBalance;
    token.safeTransfer(msg.sender, getTokenAmount(userBalance));
  }

  function userWithdraw() external nonReentrant {
    uint balance = address(this).balance;
    require(getUserCanWithdraw(), "Not allowed to withdraw");
    require(balance >= deposits[msg.sender], "Insufficient balance");

    uint256 userBalance = deposits[msg.sender];
    deposits[msg.sender] = 0;
    depositTotal -= userBalance;
    payable(msg.sender).transfer(userBalance);
  }

  function withdraw() external onlyOwner nonReentrant {
    require(isClosed, "Not allowed to withdraw");

    if (ownerAllowedToWithdraw) {
      uint balance = address(this).balance;

      if (balance > 0) {
        uint256 adminFee = balance.mul(175).div(10000); // 1.75% fee
        payable(msg.sender).transfer(balance.sub(adminFee));
        payable(adminAddress).transfer(adminFee);
      }
      if (saleTokenAmount - reservedTokenAmount > 0) {
        token.safeTransfer(msg.sender, saleTokenAmount - reservedTokenAmount);
      }
    } else if (userAllowedToWithdraw) {
      token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function close() external onlyOwner nonReentrant {
    require(!isClosed, "Already closed");
    uint balance = address(this).balance;

    isClosed = true;
    if (balance < minSaleTotal) {
      userAllowedToWithdraw = true;
      ownerAllowedToWithdraw = false;
    } else {
      userAllowedToWithdraw = false;
      ownerAllowedToWithdraw = true;
    }
  }

  function closeIfNeeded() private nonReentrant {
    uint balance = address(this).balance;

    if (block.timestamp - poolCreationDate >= saleLength) {
      isClosed = true;
      if (balance < minSaleTotal) {
        userAllowedToWithdraw = true;
        ownerAllowedToWithdraw = false;
      } else {
        userAllowedToWithdraw = false;
        ownerAllowedToWithdraw = true;
      }
    } else {
      if (balance >= maxSaleTotal) {
        isClosed = true;

        userAllowedToWithdraw = false;
        ownerAllowedToWithdraw = true;
      }
    }
  }

  function getUserCanClaim() public view returns (bool) {
    return isClosed && !userAllowedToWithdraw && ownerAllowedToWithdraw;
  }

  function getUserCanWithdraw() public view returns (bool) {
    return isClosed && userAllowedToWithdraw;
  }

  function getUserClaimableAmount(address _user) external view returns (uint256) {
    return maxSaleEnter - deposits[_user];
  }

  function getClaimableAmount() external view returns (uint256) {
    return maxSaleTotal - depositTotal;
  }

  function getTokenAmount(uint256 _eth) public view returns (uint256) {
    return (_eth / ethPerToken) * 10**tokenDecimals;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  receive() external payable {}

  fallback() external payable {}
}