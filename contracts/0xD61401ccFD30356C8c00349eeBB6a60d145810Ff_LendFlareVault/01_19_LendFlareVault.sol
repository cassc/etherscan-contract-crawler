// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/ILendingMarket.sol";
import "../interfaces/ISupplyBooster.sol";
import "../interfaces/IConvexRewardPool.sol";
import "../interfaces/ILendFlareVault.sol";
import "../interfaces/ILendFlareCRV.sol";
import "../interfaces/IConvexBooster.sol";
import "../interfaces/IConvexBasicRewards.sol";
import "../interfaces/IConvexCRVDepositor.sol";
import "../interfaces/ICurveFactoryPool.sol";
import "../interfaces/IZap.sol";

// solhint-disable no-empty-blocks, reason-string
contract LendFlareVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, ILendFlareVault {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    struct PoolInfo {
        uint256 lendingMarketPid;
        uint256 totalUnderlying;
        uint256 accRewardPerShare;
        uint256 convexPoolId;
        address lpToken;
        bool pauseDeposit;
        bool pauseWithdraw;
    }

    struct UserInfo {
        uint256 totalUnderlying;
        uint256 rewardPerSharePaid;
        uint256 rewards;
        uint256 lendingIndex;
        uint256 lendingLocked;
    }

    struct Lending {
        uint256 pid;
        uint256 lendingIndex;
        address user;
        uint256 lendingMarketPid;
        uint256 token0;
        address underlyToken;
    }

    uint256 private constant PRECISION = 1e18;
    address private constant ZERO_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address private constant CURVE_CVXCRV_CRV_POOL = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;
    address private constant CRV_DEPOSITOR = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae;

    PoolInfo[] public poolInfo;
    // pid => (user => UserInfo)
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(address => mapping(uint256 => bytes32))) public userLendings; // pid => (user => (lendingIndex => Lending Id))
    mapping(bytes32 => Lending) public lendings;

    address public lendingMarket;
    address public lendFlareCRV;
    address public zap;

    mapping(bytes32 => uint256) public originLendingId;

    function initialize(
        address _lendingMarket,
        address _lendFlareCRV,
        address _zap
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        require(_lendingMarket != address(0), "LendFlareVault: zero lendingMarket address");
        require(_lendFlareCRV != address(0), "LendFlareVault: zero lendFlareCRV address");
        require(_zap != address(0), "LendFlareVault: zero zap address");

        lendingMarket = _lendingMarket;
        lendFlareCRV = _lendFlareCRV;
        zap = _zap;
    }

    /********************************** View Functions **********************************/

    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function pendingReward(uint256 _pid, address _account) public view returns (uint256) {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][_account];

        return uint256(_userInfo.rewards).add(_pool.accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.totalUnderlying).div(PRECISION));
    }

    function pendingRewardAll(address _account) external view returns (uint256) {
        uint256 _pending;

        for (uint256 i = 0; i < poolInfo.length; i++) {
            _pending = _pending.add(pendingReward(i, _account));
        }

        return _pending;
    }

    /********************************** Mutated Functions **********************************/
    function _deposit(
        uint256 _pid,
        uint256 _token0,
        address _sender,
        bool _staked
    ) internal returns (uint256) {
        require(_token0 > 0, "LendFlareVault: zero token0 deposit");
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        // 1. update rewards
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][msg.sender];

        require(!_pool.pauseDeposit, "LendFlareVault: pool paused");

        _updateRewards(_pid, msg.sender);

        // 2. transfer user token
        address _lpToken = _pool.lpToken;
        {
            if (_sender != address(0)) {
                uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
                IERC20Upgradeable(_lpToken).safeTransferFrom(msg.sender, address(this), _token0);
                _token0 = IERC20Upgradeable(_lpToken).balanceOf(address(this)).sub(_before);
            }
        }

        // 3. deposit
        _approve(_lpToken, lendingMarket, _token0);
        ILendingMarket(lendingMarket).deposit(_pool.lendingMarketPid, _token0);

        if (!_staked) {
            _pool.totalUnderlying = _pool.totalUnderlying.add(_token0);
            _userInfo.totalUnderlying = _userInfo.totalUnderlying.add(_token0);
        }

        emit Deposit(_pid, msg.sender, _token0);

        return _token0;
    }

    function deposit(uint256 _pid, uint256 _token0) public nonReentrant returns (uint256) {
        return _deposit(_pid, _token0, msg.sender, false);
    }

    function depositAll(uint256 _pid) external returns (uint256) {
        PoolInfo storage _pool = poolInfo[_pid];

        uint256 _balance = IERC20Upgradeable(_pool.lpToken).balanceOf(msg.sender);

        return deposit(_pid, _balance);
    }

    function depositAndBorrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid,
        bool _loop
    ) public payable nonReentrant {
        require(msg.value == 0.1 ether, "LendFlareVault: !depositAndBorrow");

        _deposit(_pid, _token0, msg.sender, false);

        _borrowForDeposit(_pid, _token0, _borrowBlock, _supportPid, _loop);
    }

    function _borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid,
        bool _loop
    ) internal {
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][msg.sender];

        bytes32 lendingId = ILendingMarket(lendingMarket).borrowForDeposit{ value: msg.value }(_pool.lendingMarketPid, _token0, _borrowBlock, _supportPid);

        _userInfo.lendingIndex++;

        userLendings[_pid][msg.sender][_userInfo.lendingIndex] = lendingId;

        _userInfo.lendingLocked = _userInfo.lendingLocked.add(_token0);

        address underlyToken = ISupplyBooster(_supplyBooster()).getLendingUnderlyToken(lendingId);

        lendings[lendingId] = Lending({
            pid: _pid,
            user: msg.sender,
            lendingIndex: _userInfo.lendingIndex,
            lendingMarketPid: _pool.lendingMarketPid,
            token0: _token0,
            underlyToken: underlyToken
        });

        originLendingId[lendingId] = ILendingMarket(lendingMarket).getUserLendingsLength(address(this));

        emit BorrowForDeposit(_pid, lendingId, msg.sender, _token0, _borrowBlock, _supportPid);

        if (!_loop) {
            if (underlyToken != ZERO_ADDRESS) {
                _sendToken(underlyToken, msg.sender, IERC20Upgradeable(underlyToken).balanceOf(address(this)));
            } else {
                _sendToken(address(0), msg.sender, address(this).balance);
            }
        } else {
            // uint256 _supplyPid = ILendingMarket(lendingMarket)
            //     .getPoolSupportPid(_pool.lendingMarketPid, _supportPid);
            // uint256[] memory _supplyPids = ILendingMarket(lendingMarket).getPoolSupportPids(_pool.lendingMarketPid);
            // ISupplyBooster.PoolInfo memory _supplyPool = ISupplyBooster(_supplyBooster()).poolInfo(_supplyPids[_supportPid]);
            // uint256 _tokens = _addLiquidity(underlyToken, _pool.lpToken, _supplyPool.isErc20);
            uint256 _tokens = _addLiquidity(underlyToken, _pool.lpToken, underlyToken != ZERO_ADDRESS ? true : false);

            _deposit(_pid, _tokens, address(0), false);

            emit AddLiquidity(_pid, underlyToken, _pool.lpToken, _tokens);
        }
    }

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid,
        bool _loop
    ) public payable nonReentrant {
        require(msg.value == 0.1 ether, "LendFlareVault: !borrowForDeposit");

        _borrowForDeposit(_pid, _token0, _borrowBlock, _supportPid, _loop);
    }

    function _addLiquidity(
        address _from,
        address _to,
        bool _isErc20
    ) internal returns (uint256) {
        if (_isErc20) {
            uint256 bal = IERC20Upgradeable(_from).balanceOf(address(this));

            _sendToken(_from, zap, bal);

            return IZap(zap).zap(_from, bal, _to, 0);
        } else {
            uint256 bal = address(this).balance;

            return IZap(zap).zap{ value: bal }(WETH, bal, _to, 0);
        }
    }

    function repayBorrow(bytes32 _lendingId) public payable nonReentrant {
        Lending storage _lending = lendings[_lendingId];

        require(_lending.underlyToken != address(0), "LendFlareVault: !_lendingId");

        UserInfo storage _userInfo = userInfo[_lending.pid][_lending.user];

        uint256 amount = msg.value;
        uint256 repayAmount = ILendingMarket(lendingMarket).calculateRepayAmount(_lendingId);

        require(repayAmount > 0, "!repayAmount");

        if (amount > repayAmount) {
            _sendToken(address(0), msg.sender, amount.sub(repayAmount));

            amount = repayAmount;
        }

        uint256 _afterUnderlyingTokens;

        {
            uint256 _before = _remainingBalance(_lending.underlyToken).sub(amount);
            ILendingMarket(lendingMarket).repayBorrow{ value: amount }(_lendingId);
            // pay back 0.1 ether
            _sendToken(address(0), _lending.user, 0.1 ether);

            _afterUnderlyingTokens = _remainingBalance(_lending.underlyToken).sub(_before);
        }

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(_lending.token0);

        // triggered depeg shield
        if (_afterUnderlyingTokens > 0) {
            PoolInfo storage _pool = poolInfo[_lending.pid];

            _pool.totalUnderlying = _pool.totalUnderlying.sub(_lending.token0);
            _userInfo.totalUnderlying = _userInfo.totalUnderlying.sub(_lending.token0);

            _sendToken(address(0), _lending.user, _afterUnderlyingTokens);

            emit RepayBorrow(msg.sender, _lendingId);
            return;
        }

        _deposit(_lending.pid, _lending.token0, address(0), true);

        emit RepayBorrow(msg.sender, _lendingId);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) public nonReentrant {
        Lending storage _lending = lendings[_lendingId];

        require(_lending.underlyToken != address(0), "LendFlareVault: !_lendingId");

        UserInfo storage _userInfo = userInfo[_lending.pid][_lending.user];

        uint256 repayAmount = ILendingMarket(lendingMarket).calculateRepayAmount(_lendingId);

        require(repayAmount > 0, "!repayAmount");

        if (_amount > repayAmount) {
            _amount = repayAmount;
        }

        IERC20Upgradeable(_lending.underlyToken).safeTransferFrom(msg.sender, address(this), _amount);

        _approve(_lending.underlyToken, lendingMarket, _amount);

        uint256 _afterUnderlyingTokens;

        {
            uint256 _before = _remainingBalance(_lending.underlyToken).sub(_amount);
            ILendingMarket(lendingMarket).repayBorrowERC20(_lendingId, _amount);
            // pay back 0.1 ether
            _sendToken(address(0), _lending.user, 0.1 ether);

            _afterUnderlyingTokens = _remainingBalance(_lending.underlyToken).sub(_before);
        }

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(_lending.token0);

        // triggered depeg shield
        if (_afterUnderlyingTokens > 0) {
            PoolInfo storage _pool = poolInfo[_lending.pid];

            _pool.totalUnderlying = _pool.totalUnderlying.sub(_lending.token0);
            _userInfo.totalUnderlying = _userInfo.totalUnderlying.sub(_lending.token0);

            _sendToken(_lending.underlyToken, _lending.user, _afterUnderlyingTokens);

            emit RepayBorrow(msg.sender, _lendingId);
            return;
        }

        _deposit(_lending.pid, _lending.token0, address(0), true);

        emit RepayBorrow(msg.sender, _lendingId);
    }

    function liquidate(bytes32 _lendingId, uint256 _extraErc20Amount) external payable nonReentrant {
        Lending storage _lending = lendings[_lendingId];
        UserInfo storage _userInfo = userInfo[_lending.pid][_lending.user];
        PoolInfo storage _pool = poolInfo[_lending.pid];

        require(_lending.underlyToken != address(0), "LendFlareVault: !_lendingId");

        _updateRewards(_lending.pid, _lending.user);

        if (_extraErc20Amount > 0) {
            _approve(_lending.underlyToken, lendingMarket, _extraErc20Amount);

            IERC20Upgradeable(_lending.underlyToken).safeTransferFrom(msg.sender, address(this), _extraErc20Amount);
        }

        ILendingMarket(lendingMarket).liquidate{ value: msg.value }(_lendingId, _extraErc20Amount);

        // pay back 0.1 ether
        _sendToken(address(0), msg.sender, 0.1 ether);

        _pool.totalUnderlying = _pool.totalUnderlying.sub(_lending.token0);
        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(_lending.token0);
        _userInfo.totalUnderlying = _userInfo.totalUnderlying.sub(_lending.token0);

        emit Liquidate(_lendingId, _extraErc20Amount);
    }

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        uint256 _minOut,
        ClaimOption _option
    ) public nonReentrant returns (uint256, uint256) {
        require(_amount > 0, "LendFlareVault: zero amount withdraw");
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        // 1. update rewards
        PoolInfo storage _pool = poolInfo[_pid];
        require(!_pool.pauseWithdraw, "LendFlareVault: pool paused");
        _updateRewards(_pid, msg.sender);

        // 2. withdraw lp token
        UserInfo storage _userInfo = userInfo[_pid][msg.sender];

        require(_amount <= _userInfo.totalUnderlying, "LendFlareVault: _amount not enough");
        require(_amount <= _userInfo.totalUnderlying.sub(_userInfo.lendingLocked), "LendFlareVault: !_amount");

        _pool.totalUnderlying = _pool.totalUnderlying.sub(_amount);
        _userInfo.totalUnderlying = _userInfo.totalUnderlying.sub(_amount);

        ILendingMarket(lendingMarket).withdraw(_pool.lendingMarketPid, _amount);

        _sendToken(_pool.lpToken, msg.sender, _amount);

        emit Withdraw(_pid, msg.sender, _amount);

        if (_option == ClaimOption.None) {
            return (_amount, 0);
        } else {
            uint256 _rewards = _userInfo.rewards;

            _userInfo.rewards = 0;

            _rewards = _claim(_rewards, _minOut, _option);

            return (_amount, _rewards);
        }
    }

    function claim(
        uint256 _pid,
        uint256 _minOut,
        ClaimOption _option
    ) public nonReentrant returns (uint256 claimed) {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        PoolInfo storage _pool = poolInfo[_pid];
        require(!_pool.pauseWithdraw, "LendFlareVault: pool paused");
        _updateRewards(_pid, msg.sender);

        UserInfo storage _userInfo = userInfo[_pid][msg.sender];
        uint256 _rewards = _userInfo.rewards;

        _userInfo.rewards = 0;

        emit Claim(msg.sender, _rewards, _option);
        _rewards = _claim(_rewards, _minOut, _option);

        return _rewards;
    }

    function _harvest(uint256 _pid, uint256 _minimumOut) internal {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        PoolInfo storage _pool = poolInfo[_pid];

        IConvexBooster(_convexBooster()).getRewards(_pool.convexPoolId);

        // swap all rewards token to CRV
        address rewardCrvPool = IConvexBooster(_convexBooster()).poolInfo(_pool.convexPoolId).rewardCrvPool;

        uint256 _amount = address(this).balance;

        for (uint256 i = 0; i < IConvexRewardPool(rewardCrvPool).extraRewardsLength(); i++) {
            address extraRewardPool = IConvexRewardPool(rewardCrvPool).extraRewards(i);

            address rewardToken = IConvexRewardPool(extraRewardPool).rewardToken();

            if (rewardToken != CRV) {
                uint256 rewardTokenBal = IERC20Upgradeable(rewardToken).balanceOf(address(this));

                if (rewardTokenBal > 0) {
                    _sendToken(rewardToken, zap, rewardTokenBal);

                    _amount = _amount.add(IZap(zap).zap(rewardToken, rewardTokenBal, address(0), 0));
                }
            }
        }

        uint256 cvxBal = IERC20Upgradeable(CVX).balanceOf(address(this));

        if (cvxBal > 0) {
            _sendToken(CVX, zap, cvxBal);

            _amount = _amount.add(IZap(zap).zap(CVX, cvxBal, address(0), 0));
        }

        if (_amount > 0) {
            IZap(zap).zap{ value: _amount }(WETH, _amount, CRV, 0);
        }

        _amount = IERC20Upgradeable(CRV).balanceOf(address(this));

        uint256 _rewards;

        if (_amount > 0) {
            _sendToken(CRV, zap, _amount);

            _amount = IZap(zap).zap(CRV, _amount, CVXCRV, _minimumOut);

            _approve(CVXCRV, lendFlareCRV, _amount);

            _rewards = ILendFlareCRV(lendFlareCRV).deposit(address(this), _amount);

            _pool.accRewardPerShare = _pool.accRewardPerShare.add(_rewards.mul(PRECISION).div(_pool.totalUnderlying));
        }

        emit Harvest(_rewards, _pool.accRewardPerShare, _pool.totalUnderlying);
    }

    function harvest(uint256 _pid, uint256 _minimumOut) public nonReentrant {
        _harvest(_pid, _minimumOut);
    }

    function harvests(uint256[] calldata _pids) public nonReentrant {
        for (uint256 i = 0; i < _pids.length; i++) _harvest(_pids[i], 0);
    }

    /********************************** Restricted Functions **********************************/
    function updateSwap(address _zap) external onlyOwner {
        require(_zap != address(0), "LendFlareVault: zero zap address");
        zap = _zap;

        emit UpdateZap(_zap);
    }

    function _convexBooster() internal view returns (address) {
        return ILendingMarket(lendingMarket).convexBooster();
    }

    function _supplyBooster() internal view returns (address) {
        return ILendingMarket(lendingMarket).supplyBooster();
    }

    function _remainingBalance(address _underlyingToken) internal view returns (uint256) {
        if (_underlyingToken == ZERO_ADDRESS || _underlyingToken == address(0)) {
            return address(this).balance;
        } else {
            return IERC20Upgradeable(_underlyingToken).balanceOf(address(this));
        }
    }

    function addPool(uint256 _lendingMarketPid) public onlyOwner {
        ILendingMarket.PoolInfo memory _lendingMarketPool = ILendingMarket(lendingMarket).poolInfo(_lendingMarketPid);

        for (uint256 i = 0; i < poolInfo.length; i++) {
            require(poolInfo[i].convexPoolId != _lendingMarketPool.convexPid, "LendFlareVault: duplicate pool");
        }

        IConvexBooster.PoolInfo memory _convexBoosterPool = IConvexBooster(_convexBooster()).poolInfo(_lendingMarketPool.convexPid);

        poolInfo.push(
            PoolInfo({
                lendingMarketPid: _lendingMarketPid,
                totalUnderlying: 0,
                accRewardPerShare: 0,
                convexPoolId: _lendingMarketPool.convexPid,
                lpToken: _convexBoosterPool.lpToken,
                pauseDeposit: false,
                pauseWithdraw: false
            })
        );

        emit AddPool(poolInfo.length - 1, _lendingMarketPid, _lendingMarketPool.convexPid, _convexBoosterPool.lpToken);
    }

    function addPools(uint256[] calldata _lendingMarketPids) external {
        for (uint256 i = 0; i < _lendingMarketPids.length; i++) {
            addPool(_lendingMarketPids[i]);
        }
    }

    function pausePoolWithdraw(uint256 _pid, bool _status) external onlyOwner {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        poolInfo[_pid].pauseWithdraw = _status;

        emit PausePoolWithdraw(_pid, _status);
    }

    function pausePoolDeposit(uint256 _pid, bool _status) external onlyOwner {
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        poolInfo[_pid].pauseDeposit = _status;

        emit PausePoolDeposit(_pid, _status);
    }

    /********************************** Internal Functions **********************************/

    function _updateRewards(uint256 _pid, address _account) internal {
        uint256 _rewards = pendingReward(_pid, _account);
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][_account];

        _userInfo.rewards = _rewards;
        _userInfo.rewardPerSharePaid = _pool.accRewardPerShare;
    }

    function _claim(
        uint256 _amount,
        uint256 _minOut,
        ClaimOption _option
    ) internal returns (uint256) {
        if (_amount == 0) return _amount;

        ILendFlareCRV.WithdrawOption _withdrawOption;

        if (_option == ClaimOption.Claim) {
            require(_amount >= _minOut, "LendFlareVault: insufficient output");

            _sendToken(lendFlareCRV, msg.sender, _amount);

            return _amount;
        } else if (_option == ClaimOption.ClaimAsCvxCRV) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.Withdraw;
        } else if (_option == ClaimOption.ClaimAsCRV) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsCRV;
        } else if (_option == ClaimOption.ClaimAsCVX) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsCVX;
        } else if (_option == ClaimOption.ClaimAsETH) {
            _withdrawOption = ILendFlareCRV.WithdrawOption.WithdrawAsETH;
        } else {
            revert("LendFlareVault: invalid claim option");
        }

        return ILendFlareCRV(lendFlareCRV).withdraw(msg.sender, _amount, _minOut, _withdrawOption);
    }

    function _approve(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        IERC20Upgradeable(_token).safeApprove(_spender, 0);
        IERC20Upgradeable(_token).safeApprove(_spender, _amount);
    }

    function _sendToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}