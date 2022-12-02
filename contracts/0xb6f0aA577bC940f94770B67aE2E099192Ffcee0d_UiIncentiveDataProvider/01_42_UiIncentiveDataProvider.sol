// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IRewardsController} from "./interfaces/IRewardsController.sol";
import {IUiIncentiveDataProvider} from "./interfaces/IUiIncentiveDataProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IncentivizedERC20} from "../protocol/tokenization/base/IncentivizedERC20.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IEACAggregatorProxy} from "./interfaces/IEACAggregatorProxy.sol";

contract UiIncentiveDataProvider is IUiIncentiveDataProvider {
    using UserConfiguration for DataTypes.UserConfigurationMap;

    constructor() {}

    function getFullReservesIncentiveData(
        IPoolAddressesProvider provider,
        address user
    )
        external
        view
        override
        returns (
            AggregatedReserveIncentiveData[] memory,
            UserReserveIncentiveData[] memory
        )
    {
        return (
            _getReservesIncentivesData(provider),
            _getUserReservesIncentivesData(provider, user)
        );
    }

    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        override
        returns (AggregatedReserveIncentiveData[] memory)
    {
        return _getReservesIncentivesData(provider);
    }

    function _getReservesIncentivesData(IPoolAddressesProvider provider)
        private
        view
        returns (AggregatedReserveIncentiveData[] memory)
    {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();
        AggregatedReserveIncentiveData[]
            memory reservesIncentiveData = new AggregatedReserveIncentiveData[](
                reserves.length
            );
        // Iterate through the reserves to get all the information from the (a/s/v) Tokens
        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveIncentiveData
                memory reserveIncentiveData = reservesIncentiveData[i];
            reserveIncentiveData.underlyingAsset = reserves[i];

            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // Get xTokens rewards information
            // TODO: check that this is deployed correctly on contract and remove casting
            IRewardsController xTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.xTokenAddress)
                        .getIncentivesController()
                )
            );

            RewardInfo[] memory aRewardsInformation;
            if (address(xTokenIncentiveController) != address(0)) {
                address[]
                    memory xTokenRewardAddresses = xTokenIncentiveController
                        .getRewardsByAsset(baseData.xTokenAddress);

                aRewardsInformation = new RewardInfo[](
                    xTokenRewardAddresses.length
                );
                for (uint256 j = 0; j < xTokenRewardAddresses.length; ++j) {
                    RewardInfo memory rewardInformation;
                    rewardInformation
                        .rewardTokenAddress = xTokenRewardAddresses[j];

                    (
                        rewardInformation.tokenIncentivesIndex,
                        rewardInformation.emissionPerSecond,
                        rewardInformation.incentivesLastUpdateTimestamp,
                        rewardInformation.emissionEndTimestamp
                    ) = xTokenIncentiveController.getRewardsData(
                        baseData.xTokenAddress,
                        rewardInformation.rewardTokenAddress
                    );

                    rewardInformation.precision = xTokenIncentiveController
                        .getAssetDecimals(baseData.xTokenAddress);
                    rewardInformation.rewardTokenDecimals = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).decimals();
                    rewardInformation.rewardTokenSymbol = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    rewardInformation
                        .rewardOracleAddress = xTokenIncentiveController
                        .getRewardOracle(rewardInformation.rewardTokenAddress);
                    rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).decimals();
                    rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    aRewardsInformation[j] = rewardInformation;
                }
            }

            reserveIncentiveData.aIncentiveData = IncentiveData(
                baseData.xTokenAddress,
                address(xTokenIncentiveController),
                aRewardsInformation
            );

            // Get vTokens rewards information
            IRewardsController vTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.variableDebtTokenAddress)
                        .getIncentivesController()
                )
            );

            if (address(vTokenIncentiveController) != address(0)) {
                address[]
                    memory vTokenRewardAddresses = vTokenIncentiveController
                        .getRewardsByAsset(baseData.variableDebtTokenAddress);
                RewardInfo[] memory vRewardsInformation;
                vRewardsInformation = new RewardInfo[](
                    vTokenRewardAddresses.length
                );
                for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
                    RewardInfo memory rewardInformation;
                    rewardInformation
                        .rewardTokenAddress = vTokenRewardAddresses[j];

                    (
                        rewardInformation.tokenIncentivesIndex,
                        rewardInformation.emissionPerSecond,
                        rewardInformation.incentivesLastUpdateTimestamp,
                        rewardInformation.emissionEndTimestamp
                    ) = vTokenIncentiveController.getRewardsData(
                        baseData.variableDebtTokenAddress,
                        rewardInformation.rewardTokenAddress
                    );

                    rewardInformation.precision = vTokenIncentiveController
                        .getAssetDecimals(baseData.variableDebtTokenAddress);
                    rewardInformation.rewardTokenDecimals = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).decimals();
                    rewardInformation.rewardTokenSymbol = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    rewardInformation
                        .rewardOracleAddress = vTokenIncentiveController
                        .getRewardOracle(rewardInformation.rewardTokenAddress);
                    rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).decimals();
                    rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    vRewardsInformation[j] = rewardInformation;
                }

                reserveIncentiveData.vIncentiveData = IncentiveData(
                    baseData.variableDebtTokenAddress,
                    address(vTokenIncentiveController),
                    vRewardsInformation
                );
            }
        }

        return (reservesIncentiveData);
    }

    function getUserReservesIncentivesData(
        IPoolAddressesProvider provider,
        address user
    ) external view override returns (UserReserveIncentiveData[] memory) {
        return _getUserReservesIncentivesData(provider, user);
    }

    function _getUserReservesIncentivesData(
        IPoolAddressesProvider provider,
        address user
    ) private view returns (UserReserveIncentiveData[] memory) {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();

        UserReserveIncentiveData[]
            memory userReservesIncentivesData = new UserReserveIncentiveData[](
                user != address(0) ? reserves.length : 0
            );

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // user reserve data
            userReservesIncentivesData[i].underlyingAsset = reserves[i];

            IRewardsController xTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.xTokenAddress)
                        .getIncentivesController()
                )
            );
            if (address(xTokenIncentiveController) != address(0)) {
                // get all rewards information from the asset
                address[]
                    memory xTokenRewardAddresses = xTokenIncentiveController
                        .getRewardsByAsset(baseData.xTokenAddress);
                UserRewardInfo[]
                    memory aUserRewardsInformation = new UserRewardInfo[](
                        xTokenRewardAddresses.length
                    );
                for (uint256 j = 0; j < xTokenRewardAddresses.length; ++j) {
                    UserRewardInfo memory userRewardInformation;
                    userRewardInformation
                        .rewardTokenAddress = xTokenRewardAddresses[j];

                    userRewardInformation
                        .tokenIncentivesUserIndex = xTokenIncentiveController
                        .getUserAssetIndex(
                            user,
                            baseData.xTokenAddress,
                            userRewardInformation.rewardTokenAddress
                        );

                    userRewardInformation
                        .userUnclaimedRewards = xTokenIncentiveController
                        .getUserAccruedRewards(
                            user,
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation.rewardTokenDecimals = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).decimals();
                    userRewardInformation.rewardTokenSymbol = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    userRewardInformation
                        .rewardOracleAddress = xTokenIncentiveController
                        .getRewardOracle(
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation
                        .priceFeedDecimals = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).decimals();
                    userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    aUserRewardsInformation[j] = userRewardInformation;
                }

                userReservesIncentivesData[i]
                    .xTokenIncentivesUserData = UserIncentiveData(
                    baseData.xTokenAddress,
                    address(xTokenIncentiveController),
                    aUserRewardsInformation
                );
            }

            // variable debt token
            IRewardsController vTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.variableDebtTokenAddress)
                        .getIncentivesController()
                )
            );
            if (address(vTokenIncentiveController) != address(0)) {
                // get all rewards information from the asset
                address[]
                    memory vTokenRewardAddresses = vTokenIncentiveController
                        .getRewardsByAsset(baseData.variableDebtTokenAddress);
                UserRewardInfo[]
                    memory vUserRewardsInformation = new UserRewardInfo[](
                        vTokenRewardAddresses.length
                    );
                for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
                    UserRewardInfo memory userRewardInformation;
                    userRewardInformation
                        .rewardTokenAddress = vTokenRewardAddresses[j];

                    userRewardInformation
                        .tokenIncentivesUserIndex = vTokenIncentiveController
                        .getUserAssetIndex(
                            user,
                            baseData.variableDebtTokenAddress,
                            userRewardInformation.rewardTokenAddress
                        );

                    userRewardInformation
                        .userUnclaimedRewards = vTokenIncentiveController
                        .getUserAccruedRewards(
                            user,
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation.rewardTokenDecimals = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).decimals();
                    userRewardInformation.rewardTokenSymbol = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    userRewardInformation
                        .rewardOracleAddress = vTokenIncentiveController
                        .getRewardOracle(
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation
                        .priceFeedDecimals = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).decimals();
                    userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    vUserRewardsInformation[j] = userRewardInformation;
                }

                userReservesIncentivesData[i]
                    .vTokenIncentivesUserData = UserIncentiveData(
                    baseData.variableDebtTokenAddress,
                    address(xTokenIncentiveController),
                    vUserRewardsInformation
                );
            }
        }

        return (userReservesIncentivesData);
    }
}