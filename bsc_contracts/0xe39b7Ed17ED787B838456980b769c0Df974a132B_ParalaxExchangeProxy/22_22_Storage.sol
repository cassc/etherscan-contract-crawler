// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./EIP712.sol";
import {ExtensionPercent} from "./ExtensionPercent.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Storage is ExtensionPercent, EIP712, AccessControl {
    using SafeERC20 for IERC20;
    struct SignerData {
        address account;
        address baseCurrency;
        uint96 deadline;
        address quoteCurrency;
        uint96 price;
        uint256 amount;
        uint256 nonce;
    }
    struct OrderDCA {
        uint256 price;
        uint128 volume;
        uint64 levels;
        uint64 period;
        uint96 slippage;
        address baseCurrency;
        uint96 scale;
        address quoteCurrency;
        address account;
        uint256 nonce;
    }
    struct TimeMultiplier {
        uint256 amount;
        uint256 interval;
    }
    struct Order {
        OrderDCA dca;
        TimeMultiplier tm;
    }
    struct ProcessingDCA {
        uint256 lastLevel;
        uint256 scaleAmount;
        uint256 done;
        uint256 doneTM;
    }

    enum TypeFee {
        FeeDEX,
        FeeLMDEX,
        FeeLMP2P,
        FeeDCA
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SIGNER_DATA =
        keccak256(
            "SignerData(address account,address baseCurrency,uint96 deadline,address quoteCurrency,uint96 price,uint256 amount,uint256 nonce)"
        );
    bytes32 public constant ORDER_DCA =
        keccak256(
            "OrderDCA(uint256 price,uint128 volume,uint64 levels,uint64 period,uint96 slippage,address baseCurrency,uint96 scale,address quoteCurrency,address account,uint256 nonce)"
        );
    bytes32 public constant TIME_MULTIPLIER =
        keccak256("TimeMultiplier(uint256 amount,uint256 interval)");
    bytes32 public constant ORDER =
        keccak256(
            "Order(OrderDCA dca,TimeMultiplier tm)OrderDCA(uint256 price,uint128 volume,uint64 levels,uint64 period,uint96 slippage,address baseCurrency,uint96 scale,address quoteCurrency,address account,uint256 nonce)TimeMultiplier(uint256 amount,uint256 interval)"
        );

    address internal _adapter;
    address internal _treasure;
    uint256 internal _delta;
    address internal _wETH;

    address public _implementation;
    uint256 public feeDEX;
    uint256 public feeLMDEX;
    uint256 public feeLMP2P;
    uint256 public feeDCA;

    mapping(bytes => SignerData) internal _signerDatas;
    mapping(bytes => OrderDCA) internal _ordersDCA;
    mapping(bytes => TimeMultiplier) internal _timeMultipliers;
    // mapping(bytes => bool) internal _limitOrdersDEX;
    mapping(bytes => ProcessingDCA) internal _processingDCA;
}