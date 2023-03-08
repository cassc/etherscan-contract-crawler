// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../libraries/paraspace-upgradeability/ParaReentrancyGuard.sol";
import "../libraries/paraspace-upgradeability/ParaVersionedInitializable.sol";
import {PoolStorage} from "./PoolStorage.sol";
import "../../interfaces/IPoolApeStaking.sol";
import "../../interfaces/IPToken.sol";
import "../../dependencies/yoga-labs/ApeCoinStaking.sol";
import "../../interfaces/IXTokenType.sol";
import "../../interfaces/INTokenApeStaking.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ApeStakingLogic} from "../tokenization/libraries/ApeStakingLogic.sol";
import "../libraries/logic/BorrowLogic.sol";
import "../libraries/logic/SupplyLogic.sol";
import "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IAutoCompoundApe} from "../../interfaces/IAutoCompoundApe.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Math} from "../../dependencies/openzeppelin/contracts/Math.sol";
import {ISwapRouter} from "../../dependencies/univ3/interfaces/ISwapRouter.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";

contract PoolApeStaking is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolApeStaking
{
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeCast for uint256;
    using PercentageMath for uint256;
    using WadRayMath for uint256;

    IPoolAddressesProvider internal immutable ADDRESSES_PROVIDER;
    IAutoCompoundApe internal immutable APE_COMPOUND;
    IERC20 internal immutable APE_COIN;
    uint256 internal constant POOL_REVISION = 145;
    IERC20 internal immutable USDC;
    ISwapRouter internal immutable SWAP_ROUTER;

    uint256 internal constant DEFAULT_MAX_SLIPPAGE = 500; // 5%
    uint24 internal immutable APE_WETH_FEE;
    uint24 internal immutable WETH_USDC_FEE;
    address internal immutable WETH;

    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    struct ApeStakingLocalVars {
        address xTokenAddress;
        IERC721 bakcContract;
        address bakcNToken;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256[] amounts;
        uint256[] swapAmounts;
        address[] transferredTokenOwners;
        DataTypes.ApeCompoundStrategy[] options;
        uint256 totalAmount;
        uint256 totalNonDepositAmount;
        uint256 compoundFee;
    }

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(
        IPoolAddressesProvider provider,
        IAutoCompoundApe apeCompound,
        IERC20 apeCoin,
        IERC20 usdc,
        ISwapRouter uniswapV3SwapRouter,
        address weth,
        uint24 apeWethFee,
        uint24 wethUsdcFee
    ) {
        ADDRESSES_PROVIDER = provider;
        APE_COMPOUND = apeCompound;
        APE_COIN = apeCoin;
        USDC = IERC20(usdc);
        SWAP_ROUTER = ISwapRouter(uniswapV3SwapRouter);
        WETH = weth;
        APE_WETH_FEE = apeWethFee;
        WETH_USDC_FEE = wethUsdcFee;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /// @inheritdoc IPoolApeStaking
    function withdrawApeCoin(
        address nftAsset,
        ApeCoinStaking.SingleNft[] calldata _nfts
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        INToken nToken = INToken(xTokenAddress);
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                nToken.ownerOf(_nfts[index].tokenId) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
        INTokenApeStaking(xTokenAddress).withdrawApeCoin(_nfts, msg.sender);

        _checkUserHf(ps, msg.sender, true);
    }

    /// @inheritdoc IPoolApeStaking
    function claimApeCoin(address nftAsset, uint256[] calldata _nfts)
        external
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        INToken nToken = INToken(xTokenAddress);
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                nToken.ownerOf(_nfts[index]) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
        INTokenApeStaking(xTokenAddress).claimApeCoin(_nfts, msg.sender);

        _checkUserHf(ps, msg.sender, true);
    }

    /// @inheritdoc IPoolApeStaking
    function withdrawBAKC(
        address nftAsset,
        ApeCoinStaking.PairNftWithdrawWithAmount[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        ApeStakingLocalVars memory localVar = _generalCache(ps, nftAsset);
        localVar.transferredTokenOwners = new address[](_nftPairs.length);

        uint256[] memory transferredTokenIds = new uint256[](_nftPairs.length);
        uint256 actualTransferAmount = 0;

        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(localVar.xTokenAddress).ownerOf(
                    _nftPairs[index].mainTokenId
                ) == msg.sender,
                Errors.NOT_THE_OWNER
            );

            if (
                !_nftPairs[index].isUncommit ||
                localVar.bakcContract.ownerOf(_nftPairs[index].bakcTokenId) ==
                localVar.bakcNToken
            ) {
                localVar.transferredTokenOwners[
                        actualTransferAmount
                    ] = _validateBAKCOwnerAndTransfer(
                    localVar,
                    _nftPairs[index].bakcTokenId,
                    msg.sender
                );
                transferredTokenIds[actualTransferAmount] = _nftPairs[index]
                    .bakcTokenId;
                actualTransferAmount++;
            }
        }

        INTokenApeStaking(localVar.xTokenAddress).withdrawBAKC(
            _nftPairs,
            msg.sender
        );

        ////transfer BAKC back for user
        for (uint256 index = 0; index < actualTransferAmount; index++) {
            localVar.bakcContract.safeTransferFrom(
                localVar.xTokenAddress,
                localVar.transferredTokenOwners[index],
                transferredTokenIds[index]
            );
        }

        _checkUserHf(ps, msg.sender, true);
    }

    /// @inheritdoc IPoolApeStaking
    function claimBAKC(
        address nftAsset,
        ApeCoinStaking.PairNft[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        ApeStakingLocalVars memory localVar = _generalCache(ps, nftAsset);
        localVar.transferredTokenOwners = new address[](_nftPairs.length);

        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(localVar.xTokenAddress).ownerOf(
                    _nftPairs[index].mainTokenId
                ) == msg.sender,
                Errors.NOT_THE_OWNER
            );

            localVar.transferredTokenOwners[
                index
            ] = _validateBAKCOwnerAndTransfer(
                localVar,
                _nftPairs[index].bakcTokenId,
                msg.sender
            );
        }

        INTokenApeStaking(localVar.xTokenAddress).claimBAKC(
            _nftPairs,
            msg.sender
        );

        //transfer BAKC back for user
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            localVar.bakcContract.safeTransferFrom(
                localVar.xTokenAddress,
                localVar.transferredTokenOwners[index],
                _nftPairs[index].bakcTokenId
            );
        }
    }

    /// @inheritdoc IPoolApeStaking
    function borrowApeAndStake(
        StakingInfo calldata stakingInfo,
        ApeCoinStaking.SingleNft[] calldata _nfts,
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        require(
            stakingInfo.borrowAsset == address(APE_COIN) ||
                stakingInfo.borrowAsset == address(APE_COMPOUND),
            Errors.INVALID_ASSET_TYPE
        );

        ApeStakingLocalVars memory localVar = _generalCache(
            ps,
            stakingInfo.nftAsset
        );
        localVar.transferredTokenOwners = new address[](_nftPairs.length);
        localVar.balanceBefore = APE_COIN.balanceOf(localVar.xTokenAddress);

        DataTypes.ReserveData storage borrowAssetReserve = ps._reserves[
            stakingInfo.borrowAsset
        ];

        // 1, handle borrow part
        if (stakingInfo.borrowAmount > 0) {
            ValidationLogic.validateFlashloanSimple(borrowAssetReserve);
            if (stakingInfo.borrowAsset == address(APE_COIN)) {
                IPToken(borrowAssetReserve.xTokenAddress).transferUnderlyingTo(
                    localVar.xTokenAddress,
                    stakingInfo.borrowAmount
                );
            } else {
                IPToken(borrowAssetReserve.xTokenAddress).transferUnderlyingTo(
                    address(this),
                    stakingInfo.borrowAmount
                );
                APE_COMPOUND.withdraw(stakingInfo.borrowAmount);
                APE_COIN.safeTransfer(
                    localVar.xTokenAddress,
                    stakingInfo.borrowAmount
                );
            }
        }

        // 2, send cash part to xTokenAddress
        if (stakingInfo.cashAmount > 0) {
            APE_COIN.safeTransferFrom(
                msg.sender,
                localVar.xTokenAddress,
                stakingInfo.cashAmount
            );
        }

        // 3, deposit bayc or mayc pool
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                INToken(localVar.xTokenAddress).ownerOf(_nfts[index].tokenId) ==
                    msg.sender,
                Errors.NOT_THE_OWNER
            );
        }

        INTokenApeStaking(localVar.xTokenAddress).depositApeCoin(_nfts);

        // 4, deposit bakc pool
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(localVar.xTokenAddress).ownerOf(
                    _nftPairs[index].mainTokenId
                ) == msg.sender,
                Errors.NOT_THE_OWNER
            );

            localVar.transferredTokenOwners[
                index
            ] = _validateBAKCOwnerAndTransfer(
                localVar,
                _nftPairs[index].bakcTokenId,
                msg.sender
            );
        }

        INTokenApeStaking(localVar.xTokenAddress).depositBAKC(_nftPairs);
        //transfer BAKC back for user
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            localVar.bakcContract.safeTransferFrom(
                localVar.xTokenAddress,
                localVar.transferredTokenOwners[index],
                _nftPairs[index].bakcTokenId
            );
        }

        // 5 mint debt token
        if (stakingInfo.borrowAmount > 0) {
            BorrowLogic.executeBorrow(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteBorrowParams({
                    asset: stakingInfo.borrowAsset,
                    user: msg.sender,
                    onBehalfOf: msg.sender,
                    amount: stakingInfo.borrowAmount,
                    referralCode: 0,
                    releaseUnderlying: false,
                    reservesCount: ps._reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                    priceOracleSentinel: ADDRESSES_PROVIDER
                        .getPriceOracleSentinel()
                })
            );
        }

        //6 checkout ape balance
        require(
            APE_COIN.balanceOf(localVar.xTokenAddress) ==
                localVar.balanceBefore,
            Errors.TOTAL_STAKING_AMOUNT_WRONG
        );

        //7 collateralize sAPE
        uint16 sApeReserveId = ps._reserves[DataTypes.SApeAddress].id;
        DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
            msg.sender
        ];
        bool currentStatus = userConfig.isUsingAsCollateral(sApeReserveId);
        if (!currentStatus) {
            userConfig.setUsingAsCollateral(sApeReserveId, true);
            emit ReserveUsedAsCollateralEnabled(
                DataTypes.SApeAddress,
                msg.sender
            );
        }
    }

    /// @inheritdoc IPoolApeStaking
    function unstakeApePositionAndRepay(address nftAsset, uint256 tokenId)
        external
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();
        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        address incentiveReceiver = address(0);
        address positionOwner = INToken(xTokenAddress).ownerOf(tokenId);
        if (msg.sender != positionOwner) {
            _checkUserHf(ps, positionOwner, false);
            incentiveReceiver = msg.sender;
        }

        INTokenApeStaking(xTokenAddress).unstakePositionAndRepay(
            tokenId,
            incentiveReceiver
        );
    }

    /// @inheritdoc IPoolApeStaking
    function repayAndSupply(
        address underlyingAsset,
        address onBehalfOf,
        uint256 totalAmount
    ) external {
        DataTypes.PoolStorage storage ps = poolStorage();
        require(
            msg.sender == ps._reserves[underlyingAsset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );

        // 1, deposit APE as cAPE
        APE_COIN.safeTransferFrom(msg.sender, address(this), totalAmount);
        APE_COMPOUND.deposit(address(this), totalAmount);

        // 2, repay cAPE and supply cAPE for user
        _repayAndSupplyForUser(
            ps,
            address(APE_COMPOUND),
            address(this),
            onBehalfOf,
            totalAmount
        );
    }

    /// @inheritdoc IPoolApeStaking
    function claimApeAndCompound(
        address nftAsset,
        address[] calldata users,
        uint256[][] calldata tokenIds
    ) external nonReentrant {
        require(
            users.length == tokenIds.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        DataTypes.PoolStorage storage ps = poolStorage();
        _checkSApeIsNotPaused(ps);

        ApeStakingLocalVars memory localVar = _compoundCache(
            ps,
            nftAsset,
            users.length
        );

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                require(
                    users[i] ==
                        INToken(localVar.xTokenAddress).ownerOf(tokenIds[i][j]),
                    Errors.NOT_THE_OWNER
                );
            }

            INTokenApeStaking(localVar.xTokenAddress).claimApeCoin(
                tokenIds[i],
                address(this)
            );

            _addUserToCompoundCache(ps, localVar, i, users[i]);
        }

        _compoundForUsers(ps, localVar, users);
    }

    /// @inheritdoc IPoolApeStaking
    function claimPairedApeAndCompound(
        address nftAsset,
        address[] calldata users,
        ApeCoinStaking.PairNft[][] calldata _nftPairs
    ) external nonReentrant {
        require(
            users.length == _nftPairs.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        DataTypes.PoolStorage storage ps = poolStorage();

        ApeStakingLocalVars memory localVar = _compoundCache(
            ps,
            nftAsset,
            users.length
        );

        for (uint256 i = 0; i < _nftPairs.length; i++) {
            localVar.transferredTokenOwners = new address[](
                _nftPairs[i].length
            );
            for (uint256 j = 0; j < _nftPairs[i].length; j++) {
                require(
                    users[i] ==
                        INToken(localVar.xTokenAddress).ownerOf(
                            _nftPairs[i][j].mainTokenId
                        ),
                    Errors.NOT_THE_OWNER
                );

                localVar.transferredTokenOwners[
                        j
                    ] = _validateBAKCOwnerAndTransfer(
                    localVar,
                    _nftPairs[i][j].bakcTokenId,
                    users[i]
                );
            }

            INTokenApeStaking(localVar.xTokenAddress).claimBAKC(
                _nftPairs[i],
                address(this)
            );

            for (uint256 index = 0; index < _nftPairs[i].length; index++) {
                localVar.bakcContract.safeTransferFrom(
                    localVar.xTokenAddress,
                    localVar.transferredTokenOwners[index],
                    _nftPairs[i][index].bakcTokenId
                );
            }

            _addUserToCompoundCache(ps, localVar, i, users[i]);
        }

        _compoundForUsers(ps, localVar, users);
    }

    function _generalCache(DataTypes.PoolStorage storage ps, address nftAsset)
        internal
        view
        returns (ApeStakingLocalVars memory localVar)
    {
        localVar.xTokenAddress = ps._reserves[nftAsset].xTokenAddress;
        localVar.bakcContract = INTokenApeStaking(localVar.xTokenAddress)
            .getBAKC();
        localVar.bakcNToken = ps
            ._reserves[address(localVar.bakcContract)]
            .xTokenAddress;
    }

    function _compoundCache(
        DataTypes.PoolStorage storage ps,
        address nftAsset,
        uint256 numUsers
    ) internal view returns (ApeStakingLocalVars memory localVar) {
        localVar = _generalCache(ps, nftAsset);
        localVar.balanceBefore = APE_COIN.balanceOf(address(this));
        localVar.amounts = new uint256[](numUsers);
        localVar.swapAmounts = new uint256[](numUsers);
        localVar.options = new DataTypes.ApeCompoundStrategy[](numUsers);
        localVar.compoundFee = ps._apeCompoundFee;
    }

    function _addUserToCompoundCache(
        DataTypes.PoolStorage storage ps,
        ApeStakingLocalVars memory localVar,
        uint256 i,
        address user
    ) internal view {
        localVar.balanceAfter = APE_COIN.balanceOf(address(this));
        localVar.options[i] = ps._apeCompoundStrategies[user];
        unchecked {
            localVar.amounts[i] = (localVar.balanceAfter -
                localVar.balanceBefore).percentMul(
                    PercentageMath.PERCENTAGE_FACTOR - localVar.compoundFee
                );
            localVar.balanceBefore = localVar.balanceAfter;
            localVar.totalAmount += localVar.amounts[i];
        }

        if (localVar.options[i].ty == DataTypes.ApeCompoundType.SwapAndSupply) {
            localVar.swapAmounts[i] = localVar.amounts[i].percentMul(
                localVar.options[i].swapPercent
            );
            localVar.totalNonDepositAmount += localVar.swapAmounts[i];
        }
    }

    /// @inheritdoc IPoolApeStaking
    function getApeCompoundFeeRate() external view returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();
        return uint256(ps._apeCompoundFee);
    }

    function _checkUserHf(
        DataTypes.PoolStorage storage ps,
        address user,
        bool checkAbove
    ) private view {
        DataTypes.UserConfigurationMap memory userConfig = ps._usersConfig[
            user
        ];

        uint256 healthFactor;
        if (!userConfig.isBorrowingAny()) {
            healthFactor = type(uint256).max;
        } else {
            (, , , , , , , healthFactor, , ) = GenericLogic
                .calculateUserAccountData(
                    ps._reserves,
                    ps._reservesList,
                    DataTypes.CalculateUserAccountDataParams({
                        userConfig: userConfig,
                        reservesCount: ps._reservesCount,
                        user: user,
                        oracle: ADDRESSES_PROVIDER.getPriceOracle()
                    })
                );
        }

        if (checkAbove) {
            require(
                healthFactor > DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
                Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
            );
        } else {
            require(
                healthFactor < DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
                Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
        }
    }

    function _checkSApeIsNotPaused(DataTypes.PoolStorage storage ps)
        internal
        view
    {
        DataTypes.ReserveData storage reserve = ps._reserves[
            DataTypes.SApeAddress
        ];

        (bool isActive, , , bool isPaused, ) = reserve.configuration.getFlags();

        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function _compoundForUsers(
        DataTypes.PoolStorage storage ps,
        ApeStakingLocalVars memory localVar,
        address[] calldata users
    ) internal {
        APE_COMPOUND.deposit(
            address(this),
            localVar.totalAmount - localVar.totalNonDepositAmount
        );
        uint256 compoundFee = localVar
            .totalAmount
            .percentDiv(PercentageMath.PERCENTAGE_FACTOR - localVar.compoundFee)
            .percentMul(localVar.compoundFee);
        if (compoundFee > 0) {
            APE_COMPOUND.deposit(msg.sender, compoundFee);
        }

        bytes memory swapPath = abi.encodePacked(
            APE_COIN,
            APE_WETH_FEE,
            WETH,
            WETH_USDC_FEE,
            USDC
        );

        uint256 price = _getApeRelativePrice(address(USDC), 1E6);

        for (uint256 i = 0; i < users.length; i++) {
            _swapAndSupplyForUser(
                ps,
                address(USDC),
                localVar.swapAmounts[i],
                swapPath,
                users[i],
                price
            );
            _repayAndSupplyForUser(
                ps,
                address(APE_COMPOUND),
                address(this),
                users[i],
                localVar.amounts[i] - localVar.swapAmounts[i]
            );
        }
    }

    function _swapAndSupplyForUser(
        DataTypes.PoolStorage storage ps,
        address tokenOut,
        uint256 amountIn,
        bytes memory swapPath,
        address user,
        uint256 price
    ) internal {
        if (amountIn == 0) {
            return;
        }
        uint256 amountOut = SWAP_ROUTER.exactInput(
            ISwapRouter.ExactInputParams({
                path: swapPath,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountIn.wadMul(price)
            })
        );
        _supplyForUser(ps, tokenOut, address(this), user, amountOut);
    }

    function _getApeRelativePrice(address tokenOut, uint256 tokenOutUnit)
        internal
        view
        returns (uint256)
    {
        IPriceOracleGetter oracle = IPriceOracleGetter(
            ADDRESSES_PROVIDER.getPriceOracle()
        );
        uint256 apePrice = oracle.getAssetPrice(address(APE_COIN));
        uint256 tokenOutPrice = oracle.getAssetPrice(tokenOut);

        return
            ((apePrice * tokenOutUnit).wadDiv(tokenOutPrice * 1E18)).percentMul(
                PercentageMath.PERCENTAGE_FACTOR - DEFAULT_MAX_SLIPPAGE
            );
    }

    function _repayAndSupplyForUser(
        DataTypes.PoolStorage storage ps,
        address asset,
        address payer,
        address onBehalfOf,
        uint256 totalAmount
    ) internal {
        address variableDebtTokenAddress = ps
            ._reserves[asset]
            .variableDebtTokenAddress;
        uint256 repayAmount = Math.min(
            IERC20(variableDebtTokenAddress).balanceOf(onBehalfOf),
            totalAmount
        );
        _repayForUser(ps, asset, payer, onBehalfOf, repayAmount);
        _supplyForUser(ps, asset, payer, onBehalfOf, totalAmount - repayAmount);
    }

    function _supplyForUser(
        DataTypes.PoolStorage storage ps,
        address asset,
        address payer,
        address onBehalfOf,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
            onBehalfOf
        ];
        SupplyLogic.executeSupply(
            ps._reserves,
            userConfig,
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                payer: payer,
                referralCode: 0
            })
        );
        DataTypes.ReserveData storage assetReserve = ps._reserves[asset];
        uint16 reserveId = assetReserve.id;
        if (!userConfig.isUsingAsCollateral(reserveId)) {
            userConfig.setUsingAsCollateral(reserveId, true);
            emit ReserveUsedAsCollateralEnabled(asset, onBehalfOf);
        }
    }

    function _repayForUser(
        DataTypes.PoolStorage storage ps,
        address asset,
        address payer,
        address onBehalfOf,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        return
            BorrowLogic.executeRepay(
                ps._reserves,
                ps._usersConfig[onBehalfOf],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    onBehalfOf: onBehalfOf,
                    payer: payer,
                    usePTokens: false
                })
            );
    }

    function _validateBAKCOwnerAndTransfer(
        ApeStakingLocalVars memory localVar,
        uint256 tokenId,
        address userAddress
    ) internal returns (address bakcOwner) {
        bakcOwner = localVar.bakcContract.ownerOf(tokenId);
        require(
            (userAddress == bakcOwner) ||
                (userAddress == INToken(localVar.bakcNToken).ownerOf(tokenId)),
            Errors.NOT_THE_BAKC_OWNER
        );
        localVar.bakcContract.safeTransferFrom(
            bakcOwner,
            localVar.xTokenAddress,
            tokenId
        );
    }
}