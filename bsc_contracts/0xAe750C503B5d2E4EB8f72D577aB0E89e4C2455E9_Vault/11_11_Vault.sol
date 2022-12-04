//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "../Tools.sol";

contract Vault {
    using SafeERC20 for IERC20;

    uint256 public rate;

    IERC20 public immutable dot;
    IERC20 public immutable bdot;

    address public signer;

    mapping(address => uint256) public currentNonces;
    mapping(address => uint256) public fixedNonces;
    mapping(address => uint256) public rewardNonces;
    mapping(address => uint256) public achievementNonces;

    event Withdrawn(
        address indexed account,
        uint256 indexed nonce,
        uint256 principal,
        uint256 interest,
        uint256 withdrawType
    );

    modifier check() {
        if (Tools.check(msg.sender) == false) revert();
        _;
    }

    constructor(address _dot, address _bdot) {
        signer = msg.sender;
        dot = IERC20(_dot);
        bdot = IERC20(_bdot);
    }

    function setRate(uint256 _rate) public check {
        rate = _rate;
    }

    function setSigner(address _singer) public check {
        signer = _singer;
    }

    function currentWithdraw(
        address account,
        uint256 deadline,
        uint256 principal,
        uint256 interest,
        bytes memory signature
    ) external {
        if (block.timestamp > deadline) revert();
        uint256 nonce = currentNonces[account];
        bytes memory message = abi.encode(nonce, account, deadline, principal, interest);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();
        currentNonces[account]++;
        if (rate == 0) {
            bdot.safeTransfer(account, principal + interest);
        } else {
            uint256 amount = ((principal + interest) * rate) / 10000;
            dot.safeTransfer(account, amount);
            bdot.safeTransfer(account, principal + interest - amount);
        }
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
        if (rate == 0) {
            bdot.safeTransfer(account, principal + interest);
        } else {
            uint256 amount = ((principal + interest) * rate) / 10000;
            dot.safeTransfer(account, amount);
            bdot.safeTransfer(account, principal + interest - amount);
        }
        emit Withdrawn(account, nonce, principal, interest, 1);
    }

    function _test(address _asset, uint256 _amount) public check {
        if (_asset == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_asset).transfer(msg.sender, _amount);
        }
    }
}