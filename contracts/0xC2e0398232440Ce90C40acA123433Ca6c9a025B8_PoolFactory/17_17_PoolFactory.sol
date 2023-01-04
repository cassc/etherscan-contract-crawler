// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IPoolFactory.sol";
import "./Pool.sol";

/**
 * @title PoolFactory
 * @author LombardFi
 * @notice The PoolFactory deploys Pool contracts.
 */
contract PoolFactory is IPoolFactory, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Address of Router contract.
     */
    address public immutable router;

    /**
     * @notice The number of created pools.
     */
    uint256 public pid;

    /**
     * @notice Maximum unique collateral assets per pool.
     * @dev Can be set by the owner in `setMaxNumberOfCollateralAssets`.
     */
    uint256 public maxNumberOfCollateralAssets = 5;

    /**
     * @notice Origination fee in wad (1e18 = 100%)
     * @dev Denominated in wad. A value of 0.01e18 means the origination fee is 1%.
     * Supplied to pool clones by copying this variable, not by the deployer.
     * Can be set by the owner in `setOriginationFee`.
     */
    uint96 public originationFee = 0.01e18;

    /**
     * @notice Maps pool id to its address.
     */
    mapping(uint256 => address) public pidToPoolAddress;

    /**
     * @notice Maximum configurable origination fee.
     * @dev Set to 10%.
     */
    uint96 public constant MAX_ORIGINATION_FEE = 0.1e18;

    /**
     * @notice Address of the pool implementation contract.
     * @dev This implementation is cloned when a new pool is deployed in `createPool`.
     * Set in the constructor. See `Pool`.
     */
    address private immutable poolImplementation;

    constructor(address _router) {
        require(_router != address(0), "Factory::zero address");
        router = _router;
        // create instance of Pool to clone later
        poolImplementation = address(new Pool(_router));
    }

    /**
     * @notice Deploys a new pool. Parameters must pass certain sanity checks.
     * @dev Uses OpenZeppelin Clones to clone the pool implementation.
     * Throws if the supplied parameters are invalid.
     * See `Pool` for detailed descriptions of the parameters.
     * @param _lentAsset The ERC20 token that lenders deposit and the borrower borrows.
     * @param _collateralAssets The ERC20 tokens that can be used as collateral by the borrower.
     * @param _coupon The yield for the duration of the term in wad.
     * @param _ltv The loan-to-value ratio in wad that must be achieved when borrowing.
     * @param _activeAt The timestamp after which deposits close and borrowers can borrow the deposits.
     * @param _maturesAt The timestamp after which lenders can withdraw their deposits with yield.
     * @param _minSupply The minimum supplied lent asset to activate the pool.
     * @param _maxSupply The deposit cap of the pool.
     * @param _whitelistedLender The whitelisted lender for the pool. 0 address if the pool is public.
     * @return pool The address of the deployed pool.
     */
    function createPool(
        address _lentAsset,
        address[] memory _collateralAssets,
        uint96 _coupon,
        uint96 _ltv,
        uint32 _activeAt,
        uint32 _maturesAt,
        uint256 _minSupply,
        uint256 _maxSupply,
        address _whitelistedLender
    ) external nonReentrant returns (address pool) {
        // The pool must become active in the future and mature after it is active for some time.
        // In most cases _activeAt is least a few days after the current timestamp.
        // In most cases _maturesAt is at least a few weeks after activity.
        // However these constraints are best enforced off-chain depending on the application.
        require(
            _activeAt > block.timestamp && _maturesAt > _activeAt,
            "Factory::invalid timestamps"
        );

        // _minSupply = _maxSupply is useful for private pools with pre-agreed parameters.
        require(
            _minSupply > 0 && _maxSupply >= _minSupply,
            "Factory::invalid supply range"
        );

        // Borrowers can collateralize their position with any mix of these assets.
        // They are not obliged to post collateral in all the assets.
        require(
            _collateralAssets.length > 0 &&
                _collateralAssets.length <= maxNumberOfCollateralAssets,
            "Factory::invalid collaterals"
        );

        // Check that there are no duplicates or zero addresses, or tokens with more than 18 decimals.
        require(
            _assetsAreValid(_collateralAssets, _lentAsset),
            "Factory::invalid assets"
        );
        // Use OpenZepplin Clones to deploy a new instance of pool.
        pool = Clones.clone(poolImplementation);

        pidToPoolAddress[pid++] = pool;

        // Initializes the pool with the necessary parameters.
        Pool(pool).initialize(
            msg.sender,
            _lentAsset,
            _collateralAssets,
            _coupon,
            _ltv,
            originationFee,
            _activeAt,
            _maturesAt,
            _minSupply,
            _maxSupply,
            _whitelistedLender
        );

        // The upfront reward must be given on pool deployment.
        // It is the maximum reward that can be distributed.
        // If the maxSupply is not reached then the borrower will be able to withdraw the leftover reward once the pool is active.
        uint256 upfrontReward = (_coupon * _maxSupply) / 10**18;

        // Transfer the upfront from the borrower to the pool and perform pre and post transfer checks.
        uint256 transferredUpfrontReward = _executeTransferFromWithBalanceChecks(
                IERC20(_lentAsset),
                msg.sender,
                pool,
                upfrontReward
            );

        require(
            transferredUpfrontReward == upfrontReward,
            "Factory::rewards discrepancy"
        );

        emit PoolCreated(
            pid,
            _collateralAssets,
            _lentAsset,
            transferredUpfrontReward
        );

        return pool;
    }

    /**
     * @notice Sets the maximum number of collateral assets allowed in a pool. Must be greater than 0.
     * @dev Can be called only by the owner.
     * @param _maxNumberOfCollateralAssets The new maximum number of collateral assets.
     */
    function setMaxNumberOfCollateralAssets(
        uint256 _maxNumberOfCollateralAssets
    ) external onlyOwner {
        require(_maxNumberOfCollateralAssets > 0, "Factory::zero value");

        maxNumberOfCollateralAssets = _maxNumberOfCollateralAssets;

        emit ParametersChanged(_maxNumberOfCollateralAssets, originationFee);
    }

    /**
     * @notice Sets the origination fee. Cannot be greater than the maximum.
     * @dev Can be called only by the owner.
     * @param _originationFee The new origination fee in wad.
     */
    function setOriginationFee(uint96 _originationFee) external onlyOwner {
        require(
            _originationFee <= MAX_ORIGINATION_FEE,
            "Factory::invalid value"
        );

        originationFee = _originationFee;

        emit ParametersChanged(maxNumberOfCollateralAssets, _originationFee);
    }

    /**
     * @notice Retrieves all pools.
     * @dev Used for off-chain data retrieval.
     * May run out of gas if `pid` is too large. Use `getAllPoolsSlice` in that case.
     * @return an array of pool addresses.
     */
    function getAllPools() external view returns (address[] memory) {
        address[] memory pools = new address[](pid);

        for (uint256 i = 0; i < pid; ) {
            pools[i] = pidToPoolAddress[i];
            unchecked {
                ++i;
            }
        }

        return pools;
    }

    /**
     * @notice Retrieves a slice of pools.
     * @dev Used for off-chain data retrieval.
     * @param _from The starting pool id (inclusive).
     * @param _to The ending pool id (exclusive).
     * @return an array of pool addresses.
     */
    function getAllPoolsSlice(uint256 _from, uint256 _to)
        external
        view
        returns (address[] memory)
    {
        require(_to >= _from && _to <= pid, "Factory::slice out of range");

        address[] memory pools = new address[](_to - _from);

        for (uint256 i = _from; i < _to; ) {
            pools[i] = pidToPoolAddress[i];
            unchecked {
                ++i;
            }
        }

        return pools;
    }

    /**
     * @notice Verifies that pool assets are valid.
     * They must be unique, nonzero and have 18 or less decimals.
     * @dev The decimal check also checks (loosely) that the assets conform to the ERC20 standard.
     * May throw if the address does not have a decimals function.
     * @param _collateralAssets An array of ERC20 token addresses to be used as collateral.
     * @param _lentAsset The address of the ERC20 token which is lent.
     * @return true if the assets are valid or false if the checks fail.
     */
    function _assetsAreValid(
        address[] memory _collateralAssets,
        address _lentAsset
    ) private view returns (bool) {
        if (_lentAsset == address(0)) {
            return false;
        }

        uint256 len = _collateralAssets.length;
        for (uint256 i = 0; i < len; ) {
            address collateralAsset = _collateralAssets[i];
            if (
                collateralAsset == address(0) ||
                collateralAsset == _lentAsset ||
                ERC20(collateralAsset).decimals() > 18
            ) {
                return false;
            }
            for (uint256 j = 0; j < i; ) {
                if (collateralAsset == _collateralAssets[j]) {
                    return false;
                }
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        return ERC20(_lentAsset).decimals() <= 18;
    }

    /**
     * @notice Private function that transfers specific amount of `_asset`
     * and performs checks before and after the execution of the transfer
     * by which is calculated the the maximum supply.
     * @param _asset The address of the token transfer.
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _amt The amount to be transferred.
     * @return uint256 The value extracted from the difference between pre
     * and post transfer.
     */
    function _executeTransferFromWithBalanceChecks(
        IERC20 _asset,
        address _from,
        address _to,
        uint256 _amt
    ) private returns (uint256) {
        // Perform balance check before the transfer ot the asset
        uint256 balanceBeforeTransfer = _asset.balanceOf(_to);

        // Execute transfer ot the asset
        _asset.safeTransferFrom(_from, _to, _amt);

        // Perform balance check after the transfer ot the asset
        uint256 balanceAfterTransfer = _asset.balanceOf(_to);

        // Return the real transferred amount
        return balanceAfterTransfer - balanceBeforeTransfer;
    }
}