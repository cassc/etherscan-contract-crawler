/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable-v4/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v4/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPacocaVault.sol";
import "./interfaces/IPeanutZap.sol";
import "./interfaces/ISweetVault.sol";
import "./helpers/Permit.sol";
import "./access/ControlledUUPS.sol";

contract SweetVault_v4 is ISweetVault, IZapStructs, ControlledUUPS, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        // How many assets the user has provided.
        uint stake;
        // How many staked $PACOCA user had at his last action
        uint autoPacocaShares;
        // Pacoca shares not entitled to the user
        uint rewardDebt;
        // Timestamp of last user deposit
        uint lastDepositedTime;
    }

    struct FarmInfo {
        uint pid;
        address farm;
        address stakedToken;
        address rewardToken;
    }

    // Addresses
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant PACOCA = 0x55671114d774ee99D653D6C12460c780a67f1D18;
    IPacocaVault public AUTO_PACOCA;

    // Runtime data
    mapping(address => UserInfo) public userInfo; // Info of users
    uint public accSharesPerStakedToken; // Accumulated AUTO_PACOCA shares per staked token, times 1e18.

    // Farm info
    FarmInfo public farmInfo;

    // Settings
    IPancakeRouter02 public router;
    address[] public pathToPacoca; // Path from staked token to PACOCA
    address[] public pathToWbnb; // Path from staked token to WBNB

    address payable public zap;

    uint public platformFee;
    uint public constant platformFeeUL = 1000;

    uint public earlyWithdrawFee;
    uint public constant earlyWithdrawFeeUL = 300;
    uint public constant withdrawFeePeriod = 3 days;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event EarlyWithdraw(address indexed user, uint amount, uint fee);
    event Earn(uint amount);
    event ClaimRewards(address indexed user, uint shares, uint amount);

    // Setting updates
    event SetPathToPacoca(address[] oldPath, address[] newPath);
    event SetPathToWbnb(address[] oldPath, address[] newPath);
    event SetPlatformFee(uint oldPlatformFee, uint newPlatformFee);
    event SetEarlyWithdrawFee(uint oldEarlyWithdrawFee, uint newEarlyWithdrawFee);

    function initialize(
        FarmInfo memory _farmInfo,
        address _autoPacoca,
        address _router,
        address[] memory _pathToPacoca,
        address[] memory _pathToWbnb,
        address payable _zap,
        address _authority
    ) public initializer {
        require(
            _pathToPacoca[0] == _farmInfo.rewardToken && _pathToPacoca[_pathToPacoca.length - 1] == PACOCA,
            "SweetVault: Incorrect path to PACOCA"
        );

        require(
            _pathToWbnb[0] == _farmInfo.rewardToken && _pathToWbnb[_pathToWbnb.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        AUTO_PACOCA = IPacocaVault(_autoPacoca);

        farmInfo = _farmInfo;
        router = IPancakeRouter02(_router);
        pathToPacoca = _pathToPacoca;
        pathToWbnb = _pathToWbnb;

        zap = _zap;

        earlyWithdrawFee = 100;
        platformFee = 550;

        __ReentrancyGuard_init();
        __ControlledUUPS_init(_authority);
    }

    // 1. Harvest rewards
    // 2. Collect fees
    // 3. Convert rewards to $PACOCA
    // 4. Stake to pacoca auto-compound vault
    function earn(
        uint _minPlatformOutput,
        uint _minPacocaOutput
    ) external virtual requireRole(ROLE_KEEPER) {
        address rewardToken = farmInfo.rewardToken;

        harvest();

        // Collect platform fees
        _swap(
            _currentBalance(rewardToken) * platformFee / 10000,
            _minPlatformOutput,
            pathToWbnb,
            authority.rewardDistributor()
        );

        // Convert remaining rewards to PACOCA
        _swap(
            _currentBalance(rewardToken),
            _minPacocaOutput,
            pathToPacoca,
            address(this)
        );

        uint previousShares = totalAutoPacocaShares();
        uint pacocaBalance = _currentBalance(PACOCA);

        _approveTokenIfNeeded(
            PACOCA,
            pacocaBalance,
            address(AUTO_PACOCA)
        );

        AUTO_PACOCA.deposit(pacocaBalance);

        uint currentShares = totalAutoPacocaShares();
        uint newShares = currentShares - previousShares;

        accSharesPerStakedToken = accSharesPerStakedToken + (newShares * 1e18 / totalStake());

        emit Earn(pacocaBalance);
    }

    function harvest() internal virtual {
        FarmInfo memory _farmInfo = farmInfo;

        IFarm(_farmInfo.farm).withdraw(_farmInfo.pid, 0);
    }

    function deposit(uint _amount) external nonReentrant {
        require(_amount > 0, "SweetVault: amount must be greater than zero");

        IERC20Upgradeable(farmInfo.stakedToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _deposit(_amount);
    }

    function depositWithPermit(
        uint _amount,
        bytes calldata _signatureData
    ) external nonReentrant {
        require(_amount > 0, "SweetVault: amount must be greater than zero");

        Permit.approve(farmInfo.stakedToken, _amount, _signatureData);

        IERC20Upgradeable(farmInfo.stakedToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _deposit(_amount);
    }

    function zapAndDeposit(
        ZapInfo calldata _zapInfo,
        address _inputToken,
        uint _inputTokenAmount
    ) external payable nonReentrant {
        address stakedToken = farmInfo.stakedToken;
        uint initialStakedTokenBalance = _currentBalance(stakedToken);

        if (_inputToken == address(0)) {
            IPeanutZap(zap).zapNative{value : msg.value}(
                _zapInfo
            );
        } else {
            uint initialInputTokenBalance = _currentBalance(_inputToken);

            IERC20Upgradeable(_inputToken).safeTransferFrom(
                address(msg.sender),
                address(this),
                _inputTokenAmount
            );

            IERC20Upgradeable(_inputToken).approve(zap, _inputTokenAmount);

            IPeanutZap(zap).zapToken(
                _zapInfo,
                _inputToken,
                _currentBalance(_inputToken) - initialInputTokenBalance
            );
        }

        _deposit(_currentBalance(stakedToken) - initialStakedTokenBalance);
    }

    function zapPairWithPermitAndDeposit(
        ZapPairInfo calldata _zapPairInfo,
        bytes calldata _signature
    ) external payable nonReentrant {
        FarmInfo memory _farmInfo = farmInfo;

        require(
            _zapPairInfo.outputToken == _farmInfo.stakedToken,
            "zapPairWithPermitAndDeposit::Wrong output token"
        );

        uint inputPairInitialBalance = _currentBalance(_zapPairInfo.inputToken);
        uint outputPairInitialBalance = _currentBalance(_zapPairInfo.outputToken);

        Permit.approve(
            _zapPairInfo.inputToken,
            _zapPairInfo.inputTokenAmount,
            _signature
        );

        IERC20Upgradeable(_zapPairInfo.inputToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _zapPairInfo.inputTokenAmount
        );

        uint inputPairProfit = _currentBalance(_zapPairInfo.inputToken) - inputPairInitialBalance;

        IERC20Upgradeable(_zapPairInfo.inputToken).safeIncreaseAllowance(zap, inputPairProfit);

        IPeanutZap(zap).zapPair(_zapPairInfo);

        _deposit(_currentBalance(_zapPairInfo.outputToken) - outputPairInitialBalance);
    }

    function _deposit(uint _amount) internal virtual {
        UserInfo storage user = userInfo[msg.sender];
        FarmInfo memory _farmInfo = farmInfo;

        _approveTokenIfNeeded(
            _farmInfo.stakedToken,
            type(uint).max,
            _farmInfo.farm
        );

        _stake(_amount);

        _updateAutoPacocaShares(user);
        user.stake = user.stake + _amount;
        _updateRewardDebt(user);
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    // _stake function is removed from deposit so it can be overridden for different platforms
    function _stake(uint _amount) internal virtual {
        IFarm(farmInfo.farm).deposit(farmInfo.pid, _amount);
    }

    function withdraw(uint _amount) external virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        address stakedToken = farmInfo.stakedToken;

        require(_amount > 0, "SweetVault: amount must be greater than zero");
        require(user.stake >= _amount, "SweetVault: withdraw amount exceeds balance");

        uint currentAmount = _withdrawUnderlying(_amount);

        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            uint currentWithdrawFee = (currentAmount * earlyWithdrawFee) / 10000;

            IERC20Upgradeable(stakedToken).safeTransfer(authority.treasury(), currentWithdrawFee);

            currentAmount = currentAmount - currentWithdrawFee;

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        _updateAutoPacocaShares(user);
        user.stake = user.stake - _amount;
        _updateRewardDebt(user);

        // Withdraw pacoca rewards if user leaves
        if (user.stake == 0 && user.autoPacocaShares > 0) {
            _claimRewards(user.autoPacocaShares, false);
        }

        IERC20Upgradeable(stakedToken).safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    function _withdrawUnderlying(uint _amount) internal virtual returns (uint) {
        FarmInfo memory _farmInfo = farmInfo;

        IFarm(_farmInfo.farm).withdraw(_farmInfo.pid, _amount);

        return _amount;
    }

    function claimRewards(uint _shares) external nonReentrant {
        _claimRewards(_shares, true);
    }

    function _claimRewards(uint _shares, bool _update) internal {
        UserInfo storage user = userInfo[msg.sender];

        if (_update) {
            _updateAutoPacocaShares(user);
            _updateRewardDebt(user);
        }

        require(user.autoPacocaShares >= _shares, "SweetVault: claim amount exceeds balance");

        user.autoPacocaShares = user.autoPacocaShares - _shares;

        uint pacocaBalanceBefore = _currentBalance(PACOCA);

        AUTO_PACOCA.withdraw(_shares);

        uint withdrawAmount = _currentBalance(PACOCA) - pacocaBalanceBefore;

        _safePACOCATransfer(msg.sender, withdrawAmount);

        emit ClaimRewards(msg.sender, _shares, withdrawAmount);
    }

    function getExpectedOutputs() external view returns (
        uint platformOutput,
        uint pacocaOutput
    ) {
        uint wbnbOutput = _getExpectedOutput(pathToWbnb);
        uint pacocaOutputWithoutFees = _getExpectedOutput(pathToPacoca);
        uint pacocaOutputFees = pacocaOutputWithoutFees * platformFee / 10000;

        platformOutput = wbnbOutput * platformFee / 10000;
        pacocaOutput = pacocaOutputWithoutFees - pacocaOutputFees;
    }

    function _getExpectedOutput(
        address[] memory _path
    ) internal virtual view returns (uint) {
        FarmInfo memory _farmInfo = farmInfo;

        // TODO pending as single function
        uint pending = IFarm(_farmInfo.farm).pendingCake(_farmInfo.pid, address(this));

        uint rewards = _currentBalance(_farmInfo.rewardToken) + pending;

        if (rewards == 0) {
            return 0;
        }

        uint[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length - 1];
    }

    function balanceOf(
        address _user
    ) external view returns (
        uint stake,
        uint pacoca,
        uint autoPacocaShares
    ) {
        UserInfo memory user = userInfo[_user];

        uint pendingShares = (user.stake * accSharesPerStakedToken / 1e18) - user.rewardDebt;

        stake = user.stake;
        autoPacocaShares = user.autoPacocaShares + pendingShares;
        pacoca = autoPacocaShares * AUTO_PACOCA.getPricePerFullShare() / 1e18;
    }

    function _approveTokenIfNeeded(
        address _token,
        uint _amount,
        address _spender
    ) internal {
        IERC20Upgradeable tokenERC20 = IERC20Upgradeable(_token);
        uint allowance = tokenERC20.allowance(address(this), _spender);

        if (allowance < _amount) {
            tokenERC20.safeIncreaseAllowance(_spender, type(uint).max - allowance);
        }
    }

    function _currentBalance(address _token) internal view returns (uint) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function totalStake() public view virtual returns (uint) {
        FarmInfo memory _farmInfo = farmInfo;

        return IFarm(_farmInfo.farm).userInfo(_farmInfo.pid, address(this));
    }

    function totalAutoPacocaShares() public view returns (uint) {
        (uint shares, , ,) = AUTO_PACOCA.userInfo(address(this));

        return shares;
    }

    // Safe PACOCA transfer function, just in case if rounding error causes pool to not have enough
    function _safePACOCATransfer(address _to, uint _amount) internal {
        uint balance = _currentBalance(PACOCA);

        if (_amount > balance) {
            IERC20Upgradeable(PACOCA).transfer(_to, balance);
        } else {
            IERC20Upgradeable(PACOCA).transfer(_to, _amount);
        }
    }

    function _swap(
        uint _inputAmount,
        uint _minOutputAmount,
        address[] memory _path,
        address _to
    ) internal virtual {
        _approveTokenIfNeeded(
            farmInfo.rewardToken,
            _inputAmount,
            address(router)
        );

        router.swapExactTokensForTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );
    }

    function _updateAutoPacocaShares(UserInfo storage _user) internal {
        uint totalSharesEarned = (_user.stake * accSharesPerStakedToken) / 1e18;

        _user.autoPacocaShares = _user.autoPacocaShares + totalSharesEarned - _user.rewardDebt;
    }

    function _updateRewardDebt(UserInfo storage _user) internal {
        _user.rewardDebt = (_user.stake * accSharesPerStakedToken) / 1e18;
    }

    function setPathToPacoca(address[] memory _path) external requireRole(ROLE_OWNER) {
        require(
            _path[0] == farmInfo.rewardToken && _path[_path.length - 1] == PACOCA,
            "SweetVault: Incorrect path to PACOCA"
        );

        address[] memory oldPath = pathToPacoca;

        pathToPacoca = _path;

        emit SetPathToPacoca(oldPath, pathToPacoca);
    }

    function setPathToWbnb(address[] memory _path) external requireRole(ROLE_OWNER) {
        require(
            _path[0] == farmInfo.rewardToken && _path[_path.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        address[] memory oldPath = pathToWbnb;

        pathToWbnb = _path;

        emit SetPathToWbnb(oldPath, pathToWbnb);
    }

    function setPlatformFee(uint _platformFee) external requireRole(ROLE_OWNER) {
        require(_platformFee <= platformFeeUL, "SweetVault: Platform fee too high");

        uint oldPlatformFee = platformFee;

        platformFee = _platformFee;

        emit SetPlatformFee(oldPlatformFee, platformFee);
    }

    function setEarlyWithdrawFee(uint _earlyWithdrawFee) external requireRole(ROLE_OWNER) {
        require(
            _earlyWithdrawFee <= earlyWithdrawFeeUL,
            "SweetVault: Early withdraw fee too high"
        );

        uint oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }
}