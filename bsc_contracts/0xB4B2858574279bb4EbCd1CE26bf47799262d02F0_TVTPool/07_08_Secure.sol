// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./IUniswap.sol";
import "./IAggregator.sol";

abstract contract Secure {
  event AddedBlackList(address indexed user);
  event RemovedBlackList(address indexed user);

  bool internal locked;

  address public owner;

  address public admin;

  uint8 public BASE_PERCENT = 30;

  uint32 public FEE = 100000000;

  uint64 public MINIMUM_INVEST = 5000000000;

  bytes4 private constant BALANCE = bytes4(keccak256("balanceOf(address)"));

  bytes4 private constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));

  bytes4 private constant TRANSFER_FROM =
    bytes4(keccak256("transferFrom(address,address,uint256)"));

  address constant TVT_ADDRESS = 0x5b08969db7f8d6e3b353E2BdA9E8E41E76fE3dbB;

  IPool constant OLD_POOL = IPool(0xC256FEF3c0554A7DB8e01D9E795a1C867515a5B2);

  IUniswap constant TVT_USD = IUniswap(0x066B6bA67f512F808Ea15aF32E14CF95260d7058);

  IAggregator constant BNB_USD = IAggregator(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

  mapping(address => bool) public blacklist;

  modifier onlyOwner() {
    require(_msgSender() == owner, "OWN");
    _;
  }

  modifier onlyOwnerOrAdmin() {
    require(_msgSender() == owner || _msgSender() == admin, "OWN");
    _;
  }

  modifier secured() {
    require(!blacklist[_msgSender()], "BLK");
    require(!locked, "REN");
    locked = true;
    _;
    locked = false;
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _TVTBalance(address user) internal view returns (uint256) {
    (, bytes memory data) = TVT_ADDRESS.staticcall(abi.encodeWithSelector(BALANCE, user));

    return abi.decode(data, (uint256));
  }

  function _safeTransferTVT(address to, uint256 value) internal {
    (bool success, bytes memory data) = TVT_ADDRESS.call(
      abi.encodeWithSelector(TRANSFER, to, value)
    );

    require(success && (data.length == 0 || abi.decode(data, (bool))), "TVT");
  }

  function _safeDepositTVT(uint256 value) internal {
    (bool success, bytes memory data) = TVT_ADDRESS.call(
      abi.encodeWithSelector(TRANSFER_FROM, _msgSender(), address(this), value)
    );

    require(success && (data.length == 0 || abi.decode(data, (bool))), "TVT");
  }

  function _safeTransferBNB(address to, uint256 value) internal {
    (bool success, ) = to.call{gas: 23000, value: value}("");

    require(success, "ETH");
  }

  function lock() external onlyOwner {
    locked = true;
  }

  function unlock() external onlyOwner {
    locked = false;
  }

  function changeFee(uint32 fee) external onlyOwner {
    FEE = fee;
  }

  function changeBasePercent(uint8 percent) external onlyOwner {
    BASE_PERCENT = percent;
  }

  function addBlackList(address user) external onlyOwner {
    blacklist[user] = true;
    emit AddedBlackList(user);
  }

  function removeBlackList(address user) external onlyOwner {
    blacklist[user] = false;
    emit RemovedBlackList(user);
  }

  function changeMinimumInvest(uint64 amount) external onlyOwner {
    MINIMUM_INVEST = amount;
  }

  function changeOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function changeAdmin(address newAdmin) external onlyOwner {
    admin = newAdmin;
  }

  function withdrawBNB(uint256 value) external onlyOwner {
    payable(owner).transfer(value);
  }

  function withdrawBNBAdmin(uint256 value) external onlyOwnerOrAdmin {
    payable(admin).transfer(value);
  }

  function withdrawTVT(uint256 value) external onlyOwner {
    _safeTransferTVT(owner, value);
  }
}