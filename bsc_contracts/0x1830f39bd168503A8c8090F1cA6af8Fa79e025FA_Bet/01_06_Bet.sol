// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bet is Ownable {

  using ECDSA for bytes32;

  mapping(uint256 => bool) public usedNonces;
  mapping(address => uint256) public referrerBalance;
  address public immutable signer;
  IERC20 public immutable token;
  address public coliseums;

  event NewDeposit(address indexed from, uint256 amount, address indexed referrer);
  event PaymentClaimed(address indexed recipient, uint256 amount, uint256 nonce);
  event Withdrawal(uint256 coliseumFees, uint256 teamFees);
  event ReferrerWithdrawal(address indexed referrer, uint256 balance);

  constructor(IERC20 _token, address _coliseums, address _signer) {
    require(_coliseums != address(0), "Coliseums is address 0");
    require(_signer != address(0), "Signer is address 0");
    require(address(_token) != address(0), "Token is address 0");
    coliseums = _coliseums;
    signer = _signer;
    token = _token;
  }

  /**
   * @dev Marks a nonce as used.
   * Throws if the nonce is already used.
   */
  modifier consumeNonce(uint256 nonce) {
    require(!usedNonces[nonce], "Signature already used");
    usedNonces[nonce] = true;
    _;
  }

  function setColiseumsAddress(address _coliseums) external onlyOwner {
    require(_coliseums != address(0), "Coliseums is address 0");
    coliseums = _coliseums;
  }

  /**
   * @dev Lets users deposit `amount` token.
   *
   * 1% of `amount` goes to `referrer`. If no `referrer` is
   * present (address = address(0)), fee goes to team and coliseum owners.
   */
  function depositPayment(uint256 amount, address referrer) external {
    require(msg.sender != referrer, "Cannot auto refer");
    uint256 fee = amount / 100; // 1% fee
    referrerBalance[referrer] += fee;
    token.transferFrom(msg.sender, address(this), amount);
    emit NewDeposit(msg.sender, amount - fee, referrer);
  }

  /**
   * @dev Lets users claim a payment using an authorized `signature` from `signer`.
   *
   * The signed message must include the address of the recipient (in this case, msg.sender),
   * and the `amount` that is to be transferred.
   * In addition, the message also includes a `nonce` and the address of a particular Bet
   * contract to protect against replay attacks.
   */
  function claimPayment(uint256 amount, uint256 nonce, bytes calldata signature) external consumeNonce(nonce) {
    // Recreates the message present in the `signature`
    bytes32 message = keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this))).toEthSignedMessageHash();
    require(message.recover(signature) == signer, "Invalid signature");

    token.transfer(msg.sender, amount);
    emit PaymentClaimed(msg.sender, amount, nonce);
  }

  /**
   * @dev Allows referrers to withdraw their balance.
   */
  function withdrawReferralBalance() external {
    assert(msg.sender != address(0));
    uint256 balance = referrerBalance[msg.sender];
    referrerBalance[msg.sender] = 0;
    token.transfer(msg.sender, balance);
    emit ReferrerWithdrawal(msg.sender, balance);
  }

  /**
   * @dev Sends collected fees to contract owner and Coliseums contract,
   * including fight fees (`teamFees` and `coliseumFees`) authorized by 
   * the signer through a `signature`.
   *
   * See {depositPayment}.
   */
  function withdrawFees(uint256 teamFees, uint256 coliseumFees, uint256 nonce, bytes calldata signature) external onlyOwner consumeNonce(nonce) {
    bytes32 message = keccak256(abi.encodePacked(msg.sender, teamFees, coliseumFees, nonce, address(this))).toEthSignedMessageHash();
    require(message.recover(signature) == signer, "Invalid signature");

    uint256 coliseumAndTeamBalance = referrerBalance[address(0)] / 2;
    uint256 coliseumShares = coliseumAndTeamBalance + coliseumFees;
    uint256 teamShares = coliseumAndTeamBalance + teamFees;

    referrerBalance[address(0)] = 0;
    token.transfer(coliseums, coliseumShares);
    token.transfer(owner(), teamShares);

    emit Withdrawal(coliseumShares, teamShares);
  }

}