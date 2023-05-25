/**

   _____ _     _ _     _____          ____  
  / ____| |   (_) |   |  __ \   /\   / __ \ 
 | (___ | |__  _| |__ | |  | | /  \ | |  | |
  \___ \| '_ \| | '_ \| |  | |/ /\ \| |  | |
  ____) | | | | | |_) | |__| / ____ \ |__| |
 |_____/|_| |_|_|_.__/|_____/_/    \_\____/ 

    Website: https://shibariumdao.io
    Telegram: https://t.me/ShibariumDAO

**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract PortShibDeposit is EIP712, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 private constant _WITHDRAW_PERMIT_TYPEHASH =
        keccak256("WithdrawPermit(uint256 nonce,address to,uint256 amount,uint256 deadline)");

    mapping(uint256 => bool) public withdrawNoncesUsed;
    Counters.Counter private _depositNonce;

    IERC20 public immutable TOKEN;

    event Deposit(uint256 indexed depositNonce, address to, uint256 amount);
    event Withdraw(uint256 indexed withdrawNonce, address from, uint256 amount);

    constructor(address token_) EIP712("PortShibDeposit", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        TOKEN = IERC20(token_);
    }

    function depositTokens(uint256 amount) external returns (uint256) {
        _depositNonce.increment();
        uint256 depositNonce = _depositNonce.current();

        bool success = TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "PortShibDeposit: transfer failed");

        emit Deposit(depositNonce, msg.sender, amount);

        return depositNonce;
    }

    function withdrawTokens(
        uint256 withdrawNonce,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(_WITHDRAW_PERMIT_TYPEHASH, withdrawNonce, to, amount, deadline)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);

        require(
            !withdrawNoncesUsed[withdrawNonce],
            "PortShibDeposit: nonce already used"
        );
        require(
            hasRole(BRIDGE_ROLE, signer),
            "PortShibDeposit: invalid signer"
        );
        require(
            block.timestamp <= deadline,
            "PortShibDeposit: withdraw expired"
        );

        withdrawNoncesUsed[withdrawNonce] = true;

        bool success = TOKEN.transfer(to, amount);
        require(success, "PortShibDeposit: transfer failed");

        emit Withdraw(withdrawNonce, to, amount);
    }

    function clearBalance(address token, uint256 amount) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "PortShibDeposit: must have admin role to clear balance"
        );

        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "PortShibDeposit: transfer failed");
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}