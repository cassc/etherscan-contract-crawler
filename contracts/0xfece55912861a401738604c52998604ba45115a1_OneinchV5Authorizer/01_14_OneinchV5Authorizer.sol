// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "DEXBaseACL.sol";
import "ACLUtils.sol";

interface IPool {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract OneinchV5Authorizer is DEXBaseACL {
    bytes32 public constant NAME = "1inchV5Authorizer";
    uint256 public constant VERSION = 1;

    // For 1inch aggreator data.
    uint256 private constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _WETH_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000; // For unoswap

    uint256 private constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _WETH_UNWRAP_MASK = 1 << 253; // For uniswapV3Swap.

    uint256 private constant _UNWRAP_WETH_FLAG = 1 << 252; // For fillOrderRFQ

    address public constant ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    address public immutable WETH = getWrappedTokenAddress();

    constructor(address _owner, address _caller) DEXBaseACL(_owner, _caller) {}

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = ROUTER;
    }

    function _getToken(address _token) internal view returns (address) {
        return _token == ZERO_ADDRESS ? ETH_ADDRESS : _token;
    }

    // Checking functions.

    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(address, SwapDescription calldata _desc, bytes calldata, bytes calldata) external view {
        _checkRecipient(_desc.dstReceiver);
        address srcToken = _getToken(_desc.srcToken);
        address dstToken = _getToken(_desc.dstToken);
        _swapInOutTokenCheck(srcToken, dstToken);
    }

    //already restrict recipient must be msg.sender in 1inch contract
    function unoswap(address _srcToken, uint256, uint256, uint256[] calldata pools) external view {
        uint256 lastPool = pools[pools.length - 1];
        IPool lastPair = IPool(address(uint160(lastPool & _ADDRESS_MASK)));
        address srcToken = _getToken(_srcToken);
        bool isReversed = lastPool & _REVERSE_MASK == 0;
        bool unwrapWeth = lastPool & _WETH_MASK > 0;
        address dstToken = isReversed ? lastPair.token1() : lastPair.token0();
        if (unwrapWeth) {
            require(dstToken == WETH, "Dst not WETH");
            dstToken = ETH_ADDRESS;
        }
        _swapInOutTokenCheck(srcToken, dstToken);
    }

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] calldata pools) external view {
        uint256 lastPoolUint = pools[pools.length - 1];
        uint256 firstPoolUint = pools[0];
        IPool firstPool = IPool(address(uint160(firstPoolUint)));
        IPool lastPool = IPool(address(uint160(lastPoolUint)));
        bool zeroForOneFirstPool = firstPoolUint & _ONE_FOR_ZERO_MASK == 0;
        bool zeroForOneLastPool = lastPoolUint & _ONE_FOR_ZERO_MASK == 0;
        address srcToken = zeroForOneFirstPool ? firstPool.token0() : firstPool.token1();
        address dstToken = zeroForOneLastPool ? lastPool.token1() : lastPool.token0();

        bool wrapWeth = _txn().value > 0;
        bool unwrapWeth = lastPoolUint & _WETH_UNWRAP_MASK > 0;
        if (wrapWeth) {
            require(srcToken == WETH, "Src not WETH");
            srcToken = ETH_ADDRESS;
        }
        if (unwrapWeth) {
            require(dstToken == WETH, "Dst not WETH");
            dstToken = ETH_ADDRESS;
        }

        _swapInOutTokenCheck(_getToken(srcToken), _getToken(dstToken));
    }

    // Safe is the taker.
    struct Order {
        uint256 salt;
        address makerAsset; // For safe to buy
        address takerAsset; // For safe to sell
        address maker;
        address receiver; // Where to send takerAsset, default zero means sending to maker.
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 offsets;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    function fillOrder(
        Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external view {
        address srcToken = order.takerAsset;
        address dstToken = order.makerAsset;
        _swapInOutTokenCheck(_getToken(srcToken), _getToken(dstToken));
    }

    struct OrderRFQ {
        uint256 info; // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        address makerAsset;
        address takerAsset;
        address maker;
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
    }

    function _checkRFQOrder(OrderRFQ calldata order, uint256 flagsAndAmount) internal view {
        address srcToken = order.takerAsset;
        address dstToken = order.makerAsset;

        if (srcToken == WETH && _txn().value > 0) {
            srcToken = ETH_ADDRESS;
        }

        if (dstToken == WETH && flagsAndAmount & _UNWRAP_WETH_FLAG != 0) {
            dstToken = ETH_ADDRESS;
        }

        _swapInOutTokenCheck(_getToken(srcToken), _getToken(dstToken));
    }

    function fillOrderRFQ(OrderRFQ calldata order, bytes calldata signature, uint256 flagsAndAmount) external view {
        _checkRFQOrder(order, flagsAndAmount);
    }

    function fillOrderRFQCompact(OrderRFQ calldata order, bytes32 r, bytes32 vs, uint256 flagsAndAmount) external view {
        _checkRFQOrder(order, flagsAndAmount);
    }

    function clipperSwap(
        address clipperExchange,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external view {
        _swapInOutTokenCheck(_getToken(srcToken), _getToken(dstToken));
    }
}