// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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

    function initialize(
        address _lendingMarket,
        address _lendFlareCRV,
        address _zap
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        require(_lendFlareCRV != address(0), "LendFlareVault: zero acrv address");
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
    function _deposit(uint256 _pid, uint256 _token0) internal returns (uint256) {
        require(_token0 > 0, "LendFlareVault: zero amount deposit");
        require(_pid < poolInfo.length, "LendFlareVault: invalid pool");

        // 1. update rewards
        PoolInfo storage _pool = poolInfo[_pid];
        UserInfo storage _userInfo = userInfo[_pid][msg.sender];

        require(!_pool.pauseDeposit, "LendFlareVault: pool paused");

        _updateRewards(_pid, msg.sender);

        // 2. transfer user token
        address _lpToken = _pool.lpToken;
        {
            uint256 _before = IERC20Upgradeable(_lpToken).balanceOf(address(this));
            IERC20Upgradeable(_lpToken).safeTransferFrom(msg.sender, address(this), _token0);
            _token0 = IERC20Upgradeable(_lpToken).balanceOf(address(this)).sub(_before);
        }

        // 3. deposit
        _approve(_lpToken, lendingMarket, _token0);
        ILendingMarket(lendingMarket).deposit(_pool.lendingMarketPid, _token0);

        _pool.totalUnderlying = _pool.totalUnderlying.add(_token0);
        _userInfo.totalUnderlying = _userInfo.totalUnderlying.add(_token0);

        emit Deposit(_pid, msg.sender, _token0);

        return _token0;
    }

    function deposit(uint256 _pid, uint256 _token0) public nonReentrant returns (uint256) {
        return _deposit(_pid, _token0);
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
        require(msg.value == 0.1 ether, "!depositAndBorrow");

        _deposit(_pid, _token0);

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

        emit BorrowForDeposit(_pid, msg.sender, _token0, _borrowBlock, _supportPid);

        if (!_loop) {
            if (underlyToken != ZERO_ADDRESS) {
                sendToken(underlyToken, msg.sender, IERC20Upgradeable(underlyToken).balanceOf(address(this)));
            } else {
                sendToken(address(0), msg.sender, address(this).balance);
            }
        } else {
            // uint256 _supplyPid = ILendingMarket(lendingMarket)
            //     .getPoolSupportPid(_pool.lendingMarketPid, _supportPid);
            uint256[] memory _supplyPids = ILendingMarket(lendingMarket).getPoolSupportPids(_pool.lendingMarketPid);

            ISupplyBooster.PoolInfo memory _supplyPool = ISupplyBooster(_supplyBooster()).poolInfo(_supplyPids[_supportPid]);

            uint256 _tokens = _addLiquidity(_supplyPool.underlyToken, _pool.lpToken, _supplyPool.isErc20);

            _approve(_pool.lpToken, lendingMarket, _tokens);

            _deposit(_pid, IERC20Upgradeable(_pool.lpToken).balanceOf(address(this)));

            emit AddLiquidity(_pid, _supplyPool.underlyToken, _pool.lpToken, _tokens);
        }
    }

    function borrowForDeposit(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid,
        bool _loop
    ) public payable nonReentrant {
        require(msg.value == 0.1 ether, "!borrowForDeposit");

        _borrowForDeposit(_pid, _token0, _borrowBlock, _supportPid, _loop);
    }

    function _addLiquidity(
        address _from,
        address _to,
        bool _isErc20
    ) internal returns (uint256) {
        if (_isErc20) {
            uint256 bal = IERC20Upgradeable(_from).balanceOf(address(this));

            sendToken(_from, zap, bal);
            return IZap(zap).zap(_from, bal, _to, 0);
        } else {
            uint256 bal = address(this).balance;

            sendToken(address(0), zap, bal);
            return IZap(zap).zap(_from, bal, _to, 0);
        }
    }

    function repayBorrow(bytes32 _lendingId) public payable nonReentrant {
        Lending storage _lending = lendings[_lendingId];

        require(_lending.underlyToken != address(0), "!_lendingId");

        PoolInfo storage _pool = poolInfo[_lending.pid];
        UserInfo storage _userInfo = userInfo[_lending.pid][_lending.user];

        uint256 _before = IERC20Upgradeable(_pool.lpToken).balanceOf(address(this));

        ILendingMarket(lendingMarket).repayBorrow{ value: msg.value }(_lendingId);

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(_lending.token0);

        // pay back 0.1 ether
        sendToken(address(0), _lending.user, 0.1 ether);

        uint256 _amount = IERC20Upgradeable(_pool.lpToken).balanceOf(address(this)).sub(_before);

        sendToken(_pool.lpToken, _lending.user, _amount);

        emit RepayBorrow(msg.sender, _lendingId);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) public nonReentrant {
        Lending storage _lending = lendings[_lendingId];

        require(_lending.underlyToken != address(0), "!_lendingId");

        PoolInfo storage _pool = poolInfo[_lending.pid];
        UserInfo storage _userInfo = userInfo[_lending.pid][_lending.user];

        IERC20Upgradeable(_lending.underlyToken).safeTransferFrom(msg.sender, address(this), _amount);

        _approve(_lending.underlyToken, lendingMarket, _amount);

        uint256 _before = IERC20Upgradeable(_pool.lpToken).balanceOf(address(this));

        ILendingMarket(lendingMarket).repayBorrowERC20(_lendingId, _amount);

        _userInfo.lendingLocked = _userInfo.lendingLocked.sub(_lending.token0);

        // pay back 0.1 ether
        sendToken(address(0), _lending.user, 0.1 ether);

        _amount = IERC20Upgradeable(_pool.lpToken).balanceOf(address(this)).sub(_before);

        sendToken(_pool.lpToken, _lending.user, _amount);

        emit RepayBorrow(msg.sender, _lendingId);
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

        require(_amount <= _userInfo.totalUnderlying.sub(_userInfo.lendingLocked), "!_amount");

        _pool.totalUnderlying = _pool.totalUnderlying.sub(_amount);
        _userInfo.totalUnderlying = _userInfo.totalUnderlying.sub(_amount);

        ILendingMarket(lendingMarket).withdraw(_pool.lendingMarketPid, _amount);

        sendToken(_pool.lpToken, msg.sender, _amount);

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

    function harvest(uint256 _pid, uint256 _minimumOut) public nonReentrant {
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
                    sendToken(rewardToken, zap, rewardTokenBal);

                    _amount = _amount.add(IZap(zap).zap(rewardToken, rewardTokenBal, WETH, 0));
                }
            }
        }

        uint256 cvxBal = IERC20Upgradeable(CVX).balanceOf(address(this));

        if (cvxBal > 0) {
            _amount = _amount.add(IZap(zap).zap(CVX, cvxBal, WETH, 0));
        }

        if (_amount > 0) {
            IZap(zap).zap{ value: _amount }(WETH, _amount, CRV, 0);
        }

        _amount = IERC20Upgradeable(CRV).balanceOf(address(this));

        uint256 _rewards;

        if (_amount > 0) {
            sendToken(CRV, zap, _amount);
            _amount = IZap(zap).zap(CRV, _amount, CVXCRV, _minimumOut);

            _approve(CVXCRV, lendFlareCRV, _amount);

            _rewards = ILendFlareCRV(lendFlareCRV).deposit(address(this), _amount);

            _pool.accRewardPerShare = _pool.accRewardPerShare.add(_rewards.mul(PRECISION).div(_pool.totalUnderlying));
        }

        emit Harvest(_rewards, _pool.accRewardPerShare, _pool.totalUnderlying);
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

            sendToken(lendFlareCRV, msg.sender, _amount);

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

    function sendToken(
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

    receive() external payable {}
}