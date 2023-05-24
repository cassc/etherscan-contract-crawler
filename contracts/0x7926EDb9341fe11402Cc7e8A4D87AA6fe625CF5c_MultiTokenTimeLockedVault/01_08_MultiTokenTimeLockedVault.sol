// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TwoStepOwnable.sol";

contract MultiTokenTimeLockedVault is TwoStepOwnable {
  using SafeERC20 for IERC20;

  uint256 private _depositIdCounter;
  uint256 private withdrawableDepositFees;
  uint256 public depositFee;

  struct Deposit {
    uint256 id;
    address depositor;
    address unlockableBy;
    address token;
    uint256 amount;
    uint256 unlockTimestamp;
  }

  mapping(uint256 => Deposit) public depositInfo;
  mapping(address => bool) public tokenWhitelist;

  event DepositFeeUpdated(uint256 newFee);
  event TokenWhitelisted(address token);
  event TokenRemovedFromWhitelist(address token);
  event DepositMade(
    uint256 depositId,
    address depositor,
    address unlockableBy,
    address token,
    uint256 amount,
    uint256 unlockTimestamp
  );
  event Withdrawal(
    uint256 depositId,
    address depositor,
    address unlockableBy,
    address token,
    uint256 amount
  );
  event FeesWithdrawn(address owner, uint256 amount);

  modifier onlyWhitelistedToken(address token) {
    require(tokenWhitelist[token], "Token is not whitelisted.");
    _;
  }

  function addToWhitelist(address token) public onlyOwner {
    tokenWhitelist[token] = true;
    emit TokenWhitelisted(token);
  }

  function removeFromWhitelist(address token) public onlyOwner {
    tokenWhitelist[token] = false;
    emit TokenRemovedFromWhitelist(token);
  }

  function setDepositFee(uint256 newFee) public onlyOwner {
    depositFee = newFee;
    emit DepositFeeUpdated(newFee);
  }

  function deposit(
    address token,
    uint256 amount,
    address unlockableBy,
    uint256 unlockTimestamp
  ) public payable onlyWhitelistedToken(token) returns (uint256) {
    // Check the user is paying the correct deposit fee
    require(
      msg.value == depositFee,
      "Incorrect deposit fee. Please send the required amount."
    );

    // Check the deposit parameters
    require(amount > 0, "Amount must be greater than 0.");
    require(
      unlockTimestamp > block.timestamp,
      "Unlock timestamp must be in the future."
    );

    // Add the deposit fee to the withdrawable fees
    withdrawableDepositFees += msg.value;

    // Transfer the deposit tokens to this contract
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // Store the deposit details
    _depositIdCounter++;
    uint256 depositId = _depositIdCounter;
    depositInfo[depositId] = Deposit({
      id: depositId,
      depositor: msg.sender,
      unlockableBy: unlockableBy,
      token: token,
      amount: amount,
      unlockTimestamp: unlockTimestamp
    });

    emit DepositMade(
      depositId,
      msg.sender,
      unlockableBy,
      token,
      amount,
      unlockTimestamp
    );

    return depositId;
  }

  // To withdraw the tokens after the unlock timestamp
  function withdraw(uint256 depositId) public {
    Deposit storage userDeposit = depositInfo[depositId];

    // Check the user is the depositor
    require(
      userDeposit.unlockableBy == msg.sender,
      "Only the specificed unlocker can withdraw."
    );

    require(
      block.timestamp >= userDeposit.unlockTimestamp,
      "Deposit is still locked."
    );

    uint256 amount = userDeposit.amount;
    require(amount > 0, "No unlocked tokens to withdraw.");

    // Update the deposit information
    userDeposit.amount = 0;

    // Transfer the tokens back to the depositor
    IERC20(userDeposit.token).safeTransfer(msg.sender, amount);

    emit Withdrawal(
      depositId,
      msg.sender,
      userDeposit.unlockableBy,
      userDeposit.token,
      amount
    );
  }

  // To withdraw fees from Vaulty creation fees pool
  function withdrawFees() public onlyOwner {
    uint256 amount = withdrawableDepositFees;
    require(amount > 0, "No fees to withdraw.");

    // Reset the withdrawable fees
    withdrawableDepositFees = 0;

    // Transfer the fees to the owner
    payable(msg.sender).transfer(amount);

    emit FeesWithdrawn(msg.sender, amount);
  }
}