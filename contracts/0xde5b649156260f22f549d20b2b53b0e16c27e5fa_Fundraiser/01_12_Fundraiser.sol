// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Fundraiser is Ownable, Pausable, ERC20, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address private DAI;
  address private USDC;
  address private USDT;
  address private BUSD;

  string public _baseTokenURI;
  address private adminAddress;
  uint256 public version;
  uint256 public maxSupply = 0;

  struct multiWalletMintStruct {
    address wallet;
    uint256 amount;
  }

  constructor(
    uint256 _version,
    address _adminAddress,
    address _dai,
    address _usdc,
    address _usdt,
    address _busd,
    uint256 _maxSupply
  ) ERC20( "Pool shares", "PLSHRS") {
    require(_dai != address(0), "Zero address");
    require(_usdc != address(0), "Zero address");
    require(_usdt != address(0), "Zero address");
    require(_busd != address(0), "Zero address");
    require(_adminAddress != address(0), "Zero address");
    DAI = _dai;
    USDC = _usdc;
    USDT = _usdt;
    BUSD = _busd;
    adminAddress = _adminAddress;
    version = _version;
    maxSupply = _maxSupply;
  }

  function publicSaleMint(address token, uint256 quantity) external whenNotPaused {
    if (hasMaxSupplyLimits()) {
      uint256 toMint = quantity.add(totalSupply());
      require(toMint <= maxSupply, "Invalid amount to mint");
    }
    receiveFunds(token, quantity);
    _mint(msg.sender, quantity);
  }

  function multiWalletMint(multiWalletMintStruct[] memory walletInfo) external onlyOwner {
    if (hasMaxSupplyLimits()) {
      uint256 toMint = totalSupply();
      for(uint8 i = 0; i < walletInfo.length; i++){
        toMint = toMint.add(walletInfo[i].amount);
      }
      require(toMint <= maxSupply, "Invalid amount to mint");
    }

    for(uint8 i = 0; i < walletInfo.length; i++){
      _mint(walletInfo[i].wallet, walletInfo[i].amount);
    }
  }

  function hasMaxSupplyLimits() public view returns (bool) {
    return maxSupply != 0;
  }

  function getMintableAmount() external view returns (uint256) {
    if (hasMaxSupplyLimits()) {
      return maxSupply.sub(totalSupply());
    } else {
      uint256 maxMintable = type(uint256).max;
      return maxMintable.sub(totalSupply());
    }
  }

  function getVersion() external view returns (uint256) {
    return version;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function receiveFunds(address token, uint256 amount) private {
    require(token == USDC || token == DAI || token == BUSD || token == USDT, "Invalid currency");
    IERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney(address token) external onlyOwner nonReentrant {
    require(token == USDC || token == DAI || token == BUSD || token == USDT, "Invalid currency");
    withdraw(USDC);
    withdraw(USDT);
    withdraw(DAI);
    withdraw(BUSD);
  }

  function withdraw(address token) private {
    uint amount = IERC20(token).balanceOf(address(this));
    if (amount > 0) {
      uint256 adminFee = amount.mul(5).div(1000);
      IERC20(token).transferFrom(address(this), msg.sender, amount.sub(adminFee));
      IERC20(token).transferFrom(address(this), msg.sender, adminFee);
    }
  }
}