//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./solmate/ERC20.sol";
import "./solmate/ERC4626.sol";
import "./solmate/FixedPointMathLib.sol";
import "./solmate/ReentrancyGuard.sol";
import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./utils/Pausable.sol";
import "./utils/UniswapV2Library.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IPancakeFarm.sol";
import "./interfaces/IMasterChefV2.sol";
import "./interfaces/ICompoundProtocol.sol";

contract GalaxySingleAssetLPYieldVault is ERC4626, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;

    event FeesPaid(uint256 cakeRepaid, uint256 strategistPaidCake, uint256 keeperPaidNative);
    event Harvest(uint amount);

    address public want;
    address public farmBooster;
    address public farmBoosterProxy;
    address public masterchef;
    address public strategist;
    uint256 public pid;
    uint256 public cakeLockDuration = 1 weeks;
    
    uint256 public cakeRepayBasis = 25;
    uint256 public strategistBasis = 200;
    uint256 public keeperBasis = 100;
    uint256 public constant DIVISOR = 1000;

    address constant public wrappedNative = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address constant public unitroller = address(0x29152a70BABc383e41fa20c52DB0643F4CD007e9);
    address constant public cToken = address(0x7ff9c8DC5522c4fDA763c6dbBff88935d07DDf96);
    address constant public cake = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address constant public cakePool = address(0x45c54210128a065de780C4B0Df3d16664f7f859e);
    address constant public farmBoostFactory = address(0x2C36221bF724c60E9FEE3dd44e2da8017a8EF3BA);

    address[] public markets;
    address[] public wantToCakePath;
    address[] public cakeToWantPath;
    address[] public cakeToNativePath;
    
    uint256 public totalBorrowedAmount;
    
    address public token0;
    address public token1;

    bool public harvestEnabled = false;

    /// @param name_       ERC4626 name
    /// @param symbol_     ERC4626 symbol
    /// @param asset_      ERC4626 asset (LP Token)
    /// @param want_       ERC20 token supplied
    /// @param strategist_ Address receiving performace fees
    /// @param pid_        Masterchef Pool ID
    constructor(
        string memory name_,
        string memory symbol_,
        address asset_,
        address want_,
        address strategist_,
        uint256 pid_
    ) ERC4626(ERC20(asset_), name_, symbol_) {
        want = want_;
        pid = pid_;
        strategist = strategist_;
        address[] memory market = new address[](1);
        market[0] = cToken;
        markets = market;
        address[] memory path = new address[](2);
        path[0] = want;
        path[1] = cake;
        wantToCakePath = path;
        path[0] = cake;
        path[1] = want;
        cakeToWantPath = path;
        path[0] = cake;
        path[1] = wrappedNative;
        cakeToNativePath = path;
        ICompoundUnitroller(unitroller).enterMarkets(markets);
        IFarmBoosterProxyFactory(farmBoostFactory).createFarmBoosterProxy();
        farmBoosterProxy = IFarmBoosterProxyFactory(farmBoostFactory).proxyContract(address(this));
        farmBooster = IFarmBoosterProxyFactory(farmBoostFactory).Farm_Booster();
        masterchef = IFarmBoosterProxyFactory(farmBoostFactory).masterchefV2();
        IFarmBooster(farmBooster).activate(pid);
        token0 = IUniswapV2Pair(address(asset)).token0();
        token1 = IUniswapV2Pair(address(asset)).token1();
        _giveAllowances();
    }

    function beforeWithdraw(uint256 assets_, uint256)
        internal
        override
    {
        uint256 cakeBalBefore = IERC20(cake).balanceOf(address(this));
        IFarmBoosterProxy(farmBoosterProxy).withdraw(pid, assets_);
        uint256 lpBal = asset.balanceOf(address(this));
        IUniswapV2Router02(router).removeLiquidity(
            token0,
            token1,
            lpBal,
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 cakeBalAfter = IERC20(cake).balanceOf(address(this));
        uint256 cakeBalDelta = cakeBalAfter - cakeBalBefore;
        _repayBorrow(cakeBalDelta);
    }

    function afterDeposit(uint256 assets_, uint256) internal override {
        (uint256 token0Amount, uint256 token1Amount) = getAssetsAmounts(assets_);
        IUniswapV2Router02(router).addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 lpBal = asset.balanceOf(address(this));
        IFarmBoosterProxy(farmBoosterProxy).deposit(pid, lpBal);
    }

    /// @notice Deposit pre-calculated amount of token0/1 to get amount of UniLP (assets/getUniLpFromAssets_)
    /// @notice REQUIREMENT: Calculate amount of assets and have enough of assets0/1 to cover this amount for LP requested (slippage!)
    /// @param getUniLpFromAssets_ Acquired from getLPAmountOut()
    /// @param receiver_ - Who will receive shares (Standard ERC4626)
    /// @return shares - Of this Vault (Standard ERC4626)
    function deposit(uint256 getUniLpFromAssets_, address receiver_)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        require(
            (shares = previewDeposit(getUniLpFromAssets_)) != 0,
            "ZERO_SHARES"
        );
        (uint256 token0Amount, uint256 token1Amount) = getAssetsAmounts(getUniLpFromAssets_);
        ICompoundToken(cToken).borrow(token0Amount);
        IERC20(want).safeTransferFrom(msg.sender, address(this), token1Amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
        _mint(receiver_, shares);
        
        /// Custom assumption about assets changes assumptions about this event
        emit Deposit(msg.sender, receiver_, getUniLpFromAssets_, shares);
        afterDeposit(getUniLpFromAssets_, shares);
    }

    /// @notice Mint amount of shares of this Vault (1:1 with UniLP). Requires precalculating amount of assets to approve to this contract.
    /// @param sharesOfThisVault_ shares value == amount of Vault token (shares) to mint from requested lpToken. (1:1 with lpToken).
    /// @param receiver_ == receiver of shares (Vault token)
    /// @return assets == amount of LPTOKEN minted (1:1 with sharesOfThisVault_ input)
    function mint(uint256 sharesOfThisVault_, address receiver_)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        assets = previewMint(sharesOfThisVault_);
        (uint256 token0Amount, uint256 token1Amount) = getAssetsAmounts(assets);
        ICompoundToken(cToken).borrow(token0Amount);
        IERC20(want).safeTransferFrom(msg.sender, address(this), token1Amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
        _mint(receiver_, sharesOfThisVault_);

        /// Custom assumption about assets changes assumptions about this event
        emit Deposit(msg.sender, receiver_, assets, sharesOfThisVault_);
        afterDeposit(assets, sharesOfThisVault_);
    }

    /// @notice Withdraw amount of token0/1 by burning Vault shares (1:1 with UniLP).
    /// @param assets_ - amount of UniLP to burn (calculate amount of expected token0/1 from helper functions)
    /// @param receiver_ - Who will receive shares (Standard ERC4626)
    /// @param owner_ - Who owns shares (Standard ERC4626)
    function withdraw(
        uint256 assets_, // amount of underlying asset (pool Lp) to withdraw
        address receiver_,
        address owner_
    ) public override nonReentrant whenNotPaused returns (uint256 shares) {
        shares = previewWithdraw(assets_);
        (uint256 token0Amount, uint256 token1Amount) = getAssetsAmounts(assets_);
        if (msg.sender != owner_) {
            uint256 allowed = allowance[owner_][msg.sender];
            if (allowed != type(uint256).max) {
                allowance[owner_][msg.sender] = allowed - shares;
            }
        }
        beforeWithdraw(assets_, shares);
        _burn(owner_, shares);
        _repayBorrow(token0Amount);
        IERC20(want).safeTransfer(receiver_, token1Amount);
        /// Custom assumption about assets changes assumptions about this event
        emit Withdraw(msg.sender, receiver_, owner_, assets_, shares);
    }

    /// @notice Redeem amount of Vault shares (1:1 with UniLP) for arbitrary amount of token0/1. Calculate amount of expected token0/1 from helper functions.
    /// @param shares_ - amount of UniLP to burn
    /// @param receiver_ - Who will receive shares (Standard ERC4626)
    /// @param owner_ - Who owns shares (Standard ERC4626)
    function redeem(
        uint256 shares_,
        address receiver_,
        address owner_
    ) public override nonReentrant whenNotPaused returns (uint256 assets) {
        if (msg.sender != owner_) {
            uint256 allowed = allowance[owner_][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) {
                allowance[owner_][msg.sender] = allowed - shares_;
            }
        }
        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares_)) != 0, "ZERO_ASSETS");
        (uint256 token0Amount, uint256 token1Amount) = getAssetsAmounts(assets);
        beforeWithdraw(assets, shares_);
        _burn(owner_, shares_);
        _repayBorrow(token0Amount);
        IERC20(want).safeTransfer(receiver_, token1Amount);
        emit Withdraw(msg.sender, receiver_, owner_, assets, shares_);
    }

    function harvest() external nonReentrant whenNotPaused {
        if (harvestEnabled) {
            uint256 rewardAmount = IERC20(cake).balanceOf(address(this));
            if (rewardAmount > 0 ) {
                _payFees(rewardAmount); 
                _swapAddLiquidityAndStake();
                emit Harvest(rewardAmount);
            }
        }
    }

    function repayBorrow(uint256 amount) public onlyOwner {
        if (amount > totalBorrowedAmount) {
            amount = totalBorrowedAmount;
        }
        ICompoundToken(cToken).repayBorrow(amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
    }
    
    function borrow(uint256 amount) external onlyOwner {
        ICompoundToken(cToken).borrow(amount);
        totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
    }

    function setCakeLockDuration(uint256 time) external onlyOwner {
        cakeLockDuration = time;
    }

    function setCakeRepayBasis(uint256 basis) external onlyOwner {
        cakeRepayBasis = basis;
    }

    function lockCake(uint256 amount) external onlyOwner {
        ICakePool(cakePool).deposit(amount, cakeLockDuration);
    }

    function retriveCake(uint256 amount) external onlyOwner {
        ICakePool(cakePool).withdraw(amount);
    }

    function retriveLP(uint256 amount) external onlyOwner {
        IFarmBoosterProxy(farmBoosterProxy).withdraw(pid, amount);
    }

    function removeLP(uint256 amount) external onlyOwner {
        IUniswapV2Router01(router).removeLiquidity(want, cake, amount, 0, 0, address(this), block.timestamp);
    }

    function migrateToken(address token, address newContract) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(newContract, balance);
    }

    function panic() public onlyOwner {
        pause();
        harvestEnabled = false;
        IFarmBoosterProxy(farmBoosterProxy).emergencyWithdraw(pid);
        uint256 lpBal = asset.balanceOf(address(this));
        IUniswapV2Router01(router).removeLiquidity(want, cake, lpBal, 0, 0, address(this), block.timestamp);
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        uint256 borrowBal = ICompoundToken(cToken).borrowBalanceStored(address(this));
        if (cakeBal > borrowBal) {
            cakeBal = borrowBal;
        }
        _repayBorrow(cakeBal);
    }

    function setHarvestEnabled(bool enabled) external onlyOwner {
        harvestEnabled = enabled;
    }

    /**
     * @dev Updates Strategist
     * @param newStrategist new strategist address
     */
    function setStrategist(address newStrategist) external onlyOwner {
        strategist = newStrategist;
    }

    /**
     * @dev Updates Strategist Basis
     * @param newStrategistBasis new strategist Basis
     */
    function setStrategistBasis(uint256 newStrategistBasis) external onlyOwner {
        strategistBasis = newStrategistBasis;
    }

    /**
     * @dev Updates Keeper Basis.
     * @param newKeeperBasis Keeper Basis.
     */
    function setKeeperBasis(uint256 newKeeperBasis) external onlyOwner {
        keeperBasis = newKeeperBasis;
    }

    function pause() public onlyOwner {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyOwner {
        _unpause();
        _giveAllowances();
    }

    /// @notice wrap router method for easy access
    function getAmountsOut(uint256 amountIn, address[] calldata path) 
        public 
        view returns (uint256[] memory amounts) 
    {
        amounts = IUniswapV2Router01(router).getAmountsOut(amountIn, path);
    }

    /// @notice for requested UniLp tokens, how much token0/1 we need to give?
    function getAssetsAmounts(uint256 poolLpAmount_)
        public
        view
        returns (uint256 assets0, uint256 assets1)
    {
        /// get xy=k here, where x=ra0,y=ra1
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            address(asset),
            token0,
            token1
        );
        /// shares of uni pair contract
        uint256 pairSupply = IUniswapV2Pair(address(asset)).totalSupply();
        /// amount of token0 to provide to receive poolLpAmount_
        assets0 = (reserveA * poolLpAmount_) / pairSupply;
        /// amount of token1 to provide to receive poolLpAmount_
        assets1 = (reserveB * poolLpAmount_) / pairSupply;
       
    }

    /// @notice For requested N assets0 & N assets1, how much UniV2 LP do we get?
    function getLPAmountOut(uint256 assets0_, uint256 assets1_)
        public
        view
        returns (uint256 poolLpAmount)
    {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            address(asset),
            token0,
            token1
        );
        uint256 pairSupply = IUniswapV2Pair(address(asset)).totalSupply();
        poolLpAmount = _min(
            ((assets0_ * pairSupply) / reserveA),
            (assets1_ * pairSupply) / reserveB
        );
    }

    /// @notice Total amount of CakeLP staked by vault
    function totalAssets() public view override returns (uint256) {
        (uint256 amount,,) = IMasterChefV2(masterchef).userInfo(pid, farmBoosterProxy);
        return amount;
    }

    function _repayBorrow(uint256 amount) internal {
        if (totalBorrowedAmount > 0) {
            if (amount > totalBorrowedAmount) {
                amount = totalBorrowedAmount;
            }
            ICompoundToken(cToken).repayBorrow(amount);
            totalBorrowedAmount = ICompoundToken(cToken).borrowBalanceStored(address(this));
        }
    }

    function _payFees(uint256 amount) internal {
        uint256 strategistAmount = (amount * strategistBasis) / DIVISOR;
        IERC20(cake).safeTransfer(strategist, strategistAmount);
        uint256 repayAmount = (amount * cakeRepayBasis) / DIVISOR;
        _repayBorrow(repayAmount);
        uint256 toNativeBal = (amount * keeperBasis) / DIVISOR;
        IUniswapV2Router01(router).swapExactTokensForTokens(
            toNativeBal,
            0,
            cakeToNativePath,
            address(this),
            block.timestamp
        );
        uint256 nativeBal = IERC20(wrappedNative).balanceOf(address(this));
        IERC20(wrappedNative).safeTransfer(tx.origin, nativeBal);
        emit FeesPaid(repayAmount, strategistAmount, nativeBal);
    }

    function _swapAddLiquidityAndStake() internal {
        uint256 swapHalf = IERC20(cake).balanceOf(address(this)) / 2;
        IUniswapV2Router01(router).swapExactTokensForTokens(
            swapHalf,
            0,
            cakeToWantPath,
            address(this),
            block.timestamp
        );
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        uint256 cakeBal = IERC20(cake).balanceOf(address(this));
        IUniswapV2Router01(router).addLiquidity(want, cake, wantBal, cakeBal, 0, 0, address(this), block.timestamp);
        IUniswapV2Pair(address(asset)).skim(address(this));
        uint256 lpBal = asset.balanceOf(address(this));
        IFarmBoosterProxy(farmBoosterProxy).deposit(pid, lpBal);
    }

    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function _giveAllowances() internal {
        IERC20(cake).safeApprove(cToken, type(uint256).max);
        IERC20(want).safeApprove(router, type(uint256).max);
        IERC20(cake).safeApprove(router, type(uint256).max);
        IERC20(address(asset)).safeApprove(farmBoosterProxy, type(uint256).max);
        IERC20(address(asset)).safeApprove(router, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(cake).safeApprove(cToken, 0);
        IERC20(want).safeApprove(router, 0);
        IERC20(cake).safeApprove(router, 0);
        IERC20(address(asset)).safeApprove(farmBoosterProxy, 0);
        IERC20(address(asset)).safeApprove(router, 0);
    }
}