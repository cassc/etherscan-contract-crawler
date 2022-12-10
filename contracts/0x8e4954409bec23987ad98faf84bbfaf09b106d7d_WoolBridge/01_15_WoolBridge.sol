// SPDX-License-Identifier: NO LICENSE  

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../token/WOOL.sol";

contract WoolBridge is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using ECDSA for bytes32;

  
  address public signer;
  WOOL public wool;
  uint256 public waitingPeriod;

  struct Withdrawal {
    bool claimed;
    uint88 timestamp;
    address recipient;
    uint256 amount;
  }

  mapping(uint256 => Withdrawal) public withdrawals;

  event Deposit(
    address depositor,
    uint256 amount
  );

  event WithdrawalStarted(
    uint256 id,
    address recipient,
    uint256 amount
  );

  event WithdrawalCompleted(
    uint256 id,
    address recipient,
    uint256 amount
  );

  /**
   * instantiates contract
   * @param _signer the address of the server signing the messages
   * @param _wool the address of the WOOL contract
  */
  function initialize(
    address _signer,
    address _wool
  ) external initializer {
    __Ownable_init();
    __Pausable_init();

    signer = _signer;
    wool = WOOL(_wool);
    waitingPeriod = 3 days;
  }

  /**
   * burns WOOL on-chain to be represented off-chain
   * @param amount the amount of WOOL to bridge on-chain
   */
  function deposit(uint256 amount) external whenNotPaused {
    wool.burn(_msgSender(), amount);
    emit Deposit(_msgSender(), amount);
  }

  /**
   * creates a claimable amount of WOOL, held for a delay for security purposes
   * @param signature the signature created off-chain to verify the withdrawal
   * @param withdrawalId the ID of the withdrawal to stop duplications
   * @param amount the amount of WOOL being claimed (only used for verification)
   */
  function beginWithdrawal(bytes memory signature, uint256 withdrawalId, uint256 amount) external whenNotPaused {
    require(withdrawals[withdrawalId].recipient == address(0x0), "Withdrawal already started");
    bytes memory packed = abi.encode(_msgSender(), withdrawalId, amount);
    bytes32 messageHash = keccak256(packed);
    require(
      messageHash.toEthSignedMessageHash().recover(signature) == signer,
      "THAT SIGNATURE IS A FAKE"
    );

    withdrawals[withdrawalId] = Withdrawal({
      claimed: false,
      timestamp: uint88(block.timestamp),
      recipient: _msgSender(),
      amount: amount
    });

    emit WithdrawalStarted(withdrawalId, _msgSender(), amount);
  }

  /**
   * finishes the withdrawal after the delay period has passed
   * @param withdrawalIds ids of withdrawals to complete
   */
  function finishWithdrawal(uint256[] calldata withdrawalIds) external whenNotPaused {
    uint256 withdrawable;
    for (uint256 i = 0; i < withdrawalIds.length; i++) {
      Withdrawal storage withdrawal = withdrawals[withdrawalIds[i]];
      require(withdrawal.claimed == false, "WOOL already claimed");
      require(withdrawal.recipient == _msgSender(), "NOT YOUR WOOL");
      require(withdrawal.timestamp < block.timestamp - waitingPeriod, "Waiting period not yet complete");
      withdrawable += withdrawal.amount;
      withdrawal.claimed = true;
      emit WithdrawalCompleted(withdrawalIds[i], _msgSender(), withdrawal.amount);
    }
    wool.mint(_msgSender(), withdrawable);
  }

  /**
   * enables owner to pause / unpause claiming
   * @param _p the new pause state
  */
  function setPaused(bool _p) external onlyOwner {
    if (_p) _pause();
    else _unpause();
  }

  /**
   * updates the signer of claims
   * @param _signer the new signing address
  */
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function nullifyWithdrawals(uint256[] calldata withdrawalIds) external onlyOwner {
    for (uint256 i = 0; i < withdrawalIds.length; i++) {
      withdrawals[withdrawalIds[i]].amount = 0;
    }
  }

  function setWaitingPeriod(uint256 _period) external onlyOwner {
    waitingPeriod = _period;
  }
}