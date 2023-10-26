// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./interfaces/IKToken.sol";
import "./interfaces/IKyokoPool.sol";
import "./interfaces/IKyokoPoolAddressesProvider.sol";
import "./libraries/logic/ReserveLogic.sol";
import "./libraries/logic/ValidationLogic.sol";
import "./libraries/logic/ReserveConfiguration.sol";
import "./libraries/utils/WadRayMath.sol";
import "./libraries/utils/PercentageMath.sol";
import "./libraries/utils/MathUtils.sol";
import "./libraries/utils/DataTypes.sol";
import "./libraries/utils/Helpers.sol";
import "./libraries/utils/Errors.sol";
import "./KyokoPoolStorage.sol";
import "./KyokoPoolStorageExt.sol";

/**
 * @title KyokoPool contract
 * @dev Main point of interaction with an Kyoko protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Liquidate Loans
 *   # Bid Auction
 * @author Kyoko
 **/
contract KyokoPool is
    Initializable,
    IKyokoPool,
    KyokoPoolStorage,
    ContextUpgradeable,
    IERC721ReceiverUpgradeable,
    KyokoPoolStorageExt
{
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier onlyKyokoPoolConfigurator() {
        _onlyKyokoPoolConfigurator();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, Errors.LP_IS_PAUSED);
    }

    function _onlyKyokoPoolConfigurator() internal view {
        require(
            _addressesProvider.isConfigurator(_msgSender()),
            Errors.LP_CALLER_NOT_KYOKO_POOL_CONFIGURATOR
        );
    }

    modifier onlyPriceOracle() {
        require(
            _addressesProvider.isOracle(_msgSender()),
            Errors.LP_CALLER_NOT_KYOKO_POOL_ORACLE
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            _addressesProvider.isAdmin(_msgSender()),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Function is to initialize the necessary variables
     * @param weth The address of the WETH
     * @param provider The address of the KyokoPoolAddressesProvider
     **/
    function initialize(
        IKyokoPoolAddressesProvider provider,
        address weth
    ) external initializer {
        __Context_init();
        _addressesProvider = provider;
        WETH = IWETH(weth);
        MIN_BORROW_TIME = 5 minutes;
        _maxNumberOfReserves = type(uint16).max;
        // WETH.approve(address(this), type(uint256).max);
    }

    function authorizeLendingPool(address lendingPool) external onlyAdmin {
        WETH.approve(lendingPool, type(uint256).max);
    }

    /**
     * @dev Deposits ETH into the reserve, receiving in return overlying kTokens.
     * - E.g. User deposits 100 ETH and gets in return 100 h-NFTsymbol-ETH
     * @param reserveId The id of the reserve which user want to deposit
     * @param onBehalfOf The address that will receive the kTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of kTokens
     *   is a different wallet
     **/
    function deposit(
        uint256 reserveId,
        address onBehalfOf
    ) external payable override nonReentrant whenNotPaused {
        uint256 amount = msg.value;
        WETH.deposit{value: amount}();
        DataTypes.ReserveData storage reserve = _reserves[reserveId];

        ValidationLogic.validateDeposit(reserve, amount);

        address kToken = reserve.kTokenAddress;
        reserve.updateState();
        reserve.updateInterestRates(address(WETH), kToken, amount, 0);

        IERC20Upgradeable(address(WETH)).safeTransferFrom(
            address(this),
            kToken,
            amount
        );

        IKToken(kToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

        emit Deposit(reserveId, msg.sender, onBehalfOf, amount);
    }

    /**
     * @dev Withdraws an `amount` of ETH from the reserve, burning the equivalent kTokens owned
     * E.g. User has 100 hETH, calls withdraw() and receives 100 ETH, burning the 100 hETH
     * @param reserveId The id of the reserve
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole kToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address to
    ) external override nonReentrant whenNotPaused returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[reserveId];

        address kToken = reserve.kTokenAddress;

        uint256 userBalance = IKToken(kToken).balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        ValidationLogic.validateWithdraw(
            reserve,
            amountToWithdraw,
            userBalance
        );

        reserve.updateState();

        reserve.updateInterestRates(address(WETH), kToken, 0, amountToWithdraw);

        IKToken(kToken).burn(
            msg.sender,
            address(this),
            amountToWithdraw,
            reserve.liquidityIndex
        );

        WETH.withdraw(amountToWithdraw);
        _safeTransferETHWithFallback(to, amountToWithdraw);

        emit Withdraw(reserveId, msg.sender, to, amountToWithdraw);

        return amountToWithdraw;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function getBorrowId() internal returns (uint256) {
        _borrowId.increment();
        return _borrowId.current();
    }

    /**
     * @dev Allows users to borrow an estimate `amount` of the reserve underlying asset according to the value of the nft
     * @param reserveId The id of the reserve
     * @param asset The address of the nft which user want to use for borrow
     * @param nftId The token id of the nft
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address that will recieve the borrow asset and debt token (must be msg.sender or the msg.sender must be punkGateway)
     **/
    function borrow(
        uint256 reserveId,
        address asset,
        uint256 nftId,
        uint256 interestRateMode,
        address onBehalfOf
    ) external override nonReentrant whenNotPaused returns (uint256) {
        _requireCallerIsRight(onBehalfOf);
        address oracle = _addressesProvider.getPriceOracle()[0];
        uint256 floorPrice = SafeCastUpgradeable.toUint256(
            IPriceOracle(oracle).getPrice(asset)
        );
        return
            _executeBorrow(
                reserveId,
                asset,
                nftId,
                interestRateMode,
                floorPrice,
                onBehalfOf
            );
    }

    /**
     * @notice Repays a borrowed nft loan on a specific reserve
     * @param borrowId The id of the borrow info
     * @param onBehalfOf The address that will burn the debt token (must be msg.sender or the msg.sender must be punkGateway)
     * @return The final amount repaid
     **/
    function repay(
        uint256 borrowId,
        address onBehalfOf
    ) external payable override nonReentrant whenNotPaused returns (uint256) {
        address borrower = onBehalfOf;
        _requireCallerIsRight(borrower);
        uint256 amount = msg.value;
        DataTypes.BorrowInfo storage info = borrowMap[borrowId];
        uint256 reserveId = info.reserveId;
        DataTypes.ReserveData storage reserve = _reserves[reserveId];

        // (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(msg.sender, reserve);
        (uint256 stableDebt, uint256 variableDebt) = Helpers
            .getUserDebtOfAmount(borrower, reserve, info.principal);
        DataTypes.InterestRateMode interestRateMode = info.rateMode;

        uint256 paybackAmount = interestRateMode ==
            DataTypes.InterestRateMode.STABLE
            ? stableDebt
            : variableDebt;
        address oracle = _addressesProvider.getPriceOracle()[0];
        uint256 floor = SafeCastUpgradeable.toUint256(IPriceOracle(oracle).getPrice(info.nft));

        ValidationLogic.validateRepay(
            reserve,
            info,
            borrower,
            amount,
            paybackAmount,
            floor
        );

        WETH.deposit{value: paybackAmount}();

        reserve.updateState();

        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            IStableDebtToken(reserve.stableDebtTokenAddress).burn(
                borrower,
                paybackAmount
            );
        } else {
            IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
                borrower,
                paybackAmount,
                reserve.variableBorrowIndex
            );
        }

        address kToken = reserve.kTokenAddress;
        reserve.updateInterestRates(address(WETH), kToken, paybackAmount, 0);

        info.status = DataTypes.Status.REPAY;
        userBorrowIdMap[borrower].remove(borrowId);

        IERC20Upgradeable(address(WETH)).safeTransferFrom(
            address(this),
            kToken,
            paybackAmount
        );

        IKToken(kToken).handleRepayment(borrower, paybackAmount);

        IKToken(kToken).transferUnderlyingNFTTo(
            info.nft,
            borrower,
            info.nftId
        );

        emit Repay(
            reserveId,
            borrowId,
            borrower,
            info.nft,
            info.nftId,
            paybackAmount
        );

        if (amount - paybackAmount > 0) {
            _safeTransferETHWithFallback(borrower, amount - paybackAmount);
        }

        return paybackAmount;
    }

    /**
     * @dev Allows users to liquidate the loans that have expired
     * @param borrowId The id of liquidate borrow target
     */
    function liquidationCall(
        uint256 borrowId
    ) external payable override nonReentrant whenNotPaused {
        require(enabledLiquidation(borrowId), Errors.KPCM_LIQUIDATION_DISABLED);
        uint256 amountToLiquidation = msg.value;
        WETH.deposit{value: amountToLiquidation}();
        address liquidator = _addressesProvider.getKyokoPoolLiquidator()[0];
        // solium-disable-next-line
        (bool success, bytes memory result) = liquidator.delegatecall(
            abi.encodeWithSignature(
                "liquidationCall(uint256,uint256)",
                borrowId,
                amountToLiquidation
            )
        );
        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);
        (uint256 returnCode, ) = abi.decode(result, (uint256, string));
        require(returnCode == 0, Errors.ERROR);
    }

    /**
     * @dev Allows users bid for a liquidated auction
     * @param borrowId The id of liquidate borrow target
     */
    function bidCall(
        uint256 borrowId
    ) external payable override nonReentrant whenNotPaused {
        uint256 amountToBid = msg.value;
        WETH.deposit{value: amountToBid}();
        address liquidator = _addressesProvider.getKyokoPoolLiquidator()[0];
        // solium-disable-next-line
        (bool success, bytes memory result) = liquidator.delegatecall(
            abi.encodeWithSignature(
                "bidCall(uint256,uint256)",
                borrowId,
                amountToBid
            )
        );
        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);

        (address lastBidder, uint256 refundAmount) = abi.decode(
            result,
            (address, uint256)
        );
        require(lastBidder != address(0), Errors.ERROR);
        if (refundAmount > 0) {
            DataTypes.BorrowInfo memory info = borrowMap[borrowId];
            uint256 reserveId = info.reserveId;
            address kToken = _reserves[reserveId].kTokenAddress;
            IKToken(kToken).transferUnderlyingTo(address(this), refundAmount);
            WETH.withdraw(refundAmount);
            _safeTransferETHWithFallback(lastBidder, refundAmount);
        }
    }

    /**
     * @dev Allows users to claim the nft that has been auctioned success
     * @param borrowId The id of borrow target
     */
    function claimCall(
        uint256 borrowId
    ) external override whenNotPaused {
        address liquidator = _addressesProvider.getKyokoPoolLiquidator()[0];
        // solium-disable-next-line
        (bool success, bytes memory result) = liquidator.delegatecall(
            abi.encodeWithSignature(
                "claimCall(uint256)",
                borrowId
            )
        );
        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);
        (uint256 returnCode, ) = abi.decode(result, (uint256, string));
        require(returnCode == 0, Errors.ERROR);
    }

    function claimCall(
        uint256 borrowId,
        address onBehalfOf
    ) external override whenNotPaused {
        _requireCallerIsRight(onBehalfOf);
        address liquidator = _addressesProvider.getKyokoPoolLiquidator()[0];
        // solium-disable-next-line
        (bool success, bytes memory result) = liquidator.delegatecall(
            abi.encodeWithSignature(
                "claimCall(uint256,address)",
                borrowId,
                onBehalfOf
            )
        );
        require(success, Errors.LP_LIQUIDATION_CALL_FAILED);
        (uint256 returnCode, ) = abi.decode(result, (uint256, string));
        require(returnCode == 0, Errors.ERROR);
    }

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param reserveId The id of the reserve
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(
        uint256 reserveId,
        address user
    ) external override whenNotPaused {
        DataTypes.ReserveData storage reserve = _reserves[reserveId];

        IERC20Upgradeable stableDebtToken = IERC20Upgradeable(
            reserve.stableDebtTokenAddress
        );
        IERC20Upgradeable variableDebtToken = IERC20Upgradeable(
            reserve.variableDebtTokenAddress
        );
        address kTokenAddress = reserve.kTokenAddress;

        uint256 stableDebt = IERC20Upgradeable(stableDebtToken).balanceOf(user);

        ValidationLogic.validateRebalanceStableBorrowRate(
            reserve,
            address(WETH),
            stableDebtToken,
            variableDebtToken,
            kTokenAddress
        );

        reserve.updateState();

        IStableDebtToken(address(stableDebtToken)).burn(user, stableDebt);
        IStableDebtToken(address(stableDebtToken)).mint(
            user,
            user,
            stableDebt,
            reserve.currentStableBorrowRate
        );

        reserve.updateInterestRates(address(WETH), kTokenAddress, 0, 0);

        emit RebalanceStableBorrowRate(reserve.id, user);
    }

    /**
     * @dev Returns the state and configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(
        uint256 reserveId
    ) external view override returns (DataTypes.ReserveData memory) {
        return _reserves[reserveId];
    }

    /**
     * @dev Returns the normalized income per unit of asset
     * @param reserveId The id of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(
        uint256 reserveId
    ) external view virtual override returns (uint256) {
        return _reserves[reserveId].getNormalizedIncome();
    }

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param reserveId The id of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(
        uint256 reserveId
    ) external view override returns (uint256) {
        return _reserves[reserveId].getNormalizedDebt();
    }

    /**
     * @dev Returns if the KyokoPool is paused
     */
    function paused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the list of the initialized reserves
     **/
    function getReservesList()
        external
        view
        override
        returns (address[] memory)
    {
        return _nfts.values();
    }

    function getBorrowInfo(
        uint256 borrowId
    ) external view override returns (DataTypes.BorrowInfo memory) {
        return borrowMap[borrowId];
    }

    function getReserveNFTList(
        uint256 reserveId
    ) external view returns (address[] memory) {
        return _reservesNFTList[reserveId].values();
    }

    /**
     * @dev Returns the maximum number of reserves supported to be listed in this KyokoPool
     */
    function MAX_NUMBER_RESERVES() public view returns (uint256) {
        return _maxNumberOfReserves;
    }

    /**
     * @dev Initializes a reserve, activating it, assigning an kToken and debt info and an
     * interest rate strategy
     * @param asset The address of the underlying nft of the reserve
     * @param kTokenAddress The address of kToken
     * @param stableDebtAddress The address of stableDebtToken
     * @param variableDebtAddress The address of variableDebtToken
     * @param interestRateStrategyAddress The address of rate strategy
     **/
    function initReserve(
        address asset,
        address kTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external override onlyKyokoPoolConfigurator {
        uint256 reservesCount = _reservesCount;
        require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
        require(!_nfts.contains(asset), Errors.LP_NFT_ALREADY_EXIST);
        require(
            reservesCount < _maxNumberOfReserves,
            Errors.LP_NO_MORE_RESERVES_ALLOWED
        );
        _reserves[reservesCount].init(
            kTokenAddress,
            stableDebtAddress,
            variableDebtAddress,
            interestRateStrategyAddress
        );
        _reserves[reservesCount].id = reservesCount;
        _reservesNFTList[reservesCount].add(asset);
        _nfts.add(asset);
        _nftToReserves[asset].add(reservesCount);
        _reservesCount = reservesCount + 1;
    }

    /**
     * @dev Update NFT collection of the reserve
     * @param reserveId The id of the reserve
     * @param asset The address of NFT
     * @param flag True means add NFT to the reserve, False means remove NFT from the reserve
     **/
    function updateReserveNFT(
        uint256 reserveId,
        address asset,
        bool flag
    ) external override onlyKyokoPoolConfigurator {
        require(
            reserveId < _reservesCount,
            Errors.RL_RESERVE_ALREADY_INITIALIZED
        );
        if (flag) {
            require(
                !_reservesNFTList[reserveId].contains(asset),
                Errors.LP_NFT_ALREADY_EXIST
            );
            if (!_nfts.contains(asset)) {
                _nfts.add(asset);
            }
            _reservesNFTList[reserveId].add(asset);
            _nftToReserves[asset].add(reserveId);
        } else {
            require(
                _reservesNFTList[reserveId].contains(asset),
                Errors.LP_NFT_NOT_SUPPORT
            );
            _reservesNFTList[reserveId].remove(asset);
            _nftToReserves[asset].remove(reserveId);
            if (_nftToReserves[asset].values().length == 0) {
                _nfts.remove(asset);
            }
        }
    }

    /**
     * @dev Set the _pause state of a reserve
     * - Only callable by the KyokoPoolConfigurator contract
     * @param val `true` to pause the reserve, `false` to un-pause it
     */
    function setPause(bool val) external override onlyKyokoPoolConfigurator {
        _paused = val;
        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    struct ExecuteBorrowParams {
        uint256 reserveId;
        address nft;
        uint256 nftId;
        uint256 interestRateMode;
        uint256 floorPrice;
        address user;
    }

    function _executeBorrow(
        uint256 reserveId,
        address asset,
        uint256 nftId,
        uint256 interestRateMode,
        uint256 floorPrice,
        address onBehalfOf
    ) internal returns (uint256) {
        ExecuteBorrowParams memory vars;
        vars.reserveId = reserveId;
        vars.nft = asset;
        vars.nftId = nftId;
        vars.interestRateMode = interestRateMode;
        vars.floorPrice = floorPrice;
        vars.user = onBehalfOf;
        DataTypes.ReserveData storage reserve = _reserves[vars.reserveId];
        bool flag = _reservesNFTList[vars.reserveId].contains(vars.nft);
        DataTypes.InterestRateMode rateMode = DataTypes.InterestRateMode(
            vars.interestRateMode
        );
        {
            ValidationLogic.validateBorrow(
                reserve,
                vars.nft,
                vars.nftId,
                _msgSender(),
                vars.interestRateMode,
                flag
            );

            require(
                _msgSender() != address(0) && vars.floorPrice > 0,
                Errors.LP_BORROW_FAILED
            );
        }
        // uint256 borrowRatio = reserve.configuration.getBorrowRatio();
        uint256 amountToBorrow = vars.floorPrice.percentMul(
            reserve.configuration.getBorrowRatio()
        );
        address kToken = reserve.kTokenAddress;
        uint256 availableAmount = WETH.balanceOf(kToken);

        {
            require(
                availableAmount >= amountToBorrow,
                Errors.LP_LIQUIDITY_INSUFFICIENT
            );

            IERC721Upgradeable(vars.nft).safeTransferFrom(
                _msgSender(),
                kToken,
                vars.nftId
            );

            reserve.updateState();
        }
        uint256 principalVal = 0;
        uint256 currentStableRate = 0;
        uint256 emitBorrowRate = 0;
        {
            bool stable = rateMode == DataTypes.InterestRateMode.STABLE;
            if (stable) {
                uint256 principalBalanceBefore = IStableDebtToken(
                    reserve.stableDebtTokenAddress
                ).principalBalanceOf(vars.user);
                currentStableRate = reserve.currentStableBorrowRate;
                IStableDebtToken(reserve.stableDebtTokenAddress).mint(
                    vars.user,
                    vars.user,
                    amountToBorrow,
                    currentStableRate
                );
                uint256 principalBalanceAfter = IStableDebtToken(
                    reserve.stableDebtTokenAddress
                ).principalBalanceOf(vars.user);
                principalVal = principalBalanceAfter - principalBalanceBefore;
                emitBorrowRate = currentStableRate;
            } else {
                uint128 variableBorrowIndex = reserve.variableBorrowIndex;
                IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
                    vars.user,
                    vars.user,
                    amountToBorrow,
                    variableBorrowIndex
                );
                principalVal = amountToBorrow.rayDiv(variableBorrowIndex);
            }
        }
        reserve.updateInterestRates(address(WETH), kToken, 0, amountToBorrow);

        uint256 borrowId = getBorrowId();
        {
            uint256 period = reserve.configuration.getPeriod();

            borrowMap[borrowId] = DataTypes.BorrowInfo({
                reserveId: vars.reserveId,
                nft: vars.nft,
                nftId: vars.nftId,
                user: vars.user,
                startTime: uint64(block.timestamp),
                principal: principalVal,
                borrowId: borrowId,
                liquidateTime: uint64(block.timestamp + period),
                status: DataTypes.Status.BORROW,
                rateMode: rateMode
            });

            userBorrowIdMap[vars.user].add(borrowId);
            IKToken(kToken).transferUnderlyingTo(address(this), amountToBorrow);
            WETH.withdraw(amountToBorrow);
            _safeTransferETHWithFallback(vars.user, amountToBorrow);
        }

        if (emitBorrowRate == 0) {
            emitBorrowRate = reserve.currentVariableBorrowRate;
        }

        emit Borrow(
            vars.reserveId,
            borrowId,
            vars.nft,
            vars.nftId,
            vars.interestRateMode,
            amountToBorrow,
            emitBorrowRate
        );
        return amountToBorrow;
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(
        address to,
        uint256 value
    ) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(WETH).deposit{value: amount}();
            require(
                IERC20Upgradeable(address(WETH)).transfer(to, amount),
                Errors.LP_WETH_TRANSFER_FAILED
            );
        }
    }

    /**
     * @dev
     */
    receive() external payable {}

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }

    /**
     * @dev Returns the list of user's borrowId
     * @param user The address of the user
     **/
    function getUserBorrowList(
        address user
    ) external view override returns (uint256[] memory borrowIds) {
        borrowIds = userBorrowIdMap[user].values();
    }

    /**
     * @dev Returns the list of borrowId in auction
     **/
    function getAuctions() external view override returns (uint256[] memory) {
        return auctions.values();
    }

    /**
     * @dev Returns the accumulated debt of the specified borrowId
     * @param borrowId The id of the borrow info
     **/
    function getDebt(
        uint256 borrowId
    ) external view override returns (uint256 debt) {
        DataTypes.BorrowInfo memory info = borrowMap[borrowId];
        DataTypes.ReserveData memory reserve = _reserves[info.reserveId];
        if (info.rateMode == DataTypes.InterestRateMode.STABLE) {
            (debt, ) = Helpers.getUserDebtOfAmountMemory(
                info.user,
                reserve,
                info.principal
            );
        } else {
            (, debt) = Helpers.getUserDebtOfAmountMemory(
                info.user,
                reserve,
                info.principal
            );
        }
    }

    function getUserAccount(
        uint256 reserveId,
        address user
    ) public view returns (uint256 stableDebt, uint256 variableDebt) {
        DataTypes.ReserveData memory reserve = _reserves[reserveId];
        (stableDebt, variableDebt) = Helpers.getUserCurrentDebtMemory(
            user,
            reserve
        );
    }

    function getInitialLockTime(
        uint256 reserveId
    ) public view override returns (uint256) {
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        uint256 lockTime = reserve.configuration.getLockTime();
        return lockTime;
    }

    function enabledLiquidation(
        uint256 borrowId
    ) public view override returns (bool) {
        DataTypes.BorrowInfo memory info = borrowMap[borrowId];
        DataTypes.ReserveData memory reserve = _reserves[info.reserveId];
        uint256 debt = this.getDebt(borrowId);
        (, , , , uint256 liqThreshold, , , , ) = reserve
            .configuration
            .getParamsMemory();
        if (info.rateMode == DataTypes.InterestRateMode.STABLE) {
            return block.timestamp > info.liquidateTime;
        } else {
            address oracle = _addressesProvider.getPriceOracle()[0];
            int256 floorPrice = IPriceOracle(oracle).getPrice_view(info.nft);
            return
                SafeCastUpgradeable.toUint256(floorPrice) <
                debt.percentMul(liqThreshold);
        }
    }

    /**
     * @dev Updates the address of the interest rate strategy contract
     * - Only callable by the LendingPoolConfigurator contract
     * @param reserveId The id of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        uint256 reserveId,
        address rateStrategyAddress
    ) external override onlyKyokoPoolConfigurator {
        _reserves[reserveId].interestRateStrategyAddress = rateStrategyAddress;
    }

    /**
     * @dev Burn the initial liquidity in KToken of a reserve
     * @param reserveId The id of the reserve
     * @param amount The amount of burned KToken
     **/
    function burnLiquidity(
        uint256 reserveId,
        uint256 amount
    ) external override {
        DataTypes.ReserveData storage reserve = _reserves[reserveId];
        address kToken = reserve.kTokenAddress;
        reserve.updateState();
        reserve.updateInterestRates(address(WETH), kToken, 0, amount);
        IKToken(kToken).burn(msg.sender, amount, reserve.liquidityIndex);
    }

    /**
     * @dev Sets the configuration bitmap of the reserve as a whole
     * - Only callable by the KyokoPoolConfigurator contract
     * @param reserveId The id of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        uint256 reserveId,
        uint256 configuration
    ) external override onlyKyokoPoolConfigurator {
        _reserves[reserveId].configuration.data = configuration;
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(
        uint256 reserveId
    )
        external
        view
        override
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[reserveId].configuration;
    }

    function getReservesCount() public view override returns (uint256) {
        return _reservesCount;
    }

    function updatePunkGateway(address punkGateway) external onlyAdmin {
        _punkGateway = punkGateway;
    }

    function _requireCallerIsRight(address onBehalfOf) internal view {
        require(
            msg.sender == _punkGateway || msg.sender == onBehalfOf,
            "wrong address for onBehalfOf"
        );
    }
}