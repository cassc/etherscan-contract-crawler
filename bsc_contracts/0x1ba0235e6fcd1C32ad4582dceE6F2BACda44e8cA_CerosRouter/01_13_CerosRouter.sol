// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IDex.sol";
import "./interfaces/ICerosRouter.sol";
import "./interfaces/IBinancePool.sol";
import "./interfaces/ICertToken.sol";

contract CerosRouter is
ICerosRouter,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    /**
     * Variables
     */
    IVault private _vault;
    IDex private _dex;
    IBinancePool private _pool; // default (BinancePool)
    // Tokens
    ICertToken private _certToken; // (default aBNBc)
    address private _wBnbAddress;
    IERC20 private _ceToken; // (default ceABNBc)
    mapping(address => uint256) private _profits;
    address private _provider;
    /**
     * Modifiers
     */
    modifier onlyProvider() {
        require(
            msg.sender == owner() || msg.sender == _provider,
            "Provider: not allowed"
        );
        _;
    }
    function initialize(
        address certToken,
        address wBnbToken,
        address ceToken,
        address bondToken,
        address vault,
        address dexAddress,
        address pool
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _certToken = ICertToken(certToken);
        _wBnbAddress = wBnbToken;
        _ceToken = IERC20(ceToken);
        _vault = IVault(vault);
        _dex = IDex(dexAddress);
        _pool = IBinancePool(pool);
        IERC20(wBnbToken).approve(dexAddress, type(uint256).max);
        IERC20(certToken).approve(dexAddress, type(uint256).max);
        IERC20(certToken).approve(bondToken, type(uint256).max);
        IERC20(certToken).approve(pool, type(uint256).max);
        IERC20(certToken).approve(vault, type(uint256).max);
    }
    /**
     * DEPOSIT
     */
    function deposit()
    external
    payable
    override
    nonReentrant
    returns (uint256 value)
    {
        uint256 amount = msg.value;
        // get returned amount from Dex
        address[] memory path = new address[](2);
        path[0] = _wBnbAddress;
        path[1] = address(_certToken);
        // uint256[] memory outAmounts = _dex.getAmountsOut(amount, path);
        uint256 dexABNBcAmount = 0; // outAmounts[outAmounts.length - 1];
        // let's calculate returned amount of aBNBc from BinancePool
        uint256 minimumStake = _pool.getMinimumStake();
        uint256 relayerFee = _pool.getRelayerFee();
        uint256 ratio = _certToken.ratio();
        uint256 poolABNBcAmount;
        if (amount >= minimumStake + relayerFee) {
            poolABNBcAmount = ((amount - relayerFee) * ratio) / 1e18;
        }
        // compare poolABNBcAmount with dexABNBcAmount from Dex
        // if poolABNBcAmount >= dexABNBcAmount -> stake via BinancePool
        // else -> swap on Dex
        uint256 realAmount;
        uint256 profit;
        if (poolABNBcAmount >= dexABNBcAmount) {
            realAmount = poolABNBcAmount;
            _pool.stakeAndClaimCerts{value: amount}();
        } else {
            uint256[] memory amounts = _dex.swapExactETHForTokens{
            value: amount
            }(dexABNBcAmount, path, address(this), block.timestamp + 300);
            realAmount = amounts[1];
            if (realAmount > poolABNBcAmount && poolABNBcAmount != 0) {
                profit = realAmount - poolABNBcAmount;
            }
        }
        // let's check balance of CeRouter in aBNBc
        require(
            _certToken.balanceOf(address(this)) >= realAmount,
            "insufficient amount of CerosRouter in cert token"
        );
        // add profit
        _profits[msg.sender] += profit;
        value = _vault.depositFor(msg.sender, realAmount - profit);
        emit Deposit(msg.sender, _wBnbAddress, realAmount - profit, profit);
        return value;
    }
    function depositABNBcFrom(address owner, uint256 amount)
    external
    override
    onlyProvider
    nonReentrant
    returns (uint256 value)
    {
        _certToken.transferFrom(owner, address(this), amount);
        value = _vault.depositFor(msg.sender, amount);
        emit Deposit(msg.sender, address(_certToken), amount, 0);
        return value;
    }
    function depositABNBc(uint256 amount)
    external
    override
    nonReentrant
    returns (uint256 value)
    {
        revert("CeRouter/Disabled");
        // _certToken.transferFrom(msg.sender, address(this), amount);
        // value = _vault.depositFor(msg.sender, amount);
        // emit Deposit(msg.sender, address(_certToken), amount, 0);
        // return value;
    }
    /**
     * CLAIM
     */
    // claim yields in aBNBc
    function claim(address recipient)
    external
    override
    nonReentrant
    returns (uint256 yields)
    {
        yields = _vault.claimYieldsFor(msg.sender, recipient);
        emit Claim(recipient, address(_certToken), yields);
        return yields;
    }
    // claim profit in aBNBc
    function claimProfit(address recipient) external nonReentrant {
        uint256 profit = _profits[msg.sender];
        require(profit > 0, "has not got a profit");
        // let's check balance of CeRouter in aBNBc
        require(
            _certToken.balanceOf(address(this)) >= profit,
            "insufficient amount"
        );
        _certToken.transfer(recipient, profit);
        _profits[msg.sender] -= profit;
        emit Claim(recipient, address(_certToken), profit);
    }
    /**
     * WITHDRAWAL
     */
    // withdrawal in BNB via staking pool
    /// @param recipient address to receive withdrawan BNB
    /// @param amount in BNB to withdraw from vault
    function withdraw(address recipient, uint256 amount)
    external
    override
    nonReentrant
    returns (uint256 realAmount)
    {
        require(
            amount >= _pool.getMinimumStake(),
            "value must be greater than min unstake amount"
        );
        realAmount = _vault.withdrawFor(msg.sender, address(this), amount);
        _pool.unstakeCertsFor(recipient, realAmount);
        emit Withdrawal(msg.sender, recipient, _wBnbAddress, amount);
        return realAmount;
    }
    // withdrawal aBNBc
    /// @param recipient address to receive withdrawan aBNBc
    /// @param amount in BNB
    function withdrawABNBc(address recipient, uint256 amount)
    external
    override
    nonReentrant
    returns (uint256 realAmount)
    {
        realAmount = _vault.withdrawFor(msg.sender, recipient, amount);
        emit Withdrawal(msg.sender, recipient, address(_certToken), realAmount);
        return realAmount;
    }
    function withdrawFor(address recipient, uint256 amount)
    external
    override
    nonReentrant
    onlyProvider
    returns (uint256 realAmount)
    {
        realAmount = _vault.withdrawFor(msg.sender, address(this), amount);
        _pool.unstakeCertsFor(recipient, realAmount); // realAmount -> BNB
        emit Withdrawal(msg.sender, recipient, _wBnbAddress, realAmount);
        return realAmount;
    }
    // withdrawal in BNB via DEX
    function withdrawWithSlippage(
        address recipient,
        uint256 amount,
        uint256 outAmount
    ) external override nonReentrant returns (uint256 realAmount) {
        realAmount = _vault.withdrawFor(msg.sender, address(this), amount);
        address[] memory path = new address[](2);
        path[0] = address(_certToken);
        path[1] = _wBnbAddress;
        uint256[] memory amounts = _dex.swapExactTokensForETH(
            realAmount,
            outAmount,
            path,
            recipient,
            block.timestamp + 300
        );
        emit Withdrawal(msg.sender, recipient, _wBnbAddress, amounts[1]);
        return amounts[1];
    }
    function getProfitFor(address account) external view returns (uint256) {
        return _profits[account];
    }
    function getPendingWithdrawalOf(address account)
    external
    view
    returns (uint256)
    {
        return _pool.pendingUnstakesOf(account);
    }
    function changeVault(address vault) external onlyOwner {
        // update allowances
        _certToken.approve(address(_vault), 0);
        _vault = IVault(vault);
        _certToken.approve(address(_vault), type(uint256).max);
        emit ChangeVault(vault);
    }
    function changeDex(address dex) external onlyOwner {
        IERC20(_wBnbAddress).approve(address(_dex), 0);
        _certToken.approve(address(_dex), 0);
        _dex = IDex(dex);
        // update allowances
        IERC20(_wBnbAddress).approve(address(_dex), type(uint256).max);
        _certToken.approve(address(_dex), type(uint256).max);
        emit ChangeDex(dex);
    }
    function changePool(address pool) public onlyOwner {
        // update allowances
        _certToken.approve(address(_pool), 0);
        _pool = IBinancePool(pool);
        _certToken.approve(address(_pool), type(uint256).max);
        emit ChangePool(pool);
    }
    function changeProvider(address provider) external onlyOwner {
        _provider = provider;
        emit ChangeProvider(provider);
    }
    function getProvider() external view returns(address) {
        return _provider;
    }
    function getCeToken() external view returns(address) {
        return address(_ceToken);
    }
    function getWbnbAddress() external view returns(address) {
        return _wBnbAddress;
    }
    function getCertToken() external view returns(address) {
        return address(_certToken);
    }
    function getPoolAddress() external view returns(address) {
        return address(_pool);
    }
    function getDexAddress() external view returns(address) {
        return address(_dex);
    }
    function getVaultAddress() external view returns(address) {
        return address(_vault);
    }

    function rollbackCerosRouter(address helioProvider, uint256 profits, address ankrBNB, address abnbb, address pool) external onlyOwner {
        // Rollback profits for HelioProvider
        _profits[helioProvider] = profits;

        // Change abnbc
        _certToken = ICertToken(ankrBNB);
        changePool(pool);
        IERC20(ankrBNB).approve(address(_dex), type(uint256).max);
        IERC20(ankrBNB).approve(abnbb, type(uint256).max);
        IERC20(ankrBNB).approve(address(_pool), type(uint256).max);
        IERC20(ankrBNB).approve(address(_vault), type(uint256).max);   
    }
}