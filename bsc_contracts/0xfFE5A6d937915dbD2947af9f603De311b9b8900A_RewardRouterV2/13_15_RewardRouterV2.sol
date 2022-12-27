// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardRouterV2.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/ISlpManager.sol";
import "../access/Governable.sol";

contract RewardRouterV2 is IRewardRouterV2, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public srx;
    address public esSrx;
    address public bnSrx;

    address public slp; // SRX Liquidity Provider token

    address public stakedSrxTracker;
    address public bonusSrxTracker;
    address public feeSrxTracker;

    address public override stakedSlpTracker;
    address public override feeSlpTracker;

    address public slpManager;

    address public srxVester;
    address public slpVester;

    mapping(address => address) public pendingReceivers;

    event StakeSrx(address account, address token, uint256 amount);
    event UnstakeSrx(address account, address token, uint256 amount);

    event StakeSlp(address account, uint256 amount);
    event UnstakeSlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _srx,
        address _esSrx,
        address _bnSrx,
        address _slp,
        address _stakedSrxTracker,
        address _bonusSrxTracker,
        address _feeSrxTracker,
        address _feeSlpTracker,
        address _stakedSlpTracker,
        address _slpManager,
        address _srxVester,
        address _slpVester
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        srx = _srx;
        esSrx = _esSrx;
        bnSrx = _bnSrx;

        slp = _slp;

        stakedSrxTracker = _stakedSrxTracker;
        bonusSrxTracker = _bonusSrxTracker;
        feeSrxTracker = _feeSrxTracker;

        feeSlpTracker = _feeSlpTracker;
        stakedSlpTracker = _stakedSlpTracker;

        slpManager = _slpManager;

        srxVester = _srxVester;
        slpVester = _slpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeSrxForAccount(
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external nonReentrant onlyGov {
        address _srx = srx;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeSrx(msg.sender, _accounts[i], _srx, _amounts[i]);
        }
    }

    function stakeSrxForAccount(
        address _account,
        uint256 _amount
    ) external nonReentrant onlyGov {
        _stakeSrx(msg.sender, _account, srx, _amount);
    }

    function stakeSrx(uint256 _amount) external nonReentrant {
        _stakeSrx(msg.sender, msg.sender, srx, _amount);
    }

    function stakeEsSrx(uint256 _amount) external nonReentrant {
        _stakeSrx(msg.sender, msg.sender, esSrx, _amount);
    }

    function unstakeSrx(uint256 _amount) external nonReentrant {
        _unstakeSrx(msg.sender, srx, _amount, true);
    }

    function unstakeEsSrx(uint256 _amount) external nonReentrant {
        _unstakeSrx(msg.sender, esSrx, _amount, true);
    }

    function mintAndStakeSlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 slpAmount = ISlpManager(slpManager).addLiquidityForAccount(
            account,
            account,
            _token,
            _amount,
            _minUsdg,
            _minSlp
        );
        IRewardTracker(feeSlpTracker).stakeForAccount(
            account,
            account,
            slp,
            slpAmount
        );
        IRewardTracker(stakedSlpTracker).stakeForAccount(
            account,
            account,
            feeSlpTracker,
            slpAmount
        );

        emit StakeSlp(account, slpAmount);

        return slpAmount;
    }

    function mintAndStakeSlpETH(
        uint256 _minUsdg,
        uint256 _minSlp
    ) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(slpManager, msg.value);

        address account = msg.sender;
        uint256 slpAmount = ISlpManager(slpManager).addLiquidityForAccount(
            address(this),
            account,
            weth,
            msg.value,
            _minUsdg,
            _minSlp
        );

        IRewardTracker(feeSlpTracker).stakeForAccount(
            account,
            account,
            slp,
            slpAmount
        );
        IRewardTracker(stakedSlpTracker).stakeForAccount(
            account,
            account,
            feeSlpTracker,
            slpAmount
        );

        emit StakeSlp(account, slpAmount);

        return slpAmount;
    }

    function unstakeAndRedeemSlp(
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external nonReentrant returns (uint256) {
        require(_slpAmount > 0, "RewardRouter: invalid _slpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSlpTracker).unstakeForAccount(
            account,
            feeSlpTracker,
            _slpAmount,
            account
        );
        IRewardTracker(feeSlpTracker).unstakeForAccount(
            account,
            slp,
            _slpAmount,
            account
        );
        uint256 amountOut = ISlpManager(slpManager).removeLiquidityForAccount(
            account,
            _tokenOut,
            _slpAmount,
            _minOut,
            _receiver
        );

        emit UnstakeSlp(account, _slpAmount);

        return amountOut;
    }

    function unstakeAndRedeemSlpETH(
        uint256 _slpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external nonReentrant returns (uint256) {
        require(_slpAmount > 0, "RewardRouter: invalid _slpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSlpTracker).unstakeForAccount(
            account,
            feeSlpTracker,
            _slpAmount,
            account
        );
        IRewardTracker(feeSlpTracker).unstakeForAccount(
            account,
            slp,
            _slpAmount,
            account
        );
        uint256 amountOut = ISlpManager(slpManager).removeLiquidityForAccount(
            account,
            weth,
            _slpAmount,
            _minOut,
            address(this)
        );

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeSlp(account, _slpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSrxTracker).claimForAccount(account, account);
        IRewardTracker(feeSlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedSrxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSlpTracker).claimForAccount(account, account);
    }

    function claimEsSrx() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedSrxTracker).claimForAccount(account, account);
        IRewardTracker(stakedSlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSrxTracker).claimForAccount(account, account);
        IRewardTracker(feeSlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(
        address _account
    ) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimSrx,
        bool _shouldStakeSrx,
        bool _shouldClaimEsSrx,
        bool _shouldStakeEsSrx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 srxAmount = 0;
        if (_shouldClaimSrx) {
            uint256 srxAmount0 = IVester(srxVester).claimForAccount(
                account,
                account
            );
            uint256 srxAmount1 = IVester(slpVester).claimForAccount(
                account,
                account
            );
            srxAmount = srxAmount0.add(srxAmount1);
        }

        if (_shouldStakeSrx && srxAmount > 0) {
            _stakeSrx(account, account, srx, srxAmount);
        }

        uint256 esSrxAmount = 0;
        if (_shouldClaimEsSrx) {
            uint256 esSrxAmount0 = IRewardTracker(stakedSrxTracker)
                .claimForAccount(account, account);
            uint256 esSrxAmount1 = IRewardTracker(stakedSlpTracker)
                .claimForAccount(account, account);
            esSrxAmount = esSrxAmount0.add(esSrxAmount1);
        }

        if (_shouldStakeEsSrx && esSrxAmount > 0) {
            _stakeSrx(account, account, esSrx, esSrxAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnSrxAmount = IRewardTracker(bonusSrxTracker)
                .claimForAccount(account, account);
            if (bnSrxAmount > 0) {
                IRewardTracker(feeSrxTracker).stakeForAccount(
                    account,
                    account,
                    bnSrx,
                    bnSrxAmount
                );
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feeSrxTracker).claimForAccount(
                    account,
                    address(this)
                );
                uint256 weth1 = IRewardTracker(feeSlpTracker).claimForAccount(
                    account,
                    address(this)
                );

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeSrxTracker).claimForAccount(account, account);
                IRewardTracker(feeSlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(
        address[] memory _accounts
    ) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(
            IERC20(srxVester).balanceOf(msg.sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20(slpVester).balanceOf(msg.sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(
            IERC20(srxVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20(slpVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        address receiver = msg.sender;
        require(
            pendingReceivers[_sender] == receiver,
            "RewardRouter: transfer not signalled"
        );
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedSrx = IRewardTracker(stakedSrxTracker).depositBalances(
            _sender,
            srx
        );
        if (stakedSrx > 0) {
            _unstakeSrx(_sender, srx, stakedSrx, false);
            _stakeSrx(_sender, receiver, srx, stakedSrx);
        }

        uint256 stakedEsSrx = IRewardTracker(stakedSrxTracker).depositBalances(
            _sender,
            esSrx
        );
        if (stakedEsSrx > 0) {
            _unstakeSrx(_sender, esSrx, stakedEsSrx, false);
            _stakeSrx(_sender, receiver, esSrx, stakedEsSrx);
        }

        uint256 stakedBnSrx = IRewardTracker(feeSrxTracker).depositBalances(
            _sender,
            bnSrx
        );
        if (stakedBnSrx > 0) {
            IRewardTracker(feeSrxTracker).unstakeForAccount(
                _sender,
                bnSrx,
                stakedBnSrx,
                _sender
            );
            IRewardTracker(feeSrxTracker).stakeForAccount(
                _sender,
                receiver,
                bnSrx,
                stakedBnSrx
            );
        }

        uint256 esSrxBalance = IERC20(esSrx).balanceOf(_sender);
        if (esSrxBalance > 0) {
            IERC20(esSrx).transferFrom(_sender, receiver, esSrxBalance);
        }

        uint256 slpAmount = IRewardTracker(feeSlpTracker).depositBalances(
            _sender,
            slp
        );
        if (slpAmount > 0) {
            IRewardTracker(stakedSlpTracker).unstakeForAccount(
                _sender,
                feeSlpTracker,
                slpAmount,
                _sender
            );
            IRewardTracker(feeSlpTracker).unstakeForAccount(
                _sender,
                slp,
                slpAmount,
                _sender
            );

            IRewardTracker(feeSlpTracker).stakeForAccount(
                _sender,
                receiver,
                slp,
                slpAmount
            );
            IRewardTracker(stakedSlpTracker).stakeForAccount(
                receiver,
                receiver,
                feeSlpTracker,
                slpAmount
            );
        }

        IVester(srxVester).transferStakeValues(_sender, receiver);
        IVester(slpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(
            IRewardTracker(stakedSrxTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: stakedSrxTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedSrxTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedSrxTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(bonusSrxTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: bonusSrxTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(bonusSrxTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: bonusSrxTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeSrxTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeSrxTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeSrxTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeSrxTracker.cumulativeRewards > 0"
        );

        require(
            IVester(srxVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: srxVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(srxVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: srxVester.transferredCumulativeRewards > 0"
        );

        require(
            IRewardTracker(stakedSlpTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: stakedSlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedSlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedSlpTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeSlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeSlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeSlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeSlpTracker.cumulativeRewards > 0"
        );

        require(
            IVester(slpVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: srxVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(slpVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: srxVester.transferredCumulativeRewards > 0"
        );

        require(
            IERC20(srxVester).balanceOf(_receiver) == 0,
            "RewardRouter: srxVester.balance > 0"
        );
        require(
            IERC20(slpVester).balanceOf(_receiver) == 0,
            "RewardRouter: slpVester.balance > 0"
        );
    }

    function _compound(address _account) private {
        _compoundSrx(_account);
        _compoundSlp(_account);
    }

    function _compoundSrx(address _account) private {
        uint256 esSrxAmount = IRewardTracker(stakedSrxTracker).claimForAccount(
            _account,
            _account
        );
        if (esSrxAmount > 0) {
            _stakeSrx(_account, _account, esSrx, esSrxAmount);
        }

        uint256 bnSrxAmount = IRewardTracker(bonusSrxTracker).claimForAccount(
            _account,
            _account
        );
        if (bnSrxAmount > 0) {
            IRewardTracker(feeSrxTracker).stakeForAccount(
                _account,
                _account,
                bnSrx,
                bnSrxAmount
            );
        }
    }

    function _compoundSlp(address _account) private {
        uint256 esSrxAmount = IRewardTracker(stakedSlpTracker).claimForAccount(
            _account,
            _account
        );
        if (esSrxAmount > 0) {
            _stakeSrx(_account, _account, esSrx, esSrxAmount);
        }
    }

    function _stakeSrx(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedSrxTracker).stakeForAccount(
            _fundingAccount,
            _account,
            _token,
            _amount
        );
        IRewardTracker(bonusSrxTracker).stakeForAccount(
            _account,
            _account,
            stakedSrxTracker,
            _amount
        );
        IRewardTracker(feeSrxTracker).stakeForAccount(
            _account,
            _account,
            bonusSrxTracker,
            _amount
        );

        emit StakeSrx(_account, _token, _amount);
    }

    function _unstakeSrx(
        address _account,
        address _token,
        uint256 _amount,
        bool _shouldReduceBnSrx
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedSrxTracker).stakedAmounts(
            _account
        );

        IRewardTracker(feeSrxTracker).unstakeForAccount(
            _account,
            bonusSrxTracker,
            _amount,
            _account
        );
        IRewardTracker(bonusSrxTracker).unstakeForAccount(
            _account,
            stakedSrxTracker,
            _amount,
            _account
        );
        IRewardTracker(stakedSrxTracker).unstakeForAccount(
            _account,
            _token,
            _amount,
            _account
        );

        if (_shouldReduceBnSrx) {
            uint256 bnSrxAmount = IRewardTracker(bonusSrxTracker)
                .claimForAccount(_account, _account);
            if (bnSrxAmount > 0) {
                IRewardTracker(feeSrxTracker).stakeForAccount(
                    _account,
                    _account,
                    bnSrx,
                    bnSrxAmount
                );
            }

            uint256 stakedBnSrx = IRewardTracker(feeSrxTracker).depositBalances(
                _account,
                bnSrx
            );
            if (stakedBnSrx > 0) {
                uint256 reductionAmount = stakedBnSrx.mul(_amount).div(balance);
                IRewardTracker(feeSrxTracker).unstakeForAccount(
                    _account,
                    bnSrx,
                    reductionAmount,
                    _account
                );
                IMintable(bnSrx).burn(_account, reductionAmount);
            }
        }

        emit UnstakeSrx(_account, _token, _amount);
    }
}