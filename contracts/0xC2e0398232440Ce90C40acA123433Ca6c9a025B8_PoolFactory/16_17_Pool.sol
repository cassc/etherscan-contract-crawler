// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IRouter.sol";

/**
 * @title Pool
 * @author LombardFi
 * @notice The pool contract resembles an OTC term sheet with a single borrower and
 * one or more lenders. The borrower takes a loan from the lenders on a specific
 * predefined loan-to-value ratio against collateral.
 * @dev The implementation cloned by the PoolFactory.
 */
contract Pool is IPool {
    using SafeERC20 for IERC20;

    /**
     * @notice Address of the borrower.
     */
    address public borrower;

    /**
     * @notice Address of the whitelisted lender.
     * @dev Zero address if the pool is open to everyone.
     */
    address public whitelistedLender;

    /**
     * @notice The ERC20 token that lenders deposit and the borrower borrows.
     */
    address public lentAsset;

    /**
     * @notice The ERC20 tokens that can be used as collateral.
     */
    address[] public collateralAssets;

    /**
     * @notice The timestamp at which the pool was deployed.
     * Lenders can deposit `lentAsset` until the pool becomes active.
     * @dev Set to block.timestamp during pool initialization.
     */
    uint32 public startsAt;

    /**
     * @notice The timestamp after which deposits close and borrowers can borrow the deposits.
     * If the minimum is not reached, borrowers cannot borrow and lenders can withdraw their deposits without accruing yield.
     */
    uint32 public activeAt;

    /**
     * @notice The timestamp at which the Pool matures.
     * Lenders can withdraw their deposits after maturity.
     */
    uint32 public maturesAt;

    /**
     * @notice The yield for the pool during the term. The term is the duration at which the pool is active.
     * Borrower must pay this
     * @dev Denonimated in wad. A value of 1e17 means the coupon is 10%.
     * The APR can be calculated by multiplying this value by the number of seconds in a year and dividing it by `maturesAt-activeAt`.
     */
    uint96 public coupon;

    /**
     * @notice The loan-to-value ratio of the pool. When borrowing the borrower must supply collateral such that
     * the value of the loan = ltv * value of the collateral.
     * @dev Denonimated in wad. A value of 2e18 means the LTV is 200%.
     * @dev The collateralization ratio is the inverse of the LTV. If the LTV is 200% then the CR is 50%.
     */
    uint96 public ltv;

    /**
     * @notice The origination fee charged to the protocol treasury. When borrowing, the origination fee is
     * deducted from the borrowed amount and transferred to the protocol treasury.
     * @dev Denominated in wad. A value of 3e15 means the origination fee is 0.3%.
     * The Treasury address is kept in the `Router` contract.
     */
    uint96 public originationFee;

    /**
     * @notice A boolean that stores whether the borrower has withdrawn the redundant coupon for the pool.
     * Borrowers are required to supply the coupon for the maximum capacity of the pool at pool creation.
     * If the maximum capacity is not reached and the pool is active or mature, the coupon for the unfilled capacity can be withdrawn by the borrower.
     */
    bool public leftoversWithdrawn;

    /**
     * @notice The minimum amount of `lentAsset` that lenders must deposit to activate borrowing functionality.
     * @dev If at least `minSupply` of `lentAsset` is deposited, borrowers can borrow all or a part of deposits.
     * Borrowers must repay their loan before maturity or the pool will default.
     */
    uint256 public minSupply;

    /**
     * @notice The maximum amount of `lentAsset` that lenders can deposit.
     * Borrowers must pay the coupon upfront based on this amount, so in practice this cannot be unbounded.
     * This measure also keeps away pool spam.
     */
    uint256 public maxSupply;

    /**
     * @notice The pool supply reached.
     * This is used for a checkpoint to calculate the amount of extra coupon to withdraw.
     * @dev When lenders deposit the amount is added to `supply`.
     * However when lenders redeem the amount is NOT subtracted from `supply`.
     * Therefore this variable can be interpreted as the supply reached.
     * This is done so that the borrower can withdraw the extra coupon at any time.
     */
    uint256 public supply;

    /**
     * @notice The amount of `lentAsset` borrowed by the borrower.
     * Borrowers must pay the coupon upfront based on this amount, so in practice this cannot be unbounded.
     * This is also a measure to keep away pool spam.
     */
    uint256 public borrowed;

    /**
     * @notice Stores a lender's notional (total deposited amount), used to calculate rewards.
     */
    mapping(address => uint256) public notionals;

    /**
     * @notice Collateral amounts supplied by the borrower.
     */
    mapping(address => uint256) public collateralReserves;

    /**
     * @notice Address of the Router contract.
     */
    address private immutable router;

    /**
     * @notice Verify that the caller is the router.
     * @dev Throws an error otherwise.
     */
    modifier onlyRouter() {
        require(msg.sender == router, "Pool::caller not router");
        _;
    }

    constructor(address _router) {
        require(_router != address(0), "Pool::zero address");
        router = _router;
    }

    /**
     * @notice Initialize the pool variables.
     * @dev Called by the Router when the clone is created.
     * @param _borrower The address of the borrower.
     * @param _lentAsset The address of the lent asset.
     * @param _collateralAssets The addresses of the collateral assets.
     * @param _coupon The yield generated by lenders in wad.
     * @param _ltv The loan-to-value ratio for the borrower.
     * @param _originationFee The fee charged by the protocol given by the PoolFactory.
     * @param _activeAt When deposits end and borrowing is allowed.
     * @param _maturesAt When the pool is over.
     * @param _minSupply Minimum supply of the lent asset to enable borrowing.
     * @param _maxSupply Maximum allowed supply of the lent asset.
     */
    function initialize(
        address _borrower,
        address _lentAsset,
        address[] memory _collateralAssets,
        uint96 _coupon,
        uint96 _ltv,
        uint96 _originationFee,
        uint32 _activeAt,
        uint32 _maturesAt,
        uint256 _minSupply,
        uint256 _maxSupply,
        address _whitelistedLender
    ) external {
        // This check also prevents a reentrancy
        require(lentAsset == address(0), "Pool::already initialized");

        // Set addresses
        borrower = _borrower;
        lentAsset = _lentAsset;
        collateralAssets = _collateralAssets;
        whitelistedLender = _whitelistedLender;

        // Set params
        coupon = _coupon;
        ltv = _ltv;
        originationFee = _originationFee;

        // Set timestamps
        startsAt = uint32(block.timestamp);
        activeAt = _activeAt;
        maturesAt = _maturesAt;

        // Set supply ranges
        minSupply = _minSupply;
        maxSupply = _maxSupply;

        emit Initialized(router, _borrower, collateralAssets, lentAsset);
    }

    /**
     * @notice Performs accounting when an asset is deposited.
     * Called when the lender deposits.
     * @dev Can be called only by the Router.
     * @param _src The lender address.
     * @param _amt The amount of `_asset` deposited.
     */
    function deposit(address _src, uint256 _amt) external onlyRouter {
        // The lender deposits lent asset
        // Increase the lender's notional
        notionals[_src] += _amt;
        // Increase the supply reached in the pool
        supply += _amt;
    }

    /**
     * @notice Performs accounting when the borrower supplies collateral.
     * @dev Can be called only by the Router.
     * @param _asset The address of the asset deposited.
     * @param _amt The amount of `_asset` deposited.
     */
    function supplyCollateral(address _asset, uint256 _amt)
        external
        onlyRouter
    {
        // The borrower deposits collateral
        // Increase the amount of supplied collateral
        collateralReserves[_asset] += _amt;
    }

    /**
     * @notice Performs accounting and transfers on borrow.
     * Called when the borrower borrows.
     * @dev Can be called only by the Router.
     * @param _lentAsset The address of `lentAsset` supplied for efficiency.
     * @param _amt The amount of `lentAsset` to borrow.
     */
    function borrow(address _lentAsset, uint256 _amt) external onlyRouter {
        // Effects before interactions
        borrowed += _amt;

        // The amount of lent asset to transfer to the treasury
        uint256 treasuryClaim = 0;

        uint96 _originationFee = originationFee;
        if (_originationFee > 0) {
            // Fee = origination fee (in wad) * the amount borrowed
            treasuryClaim = (_originationFee * _amt) / 10**18;
            // Transfer the fee to the protocol treasury
            _transfer(_lentAsset, IRouter(router).treasury(), treasuryClaim);
        }

        // Transfer the rest to the borrower
        _transfer(_lentAsset, borrower, _amt - treasuryClaim);
    }

    /**
     * @notice Performs accounting and transfers back collateral on repay.
     * Called when the borrower repays their loan.
     * @dev Can be called only by the Router.
     * @param _amt The amount of `lentAsset` to repay.
     */
    function repay(uint256 _amt) external onlyRouter {
        address _borrower = borrower;

        // The proportion of total debt that the borrower repays
        uint256 claimProportion = (_amt * 10**18) / borrowed;

        uint256 numCollaterals = collateralAssets.length;
        for (uint256 i = 0; i < numCollaterals; ) {
            address collateral = collateralAssets[i];

            // The amount of collateral deposited in the borrow
            uint256 collateralReserve = collateralReserves[collateral];

            // Skip collateral if none was deposited
            if (collateralReserve > 0) {
                // `claimProportion` is in wad
                // The same proportion of the initially deposited colalteral will be returned to the borrower
                uint256 collateralToReturn = (claimProportion *
                    collateralReserve) / 10**18;

                if (collateralToReturn > 0) {
                    // decrease the reserves
                    collateralReserves[collateral] -= collateralToReturn;
                    // transfer collateral back
                    _transfer(collateral, _borrower, collateralToReturn);
                }
            }

            unchecked {
                ++i;
            }
        }

        // Decrease debt
        borrowed -= _amt;
    }

    /**
     * @notice Performs accounting and returns deposit to the lender.
     * Called when the lender redeems their deposit.
     * Partial redeems are not allowed.
     * @dev Can be called only by the Router.
     * @param _src The address of the lender.
     */
    function redeem(address _src) external onlyRouter {
        uint256 amountToReturn = notionals[_src];

        if (supply >= minSupply) {
            // Give interest if the minimum size was achieved
            amountToReturn += (coupon * amountToReturn) / 10**18;
        }

        // Zero out the deposited amount for the lender
        notionals[_src] = 0;

        // Transfer lent asset to the lender
        _transfer(lentAsset, _src, amountToReturn);
    }

    /**
     * @notice Performs accounting and returns some lent asset and collateral to the lender.
     * Called when the lender redeems their deposit and the borrower has not repaid all debt before maturity.
     * @dev Can be called only by the Router.
     * @param _src The address of the lender.
     */
    function _default(address _src) external onlyRouter {
        uint256 notional = notionals[_src];

        uint256 _supply = supply;

        // The lender's deposit as a proportion of total deposits
        // Will be <= 1e18 (1e18 = 100% of the deposits)
        uint256 claimProportion = (notional * 10**27) / _supply;

        // Lender will get a pro-rata distribution of pool rewards
        uint256 amountOfLentAssetToReturn = (coupon * notional) / 10**18;

        uint256 _borrowed = borrowed;
        // If some debt has been repaid, transfer that repaid amount pro-rata as well.
        if (_borrowed < _supply) {
            uint256 repaidAmount = _supply - _borrowed;

            // Add to the return amount a pro-rata distribution of the repaid amount.
            amountOfLentAssetToReturn +=
                (repaidAmount * claimProportion) /
                10**27;
        }

        // Transfer the lent asset to the lender
        _transfer(lentAsset, _src, amountOfLentAssetToReturn);

        // Return a pro-rata distribution of pledged collateral
        uint256 numCollaterals = collateralAssets.length;
        for (uint256 i = 0; i < numCollaterals; ) {
            address collateral = collateralAssets[i];
            uint256 collateralReserve = collateralReserves[collateral];

            // Lender will get a pro-rata distribution of collateral
            uint256 collateralToReturn = (collateralReserve * claimProportion) /
                10**27;

            if (collateralToReturn > 0) {
                // Transfer the collateral to the lender
                _transfer(collateral, _src, collateralToReturn);
            }

            unchecked {
                ++i;
            }
        }

        // Zero out the lender's notional
        notionals[_src] = 0;
    }

    /**
     * @notice Performs accounting when the borrower withdraws redundant rewards.
     * @dev Can be called only by the Router.
     * @param _amt The amount of rewards to withdraw.
     */
    function withdrawLeftovers(uint256 _amt) external onlyRouter {
        leftoversWithdrawn = true;
        _transfer(lentAsset, borrower, _amt);
    }

    /**
     * @notice Transfers an ERC20 token from the pool.
     * @dev Uses the OpenZeppelin's SafeERC20 library.
     * @param _asset The address of the token to transfer.
     * @param _dst The recipient of the transfer.
     * @param _amt The amount to transfer.
     */
    function _transfer(
        address _asset,
        address _dst,
        uint256 _amt
    ) private {
        IERC20(_asset).safeTransfer(_dst, _amt);
    }

    /**
     * @notice Retrieves the array of collateral assets.
     * @dev Used for off-chain data retrieval.
     * @return `collateralAssets` as a memory array.
     */
    function getCollateralAssets() external view returns (address[] memory) {
        return collateralAssets;
    }
}