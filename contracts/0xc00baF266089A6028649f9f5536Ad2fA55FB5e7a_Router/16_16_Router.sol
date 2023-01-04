// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IBasePriceOracle.sol";
import "./interfaces/IOracleManager.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IRouter.sol";

/**
 * @title Router
 * @author LombardFi
 * @notice The router is the entry point for interacting with the LombardFi system.
 * @dev Much of the verification logic is done in the router to compress the size of the Pool contract.
 */
contract Router is IRouter, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Address of the PoolFactory.
     */
    IPoolFactory public poolFactory;

    /**
     * @notice Address of the OracleManager.
     */
    IOracleManager public oracleManager;

    /**
     * @notice Address of the protocol treasury.
     * @dev Receives the origination fee at pool creation.
     */
    address public treasury;

    /**
     * @notice Verify that an integer is greater than 0.
     * @dev Throws an error if the uint256 is equal to 0
     * @param amt The integer to check.
     */
    modifier nonZero(uint256 amt) {
        require(amt > 0, "Router::zero amt");
        _;
    }

    /**
     * @notice Verify that an address is not the zero address.
     * @dev Throws an error if the address is the zero address.
     * @param _address The address to check.
     */
    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Router::zero address");
        _;
    }

    /**
     * @notice Set the PoolFactory implementation address. Callable only by the owner.
     * @dev Throws an error if the supplied address is the zero address.
     * @param _poolFactory The new implementation.
     */
    function setFactory(IPoolFactory _poolFactory)
        external
        nonZeroAddress(address(_poolFactory))
        onlyOwner
    {
        require(
            address(poolFactory) == address(0),
            "Router::factory already set"
        );
        poolFactory = _poolFactory;
        emit FactorySet(msg.sender, address(_poolFactory));
    }

    /**
     * @notice Set the OracleManager implementation address. Callable only by the owner.
     * @dev Throws an error if the address is the zero address.
     * @param _oracleManager The new implementation.
     */
    function setOracleManager(IOracleManager _oracleManager)
        external
        nonZeroAddress(address(_oracleManager))
        onlyOwner
    {
        oracleManager = _oracleManager;
        emit OracleManagerSet(msg.sender, address(_oracleManager));
    }

    /**
     * @notice Set the treasury address. Callable only by the owner.
     * @dev Throws an error if the address is the zero address.
     * @param _treasury The new recipient.
     */
    function setTreasury(address _treasury)
        external
        nonZeroAddress(_treasury)
        onlyOwner
    {
        treasury = _treasury;
        emit TreasurySet(msg.sender, _treasury);
    }

    /**
     * @notice Pause the contract. Callable only by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract. Callable only by the owner.
     * @dev The contract must be paused to unpause it.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Deposit into a pool.
     * @dev The contract must not be paused.
     * `_amt` must be nonzero.
     * A pool with the `_pid` must exist.
     * Caller must not be the pool's borrower.
     * Caller must be the whitelisted lender if the pool has one.
     * Caller must have approved this contract to spend `_amt` of the pool's lent asset.
     * The pool must not be active or mature.
     * The pool must have sufficient open capacity for `_amt`.
     * @param _pid The id of the pool to deposit in.
     * @param _amt The amount of the pool's lent asset to deposit.
     */
    function deposit(uint256 _pid, uint256 _amt)
        external
        nonZero(_amt)
        whenNotPaused
        nonReentrant
    {
        IPool pool = _getPool(_pid);

        // If there is a whitelisted lender verify that the sender is the whitelisted lender.
        address whitelistedLender = pool.whitelistedLender();
        require(
            whitelistedLender == address(0) || whitelistedLender == msg.sender,
            "Router::caller not whitelisted lender"
        );
        // Caller cannot be borrower
        _verifyCallerIsNotBorrower(pool);
        // Pool must accept deposits
        require(
            block.timestamp < pool.activeAt(),
            "Router::expired deposit period"
        );
        // Pool must have enough open capacity
        require(
            pool.maxSupply() - pool.supply() >= _amt,
            "Router::supply cap exceeded"
        );

        // Transfer lent asset from lender to pool and perform accounting.
        address lentAsset = pool.lentAsset();
        IERC20(lentAsset).safeTransferFrom(msg.sender, address(pool), _amt);
        pool.deposit(msg.sender, _amt);

        emit Deposit(_pid, lentAsset, _amt);
    }

    /**
     * @notice Borrow the avaiable amount of lent asset from a pool.
     * Transfers the pool's lent asset from pool to borrower.
     * Transfers collateral from borrower to pool.
     * @dev The contract must not be paused.
     * A pool with the `_pid` must exist.
     * Caller must be the pool's borrower.
     * Lengths of `_collateralAssets` and `amts` must match.
     * `_collateralAssets` must be the pool's collateral assets or a subset.
     * The pool must be active.
     * The pool's minimum deposit must have been reached.
     * The loan amount and value of the supplied collateral must satisfy the loan-to-value ratio.
     * @param _pid The id of the pool to borrow from.
     * @param _collateralAssets The assets to deposit as collateral
     * @param _amts The amounts corresponding to the collaterals
     */
    function borrow(
        uint256 _pid,
        address[] calldata _collateralAssets,
        uint256[] calldata _amts
    ) external whenNotPaused nonReentrant {
        IPool pool = _getPool(_pid);

        // Only the borrower can borrow
        require(msg.sender == pool.borrower(), "Router::caller not borrower");
        // Cardinality of assets and amounts must match
        require(
            _collateralAssets.length == _amts.length,
            "Router::invalid params"
        );
        // Assets must be a subset of the collateral assets
        require(
            _assetsAreValidPoolCollateral(pool, _collateralAssets),
            "Router::invalid assets"
        );

        // Pool must be active and the minimum must be met
        uint256 supply = pool.supply();
        require(
            block.timestamp >= pool.activeAt() &&
                block.timestamp < pool.maturesAt() &&
                supply >= pool.minSupply(),
            "Router::can't borrow"
        );

        uint256 borrowAmount = supply - pool.borrowed();

        // Calculate the loan value from the oracle
        address lentAsset = pool.lentAsset();
        uint256 loanValue = (oracleManager.getPrice(lentAsset) * borrowAmount) /
            10**ERC20(lentAsset).decimals();

        // Calculate the value of the collateral from the oracle
        uint256 borrowingPower = getBorrowingPower(_collateralAssets, _amts);

        // Check that the loan-to-value ratio is not exceeded
        require(
            (loanValue * 10**18) / borrowingPower <= pool.ltv(),
            "Router::low BP"
        );

        // Transfer collateral from borrower and perform accounting for the deposits
        for (uint256 i = 0; i < _collateralAssets.length; ) {
            if (_amts[i] > 0) {
                IERC20(_collateralAssets[i]).safeTransferFrom(
                    msg.sender,
                    address(pool),
                    _amts[i]
                );
                pool.supplyCollateral(_collateralAssets[i], _amts[i]);
            }
            unchecked {
                ++i;
            }
        }

        // Transfer the loan from pool to borrower and perform accounting for the borrow
        pool.borrow(lentAsset, borrowAmount);

        emit Borrow(_pid, borrowAmount, _collateralAssets, _amts);
    }

    /**
     * @notice Repay a part of the loan.
     * Transfers the pool's lent asset from borrower to pool.
     * Transfers collateral from pool to borrower.
     * @dev A pool with the `_pid` must exist.
     * `_amt` must be nonzero.
     * The contract must not be paused.
     * Pool must be active if the router is under normal operation.
     * Caller must be the pool's borrower.
     * The pool must be active.
     * @param _pid The id of the pool to repay in.
     * @param _amt The amount of the pool's lent asset to repay.
     */
    function repay(uint256 _pid, uint256 _amt)
        external
        nonZero(_amt)
        nonReentrant
    {
        IPool pool = _getPool(_pid);

        // Pool must be active.
        // If the Router is paused then repayment is allowed at any time.
        require(
            paused() ||
                (block.timestamp >= pool.activeAt() &&
                    block.timestamp < pool.maturesAt()),
            "Router::not active"
        );

        // Check that there is existing debt
        uint256 debt = pool.borrowed();
        require(debt > 0, "Router::no debt");

        // The amount repaid is the minimum of the supplied `_amt` and the outstanding debt
        // The owner cannot repay more than the debt (which will lead to accounting errors and overflows)
        // This nullifies griefing attacks (since anyone can repay on behalf of the borrower)
        uint256 amountToRepay;
        if (_amt < debt) {
            amountToRepay = _amt;
        } else {
            amountToRepay = debt;
        }

        // Perform accounting and transfer collateral from the pool to the borrower
        pool.repay(amountToRepay);

        // Transfer lent asset from the borrower to the pool
        address lentAsset = pool.lentAsset();
        IERC20(lentAsset).safeTransferFrom(
            msg.sender,
            address(pool),
            amountToRepay
        );

        emit Repay(_pid, lentAsset, _amt);
    }

    /**
     * @notice Redeem notional and yield from a mature pool or redeem notional from an unsuccessful pool.
     * Transfers the pool's lent asset from pool to caller.
     * Transfers collateral from caller to pool.
     * @dev The contract must not be paused.
     * A pool with the `_pid` must exist.
     * Caller must not be the pool's borrower.
     * The pool must be mature or active with less deposits than the minimum.
     * Caller must have made a deposit.
     * Caller can redeem only once per pool.
     * @param _pid The id of the pool to redeem from.
     */
    function redeem(uint256 _pid) external whenNotPaused nonReentrant {
        IPool pool = _getPool(_pid);

        // Caller cannot be the borrower
        _verifyCallerIsNotBorrower(pool);

        // Either the pool is mature (redeem notional + yield)
        // Or the pool is active but minimum has not been met (redeem notional)
        require(
            block.timestamp >= pool.maturesAt() ||
                (block.timestamp >= pool.activeAt() &&
                    pool.minSupply() > pool.supply()),
            "Router::can't redeem"
        );

        // Caller has deposited something and has not redeemed their rewards yet
        uint256 notional = pool.notionals(msg.sender);
        require(notional > 0, "Router::no notional");

        bool hasDefaulted = pool.borrowed() > 0;

        if (!hasDefaulted) {
            // All debt has been repaid
            // Perform accounting and transfer lent asset from pool to lender
            pool.redeem(msg.sender);
        } else {
            // There is outstanding debt (borrower defaults)
            // Perform accounting and transfer pro-rata lent asset and collateral from pool to lender
            pool._default(msg.sender);
        }

        emit Redeem(_pid, pool.lentAsset(), hasDefaulted);
    }

    /**
     * @notice Withdraw redundant yield from a pool.
     * Transfers a part of the upfront for the unrealized size back to the borrower.
     * @dev The contract must not be paused.
     * A pool with the `_pid` must exist.
     * Caller must be the pool's borrower.
     * Borower can withdraw only once.
     * The pool must be active.
     * @param _pid The id of the pool to withdraw leftovers from.
     */
    function withdrawLeftovers(uint256 _pid)
        external
        whenNotPaused
        nonReentrant
    {
        IPool pool = _getPool(_pid);

        // Caller must be the pool's borrower
        require(pool.borrower() == msg.sender, "Router::not borrower");

        // Borower can withdraw only once per pool
        require(!pool.leftoversWithdrawn(), "Router::already withdrawn");

        // Pool must be active
        require(block.timestamp >= pool.activeAt(), "Router::not active");

        // If the minimum was not met, withdraw all of the upfront rewards
        uint256 supplyClaim = pool.maxSupply();
        uint256 _supply = pool.supply();
        if (_supply >= pool.minSupply()) {
            // If the minimum was met, withdraw the rewards for the unfilled size
            supplyClaim -= _supply;
        }

        // Perform accounting and transfer the rewards back to the borrower
        uint256 rewardsToWithdraw = (pool.coupon() * supplyClaim) / 10**18;
        pool.withdrawLeftovers(rewardsToWithdraw);

        emit LeftoversWithdrawn(_pid, rewardsToWithdraw);
    }

    /**
     * @notice Utility function that returns the value of collateral.
     * Prices are fetched from the OracleManager.
     * @dev Also used for off-chain data retrieval.
     * @param _collateralAssets Array of collateral assets.
     * @param _amts The amounts corresponding to the collateral assets.
     * @return _borrowingPower The total value of the collateral.
     */
    function getBorrowingPower(
        address[] calldata _collateralAssets,
        uint256[] calldata _amts
    ) public view returns (uint256 _borrowingPower) {
        uint256 numCollaterals = _collateralAssets.length;
        for (uint256 i = 0; i < numCollaterals; ) {
            // Skip asset if the amount is 0
            if (_amts[i] > 0) {
                // Fetch the price of a unit of asset from the oracle
                address asset = _collateralAssets[i];
                uint256 price = oracleManager.getPrice(asset);

                // Calculate the value of the collateral and add it to the borrowing power.
                _borrowingPower +=
                    (price * _amts[i]) /
                    10**ERC20(asset).decimals();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Utility function that checks whether an array of addresses match pool collateral.
     * They must be a subset.
     * @param _pool The pool to check the assets against.
     * @param _assets The array of ERC20 token addresses to check against the pool.
     * @return Whether the given assets are valid subset of pool collateral.
     */
    function _assetsAreValidPoolCollateral(
        IPool _pool,
        address[] memory _assets
    ) private view returns (bool) {
        // Reads all assets from storage into memory.
        address[] memory collateralAssets = _pool.getCollateralAssets();
        uint256 numCollaterals = collateralAssets.length;

        // Iterate through the assets
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; ) {
            address asset = _assets[i];

            // Check if there is a duplicate asset in the rest of the array
            // Only need to search after the current position
            uint256 j = i + 1;
            for (; j < assetsLength; ) {
                if (asset == _assets[j]) {
                    return false;
                }
                unchecked {
                    ++j;
                }
            }

            // Check if the collateral exists in the pool
            for (j = 0; j < numCollaterals; ) {
                if (asset == collateralAssets[j]) {
                    break;
                }
                unchecked {
                    ++j;
                }
            }

            if (j == numCollaterals) {
                // Did not find a match
                return false;
            }

            unchecked {
                ++i;
            }
        }
        return true;
    }

    /**
     * @notice Private function that verifies that the caller is not the pool's borrower.
     * @param _pool The pool contract.
     */
    function _verifyCallerIsNotBorrower(IPool _pool) private view {
        require(msg.sender != _pool.borrower(), "Router::cannot be borrower");
    }

    /**
     * @notice Private function that gets a pool address from a pool id.
     * @dev Throws an error if a pool with the `_pid` does not exist.
     * @param _pid The id of the pool to get the address of.
     * @return _pool The pool contract.
     */
    function _getPool(uint256 _pid) private view returns (IPool _pool) {
        address poolAddress = poolFactory.pidToPoolAddress(_pid);
        require(poolAddress != address(0), "Router::no pool");
        _pool = IPool(poolAddress);
    }
}