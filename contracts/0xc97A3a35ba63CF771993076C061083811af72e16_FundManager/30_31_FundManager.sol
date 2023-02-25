// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "hardhat/console.sol";

import {IAlluoStrategyV2} from "../interfaces/IAlluoStrategyV2.sol";
import {IExchange} from "../interfaces/IExchange.sol";
import {IWrappedEther} from "../interfaces/IWrappedEther.sol";
import {IIbAlluo} from "../interfaces/IIbAlluo.sol";
import {IStrategyHandler} from "../interfaces/IStrategyHandler.sol";
import {IVoteExecutorMaster} from "../interfaces/IVoteExecutorMaster.sol";
import {IFastGas} from "../interfaces/IFastGas.sol";

contract FundManager is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IWrappedEther public constant WETH =
        IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IFastGas public constant CHAINLINK_FAST_GAS =
        IFastGas(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    bool public upgradeStatus;
    uint88 public maxGasPrice;

    address public exchangeAddress;
    address public strategyHandler;
    address public voteExecutorMaster;

    mapping(uint256 => uint256) public assetIdToMinDeposit;

    modifier markToMarket() {
        IStrategyHandler(strategyHandler).calculateAll();
        _;
        IStrategyHandler(strategyHandler).calculateOnlyLp();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _voteExecutorMaster,
        address _strategyHandler,
        uint88 _maxGasPrice
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract());
        exchangeAddress = 0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec;
        voteExecutorMaster = _voteExecutorMaster;
        strategyHandler = _strategyHandler;
        maxGasPrice = _maxGasPrice;
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        if (msg.sender != address(WETH)) {
            WETH.deposit{value: msg.value}();
        }
    }

    function isGasPriceAcceptable() public view returns (bool) {
        (, uint256 gas, , , ) = CHAINLINK_FAST_GAS.latestRoundData();
        return gas < maxGasPrice;
    }

    function checker()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IStrategyHandler handler = IStrategyHandler(strategyHandler);
        uint8 numberOfAssets = handler.numberOfAssets();
        require(isGasPriceAcceptable(), "Gas price too high");
        require(tx.gasprice < maxGasPrice, "Effective gas price too high");

        for (uint256 i; i < numberOfAssets; i++) {
            address strategyPrimaryToken = handler.getPrimaryTokenByAssetId(
                i,
                1
            );

            uint256 totalBalance = IERC20MetadataUpgradeable(
                strategyPrimaryToken
            ).balanceOf(address(this));
            if (totalBalance > assetIdToMinDeposit[i]) {
                return (
                    true,
                    abi.encodeWithSignature(
                        "executeSpecificMidCycleDeposits(uint256)",
                        i
                    )
                );
            }
        }
    }

    function executeAllMidCycleDeposits()
        public
        markToMarket
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IStrategyHandler handler = IStrategyHandler(strategyHandler);
        uint8 numberOfAssets = handler.numberOfAssets();
        for (uint256 i; i < numberOfAssets; i++) {
            _executeAssetMidCycleDeposits(i);
        }
    }

    function executeSpecificMidCycleDeposits(
        uint256 _assetId
    ) public markToMarket onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isGasPriceAcceptable(), "Gas price too high");
        require(tx.gasprice < maxGasPrice, "Gas price too high");
        _executeAssetMidCycleDeposits(_assetId);
    }

    function _executeAssetMidCycleDeposits(uint256 _assetId) internal {
        IStrategyHandler handler = IStrategyHandler(strategyHandler);

        address strategyPrimaryToken = handler.getPrimaryTokenByAssetId(
            _assetId,
            1
        );

        uint256 totalBalance = IERC20MetadataUpgradeable(strategyPrimaryToken)
            .balanceOf(address(this));

        if (totalBalance <= assetIdToMinDeposit[_assetId]) return;

        IVoteExecutorMaster.Deposit[] memory depositInfo = IVoteExecutorMaster(
            voteExecutorMaster
        ).getAssetIdToDepositPercentages(_assetId);
        for (uint256 j; j < depositInfo.length; j++) {
            IVoteExecutorMaster.Deposit memory deposit = depositInfo[j];
            IStrategyHandler.LiquidityDirection memory direction = handler
                .getLiquidityDirectionById(deposit.directionId);
            uint256 tokenAmount = (deposit.amount * totalBalance) / 10000;

            if (direction.entryToken != strategyPrimaryToken) {
                IERC20MetadataUpgradeable(strategyPrimaryToken).safeApprove(
                    exchangeAddress,
                    tokenAmount
                );
                tokenAmount = IExchange(exchangeAddress).exchange(
                    strategyPrimaryToken,
                    direction.entryToken,
                    tokenAmount,
                    0
                );
            }

            IERC20MetadataUpgradeable(direction.entryToken).safeTransfer(
                direction.strategyAddress,
                tokenAmount
            );
            // Make sure to set correct roles
            IAlluoStrategyV2(direction.strategyAddress).invest(
                direction.entryData,
                tokenAmount
            );
        }
    }

    function setMinDepositForAsset(
        uint256 _assetId,
        uint256 _threshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        assetIdToMinDeposit[_assetId] = _threshold;
    }

    function setExchangeAddress(
        address _newExchange
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeAddress = _newExchange;
    }

    function setStrategyHandler(
        address _newHandler
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyHandler = _newHandler;
    }

    function setVoteExecutorMaster(
        address _newVoteExecutorMaster
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        voteExecutorMaster = _newVoteExecutorMaster;
    }

    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Manager: Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(upgradeStatus, "Manager: Upgrade not allowed");
        upgradeStatus = false;
    }

    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }
}