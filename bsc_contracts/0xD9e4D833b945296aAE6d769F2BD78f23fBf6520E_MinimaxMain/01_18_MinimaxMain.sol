// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IPriceOracle.sol";
import "./interfaces/IGelatoOps.sol";

import "./pool/IPoolAdapter.sol";
import "./ProxyCaller.sol";
import "./ProxyPool.sol";
import "./PositionInfo.sol";
import "./IProxyOwner.sol";
import "./market/IMarket.sol";

contract MinimaxMain is IProxyOwner, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ProxyPool for ProxyCaller[];

    address cakeAddress; // TODO: remove when deploy clean version

    // BUSD for BSC, USDT for POLYGON
    address public busdAddress; // TODO: rename to stableToken when deploy clean version

    address minimaxStaking;

    uint public lastPositionIndex;

    // Use mapping instead of array for upgradeability of PositionInfo struct
    mapping(uint => PositionInfo) positions;

    mapping(address => bool) isLiquidator;

    ProxyCaller[] proxyPool;

    // Fee threshold
    struct FeeThreshold {
        uint fee;
        uint stakedAmountThreshold;
    }

    FeeThreshold[] depositFees;

    /// @custom:oz-renamed-from poolAdapters
    mapping(address => IPoolAdapter) poolAdaptersDeprecated;

    mapping(IERC20Upgradeable => IPriceOracle) public priceOracles;

    // TODO: deprecated
    mapping(address => address) tokenExchanges;

    // gelato
    IGelatoOps public gelatoOps;

    address payable public gelatoPayee;

    mapping(address => uint256) gelatoLiquidateFee; // TODO: remove when deploy clean version
    uint256 liquidatorFee; // transfered to liquidator (not gelato) when `gelatoOps` is not set
    address gelatoFeeToken; // TODO: remove when deploy clean version

    // TODO: deprecated
    address defaultExchange;

    // poolAdapters by bytecode hash
    mapping(uint256 => IPoolAdapter) public poolAdapters;

    IMarket public market;

    address wrappedNative;

    address public oneInchRouter;

    // Migrate

    bool public disabled;

    mapping(address => bool) public isProxyManager;

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setProxyManager(address _address, bool _value) external onlyOwner {
        isProxyManager[_address] = _value;
    }

    modifier onlyProxyManager() {
        require(isProxyManager[address(msg.sender)], "onlyProxyManager");
        _;
    }

    function acquireProxy() external onlyProxyManager returns (ProxyCaller) {
        return proxyPool.acquire();
    }

    function isModernProxy(ProxyCaller proxy) public view returns (bool) {
        return address(proxy).code.length == 945;
    }

    function releaseProxy(ProxyCaller proxy) external onlyProxyManager {
        if (isModernProxy(proxy)) {
            proxyPool.release(proxy);
        }
    }

    function proxyExec(
        ProxyCaller proxy,
        bool delegate,
        address target,
        bytes calldata data
    ) external nonReentrant onlyProxyManager returns (bool success, bytes memory) {
        return proxy.exec(delegate, target, data);
    }

    function proxyTransfer(
        ProxyCaller proxy,
        address target,
        uint256 amount
    ) external nonReentrant onlyProxyManager returns (bool success, bytes memory) {
        return proxy.transfer(target, amount);
    }
}