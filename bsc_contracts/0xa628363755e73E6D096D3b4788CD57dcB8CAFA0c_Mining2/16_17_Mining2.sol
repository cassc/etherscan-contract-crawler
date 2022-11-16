// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./Referral2.sol";
import "./Agent2.sol";
import "../Tools.sol";

contract Mining2 is Agent2, Pausable {
    using SafeERC20 for IERC20;

    address public feeTo;
    uint256 public feeRate;

    mapping(address => uint256) public currentNonces;
    mapping(address => uint256) public fixedNonces;
    mapping(address => uint256) public rewardNonces;

    event FixedDeposited(address indexed account, uint256 indexed period, uint256 amount);
    event Withdrawn(
        address indexed account,
        uint256 indexed nonce,
        uint256 principal,
        uint256 interest,
        uint256 withdrawType
    );
    event RewardWithdrawn(address indexed account, uint256 indexed nonce, uint256 interest);

    constructor(
        address _agent,
        address _referral,
        address _dot
    ) Agent2(_agent, _referral, _dot) {
        feeTo = 0xfdb955332520206A83F13B224B2dcCADdB7C0340;
        feeRate = 1000;
    }

    function pause() public check {
        _pause();
    }

    function unpause() public check {
        _unpause();
    }

    function setFeeTo(address _feeTo) external check {
        feeTo = _feeTo;
    }

    function setFeeRate(uint256 _feeRate) external check {
        feeRate = _feeRate;
    }

    function fixedDeposit(uint256 _period, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert();
        if (referral.isRegistered(msg.sender) == false) revert();

        dot.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 fee = (_amount * feeRate) / 10000;
        dot.safeTransfer(feeTo, fee);

        emit FixedDeposited(msg.sender, _period, _amount);
    }

    function currentWithdraw(
        address account,
        uint256 deadline,
        uint256 principal,
        uint256 interest,
        bytes memory signature
    ) external whenNotPaused {
        if (block.timestamp > deadline) revert();
        uint256 nonce = currentNonces[account];
        bytes memory message = abi.encode(nonce, account, deadline, principal, interest);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();
        currentNonces[account]++;
        dot.safeTransfer(account, principal + interest);
        emit Withdrawn(account, nonce, principal, interest, 0);
    }

    function fixedWithdraw(
        address account,
        uint256 deadline,
        uint256 principal,
        uint256 interest,
        bytes memory signature
    ) external {
        if (block.timestamp > deadline) revert();
        uint256 nonce = fixedNonces[account];
        bytes memory message = abi.encode(nonce, account, deadline, principal, interest);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();
        fixedNonces[account]++;
        dot.safeTransfer(account, principal + interest);
        emit Withdrawn(account, nonce, principal, interest, 1);
    }

    function rewardWithdraw(
        address account,
        uint256 deadline,
        uint256 interest,
        bytes memory signature
    ) external {
        if (block.timestamp > deadline) revert();
        uint256 nonce = rewardNonces[account];
        bytes memory message = abi.encode(nonce, account, deadline, interest);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();
        rewardNonces[account]++;
        dot.safeTransfer(account, interest);
        emit RewardWithdrawn(account, nonce, interest);
    }
}