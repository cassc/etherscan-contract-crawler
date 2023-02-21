// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IController.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IRouter.sol";
import "../utils/TransferHelper.sol";

contract EFVault is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using SafeMath for uint256;

    ERC20Upgradeable public asset;

    string public constant version = "3.0";

    address public depositApprover;

    address public controller;

    address public weth;

    // Exchange Address
    address public exchange;

    uint256 public maxDeposit;

    uint256 public maxWithdraw;

    uint256 public assetDecimal;

    bool public paused;

    address[] public swapRouters;

    bytes32[] public swapIndexes;

    enum WithdrawMode {
        WITHOUT_CLAIM,
        WITH_REWARD,
        WITH_ASSET
    }

    struct UserInfo {
        uint256 rewardDebt;
        uint256 pendingReward;
    }

    uint256 public depositThres;

    mapping(address => mapping(address => UserInfo)) public userInfo;

    mapping(address => uint256) public userLastDeposit;

    event Deposit(address indexed asset, address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed asset,
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 fee
    );

    event Claim(address[] indexed rewards, address indexed caller, address indexed owner, uint256[] amounts);

    event SetMaxDeposit(uint256 maxDeposit);

    event SetExchange(address exchange);

    event SetMaxWithdraw(uint256 maxWithdraw);

    event SetController(address controller);

    event SetDepositApprover(address depositApprover);

    modifier unPaused() {
        require(!paused, "PAUSED");
        _;
    }

    function initialize(
        ERC20Upgradeable _asset,
        string memory _name,
        string memory _symbol,
        address _weth,
        uint256 _assetDecimal
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        asset = _asset;
        weth = _weth;
        assetDecimal = _assetDecimal;
        maxDeposit = type(uint256).max;
        maxWithdraw = type(uint256).max;
        depositThres = 172800; // 2 days
    }

    receive() external payable {}

    function deposit(uint256 assets, address receiver)
        public
        payable
        virtual
        nonReentrant
        unPaused
        returns (uint256 shares)
    {
        require(assets != 0, "ZERO_ASSETS");
        require(assets <= maxDeposit, "EXCEED_ONE_TIME_MAX_DEPOSIT");

        require(address(this).balance >= assets, "INSUFFICIENT_TRANSFER");

        // Need to transfer before minting or ERC777s could reenter.
        TransferHelper.safeTransferETH(address(controller), assets);

        // Total Assets amount until now
        uint256 totalDeposit = IController(controller).totalAssets(false);
        // Calls Deposit function on controller
        uint256 newDeposit = IController(controller).deposit(assets);

        require(newDeposit > 0, "INVALID_DEPOSIT_SHARES");

        // Calculate share amount to be mint
        shares = totalSupply() == 0 || totalDeposit == 0 ? assets : (totalSupply() * newDeposit) / totalDeposit;

        uint256 prevBal = balanceOf(receiver);

        // Mint ENF token to receiver
        _mint(receiver, shares);

        // Update user's data
        _updateUserData(receiver, prevBal);
        userLastDeposit[receiver] = block.timestamp;

        emit Deposit(address(asset), msg.sender, receiver, assets, shares);
    }

    function getBalance(address token, address account) internal view returns (uint256) {
        // Asset is zero address when it is ether
        if (address(token) == address(0) || address(token) == address(weth)) return address(account).balance;
        else return IERC20Upgradeable(token).balanceOf(account);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        WithdrawMode mode
    ) public virtual nonReentrant unPaused returns (uint256 shares) {
        require(assets != 0, "ZERO_ASSETS");
        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Calculate share amount to be burnt
        shares = (totalSupply() * assets) / IController(controller).totalAssets(false);

        require(balanceOf(msg.sender) >= shares, "EXCEED_TOTAL_DEPOSIT");

        // Withdraw asset
        _withdraw(assets, shares, receiver, mode);
    }

    function redeem(
        uint256 shares,
        address receiver,
        WithdrawMode mode
    ) public virtual nonReentrant unPaused returns (uint256 assets) {
        require(shares > 0, "ZERO_SHARES");
        require(shares <= balanceOf(msg.sender), "EXCEED_TOTAL_BALANCE");

        assets = (shares * assetsPerShare()) / 1e36;

        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Withdraw asset
        _withdraw(assets, shares, receiver, mode);
    }

    function _withdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        WithdrawMode mode
    ) internal {
        // Calls Withdraw function on controller
        (uint256 withdrawn, uint256 fee) = IController(controller).withdraw(assets, receiver);
        require(withdrawn > 0, "INVALID_WITHDRAWN_SHARES");

        // Get Previous balance before burn
        uint256 prevBal = balanceOf(msg.sender);

        // Burn shares amount
        _burn(msg.sender, shares);

        // According to withdraw mode, do claim
        if (mode == WithdrawMode.WITH_ASSET) _claim(true, receiver, prevBal);
        else if (mode == WithdrawMode.WITH_REWARD)
            _claim(false, receiver, prevBal);
            // If no claim occurred, update user's data
        else {
            _updateUserData(msg.sender, prevBal);
        }
        emit Withdraw(address(asset), msg.sender, receiver, assets, shares, fee);
    }

    function _updateUserData(address account, uint256 prevAmount) internal {
        (
            address[] memory rewardTokens,
            uint256[] memory accOldRewardPerTokens,
            uint256[] memory accRewardPerTokens
        ) = IController(controller).getRewardInfo();
        uint256 lastHarvest = IController(controller).lastHarvest();

        for (uint8 i = 0; i < rewardTokens.length; i++) {
            UserInfo storage user = userInfo[rewardTokens[i]][account];
            // Calculate user's current pending
            uint256 accRewardPerShare;
            if (userLastDeposit[account] + depositThres < lastHarvest || userLastDeposit[account] > lastHarvest) {
                accRewardPerShare = accRewardPerTokens[i];
            } else {
                accRewardPerShare = accOldRewardPerTokens[i];
            }
            uint256 rewardTotal = (accRewardPerShare * prevAmount) / (1e18) + user.pendingReward;

            uint256 pending = rewardTotal > user.rewardDebt ? rewardTotal - user.rewardDebt : 0;
            user.pendingReward = pending;
            user.rewardDebt = (accRewardPerTokens[i] * balanceOf(account)) / (1e18);
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        // Get Previous balances for from and to accounts
        uint256 fromPrevBal = balanceOf(owner);
        uint256 toPrevBal = balanceOf(to);

        _transfer(owner, to, amount);

        // Update states for both accounts
        _updateUserData(owner, fromPrevBal);
        _updateUserData(to, toPrevBal);

        // Update receiver's deposit time as to sender's
        if (userLastDeposit[to] <= userLastDeposit[owner]) userLastDeposit[to] = userLastDeposit[owner];
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        // Get Previous balances for from and to accounts
        uint256 fromPrevBal = balanceOf(from);
        uint256 toPrevBal = balanceOf(to);

        _transfer(from, to, amount);

        // Update states for both accounts
        _updateUserData(from, fromPrevBal);
        _updateUserData(to, toPrevBal);

        // Update receiver's deposit time as to sender's
        if (userLastDeposit[to] <= userLastDeposit[from]) userLastDeposit[to] = userLastDeposit[from];

        return true;
    }

    function pendingReward(address account, uint256 assetNum) public view returns (uint256 pending) {
        (
            address[] memory rewardTokens,
            uint256[] memory accOldRewardPerTokens,
            uint256[] memory accRewardPerTokens
        ) = IController(controller).getRewardInfo();
        address rewardToken = rewardTokens[assetNum];
        uint256 lastHarvest = IController(controller).lastHarvest();

        UserInfo memory user = userInfo[rewardToken][account];

        uint256 accRewardPerShare;
        if (userLastDeposit[account] + depositThres < lastHarvest || userLastDeposit[account] >= lastHarvest) {
            accRewardPerShare = accRewardPerTokens[assetNum];
        } else {
            accRewardPerShare = accOldRewardPerTokens[assetNum];
        }

        uint256 rewardTotal = (accRewardPerShare * balanceOf(account)) / (1e18) + user.pendingReward;

        pending = rewardTotal > user.rewardDebt ? rewardTotal - user.rewardDebt : 0;
    }

    function claim(bool toAsset, address receiver) public {
        _claim(toAsset, receiver, balanceOf(msg.sender));
    }

    function _claim(
        bool toAsset,
        address receiver,
        uint256 prevBal
    ) internal {
        (
            address[] memory rewardTokens,
            uint256[] memory accOldRewardPerTokens,
            uint256[] memory accRewardPerTokens
        ) = IController(controller).getRewardInfo();
        uint256 lastHarvest = IController(controller).lastHarvest();

        uint256[] memory pendings = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            UserInfo storage user = userInfo[rewardTokens[i]][msg.sender];
            // Calculate user's current pending

            uint256 accRewardPerShare;
            if (userLastDeposit[msg.sender] + depositThres < lastHarvest || userLastDeposit[msg.sender] > lastHarvest) {
                accRewardPerShare = accRewardPerTokens[i];
            } else {
                accRewardPerShare = accOldRewardPerTokens[i];
            }

            uint256 rewardTotal = (accRewardPerShare * prevBal) / (1e18) + user.pendingReward;

            uint256 pending = rewardTotal > user.rewardDebt ? rewardTotal - user.rewardDebt : 0;
            pendings[i] = pending;

            // Update user's reward related info
            user.rewardDebt = (accRewardPerTokens[i] * balanceOf(msg.sender)) / (1e18);
            user.pendingReward = 0;
        }

        if (!toAsset) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                TransferHelper.safeTransfer(rewardTokens[i], receiver, pendings[i]);
            }
        } else {
            // Swap Reward token to principal asset
            _swap(rewardTokens, pendings);
            uint256 assetOut = getBalance(address(asset), address(this));
            TransferHelper.safeTransfer(address(asset), receiver, assetOut);
        }

        emit Claim(rewardTokens, receiver, msg.sender, pendings);
    }

    function _swap(address[] memory rewardTokens, uint256[] memory pendings) internal {
        require(exchange != address(0), "EXCHANGE_NOT_SET");

        // Swap fromToken to toToken for deposit
        for (uint256 i = 0; i < swapIndexes.length; i++) {
            // If index of path is not registered, revert it
            require(swapIndexes[i] != 0, "NON_REGISTERED_PATH");

            // Get fromToken Address
            address fromToken = IRouter(swapRouters[i]).pathFrom(swapIndexes[i]);
            // Get toToken Address
            address toToken = IRouter(swapRouters[i]).pathTo(swapIndexes[i]);

            uint256 tokenIndex = _getTokenIndex(fromToken, rewardTokens);

            uint256 amount = tokenIndex < rewardTokens.length
                ? pendings[tokenIndex]
                : getBalance(address(fromToken), address(this));
            if (amount == 0) continue;

            if (fromToken == weth) {
                IExchange(exchange).swapExactETHInput{value: amount}(toToken, swapRouters[i], swapIndexes[i], amount);
            } else {
                // Approve fromToken to Exchange
                IERC20Upgradeable(fromToken).approve(exchange, 0);
                IERC20Upgradeable(fromToken).approve(exchange, amount);

                // Call Swap on exchange
                IExchange(exchange).swapExactTokenInput(fromToken, toToken, swapRouters[i], swapIndexes[i], amount);
            }
        }
    }

    function assetsPerShare() internal view returns (uint256) {
        return (IController(controller).totalAssets(false) * assetDecimal * 1e18) / totalSupply();
    }

    function _getTokenIndex(address _token, address[] memory rewardTokens) internal pure returns (uint256) {
        for (uint8 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == _token) return i;
        }
        return rewardTokens.length;
    }

    function totalAssets() public view virtual returns (uint256) {
        return IController(controller).totalAssets(true);
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    ///////////////////////////////////////////////////////////////
    //                 SET CONFIGURE LOGIC                       //
    ///////////////////////////////////////////////////////////////

    function setMaxDeposit(uint256 _maxDeposit) public onlyOwner {
        require(_maxDeposit > 0, "INVALID_MAX_DEPOSIT");
        maxDeposit = _maxDeposit;

        emit SetMaxDeposit(maxDeposit);
    }

    function setMaxWithdraw(uint256 _maxWithdraw) public onlyOwner {
        require(_maxWithdraw > 0, "INVALID_MAX_WITHDRAW");
        maxWithdraw = _maxWithdraw;

        emit SetMaxWithdraw(maxWithdraw);
    }

    function setController(address _controller) public onlyOwner {
        require(_controller != address(0), "INVALID_ZERO_ADDRESS");
        controller = _controller;

        emit SetController(controller);
    }

    function setDepositApprover(address _approver) public onlyOwner {
        require(_approver != address(0), "INVALID_ZERO_ADDRESS");
        depositApprover = _approver;

        emit SetDepositApprover(depositApprover);
    }

    /**
        Set exchange address
     */
    function setExchange(address _exchange) public onlyOwner {
        require(_exchange != address(0), "ZERO_ADDRESS");
        exchange = _exchange;

        emit SetExchange(exchange);
    }

    /**
        Set path
     */
    function setSwapPath(address[] memory _swapRouters, bytes32[] memory _swapIndexes) public onlyOwner {
        require(_swapRouters.length == _swapIndexes.length, "MISMATCHING_LENGTH");

        swapRouters = _swapRouters;
        swapIndexes = _swapIndexes;
    }

    function setDepositThres(uint256 _depositThres) public onlyOwner {
        require(_depositThres > 0, "INVALID_DEPOSIT_THRESHOLD");

        depositThres = _depositThres;
    }

    ////////////////////////////////////////////////////////////////////
    //                      PAUSE/RESUME                              //
    ////////////////////////////////////////////////////////////////////

    function pause() public onlyOwner {
        require(!paused, "CURRENTLY_PAUSED");
        paused = true;
    }

    function resume() public onlyOwner {
        require(paused, "CURRENTLY_RUNNING");
        paused = false;
    }
}