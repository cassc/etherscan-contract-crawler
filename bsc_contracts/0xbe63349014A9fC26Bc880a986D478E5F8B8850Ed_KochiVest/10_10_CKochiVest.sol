// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// openzeppelin contracts
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// interface and library
import "../interfaces/IKochiVest.sol";
import "../libraries/LTransfers.sol";

// hardhat tools
// DEV ENVIRONMENT ONLY
// import "hardhat/console.sol";

// this contract allows to lock liquidity cheaply and on multiple DEXs
contract KochiVest is ContextUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IKochiVest {
  mapping(address => SVestMetadata[]) public vestings;
  mapping(address => mapping(address => uint256)) public released;

  function initialize() public initializer {
    __Context_init();
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
  }

  function vestETH(EVestType vest_type, address beneficiary, uint256 startline, uint256 deadline) external payable override nonReentrant whenNotPaused {
    require(msg.value > 0, "KochiVest: amount is 0");
    require(startline < deadline, "KochiVest: startline must be less than deadline");

    // update metadata
    SVestMetadata memory vesting = SVestMetadata(vest_type, beneficiary, address(0), msg.value, startline, deadline);
    vestings[beneficiary].push(vesting);

    emit Vested(vest_type, beneficiary, address(0), msg.value, startline, deadline);
  }

  function vest(EVestType vest_type, address beneficiary, address token, uint256 amount, uint256 startline, uint256 deadline) external override nonReentrant whenNotPaused {
    require(token != address(0), "KochiVest: token is invalid");
    require(amount > 0, "KochiVest: amount is 0");
    require(startline < deadline, "KochiVest: startline must be less than deadline");

    // transfer token to this contract, or revert.
    LTransfers.internalTransferFrom(_msgSender(), address(this), amount, IERC20(token));

    // update metadata
    SVestMetadata memory vesting = SVestMetadata(vest_type, beneficiary, token, amount, startline, deadline);
    vestings[beneficiary].push(vesting);

    emit Vested(vest_type, beneficiary, token, amount, startline, deadline);
  }

  function releaseETH() external override nonReentrant {
    // get releasable amount
    uint256 amount = _releasable(_msgSender(), address(0));

    // update released amount
    require(amount > 0, "KochiVest: nothing to withdraw");
    released[address(0)][_msgSender()] += amount;

    // release the tokens
    bool sent = false;
    (sent, ) = _msgSender().call{value: amount}("");
    require(sent, "Failed to send Ether");

    emit Released(_msgSender(), address(0), amount);
  }

  function release(address token) external override nonReentrant {
    require(token != address(0), "KochiVest: token is invalid");

    // get releasable amount
    uint256 amount = _releasable(_msgSender(), token);

    // update released amount
    require(amount > 0, "KochiVest: nothing to withdraw");
    released[token][_msgSender()] += amount;

    // release the tokens
    LTransfers.internalTransferTo(_msgSender(), amount, IERC20(token));

    emit Released(_msgSender(), token, amount);
  }

  function releasableETH(address user) external view override returns (uint256) {
    return _releasable(user, address(0));
  }

  function releasable(address user, address token) external view override returns (uint256) {
    return _releasable(user, token);
  }

  function _releasable(address user, address token) internal view returns (uint256) {
    uint256 amount = 0;

    SVestMetadata[] memory vesting = vestings[user];

    for (uint256 i = 0; i < vesting.length; i++) {
      if (vesting[i].token == token) amount += vestingSchedule(vesting[i]);
    }

    amount -= released[token][user]; // should never undeflow.

    return amount;
  }

  // using block.timestamp should be fine here, as we are looking for times far in the future.
  function vestingSchedule(SVestMetadata memory vesting) internal view returns (uint256) {
    // before, after.
    if (vesting.startline > block.timestamp) return 0;
    if (vesting.deadline < block.timestamp) return vesting.amount;

    // can implement more algos.
    if (vesting.vest_type == EVestType.linear) return (vesting.amount * (block.timestamp - vesting.startline)) / (vesting.deadline - vesting.startline);

    return 0; // should not happen unless vest_type overflow
  }
}