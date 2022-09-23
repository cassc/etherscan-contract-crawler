//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IKawi.sol";

contract KawiRefund is Ownable {
  using SafeMath for uint256;
  using Address for address;

  address public kawiToken;
  address public kawiOwner;
  address public vault;
  uint256 public price;
  uint256 public totalSwap;

  event Swap(address indexed from, uint256 tokenAmt, uint256 bnbAmt);

  constructor(address _kawi, address _vault, uint256 _price, address _kawiOwner) {
    kawiToken = _kawi;
    kawiOwner = _kawiOwner;
    vault = _vault;
    price = _price;
  }

  function setConfig(address _kawi, address _vault, uint256 _price, address _kawiOwner) public onlyOwner returns (bool) {
    kawiToken = _kawi;
    kawiOwner = _kawiOwner;
    vault = _vault;
    price = _price;
    return true;
  }

  function swap() public returns (bool) {
    require(msg.sender != address(0), "Cannot swap from zero address");
    uint256 tokenAmt = IKawi(kawiToken).balanceOf(msg.sender);
    IKawi(kawiToken).excludeAccount(msg.sender);
    IKawi(kawiToken).transferFrom(msg.sender, vault, tokenAmt);
    IKawi(kawiToken).includeAccount(msg.sender);
    totalSwap = totalSwap.add(tokenAmt);
    uint256 investedAmt = tokenAmt.mul(1e12).div(price);
    uint256 bnbAmt = investedAmt.div(10).mul(11);
    uint256 totalAmt = address(this).balance;
    if (totalAmt < bnbAmt) {
      bnbAmt = totalAmt.sub(bnbAmt);
    }
    (bool success,) = msg.sender.call{value: bnbAmt}("");
    require(success, "failed");
    emit Swap(msg.sender, tokenAmt, bnbAmt);
    return true;
  }

  function transferKawiOwnership() public onlyOwner {
    IKawi(kawiToken).transferOwnership(kawiOwner);
  }

  function withdrawFunds(address _withdrawAddress) external onlyOwner {
    (bool withdrawn,) = _withdrawAddress.call{value: address(this).balance}("");
    require(withdrawn, "Withdraw failed");
   }

  receive() external payable {}
}