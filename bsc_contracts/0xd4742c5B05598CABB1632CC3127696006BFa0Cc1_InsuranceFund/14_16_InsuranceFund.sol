// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router.sol";
import {Errors} from "./libraries/helpers/Errors.sol";
import {WhitelistManager} from "./modules/WhitelistManager.sol";

contract InsuranceFund is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    WhitelistManager
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    uint256 public totalFee;
    uint256 public totalBurned;

    address public counterParty;

    IERC20Upgradeable public posi;
    IERC20Upgradeable public busdBonus;
    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;

    bool public acceptBonus;
    // PositionManager => (Trader => (BonusBalance))
    mapping(address => mapping(address => uint256)) public busdBonusBalances;
    // mapping Position Manager => Quote Asset
    mapping(address => address) public managerAsset;
    mapping(bytes32 => bool) refundedTxHash;
    mapping(address => bool) private validatedAdmin;

    event BuyBackAndBurned(
        address _token,
        uint256 _tokenAmount,
        uint256 _posiAmount
    );
    event SoldPosiForFund(uint256 _posiAmount, uint256 _tokenAmount);
    event Deposit(
        address indexed _token,
        address indexed _trader,
        uint256 _amount,
        uint256 _amountBonus
    );
    event Withdraw(
        address indexed _token,
        address indexed _trader,
        uint256 _amount,
        uint256 _amountBonus
    );
    event CounterPartyTransferred(address _old, address _new);
    event PosiChanged(address _new);
    event RouterChanged(address _new);
    event FactoryChanged(address _new);
    event WhitelistManagerUpdated(address positionManager, bool isWhitelist);
    event BonusBalanceCleared(address positionManager, address trader);
    event RealTimeBuyBackAndBurnChanged(bool previousValue, bool newValue);

    modifier onlyCounterParty() {
        require(counterParty == _msgSender(), Errors.VL_NOT_COUNTERPARTY);
        _;
    }

    modifier onlyFuturesStaking() {
        require(
            validatedFuturesStaking[_msgSender()],
            "only futures staking contract"
        );
        _;
    }

    modifier onlyAdmin() {
        require(isValidatedAdmin(_msgSender()), "only admin");
        _;
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        posi = IERC20Upgradeable(0x5CA42204cDaa70d5c773946e69dE942b85CA6706);
        busdBonus = IERC20Upgradeable(
            0xfca3c89c3Bd3c3c65a33656BF3178a5fC5C3aF8e
        ); // TODO: Change later
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    }

    struct AcceptBusdBonusConfig {
        uint256 notional;
        uint256 percentage;
        // 1 -> <=
        // 2 -> <
        // 3 -> >=
        uint8 comparator;
    }

    function _getAcceptBusdBonusConfig()
        public
        pure
        returns (AcceptBusdBonusConfig[] memory)
    {
        AcceptBusdBonusConfig[] memory configs = new AcceptBusdBonusConfig[](6);

        configs[0] = AcceptBusdBonusConfig(500 * 1e18, 70, 1);
        configs[1] = AcceptBusdBonusConfig(1000 * 1e18, 60, 1);
        configs[2] = AcceptBusdBonusConfig(10000 * 1e18, 40, 1);
        configs[3] = AcceptBusdBonusConfig(20000 * 1e18, 25, 1);
        configs[4] = AcceptBusdBonusConfig(30000 * 1e18, 15, 2);
        configs[5] = AcceptBusdBonusConfig(30000 * 1e18, 5, 3);
        return configs;
    }

    function _correctBusdBonusNewRules(
        uint256 _notional,
        uint256 busdAmount,
        uint256 bonusAmount
    ) internal pure returns (uint256, uint256) {
        /*
        if notional
             <=500 BUSD then use busdBonus 90%, 10% for busdAmount
             // same as above
             <=1000 BUSD	70%
             <=10000 BUSD	50%
             <=200000 BUSD	30%
             <300000 BUSD	20%
             >300000 BUSD	10%
         */
        AcceptBusdBonusConfig[] memory configs = _getAcceptBusdBonusConfig();
        for (uint256 i = 0; i < configs.length; i++) {
            if (configs[i].comparator == 1) {
                if (_notional <= configs[i].notional) {
                    return (
                        (bonusAmount * (100 - configs[i].percentage)) /
                            100 +
                            busdAmount,
                        (bonusAmount * configs[i].percentage) / 100
                    );
                }
            } else if (configs[i].comparator == 2) {
                if (_notional < configs[i].notional) {
                    return (
                        (bonusAmount * (100 - configs[i].percentage)) /
                            100 +
                            busdAmount,
                        (bonusAmount * configs[i].percentage) / 100
                    );
                }
            } else if (configs[i].comparator == 3) {
                if (_notional >= configs[i].notional) {
                    return (
                        (bonusAmount * (100 - configs[i].percentage)) /
                            100 +
                            busdAmount,
                        (bonusAmount * configs[i].percentage) / 100
                    );
                }
            }
        }
        return (busdAmount + bonusAmount, 0);
    }

    function calculateBusdBonusAmount(
        address _positionManager,
        address _trader,
        uint256 _initialMargin,
        uint256 _fee,
        uint256 _notional
    )
        public
        view
        returns (
            uint256 _realMarginNeeded,
            uint256 _bonusMarginNeededWithFee,
            uint256 _bonusMarginNeeded,
            bool _isSufficientCollateral
        )
    {
        IERC20Upgradeable _collateralToken = IERC20Upgradeable(
            managerAsset[_positionManager]
        );
        uint256 bonusBalance = busdBonus.balanceOf(_trader);
        if (bonusBalance == 0 || !acceptBonus) {
            return (
                _initialMargin,
                0,
                0,
                _collateralToken.balanceOf(_trader) >= _initialMargin + _fee
            );
        }
        (
            _realMarginNeeded,
            _bonusMarginNeededWithFee,
            _bonusMarginNeeded
        ) = calcDepositAmount(
            _initialMargin,
            _fee,
            bonusBalance,
            _initialMargin
        );
        (_realMarginNeeded, _bonusMarginNeeded) = _correctBusdBonusNewRules(
            _notional,
            _realMarginNeeded,
            _bonusMarginNeededWithFee
        );

        _isSufficientCollateral =
            _collateralToken.balanceOf(_trader) >= _realMarginNeeded + _fee;
        return (
            _realMarginNeeded,
            _bonusMarginNeeded + _fee,
            _bonusMarginNeeded,
            _isSufficientCollateral
        );
    }

    // only for external view
    function calculateAmountWithdraw(
        address _positionManager,
        address _trader,
        uint256 _amount
    ) external view returns (uint256 _busdAmount, uint256 _bonusAmount) {
        address _token = managerAsset[_positionManager];
        uint256 withdrawBUSDAmount;
        uint256 withdrawBonusAmount;
        uint256 remainingBonusAmount;
        //        if (acceptBonus) {
        uint256 bonusBalance = busdBonusBalances[_positionManager][_trader];
        (
            withdrawBUSDAmount,
            withdrawBonusAmount,
            remainingBonusAmount
        ) = calcWithdrawAmount(_amount, bonusBalance);
        return (withdrawBUSDAmount, withdrawBonusAmount);
        //        }
        //        return (_amount, 0);
    }

    /**
     * @dev Deposit with bonus calculated outsite
     * @param _positionManager address of position manager
     * @param _trader address of trader
     * @param _realInitialMargin amount of deposit token. Eg: BUSD
     * @param _bonusInitialMargin amount of deposit bonus token.
     * @param _fee, fee must be paid by BUSD token
     */
    function depositWithBonus(
        address _positionManager,
        address _trader,
        uint256 _realInitialMargin,
        uint256 _bonusInitialMargin,
        uint256 _fee
    ) public onlyCounterParty onlyWhitelistManager(_positionManager) {
        address _asset = managerAsset[_positionManager];
        IERC20Upgradeable _collateralToken = IERC20Upgradeable(_asset);
        totalFee += _fee;
        if (_bonusInitialMargin > 0) {
            busdBonus.safeTransferFrom(
                _trader,
                address(this),
                _bonusInitialMargin
            );
        }
        // fee must be paid by BUSD token
        _collateralToken.safeTransferFrom(
            _trader,
            address(this),
            _realInitialMargin + _fee
        );
        emit Deposit(
            address(_collateralToken),
            _trader,
            _realInitialMargin + _fee,
            _bonusInitialMargin
        );
    }

    function deposit(
        address _positionManager,
        address _trader,
        uint256 _initialMargin,
        uint256 _fee
    ) public onlyCounterParty onlyWhitelistManager(_positionManager) {
        address _asset = managerAsset[_positionManager];
        IERC20Upgradeable _token = IERC20Upgradeable(_asset);
        uint256 collectableAmount = _initialMargin + _fee;
        uint256 collectableBUSDAmount;
        uint256 collectableBonusAmount;
        uint256 depositedBonusAmount;
        if (acceptBonus) {
            uint256 bonusBalance = busdBonus.balanceOf(_trader);
            (
                collectableBUSDAmount,
                collectableBonusAmount,
                depositedBonusAmount
            ) = calcDepositAmount(
                _initialMargin,
                _fee,
                bonusBalance,
                collectableAmount
            );

            if (collectableBonusAmount > 0) {
                busdBonus.safeTransferFrom(
                    _trader,
                    address(this),
                    collectableBonusAmount
                );
            }

            if (depositedBonusAmount > 0) {
                busdBonusBalances[_positionManager][
                    _trader
                ] += depositedBonusAmount;
            }

            collectableAmount = collectableBUSDAmount;
            if (collectableAmount == 0) {
                emit Deposit(
                    address(_token),
                    _trader,
                    _initialMargin + _fee,
                    depositedBonusAmount
                );
                return;
            }
        }

        totalFee += _fee;
        _token.safeTransferFrom(_trader, address(this), collectableAmount);
        emit Deposit(
            address(_token),
            _trader,
            _initialMargin + _fee,
            depositedBonusAmount
        );
    }

    // TODO Fix withdraw with param asset address, trader, amount
    function withdraw(
        address _positionManager,
        address _trader,
        uint256 _totalAmount,
        uint256 _busdBonusAmount
    ) public onlyCounterParty onlyWhitelistManager(_positionManager) {
        uint256 _realBusdAmount = _totalAmount - _busdBonusAmount;
        _withdraw(_positionManager, _trader, _realBusdAmount, _busdBonusAmount);
    }

    function refund(
        address _positionManager,
        address _trader,
        uint256 _totalAmount,
        uint256 _busdBonusAmount,
        bytes32 _txHash
    ) public onlyAdmin onlyWhitelistManager(_positionManager) {
        require(!isRefundedHash(_txHash), "already refunded");
        refundedTxHash[_txHash] = true;
        uint256 _realBusdAmount = _totalAmount - _busdBonusAmount;
        _withdraw(_positionManager, _trader, _realBusdAmount, _busdBonusAmount);
    }

    function futuresStakingWithdraw(
        uint256 _amount,
        address _user,
        address _token
    ) public onlyFuturesStaking nonReentrant {
        IERC20Upgradeable(_token).safeTransfer(_user, _amount);
    }

    function futuresStakingDeposit(
        uint256 _amount,
        address _user,
        address _token
    ) public onlyFuturesStaking nonReentrant {
        IERC20Upgradeable(_token).safeTransferFrom(
            _user,
            address(this),
            _amount
        );
    }

    function liquidateAndDistributeReward(
        address _positionManager,
        address _liquidator,
        address _trader,
        uint256 _liquidatedBusdBonus,
        uint256 _liquidatorReward
    ) external onlyCounterParty {
        //        _reduceBonus(_positionManager, _trader, _liquidatedBusdBonus);
        _distributeLiquidatorReward(
            _positionManager,
            _liquidator,
            _liquidatorReward
        );
    }

    function _reduceBonus(
        address _positionManager,
        address _trader,
        uint256 _reduceAmount
    ) internal {
        uint256 traderBusdBonusBalance = busdBonusBalances[_positionManager][
            _trader
        ];
        if (traderBusdBonusBalance != 0) {
            if (_reduceAmount != 0 && _reduceAmount < traderBusdBonusBalance) {
                busdBonusBalances[_positionManager][_trader] -= _reduceAmount;
                return;
            }

            // Use when fully liquidated
            busdBonusBalances[_positionManager][_trader] = 0;
            emit BonusBalanceCleared(_positionManager, _trader);
        }
    }

    function _distributeLiquidatorReward(
        address _positionManager,
        address _liquidator,
        uint256 _rewardAmount
    ) internal {
        IERC20Upgradeable _token = IERC20Upgradeable(
            managerAsset[_positionManager]
        );
        _token.safeTransfer(_liquidator, _rewardAmount);
    }

    function _withdraw(
        address _positionManager,
        address _trader,
        uint256 _realBusdAmount,
        uint256 _busdBonusAmount
    ) internal {
        address _token = managerAsset[_positionManager];
        if (_busdBonusAmount > 0) {
            busdBonus.safeTransfer(_trader, _busdBonusAmount);
        }
        // if insurance fund not enough amount for trader, should sell posi and pay for trader
        uint256 _tokenBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        if (_tokenBalance < _realBusdAmount) {
            uint256 _gap = ((_realBusdAmount - _tokenBalance) * 110) / 100;
            uint256[] memory _amountIns = router.getAmountsIn(
                _gap,
                getPosiToTokenRoute(_token)
            );
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountIns[0],
                0,
                getPosiToTokenRoute(_token),
                address(this),
                block.timestamp
            );
            emit SoldPosiForFund(_amountIns[0], _gap);
        }
        IERC20Upgradeable(_token).safeTransfer(_trader, _realBusdAmount);
        emit Withdraw(_token, _trader, _realBusdAmount, _busdBonusAmount);
    }

    //******************************************************************************************************************
    // ONLY OWNER FUNCTIONS
    //******************************************************************************************************************

    // update real time buy back and burn
    function updateBuyBackAndBurnRealtime(bool _val) external onlyOwner {
        emit RealTimeBuyBackAndBurnChanged(enableRealTimeBuyBackAndBurn, _val);
        enableRealTimeBuyBackAndBurn = _val;
    }

    function updateAdminStatus(address _admin, bool _isValidated)
        external
        onlyOwner
    {
        validatedAdmin[_admin] = _isValidated;
    }

    function updateWhitelistManager(address _positionManager, bool _isWhitelist)
        external
        onlyOwner
    {
        if (_isWhitelist) {
            _setWhitelistManager(_positionManager);
        } else {
            _removeWhitelistManager(_positionManager);
        }
        emit WhitelistManagerUpdated(_positionManager, _isWhitelist);
    }

    function updatePosiAddress(IERC20Upgradeable _newPosiAddress)
        public
        onlyOwner
    {
        posi = _newPosiAddress;
        emit PosiChanged(address(_newPosiAddress));
    }

    function updateRouterAddress(IUniswapV2Router02 _newRouterAddress)
        public
        onlyOwner
    {
        router = _newRouterAddress;
        emit RouterChanged(address(_newRouterAddress));
    }

    function updateFactoryAddress(IUniswapV2Factory _newFactory)
        public
        onlyOwner
    {
        factory = _newFactory;
        emit FactoryChanged(address(_newFactory));
    }

    // Buy POSI on market and burn it
    function buyBackAndBurn(address _token, uint256 _amount) public onlyOwner {
        _buyBackAndBurn(_token, _amount);
    }

    event BBBCallerRewardRateUpdated(uint256 oldRate, uint256 newRate);

    function updateBBCallerRewardRate(uint256 _rate) public onlyOwner {
        _updateBBCallerRewardRate(_rate);
    }

    function _updateBBCallerRewardRate(uint256 _rate) internal {
        emit BBBCallerRewardRateUpdated(bbbCallerRewardRate, _rate);
        require(_rate <= 100, "Reward rate must be less than 100");
        bbbCallerRewardRate = _rate;
    }

    function initializeBBB(
        address _busdToken,
        uint256 startingAmount,
        uint256 callerRate
    ) public onlyOwner {
        busdToken = IERC20Upgradeable(_busdToken);
        cumulativeBuyBackAndBurnBUSD = startingAmount;
        _updateBBCallerRewardRate(callerRate);
    }

    function buyBackAndBurn() public nonReentrant {
        require(
            enableRealTimeBuyBackAndBurn,
            "Real time buy back and burn is disabled"
        );
        (
            uint256 _buyAmount,
            uint256 _rewardAmount
        ) = getAmountAvailableToBurn();
        _buyBackAndBurn(address(busdToken), _buyAmount);
        if (_rewardAmount > 0) {
            busdToken.safeTransfer(msg.sender, _rewardAmount);
        }
    }

    function getAmountAvailableToBurn()
        public
        view
        returns (uint256 burnAmount, uint256 rewardCaller)
    {
        burnAmount = totalFee - cumulativeBuyBackAndBurnBUSD;
        rewardCaller = (burnAmount * bbbCallerRewardRate) / 100;
        burnAmount -= rewardCaller;
    }

    function _buyBackAndBurn(address _token, uint256 _amount) internal {
        // buy back
        // To save gas more gas fee for buy back, we will not check balance of posi before and after swap
        uint256 _posiBalanceBefore = posi.balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            getTokenToPosiRoute(_token),
            BURN_ADDRESS,
            block.timestamp
        );
        uint256 _posiBalanceAfter = posi.balanceOf(address(this));
        uint256 _posiAmount = _posiBalanceAfter - _posiBalanceBefore;
        totalBurned += _posiAmount;
        cumulativeBuyBackAndBurnBUSD += _amount;
        emit BuyBackAndBurned(_token, _amount, _posiAmount);
    }

    function _realTimeBuyBackAndBurn(address _token, uint256 _amount) internal {
        if (enableRealTimeBuyBackAndBurn) {
            _buyBackAndBurn(_token, _amount);
        }
    }

    function setCounterParty(address _counterParty) public onlyOwner {
        require(_counterParty != address(0), Errors.VL_EMPTY_ADDRESS);
        emit CounterPartyTransferred(counterParty, _counterParty);
        counterParty = _counterParty;
    }

    function updateFuturesStakingStatus(
        address _futuresStaking,
        bool _isValidated
    ) public onlyOwner {
        validatedFuturesStaking[_futuresStaking] = _isValidated;
    }

    //******************************************************************************************************************
    // ONLY OWNER FUNCTIONS
    //******************************************************************************************************************

    // Approve for the reserved funds
    // due to security issue, the reserved funds contract address is hardcode
    function approveReserveFund() external onlyOwner {
        IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56).approve(
            0xf7Cc1d59C8022517CC9553c2c39909b610fC431e,
            type(uint256).max
        );
    }

    // approve token for router in order to swap tokens
    function approveTokenForRouter(address _token) public onlyOwner {
        IERC20Upgradeable(_token).safeApprove(
            address(router),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    function setManagerAssetMapping(address _positionManager, address _address)
        public
        onlyOwner
    {
        require(_positionManager != address(0), Errors.VL_EMPTY_ADDRESS);
        require(_address != address(0), Errors.VL_EMPTY_ADDRESS);
        managerAsset[_positionManager] = _address;
    }

    function setBUSDBonusAddress(IERC20Upgradeable _newBUSDBonusAddress)
        public
        onlyOwner
    {
        busdBonus = _newBUSDBonusAddress;
    }

    event MaxBUSDBonusAcceptedPerPositionUpdated(
        uint256 oldMax,
        uint256 newMax
    );

    function updateMaximumBUSDBonusAcceptedPerPosition(
        uint256 _newMaximumBUSDBonusAccepted
    ) public onlyOwner {
        emit MaxBUSDBonusAcceptedPerPositionUpdated(
            maximumBUSDBonusAccepted,
            _newMaximumBUSDBonusAccepted
        );
        maximumBUSDBonusAccepted = _newMaximumBUSDBonusAccepted;
    }

    function shouldAcceptBonus(bool _acceptBonus) public onlyOwner {
        acceptBonus = _acceptBonus;
    }

    function isRefundedHash(bytes32 _txHash) public view returns (bool) {
        return refundedTxHash[_txHash];
    }

    function isValidatedAdmin(address _admin) public view returns (bool) {
        return validatedAdmin[_admin];
    }

    //******************************************************************************************************************
    // VIEW FUNCTIONS
    //******************************************************************************************************************

    function getTokenToPosiRoute(address token)
        private
        view
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = token;
        paths[1] = address(posi);
    }

    function getPosiToTokenRoute(address token)
        private
        view
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = address(posi);
        paths[1] = token;
    }

    function calcDepositAmount(
        uint256 _amount,
        uint256 _fee,
        uint256 _busdBonusBalance,
        uint256 _totalCollectable
    )
        private
        view
        returns (
            uint256 _realMarginNeeded,
            uint256 _bonusMarginNeededWithFee,
            uint256 _bonusMarginNeeded
        )
    {
        if (_busdBonusBalance == 0) {
            return (_totalCollectable, 0, 0);
        }

        if (_totalCollectable <= _busdBonusBalance) {
            return (0, _totalCollectable, _amount);
        }

        if (_fee >= _busdBonusBalance) {
            return (
                _totalCollectable - _busdBonusBalance,
                _busdBonusBalance,
                0
            );
        }

        return (
            _totalCollectable - _busdBonusBalance,
            _busdBonusBalance,
            _busdBonusBalance - _fee
        );
    }

    function calcWithdrawAmount(
        uint256 _withdrawAmount,
        uint256 _busdBonusBalance
    )
        private
        view
        returns (
            uint256 withdrawBUSDAmount,
            uint256 withdrawBonusAmount,
            uint256 remainingBonusAmount
        )
    {
        if (_busdBonusBalance == 0) {
            return (_withdrawAmount, 0, 0);
        }

        if (_withdrawAmount <= _busdBonusBalance) {
            return (0, _withdrawAmount, _busdBonusBalance - _withdrawAmount);
        }

        return (_withdrawAmount - _busdBonusBalance, _busdBonusBalance, 0);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
    bool public enableRealTimeBuyBackAndBurn;
    // total cumulative BUSD used to buy back and burn
    uint256 public cumulativeBuyBackAndBurnBUSD;
    uint256 public bbbCallerRewardRate;
    IERC20Upgradeable public busdToken;
    mapping(address => bool) public validatedFuturesStaking;
    uint256 public maximumBUSDBonusAccepted;
}