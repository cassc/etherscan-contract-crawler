// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {INToken} from "../../../interfaces/INToken.sol";
import {IProtocolDataProvider} from "../../../interfaces/IProtocolDataProvider.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {Errors} from "../helpers/Errors.sol";
import {SupplyLogic} from "./SupplyLogic.sol";
import {BorrowLogic} from "./BorrowLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {ILendPoolLoan} from "../../../dependencies/benddao/contracts/interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../../../dependencies/benddao/contracts/interfaces/ILendPool.sol";
import {BDaoDataTypes} from "../../../dependencies/benddao/contracts/libraries/types/BDaoDataTypes.sol";
import {Helpers} from "../../../protocol/libraries/helpers/Helpers.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {ICApe} from "../../../interfaces/ICApe.sol";
import {IAccount} from "../../../interfaces/IAccount.sol";
import {IAutoCompoundApe} from "../../../interfaces/IAutoCompoundApe.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title PositionMoverLogic library
 *
 * @notice Implements the base logic for moving positions
 */
library PositionMoverLogic {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    struct BendDAOPositionMoverVars {
        address weth;
        address xTokenAddress;
        address nftAsset;
        uint256 tokenId;
        uint256 borrowAmount;
    }

    struct ParaSpacePositionMoverVars {
        address cTokenV2;
        address xTokenAddressV2;
        address xTokenAddressV1;
        address variableDebtTokenAddressV1;
        uint256 dAmount;
        uint256 cAmount;
    }

    event PositionMovedFromBendDAO(
        address asset,
        uint256 tokenId,
        address user
    );

    event PositionMovedFromParaSpaceV1(
        address indexed user,
        address indexed to,
        address[] cTokens,
        DataTypes.AssetType[] cTypes,
        uint256[][] cAmountsOrTokenIds,
        address[] dTokens,
        uint256[] dAmounts
    );

    function executeMovePositionFromBendDAO(
        DataTypes.PoolStorage storage ps,
        IPoolAddressesProvider poolAddressProvider,
        ILendPoolLoan lendPoolLoan,
        ILendPool lendPool,
        uint256[] calldata loandIds
    ) external {
        BendDAOPositionMoverVars memory tmpVar;

        tmpVar.weth = poolAddressProvider.getWETH();
        DataTypes.ReserveData storage reserve = ps._reserves[tmpVar.weth];
        tmpVar.xTokenAddress = reserve.xTokenAddress;

        for (uint256 index = 0; index < loandIds.length; index++) {
            (
                tmpVar.nftAsset,
                tmpVar.tokenId,
                tmpVar.borrowAmount
            ) = _repayBendDAOPositionLoan(
                lendPoolLoan,
                lendPool,
                tmpVar.weth,
                tmpVar.xTokenAddress,
                loandIds[index]
            );

            supplyNFTandBorrowWETH(ps, poolAddressProvider, tmpVar);

            emit PositionMovedFromBendDAO(
                tmpVar.nftAsset,
                tmpVar.tokenId,
                msg.sender
            );
        }
    }

    function _repayBendDAOPositionLoan(
        ILendPoolLoan lendPoolLoan,
        ILendPool lendPool,
        address weth,
        address xTokenAddress,
        uint256 loanId
    )
        internal
        returns (
            address nftAsset,
            uint256 tokenId,
            uint256 borrowAmount
        )
    {
        BDaoDataTypes.LoanData memory loanData = lendPoolLoan.getLoan(loanId);

        require(
            loanData.state == BDaoDataTypes.LoanState.Active,
            "Loan not active"
        );
        require(loanData.borrower == msg.sender, Errors.NOT_THE_OWNER);

        (, borrowAmount) = lendPoolLoan.getLoanReserveBorrowAmount(loanId);

        DataTypes.TimeLockParams memory timeLockParams;
        IPToken(xTokenAddress).transferUnderlyingTo(
            address(this),
            borrowAmount,
            timeLockParams
        );
        IERC20(weth).approve(address(lendPool), borrowAmount);

        lendPool.repay(loanData.nftAsset, loanData.nftTokenId, borrowAmount);

        (nftAsset, tokenId) = (loanData.nftAsset, loanData.nftTokenId);
    }

    function supplyNFTandBorrowWETH(
        DataTypes.PoolStorage storage ps,
        IPoolAddressesProvider poolAddressProvider,
        BendDAOPositionMoverVars memory tmpVar
    ) internal {
        DataTypes.ERC721SupplyParams[]
            memory tokenData = new DataTypes.ERC721SupplyParams[](1);
        tokenData[0] = DataTypes.ERC721SupplyParams({
            tokenId: tmpVar.tokenId,
            useAsCollateral: true
        });

        SupplyLogic.executeSupplyERC721(
            ps._reserves,
            ps._usersConfig[msg.sender],
            DataTypes.ExecuteSupplyERC721Params({
                asset: tmpVar.nftAsset,
                tokenData: tokenData,
                onBehalfOf: msg.sender,
                payer: msg.sender,
                referralCode: 0x0
            })
        );

        BorrowLogic.executeBorrow(
            ps._reserves,
            ps._reservesList,
            ps._usersConfig[msg.sender],
            DataTypes.ExecuteBorrowParams({
                asset: tmpVar.weth,
                user: msg.sender,
                onBehalfOf: msg.sender,
                amount: tmpVar.borrowAmount,
                referralCode: 0x0,
                releaseUnderlying: false,
                reservesCount: ps._reservesCount,
                oracle: poolAddressProvider.getPriceOracle(),
                priceOracleSentinel: poolAddressProvider.getPriceOracleSentinel()
            })
        );
    }

    function executeMovePositionFromParaSpaceV1(
        DataTypes.PoolStorage storage ps,
        IPool poolV1,
        IProtocolDataProvider protocolDataProviderV1,
        ICApe cApeV1,
        ICApe cApeV2,
        DataTypes.ParaSpacePositionMoveParams memory params
    ) external {
        require(
            params.cTokens.length == params.cTypes.length &&
                params.cTypes.length == params.cAmountsOrTokenIds.length &&
                params.dTokens.length == params.dAmounts.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        require(
            params.to == params.user ||
                IAccount(params.to).owner() == params.user,
            Errors.NOT_THE_OWNER
        );

        // 1. cache poolV1 apeCoin xTokenAddress
        ParaSpacePositionMoverVars memory vars;
        DataTypes.TimeLockParams memory timeLockParams;

        // 2. repay debt in poolV1
        for (uint256 index = 0; index < params.dTokens.length; index++) {
            // 2.1 query reserveData and debt
            (
                vars.xTokenAddressV1,
                vars.variableDebtTokenAddressV1
            ) = protocolDataProviderV1.getReserveTokensAddresses(
                params.dTokens[index]
            );
            vars.dAmount = Helpers.getUserCurrentDebt(
                params.user,
                vars.variableDebtTokenAddressV1
            );
            if (
                params.dAmounts[index] == 0 ||
                params.dAmounts[index] > vars.dAmount
            ) {
                params.dAmounts[index] = vars.dAmount;
            }

            // 2.2 flash loan enough assets to poolV2
            if (params.dTokens[index] == address(cApeV1)) {
                IPToken(ps._reserves[address(cApeV2)].xTokenAddress)
                    .transferUnderlyingTo(
                        address(this),
                        params.dAmounts[index],
                        timeLockParams
                    );
                IAutoCompoundApe(address(cApeV2)).withdraw(
                    params.dAmounts[index]
                );
                // NOTE: ignored approve because we will do it inside `unlimitedApproveTo`
                IAutoCompoundApe(params.dTokens[index]).deposit(
                    address(this),
                    params.dAmounts[index]
                );
            } else {
                IPToken(ps._reserves[params.dTokens[index]].xTokenAddress)
                    .transferUnderlyingTo(
                        address(this),
                        params.dAmounts[index],
                        timeLockParams
                    );
            }

            // 2.3 repay user variableDebt
            poolV1.repay(
                params.dTokens[index],
                params.dAmounts[index],
                params.user
            );
            if (params.dTokens[index] == address(cApeV1)) {
                params.dTokens[index] = address(cApeV2);
            }
        }

        // 3. transfer xToken to poolV2
        for (uint256 i = 0; i < params.cTokens.length; i++) {
            (
                vars.xTokenAddressV1,
                vars.variableDebtTokenAddressV1
            ) = protocolDataProviderV1.getReserveTokensAddresses(
                params.cTokens[i]
            );
            vars.cTokenV2 = params.cTokens[i] == address(cApeV1)
                ? address(cApeV2)
                : params.cTokens[i];
            DataTypes.ReserveData storage reserveV2 = ps._reserves[
                vars.cTokenV2
            ];

            if (params.cTypes[i] == DataTypes.AssetType.ERC20) {
                DataTypes.ReserveCache memory reserveV2Cache = reserveV2
                    .cache();
                reserveV2.updateState(reserveV2Cache);
                // 3.1 transfer pToken to poolV2
                vars.cAmount = IPToken(vars.xTokenAddressV1).balanceOf(
                    params.user
                );
                if (
                    params.cAmountsOrTokenIds[i][0] == 0 ||
                    params.cAmountsOrTokenIds[i][0] > vars.cAmount
                ) {
                    params.cAmountsOrTokenIds[i][0] = vars.cAmount;
                }
                IERC20(vars.xTokenAddressV1).transferFrom(
                    params.user,
                    address(this),
                    params.cAmountsOrTokenIds[i][0]
                );

                // 3.2 withdraw and specifying recipient as new pToken
                poolV1.withdraw(
                    params.cTokens[i],
                    params.cAmountsOrTokenIds[i][0],
                    reserveV2Cache.xTokenAddress
                );
                // 3.3 record unbacked
                reserveV2.unbacked += params
                .cAmountsOrTokenIds[i][0].toUint128();
                reserveV2.updateInterestRates(
                    reserveV2Cache,
                    vars.cTokenV2,
                    0,
                    0
                );

                // 3.4 mint new pToken and do normal supply check etc
                Helpers.setAssetUsedAsCollateral(
                    ps._usersConfig[params.to],
                    ps._reserves,
                    vars.cTokenV2,
                    params.to
                );
                IPToken(reserveV2Cache.xTokenAddress).mint(
                    params.user,
                    params.to,
                    params.cAmountsOrTokenIds[i][0],
                    reserveV2Cache.nextLiquidityIndex
                );
            } else {
                vars.xTokenAddressV2 = reserveV2.xTokenAddress;
                // 3.4 transfer nToken to poolV2
                DataTypes.ERC721SupplyParams[]
                    memory supplyParams = new DataTypes.ERC721SupplyParams[](
                        params.cAmountsOrTokenIds[i].length
                    );
                for (
                    uint256 j = 0;
                    j < params.cAmountsOrTokenIds[i].length;
                    j++
                ) {
                    supplyParams[j] = DataTypes.ERC721SupplyParams(
                        params.cAmountsOrTokenIds[i][j],
                        true
                    );
                    // NOTE: since we already bring underlying BAYC & MAYC back to NToken
                    // this should also unstake for user
                    IERC721(vars.xTokenAddressV1).transferFrom(
                        params.user,
                        address(this),
                        params.cAmountsOrTokenIds[i][j]
                    );
                }
                // 3.6 withdraw and specify recipient as new nToken
                poolV1.withdrawERC721(
                    params.cTokens[i],
                    params.cAmountsOrTokenIds[i],
                    vars.xTokenAddressV2
                );
                // 3.7 mint new nToken
                Helpers.setAssetUsedAsCollateral(
                    ps._usersConfig[params.to],
                    ps._reserves,
                    vars.cTokenV2,
                    params.to
                );
                INToken(vars.xTokenAddressV2).mint(params.to, supplyParams);
            }
        }

        // 4. repay flashloan by minting new variableDebt
        _repayFlashLoan(ps, params);

        // 5. emit event
        emit PositionMovedFromParaSpaceV1(
            params.user,
            params.to,
            params.cTokens,
            params.cTypes,
            params.cAmountsOrTokenIds,
            params.dTokens,
            params.dAmounts
        );
    }

    function _repayFlashLoan(
        DataTypes.PoolStorage storage ps,
        DataTypes.ParaSpacePositionMoveParams memory params
    ) internal {
        for (uint256 index = 0; index < params.dTokens.length; index++) {
            BorrowLogic.executeBorrow(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[params.to],
                DataTypes.ExecuteBorrowParams({
                    asset: params.dTokens[index],
                    user: params.to,
                    onBehalfOf: params.to,
                    amount: params.dAmounts[index],
                    referralCode: 0,
                    releaseUnderlying: false,
                    reservesCount: params.reservesCount,
                    oracle: params.priceOracle,
                    priceOracleSentinel: params.priceOracleSentinel
                })
            );
        }
    }
}