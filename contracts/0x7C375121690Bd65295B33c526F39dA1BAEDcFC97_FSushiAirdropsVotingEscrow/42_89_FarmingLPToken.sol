// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IFarmingLPToken.sol";
import "./interfaces/IFarmingLPTokenFactory.sol";
import "./interfaces/IFarmingLPTokenMigrator.sol";
import "./interfaces/IMasterChef.sol";
import "./libraries/UniswapV2Utils.sol";
import "./base/BaseERC20.sol";

contract FarmingLPToken is BaseERC20, ReentrancyGuard, IFarmingLPToken {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint128 internal constant POINTS_MULTIPLIER = type(uint128).max;

    address public override factory;
    address public override router;
    address public override masterChef;
    uint256 public override pid;
    address public override sushi;
    address public override lpToken;
    address public override token0;
    address public override token1;

    uint256 public override withdrawableTotalLPs;
    uint256 internal _pointsPerShare;
    mapping(address => int256) internal _pointsCorrection;
    mapping(address => uint256) internal _withdrawnVaultBalanceOf;

    function initialize(
        address _router,
        address _masterChef,
        uint256 _pid
    ) external override initializer {
        if (_router == address(0)) return;

        factory = msg.sender;
        (address _lpToken, , , ) = IMasterChef(_masterChef).poolInfo(_pid);
        address _token0 = IUniswapV2Pair(_lpToken).token0();
        address _token1 = IUniswapV2Pair(_lpToken).token1();
        router = _router;
        masterChef = _masterChef;
        pid = _pid;
        sushi = IMasterChef(_masterChef).sushi();
        lpToken = _lpToken;
        token0 = _token0;
        token1 = _token1;

        BaseERC20_initialize(
            string.concat(
                "Farming LP Token (",
                IERC20Metadata(_token0).name(),
                "-",
                IERC20Metadata(_token1).name(),
                ")"
            ),
            string.concat("fLP:", IERC20Metadata(_token0).symbol(), "-", IERC20Metadata(_token1).symbol()),
            "1"
        );
        approveMax();
    }

    function withdrawableLPsOf(address account) external view override returns (uint256) {
        uint256 total = totalShares();
        if (total == 0) return 0;
        return (sharesOf(account) * withdrawableTotalLPs) / total;
    }

    /**
     * @return Sum of (shares in SUSHI) + (withdrawable total SUSHI)
     */
    function totalSupply() public view override(BaseERC20, IERC20) returns (uint256) {
        return totalShares() + withdrawableTotalYield();
    }

    /**
     * @return Sum of (shares in SUSHI by depositd account) + (SUSHI withdrawable by account)
     */
    function balanceOf(address account) public view override(BaseERC20, IERC20) returns (uint256) {
        return sharesOf(account) + withdrawableYieldOf(account);
    }

    /**
     * @return total shares in SUSHI currently being depositd
     */
    function totalShares() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return shares in SUSHI currently being depositd by account
     */
    function sharesOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    /**
     * @dev Returns the total amount of SUSHI if every holder wants to withdraw at once
     * @return A uint256 representing the total SUSHI
     */
    function withdrawableTotalYield() public view override returns (uint256) {
        address yieldVault = IFarmingLPTokenFactory(factory).yieldVault();
        uint256 pendingSushi = IMasterChef(masterChef).pendingSushi(pid, address(this));
        return pendingSushi + IERC4626(yieldVault).maxWithdraw(address(this));
    }

    /**
     * @dev Returns the amount of SUSHI a given address is able to withdraw.
     * @param account Address of a reward recipient
     * @return A uint256 representing the SUSHI `account` can withdraw
     */
    function withdrawableYieldOf(address account) public view override returns (uint256) {
        address yieldVault = IFarmingLPTokenFactory(factory).yieldVault();
        return IERC4626(yieldVault).convertToAssets((_withdrawableVaultBalanceOf(account, true)));
    }

    /**
     * @dev Vault balance is used to record reward debt for account.
     * @param account Address of a reward recipient
     * @param preview if true, it adds the amount of MasterChef.pendingSushi()
     * @return A uint256 representing the SUSHI `account` can withdraw
     */
    function _withdrawableVaultBalanceOf(address account, bool preview) internal view returns (uint256) {
        return _cumulativeVaultBalanceOf(account, preview) - _withdrawnVaultBalanceOf[account];
    }

    /**
     * @notice View the amount of vault balance that an address has earned in total.
     * @dev cumulativeVaultBalanceOf(account) = withdrawableVaultBalanceOf(account) + withdrawnVaultBalanceOf(account)
     *  = (pointsPerShare * sharesOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
     * @param account The address of a token holder.
     * @param preview if true, it adds the amount of MasterChef.pendingSushi()
     * @return The amount of SUSHI that `account` has earned in total.
     */
    function _cumulativeVaultBalanceOf(address account, bool preview) internal view returns (uint256) {
        uint256 pointsPerShare = _pointsPerShare;
        if (preview) {
            uint256 total = totalShares();
            if (total > 0) {
                address yieldVault = IFarmingLPTokenFactory(factory).yieldVault();
                uint256 pendingSushi = IMasterChef(masterChef).pendingSushi(pid, address(this));
                pointsPerShare += (IERC4626(yieldVault).previewDeposit(pendingSushi) * POINTS_MULTIPLIER) / total;
            }
        }
        return
            ((pointsPerShare * sharesOf(account)).toInt256() + _pointsCorrection[account]).toUint256() /
            POINTS_MULTIPLIER;
    }

    function approveMax() public override {
        IERC20(lpToken).approve(masterChef, type(uint256).max);
        IERC20(sushi).approve(IFarmingLPTokenFactory(factory).yieldVault(), type(uint256).max);
        IERC20(sushi).approve(router, type(uint256).max);
        IERC20(token0).approve(router, type(uint256).max);
        IERC20(token1).approve(router, type(uint256).max);
    }

    /**
     * @dev amount of sushi that LPs converted to is added to sharesOf(account) and aLP is minted
     *  user signature is needed for IUniswapV2Pair.permit()
     */
    function depositSigned(
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override nonReentrant {
        IUniswapV2Pair(lpToken).permit(msg.sender, address(this), amountLP, deadline, v, r, s);
        _deposit(amountLP, path0, path1, amountMin, beneficiary);
    }

    /**
     * @dev amount of sushi that LPs converted to is added to sharesOf(account) and aLP is minted
     */
    function deposit(
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary,
        uint256 deadline
    ) external override nonReentrant {
        if (block.timestamp > deadline) revert Expired();
        _deposit(amountLP, path0, path1, amountMin, beneficiary);
    }

    function _deposit(
        uint256 amountLP,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountMin,
        address beneficiary
    ) internal {
        if (path0[0] != token0 || path0[path0.length - 1] != sushi) revert InvalidPath();
        if (path1[0] != token1 || path1[path1.length - 1] != sushi) revert InvalidPath();

        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amountLP);

        uint256 total = IUniswapV2Pair(lpToken).totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        uint256 amount = UniswapV2Utils.quote(router, (reserve0 * amountLP) / total, path0) +
            UniswapV2Utils.quote(router, (reserve1 * amountLP) / total, path1);

        if (amount < amountMin) revert InsufficientAmount();

        IMasterChef(masterChef).deposit(pid, amountLP);
        _depositSushi();

        _mint(beneficiary, amount);
        withdrawableTotalLPs += amountLP;

        emit Deposit(amount, amountLP, beneficiary);
    }

    /**
     * @dev amount is added to sharesOf(account) and same amount of aLP is minted
     *  provided SUSHI is swapped then added as liquidity which results in LP tokens depositd
     */
    function depositWithSushi(
        uint256 amount,
        address[] calldata path0,
        address[] calldata path1,
        uint256 amountLPMin,
        address beneficiary,
        uint256 deadline
    ) external override {
        if (path0[0] != sushi || path0[path0.length - 1] != token0) revert InvalidPath();
        if (path1[0] != sushi || path1[path1.length - 1] != token1) revert InvalidPath();

        IERC20(sushi).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountLP = UniswapV2Utils.addLiquidityWithSingleToken(router, amount, path0, path1, deadline);
        if (amountLP < amountLPMin) revert InsufficientAmount();

        IMasterChef(masterChef).deposit(pid, amountLP);
        _depositSushi();

        _mint(beneficiary, amount);
        withdrawableTotalLPs += amountLP;

        emit Deposit(amount, amountLP, beneficiary);
    }

    /**
     * @dev when unstaking, the user's share of LP tokens are returned and pro-rata SUSHI yield is return as well
     */
    function withdraw(uint256 shares, address beneficiary) external override nonReentrant {
        uint256 amountLP = (shares * withdrawableTotalLPs) / totalShares();
        IMasterChef(masterChef).withdraw(pid, amountLP);

        _claimSushi(shares, beneficiary);

        IERC20(lpToken).safeTransfer(beneficiary, amountLP);

        _burn(msg.sender, shares);
        withdrawableTotalLPs -= amountLP;

        emit Withdraw(shares, amountLP, beneficiary);
    }

    function _claimSushi(uint256 shares, address beneficiary) internal {
        _depositSushi();

        uint256 sharesMax = sharesOf(msg.sender);
        if (shares > sharesMax) revert InsufficientAmount();

        address yieldVault = IFarmingLPTokenFactory(factory).yieldVault();
        uint256 withdrawable = _withdrawableVaultBalanceOf(msg.sender, false);
        if (withdrawable == 0) revert InsufficientYield();

        uint256 yieldShares = (withdrawable * shares) / sharesMax;
        _withdrawnVaultBalanceOf[msg.sender] += yieldShares;

        uint256 yield = IERC4626(yieldVault).redeem(yieldShares, beneficiary, address(this));

        emit ClaimSushi(shares, yield, beneficiary);
    }

    /**
     * @dev withdraw without caring about rewards. EMERGENCY ONLY
     */
    function emergencyWithdraw(address beneficiary) external override nonReentrant {
        uint256 shares = sharesOf(msg.sender);
        uint256 amountLP = (shares * withdrawableTotalLPs) / totalShares();
        IMasterChef(masterChef).withdraw(pid, amountLP);

        IERC20(lpToken).safeTransfer(beneficiary, amountLP);

        _burn(msg.sender, shares);
        withdrawableTotalLPs -= amountLP;

        emit EmergencyWithdraw(shares, amountLP, beneficiary);
    }

    /**
     * @dev migrate to a new version of fLP
     */
    function migrate(address beneficiary, bytes calldata params) external nonReentrant {
        address migrator = IFarmingLPTokenFactory(factory).migrator();
        if (migrator == address(0)) revert NoMigratorSet();

        uint256 shares = sharesOf(msg.sender);
        uint256 amountLP = (shares * withdrawableTotalLPs) / totalShares();
        IMasterChef(masterChef).withdraw(pid, amountLP);

        _claimSushi(shares, beneficiary);

        _burn(msg.sender, shares);
        withdrawableTotalLPs -= amountLP;

        address _lpToken = lpToken;
        IERC20(_lpToken).approve(migrator, amountLP);
        IFarmingLPTokenMigrator(migrator).onMigrate(msg.sender, pid, _lpToken, shares, amountLP, beneficiary, params);

        emit Migrate(shares, amountLP, beneficiary);
    }

    /**
     * @dev migrate to a new version of fLP without caring about rewards. EMERGENCY ONLY
     */
    function emergencyMigrate(address beneficiary, bytes calldata params) external nonReentrant {
        address migrator = IFarmingLPTokenFactory(factory).migrator();
        if (migrator == address(0)) revert NoMigratorSet();

        uint256 shares = sharesOf(msg.sender);
        uint256 amountLP = (shares * withdrawableTotalLPs) / totalShares();
        IMasterChef(masterChef).withdraw(pid, amountLP);

        _burn(msg.sender, shares);
        withdrawableTotalLPs -= amountLP;

        address _lpToken = lpToken;
        IERC20(_lpToken).approve(migrator, amountLP);
        IFarmingLPTokenMigrator(migrator).onMigrate(msg.sender, pid, _lpToken, shares, amountLP, beneficiary, params);

        emit EmergencyMigrate(shares, amountLP, beneficiary);
    }

    /**
     * @dev withdraws pending SUSHI from MasterChef and add it to the balance
     */
    function checkpoint() external override nonReentrant {
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        if (balance > withdrawableTotalLPs) {
            withdrawableTotalLPs = balance;
        }

        IMasterChef(masterChef).deposit(pid, 0);
        _depositSushi();
    }

    function _depositSushi() internal {
        uint256 balance = IERC20(sushi).balanceOf(address(this));
        if (balance > 0) {
            address yieldVault = IFarmingLPTokenFactory(factory).yieldVault();
            uint256 yieldBalance = IERC4626(yieldVault).deposit(balance, address(this));

            uint256 total = totalShares();
            if (total > 0) {
                _pointsPerShare += (yieldBalance * POINTS_MULTIPLIER) / total;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override returns (uint256 balanceOfFrom, uint256 balanceOfTo) {
        uint256 balance = balanceOf(from);
        uint256 shares = balance == 0 ? 0 : (amount * sharesOf(from)) / balance;

        (balanceOfFrom, balanceOfTo) = super._transfer(from, to, shares);

        int256 _magCorrection = (_pointsPerShare * shares).toInt256();
        _pointsCorrection[from] += _magCorrection;
        _pointsCorrection[to] += _magCorrection;
    }

    function _mint(address account, uint256 shares) internal override {
        super._mint(account, shares);

        _correctPoints(account, -int256(shares));
    }

    function _burn(address account, uint256 shares) internal override {
        super._burn(account, shares);

        _correctPoints(account, int256(shares));
    }

    function _correctPoints(address account, int256 amount) internal {
        _pointsCorrection[account] += amount * int256(_pointsPerShare);
    }
}