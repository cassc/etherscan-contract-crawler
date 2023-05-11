// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IKlpManager.sol";
import "../access/Governable.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public ktx;
    address public esKtx;
    address public bnKtx;

    address public klp; // KTX Liquidity Provider token

    address public stakedKtxTracker;
    address public bonusKtxTracker;
    address public feeKtxTracker;

    address public stakedKlpTracker;
    address public feeKlpTracker;

    address public klpManager;

    address public ktxVester;
    address public klpVester;

    mapping (address => address) public pendingReceivers;

    event StakeKtx(address account, address token, uint256 amount);
    event UnstakeKtx(address account, address token, uint256 amount);

    event StakeKlp(address account, uint256 amount);
    event UnstakeKlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _ktx,
        address _esKtx,
        address _bnKtx,
        address _klp,
        address _stakedKtxTracker,
        address _bonusKtxTracker,
        address _feeKtxTracker,
        address _feeKlpTracker,
        address _stakedKlpTracker,
        address _klpManager,
        address _ktxVester,
        address _klpVester
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        ktx = _ktx;
        esKtx = _esKtx;
        bnKtx = _bnKtx;

        klp = _klp;

        stakedKtxTracker = _stakedKtxTracker;
        bonusKtxTracker = _bonusKtxTracker;
        feeKtxTracker = _feeKtxTracker;

        feeKlpTracker = _feeKlpTracker;
        stakedKlpTracker = _stakedKlpTracker;

        klpManager = _klpManager;

        ktxVester = _ktxVester;
        klpVester = _klpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeKtxForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _ktx = ktx;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeKtx(msg.sender, _accounts[i], _ktx, _amounts[i]);
        }
    }

    function stakeKtxForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeKtx(msg.sender, _account, ktx, _amount);
    }

    function stakeKtx(uint256 _amount) external nonReentrant {
        _stakeKtx(msg.sender, msg.sender, ktx, _amount);
    }

    function stakeEsKtx(uint256 _amount) external nonReentrant {
        _stakeKtx(msg.sender, msg.sender, esKtx, _amount);
    }

    function unstakeKtx(uint256 _amount) external nonReentrant {
        _unstakeKtx(msg.sender, ktx, _amount, true);
    }

    function unstakeEsKtx(uint256 _amount) external nonReentrant {
        _unstakeKtx(msg.sender, esKtx, _amount, true);
    }

    function mintAndStakeKlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minKlp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 klpAmount = IKlpManager(klpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsdg, _minKlp);
        IRewardTracker(feeKlpTracker).stakeForAccount(account, account, klp, klpAmount);
        IRewardTracker(stakedKlpTracker).stakeForAccount(account, account, feeKlpTracker, klpAmount);

        emit StakeKlp(account, klpAmount);

        return klpAmount;
    }

    function mintAndStakeKlpETH(uint256 _minUsdg, uint256 _minKlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(klpManager, msg.value);

        address account = msg.sender;
        uint256 klpAmount = IKlpManager(klpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minUsdg, _minKlp);

        IRewardTracker(feeKlpTracker).stakeForAccount(account, account, klp, klpAmount);
        IRewardTracker(stakedKlpTracker).stakeForAccount(account, account, feeKlpTracker, klpAmount);

        emit StakeKlp(account, klpAmount);

        return klpAmount;
    }

    function unstakeAndRedeemKlp(address _tokenOut, uint256 _klpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_klpAmount > 0, "RewardRouter: invalid _klpAmount");

        address account = msg.sender;
        IRewardTracker(stakedKlpTracker).unstakeForAccount(account, feeKlpTracker, _klpAmount, account);
        IRewardTracker(feeKlpTracker).unstakeForAccount(account, klp, _klpAmount, account);
        uint256 amountOut = IKlpManager(klpManager).removeLiquidityForAccount(account, _tokenOut, _klpAmount, _minOut, _receiver);

        emit UnstakeKlp(account, _klpAmount);

        return amountOut;
    }

    function unstakeAndRedeemKlpETH(uint256 _klpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_klpAmount > 0, "RewardRouter: invalid _klpAmount");

        address account = msg.sender;
        IRewardTracker(stakedKlpTracker).unstakeForAccount(account, feeKlpTracker, _klpAmount, account);
        IRewardTracker(feeKlpTracker).unstakeForAccount(account, klp, _klpAmount, account);
        uint256 amountOut = IKlpManager(klpManager).removeLiquidityForAccount(account, weth, _klpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeKlp(account, _klpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeKtxTracker).claimForAccount(account, account);
        IRewardTracker(feeKlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedKtxTracker).claimForAccount(account, account);
        IRewardTracker(stakedKlpTracker).claimForAccount(account, account);
    }

    function claimEsKtx() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedKtxTracker).claimForAccount(account, account);
        IRewardTracker(stakedKlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeKtxTracker).claimForAccount(account, account);
        IRewardTracker(feeKlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimKtx,
        bool _shouldStakeKtx,
        bool _shouldClaimEsKtx,
        bool _shouldStakeEsKtx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 ktxAmount = 0;
        if (_shouldClaimKtx) {
            uint256 ktxAmount0 = IVester(ktxVester).claimForAccount(account, account);
            uint256 ktxAmount1 = IVester(klpVester).claimForAccount(account, account);
            ktxAmount = ktxAmount0.add(ktxAmount1);
        }

        if (_shouldStakeKtx && ktxAmount > 0) {
            _stakeKtx(account, account, ktx, ktxAmount);
        }

        uint256 esKtxAmount = 0;
        if (_shouldClaimEsKtx) {
            uint256 esKtxAmount0 = IRewardTracker(stakedKtxTracker).claimForAccount(account, account);
            uint256 esKtxAmount1 = IRewardTracker(stakedKlpTracker).claimForAccount(account, account);
            esKtxAmount = esKtxAmount0.add(esKtxAmount1);
        }

        if (_shouldStakeEsKtx && esKtxAmount > 0) {
            _stakeKtx(account, account, esKtx, esKtxAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnKtxAmount = IRewardTracker(bonusKtxTracker).claimForAccount(account, account);
            if (bnKtxAmount > 0) {
                IRewardTracker(feeKtxTracker).stakeForAccount(account, account, bnKtx, bnKtxAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feeKtxTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker(feeKlpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeKtxTracker).claimForAccount(account, account);
                IRewardTracker(feeKlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(ktxVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(klpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(ktxVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(klpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedKtx = IRewardTracker(stakedKtxTracker).depositBalances(_sender, ktx);
        if (stakedKtx > 0) {
            _unstakeKtx(_sender, ktx, stakedKtx, false);
            _stakeKtx(_sender, receiver, ktx, stakedKtx);
        }

        uint256 stakedEsKtx = IRewardTracker(stakedKtxTracker).depositBalances(_sender, esKtx);
        if (stakedEsKtx > 0) {
            _unstakeKtx(_sender, esKtx, stakedEsKtx, false);
            _stakeKtx(_sender, receiver, esKtx, stakedEsKtx);
        }

        uint256 stakedBnKtx = IRewardTracker(feeKtxTracker).depositBalances(_sender, bnKtx);
        if (stakedBnKtx > 0) {
            IRewardTracker(feeKtxTracker).unstakeForAccount(_sender, bnKtx, stakedBnKtx, _sender);
            IRewardTracker(feeKtxTracker).stakeForAccount(_sender, receiver, bnKtx, stakedBnKtx);
        }

        uint256 esKtxBalance = IERC20(esKtx).balanceOf(_sender);
        if (esKtxBalance > 0) {
            IERC20(esKtx).transferFrom(_sender, receiver, esKtxBalance);
        }

        uint256 klpAmount = IRewardTracker(feeKlpTracker).depositBalances(_sender, klp);
        if (klpAmount > 0) {
            IRewardTracker(stakedKlpTracker).unstakeForAccount(_sender, feeKlpTracker, klpAmount, _sender);
            IRewardTracker(feeKlpTracker).unstakeForAccount(_sender, klp, klpAmount, _sender);

            IRewardTracker(feeKlpTracker).stakeForAccount(_sender, receiver, klp, klpAmount);
            IRewardTracker(stakedKlpTracker).stakeForAccount(receiver, receiver, feeKlpTracker, klpAmount);
        }

        IVester(ktxVester).transferStakeValues(_sender, receiver);
        IVester(klpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedKtxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedKtxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedKtxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedKtxTracker.cumulativeRewards > 0");

        require(IRewardTracker(bonusKtxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: bonusKtxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(bonusKtxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: bonusKtxTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeKtxTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeKtxTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeKtxTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeKtxTracker.cumulativeRewards > 0");

        require(IVester(ktxVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: ktxVester.transferredAverageStakedAmounts > 0");
        require(IVester(ktxVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: ktxVester.transferredCumulativeRewards > 0");

        require(IRewardTracker(stakedKlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedKlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedKlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedKlpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeKlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeKlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeKlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeKlpTracker.cumulativeRewards > 0");

        require(IVester(klpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: ktxVester.transferredAverageStakedAmounts > 0");
        require(IVester(klpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: ktxVester.transferredCumulativeRewards > 0");

        require(IERC20(ktxVester).balanceOf(_receiver) == 0, "RewardRouter: ktxVester.balance > 0");
        require(IERC20(klpVester).balanceOf(_receiver) == 0, "RewardRouter: klpVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundKtx(_account);
        _compoundKlp(_account);
    }

    function _compoundKtx(address _account) private {
        uint256 esKtxAmount = IRewardTracker(stakedKtxTracker).claimForAccount(_account, _account);
        if (esKtxAmount > 0) {
            _stakeKtx(_account, _account, esKtx, esKtxAmount);
        }

        uint256 bnKtxAmount = IRewardTracker(bonusKtxTracker).claimForAccount(_account, _account);
        if (bnKtxAmount > 0) {
            IRewardTracker(feeKtxTracker).stakeForAccount(_account, _account, bnKtx, bnKtxAmount);
        }
    }

    function _compoundKlp(address _account) private {
        uint256 esKtxAmount = IRewardTracker(stakedKlpTracker).claimForAccount(_account, _account);
        if (esKtxAmount > 0) {
            _stakeKtx(_account, _account, esKtx, esKtxAmount);
        }
    }

    function _stakeKtx(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedKtxTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusKtxTracker).stakeForAccount(_account, _account, stakedKtxTracker, _amount);
        IRewardTracker(feeKtxTracker).stakeForAccount(_account, _account, bonusKtxTracker, _amount);

        emit StakeKtx(_account, _token, _amount);
    }

    function _unstakeKtx(address _account, address _token, uint256 _amount, bool _shouldReduceBnKtx) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedKtxTracker).stakedAmounts(_account);

        IRewardTracker(feeKtxTracker).unstakeForAccount(_account, bonusKtxTracker, _amount, _account);
        IRewardTracker(bonusKtxTracker).unstakeForAccount(_account, stakedKtxTracker, _amount, _account);
        IRewardTracker(stakedKtxTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnKtx) {
            uint256 bnKtxAmount = IRewardTracker(bonusKtxTracker).claimForAccount(_account, _account);
            if (bnKtxAmount > 0) {
                IRewardTracker(feeKtxTracker).stakeForAccount(_account, _account, bnKtx, bnKtxAmount);
            }

            uint256 stakedBnKtx = IRewardTracker(feeKtxTracker).depositBalances(_account, bnKtx);
            if (stakedBnKtx > 0) {
                uint256 reductionAmount = stakedBnKtx.mul(_amount).div(balance);
                IRewardTracker(feeKtxTracker).unstakeForAccount(_account, bnKtx, reductionAmount, _account);
                IMintable(bnKtx).burn(_account, reductionAmount);
            }
        }

        emit UnstakeKtx(_account, _token, _amount);
    }
}