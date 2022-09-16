// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAngleRouter.sol";
import "../interfaces/coreModule/IAgTokenMainnet.sol";
import "../interfaces/coreModule/ICore.sol";
import "../interfaces/coreModule/IOracleCore.sol";
import "../interfaces/coreModule/IPerpetualManager.sol";
import "../interfaces/coreModule/IPoolManager.sol";
import "../interfaces/coreModule/IStableMaster.sol";

pragma solidity 0.8.12;

struct Parameters {
    SLPData slpData;
    MintBurnData feeData;
    PerpetualManagerFeeData perpFeeData;
    PerpetualManagerParamData perpParam;
}

struct PerpetualManagerFeeData {
    uint64[] xHAFeesDeposit;
    uint64[] yHAFeesDeposit;
    uint64[] xHAFeesWithdraw;
    uint64[] yHAFeesWithdraw;
    uint64 haBonusMalusDeposit;
    uint64 haBonusMalusWithdraw;
}

struct PerpetualManagerParamData {
    uint64 maintenanceMargin;
    uint64 maxLeverage;
    uint64 targetHAHedge;
    uint64 limitHAHedge;
    uint64 lockTime;
}

struct CollateralAddresses {
    address stableMaster;
    address poolManager;
    address perpetualManager;
    address sanToken;
    address oracle;
    address gauge;
    address feeManager;
    address[] strategies;
}

/// @title AngleHelpers
/// @author Angle Core Team
/// @notice Contract with view functions designed to facilitate integrations on the Core module of the Angle Protocol
/// @dev This contract only contains view functions to be queried off-chain. It was thus not optimized for gas consumption
contract AngleHelpers is Initializable {
    // ======================== Helper View Functions ==============================

    /// @notice Gives the amount of `agToken` you'd be getting if you were executing in the same block a mint transaction
    /// with `amount` of `collateral` in the Core module of the Angle protocol as well as the value of the fees
    /// (in `BASE_PARAMS`) that would be applied during the mint
    /// @return Amount of `agToken` that would be obtained with a mint transaction in the same block
    /// @return Percentage of fees that would be taken during a mint transaction in the same block
    /// @dev This function reverts if the mint transaction was to revert in the same conditions (without taking into account
    /// potential approval problems to the `StableMaster` contract)
    function previewMintAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) external view returns (uint256, uint256) {
        return _previewMintAndFees(amount, agToken, collateral);
    }

    /// @notice Gives the amount of `collateral` you'd be getting if you were executing in the same block a burn transaction
    ///  with `amount` of `agToken` in the Core module of the Angle protocol as well as the value of the fees
    /// (in `BASE_PARAMS`) that would be applied during the burn
    /// @return Amount of `collateral` that would be obtained with a burn transaction in the same block
    /// @return Percentage of fees that would be taken during a burn transaction in the same block
    /// @dev This function reverts if the burn transaction was to revert in the same conditions (without taking into account
    /// potential approval problems to the `StableMaster` contract or agToken balance prior to the call)
    function previewBurnAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) external view returns (uint256, uint256) {
        return _previewBurnAndFees(amount, agToken, collateral);
    }

    /// @notice Returns all the addresses associated to the (`agToken`,`collateral`) pair given
    /// @return addresses A struct with all the addresses associated in the Core module
    function getCollateralAddresses(address agToken, address collateral)
        external
        view
        returns (CollateralAddresses memory addresses)
    {
        address stableMaster = IAgTokenMainnet(agToken).stableMaster();
        (address poolManager, address perpetualManager, address sanToken, address gauge) = ROUTER.mapPoolManagers(
            stableMaster,
            collateral
        );
        (, , , IOracleCore oracle, , , , , ) = IStableMaster(stableMaster).collateralMap(poolManager);
        addresses.stableMaster = stableMaster;
        addresses.poolManager = poolManager;
        addresses.perpetualManager = perpetualManager;
        addresses.sanToken = sanToken;
        addresses.gauge = gauge;
        addresses.oracle = address(oracle);
        addresses.feeManager = IPoolManager(poolManager).feeManager();

        uint256 length = 0;
        while (true) {
            try IPoolManager(poolManager).strategyList(length) returns (address) {
                length += 1;
            } catch {
                break;
            }
        }
        address[] memory strategies = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            strategies[i] = IPoolManager(poolManager).strategyList(i);
        }
        addresses.strategies = strategies;
    }

    /// @notice Gets the addresses of all the `StableMaster` contracts and their associated `AgToken` addresses
    /// @return List of the `StableMaster` addresses of the Angle protocol
    /// @return List of the `AgToken` addresses of the protocol
    /// @dev The place of an agToken address in the list is the same as the corresponding `StableMaster` address
    function getStablecoinAddresses() external view returns (address[] memory, address[] memory) {
        address[] memory stableMasterAddresses = CORE.stablecoinList();
        address[] memory agTokenAddresses = new address[](stableMasterAddresses.length);
        for (uint256 i = 0; i < stableMasterAddresses.length; ++i) {
            agTokenAddresses[i] = IStableMaster(stableMasterAddresses[i]).agToken();
        }
        return (stableMasterAddresses, agTokenAddresses);
    }

    /// @notice Returns most of the governance parameters associated to the (`agToken`,`collateral`) pair given
    /// @return params Struct with most of the parameters in the `StableMaster` and `PerpetualManager` contracts
    /// @dev Check out the struct `Parameters` for the meaning of the return values
    function getCollateralParameters(address agToken, address collateral)
        external
        view
        returns (Parameters memory params)
    {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            ,
            ,
            IPerpetualManager perpetualManager,
            ,
            ,
            ,
            ,
            SLPData memory slpData,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);

        params.slpData = slpData;
        params.feeData = feeData;
        params.perpParam.maintenanceMargin = perpetualManager.maintenanceMargin();
        params.perpParam.maxLeverage = perpetualManager.maxLeverage();
        params.perpParam.targetHAHedge = perpetualManager.targetHAHedge();
        params.perpParam.limitHAHedge = perpetualManager.limitHAHedge();
        params.perpParam.lockTime = perpetualManager.lockTime();

        params.perpFeeData.haBonusMalusDeposit = perpetualManager.haBonusMalusDeposit();
        params.perpFeeData.haBonusMalusWithdraw = perpetualManager.haBonusMalusWithdraw();

        uint256 length = 0;
        while (true) {
            try perpetualManager.xHAFeesDeposit(length) returns (uint64) {
                length += 1;
            } catch {
                break;
            }
        }
        uint64[] memory data = new uint64[](length);
        uint64[] memory data2 = new uint64[](length);
        for (uint256 i = 0; i < length; ++i) {
            data[i] = perpetualManager.xHAFeesDeposit(i);
            data2[i] = perpetualManager.yHAFeesDeposit(i);
        }
        params.perpFeeData.xHAFeesDeposit = data;
        params.perpFeeData.yHAFeesDeposit = data2;

        length = 0;
        while (true) {
            try perpetualManager.xHAFeesWithdraw(length) returns (uint64) {
                length += 1;
            } catch {
                break;
            }
        }
        data = new uint64[](length);
        data2 = new uint64[](length);
        for (uint256 i = 0; i < length; ++i) {
            data[i] = perpetualManager.xHAFeesWithdraw(i);
            data2[i] = perpetualManager.yHAFeesWithdraw(i);
        }
        params.perpFeeData.xHAFeesWithdraw = data;
        params.perpFeeData.yHAFeesWithdraw = data2;
    }

    /// @notice Returns the address of the poolManager associated to an (`agToken`, `collateral`) pair
    /// in the Core module of the protocol
    function getPoolManager(address agToken, address collateral) public view returns (address poolManager) {
        (, poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
    }

    // ======================== Replica Functions ==================================
    // These replicate what is done in the other contracts of the protocol

    function _previewBurnAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) internal view returns (uint256 amountForUserInCollat, uint256 feePercent) {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            address token,
            ,
            IPerpetualManager perpetualManager,
            IOracleCore oracle,
            uint256 stocksUsers,
            ,
            uint256 collatBase,
            ,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);
        if (token == address(0) || IStableMaster(stableMaster).paused(keccak256(abi.encodePacked(STABLE, poolManager))))
            revert NotInitialized();
        if (amount > stocksUsers) revert InvalidAmount();

        if (feeData.xFeeBurn.length == 1) {
            feePercent = feeData.yFeeBurn[0];
        } else {
            bytes memory data = abi.encode(address(perpetualManager), feeData.targetHAHedge);
            uint64 hedgeRatio = _computeHedgeRatio(stocksUsers - amount, data);
            feePercent = _piecewiseLinear(hedgeRatio, feeData.xFeeBurn, feeData.yFeeBurn);
        }
        feePercent = (feePercent * feeData.bonusMalusBurn) / BASE_PARAMS;

        amountForUserInCollat = (amount * (BASE_PARAMS - feePercent) * collatBase) / (oracle.readUpper() * BASE_PARAMS);
    }

    function _previewMintAndFees(
        uint256 amount,
        address agToken,
        address collateral
    ) internal view returns (uint256 amountForUserInStable, uint256 feePercent) {
        (address stableMaster, address poolManager) = _getStableMasterAndPoolManager(agToken, collateral);
        (
            address token,
            ,
            IPerpetualManager perpetualManager,
            IOracleCore oracle,
            uint256 stocksUsers,
            ,
            ,
            ,
            MintBurnData memory feeData
        ) = IStableMaster(stableMaster).collateralMap(poolManager);
        if (token == address(0) || IStableMaster(stableMaster).paused(keccak256(abi.encodePacked(STABLE, poolManager))))
            revert NotInitialized();

        amountForUserInStable = oracle.readQuoteLower(amount);

        if (feeData.xFeeMint.length == 1) feePercent = feeData.yFeeMint[0];
        else {
            bytes memory data = abi.encode(address(perpetualManager), feeData.targetHAHedge);
            uint64 hedgeRatio = _computeHedgeRatio(amountForUserInStable + stocksUsers, data);
            feePercent = _piecewiseLinear(hedgeRatio, feeData.xFeeMint, feeData.yFeeMint);
        }
        feePercent = (feePercent * feeData.bonusMalusMint) / BASE_PARAMS;

        amountForUserInStable = (amountForUserInStable * (BASE_PARAMS - feePercent)) / BASE_PARAMS;
        if (stocksUsers + amountForUserInStable > feeData.capOnStableMinted) revert InvalidAmount();
    }

    // ======================== Utility Functions ==================================
    // These utility functions are taken from other contracts of the protocol

    function _computeHedgeRatio(uint256 newStocksUsers, bytes memory data) internal view returns (uint64 ratio) {
        (address perpetualManager, uint64 targetHAHedge) = abi.decode(data, (address, uint64));
        uint256 totalHedgeAmount = IPerpetualManager(perpetualManager).totalHedgeAmount();
        newStocksUsers = (targetHAHedge * newStocksUsers) / BASE_PARAMS;
        if (newStocksUsers > totalHedgeAmount) ratio = uint64((totalHedgeAmount * BASE_PARAMS) / newStocksUsers);
        else ratio = uint64(BASE_PARAMS);
    }

    function _piecewiseLinear(
        uint64 x,
        uint64[] memory xArray,
        uint64[] memory yArray
    ) internal pure returns (uint64) {
        if (x >= xArray[xArray.length - 1]) {
            return yArray[xArray.length - 1];
        } else if (x <= xArray[0]) {
            return yArray[0];
        } else {
            uint256 lower;
            uint256 upper = xArray.length - 1;
            uint256 mid;
            while (upper - lower > 1) {
                mid = lower + (upper - lower) / 2;
                if (xArray[mid] <= x) {
                    lower = mid;
                } else {
                    upper = mid;
                }
            }
            if (yArray[upper] > yArray[lower]) {
                return
                    yArray[lower] +
                    ((yArray[upper] - yArray[lower]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            } else {
                return
                    yArray[lower] -
                    ((yArray[lower] - yArray[upper]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            }
        }
    }

    function _getStableMasterAndPoolManager(address agToken, address collateral)
        internal
        view
        returns (address stableMaster, address poolManager)
    {
        stableMaster = IAgTokenMainnet(agToken).stableMaster();
        (poolManager, , , ) = ROUTER.mapPoolManagers(stableMaster, collateral);
    }

    // ====================== Constants and Initializers ===========================

    IAngleRouter public constant ROUTER = IAngleRouter(0xBB755240596530be0c1DE5DFD77ec6398471561d);
    ICore public constant CORE = ICore(0x61ed74de9Ca5796cF2F8fD60D54160D47E30B7c3);

    bytes32 public constant STABLE = keccak256("STABLE");
    uint256 public constant BASE_PARAMS = 10**9;

    error NotInitialized();
    error InvalidAmount();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
}