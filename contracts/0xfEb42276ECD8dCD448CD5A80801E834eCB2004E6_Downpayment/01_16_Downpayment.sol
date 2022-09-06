// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAaveLendPoolAddressesProvider} from "./interfaces/IAaveLendPoolAddressesProvider.sol";
import {IAaveLendPool} from "./interfaces/IAaveLendPool.sol";
import {ILendPool} from "./interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "./interfaces/ILendPoolAddressesProvider.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IDownpayment} from "./interfaces/IDownpayment.sol";

import {PercentageMath} from "./libraries/PercentageMath.sol";

contract Downpayment is Ownable, ReentrancyGuard, IDownpayment {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    EnumerableSet.AddressSet private _whitelistedAdapters;

    IAaveLendPoolAddressesProvider public immutable aaveAddressesProvider;
    IWETH public immutable override WETH;
    ILendPoolAddressesProvider public bendAddressesProvider;
    address public feeCollector;

    event AdapterRemoved(address indexed adapter);
    event AdapterWhitelisted(address indexed adapter);

    event FeeUpdated(address indexed adapter, uint256 indexed newFee);

    mapping(address => Counters.Counter) internal _nonces;
    mapping(address => uint256) private fees;

    modifier onlyWhitelisted(address adapter) {
        require(_whitelistedAdapters.contains(adapter), "Adapter: not whitelisted");
        _;
    }

    constructor(
        address _aaveAddressesProvider,
        address _bendAddressesProvider,
        address _feeCollector,
        address _weth
    ) {
        aaveAddressesProvider = IAaveLendPoolAddressesProvider(_aaveAddressesProvider);
        bendAddressesProvider = ILendPoolAddressesProvider(_bendAddressesProvider);
        feeCollector = _feeCollector;
        WETH = IWETH(_weth);
    }

    function buy(
        address adapter,
        uint256 borrowAmount,
        bytes calldata data,
        Sig calldata sig
    ) external payable override onlyWhitelisted(adapter) nonReentrant {
        if (msg.value > 0) {
            // Wrap ETH sent to this contract
            WETH.deposit{value: msg.value}();
            // Sent WETH back to sender
            IERC20(address(WETH)).safeTransfer(msg.sender, msg.value);
        }
        IAaveLendPool aavePool = IAaveLendPool(aaveAddressesProvider.getLendingPool());
        address[] memory assets = new address[](1);
        assets[0] = address(WETH);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        bytes memory dataWithSignature = abi.encode(data, msg.sender, sig.v, sig.r, sig.s);
        aavePool.flashLoan(adapter, assets, amounts, modes, address(0), dataWithSignature, 0);
        _incrementNonce(msg.sender);
    }

    function addAdapter(address adapter) external override onlyOwner {
        require(adapter != address(0), "Adapter: can not be null address");
        require(!_whitelistedAdapters.contains(adapter), "Adapter: already whitelisted");
        _whitelistedAdapters.add(adapter);
        emit AdapterWhitelisted(adapter);
    }

    function removeAdapter(address adapter) external override onlyOwner onlyWhitelisted(adapter) {
        _whitelistedAdapters.remove(adapter);

        emit AdapterRemoved(adapter);
    }

    function updateFee(address adapter, uint256 _newFee) external onlyOwner onlyWhitelisted(adapter) {
        require(_newFee <= PercentageMath.PERCENTAGE_FACTOR, "Fee overflow");
        fees[adapter] = _newFee;
        emit FeeUpdated(adapter, _newFee);
    }

    // external view functions
    function getBendLendPool() external view returns (ILendPool) {
        return ILendPool(bendAddressesProvider.getLendPool());
    }

    function getAaveLendPool() external view returns (IAaveLendPool) {
        return IAaveLendPool(aaveAddressesProvider.getLendingPool());
    }

    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner].current();
    }

    function isAdapterWhitelisted(address adapter) external view override returns (bool) {
        return _whitelistedAdapters.contains(adapter);
    }

    function viewCountWhitelistedAdapters() external view override returns (uint256) {
        return _whitelistedAdapters.length();
    }

    function viewWhitelistedAdapters(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;
        if (length > _whitelistedAdapters.length() - cursor) {
            length = _whitelistedAdapters.length() - cursor;
        }
        address[] memory whitelistedAdapters = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedAdapters[i] = _whitelistedAdapters.at(cursor + i);
        }
        return (whitelistedAdapters, cursor + length);
    }

    function getFee(address adapter) external view override onlyWhitelisted(adapter) returns (uint256) {
        return fees[adapter];
    }

    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    // internal functions
    function _incrementNonce(address owner) internal {
        Counters.Counter storage nonce = _nonces[owner];
        nonce.increment();
    }
}