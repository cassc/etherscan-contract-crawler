// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;
/**
 * @title VestingFactory
 *
 * @notice This contract allows the owner to create, initialize and manage vesting pools with specified percentage
 * shares and names. The total percentage share of all pools cannot exceed 100%.
 *
 * @dev The contract uses OpenZeppelin's Ownable, SafeERC20, and IERC20 libraries.
 */

import "./VestingPool.sol";
import "./interface/IVestingFactory.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VestingFactory is Ownable, IVestingFactory {
    /**
     * @dev Mapping to store information about each vesting pool, with the address of the pool contract as the key and a
     * PoolInfo struct as the value.
     */
    mapping(address => PoolInfo) private _pools;
    /**
     * @dev Total percentage of the token held by all vesting pools combined.
     */
    uint256 public poolTotalPercent = 0;
    /**
     * @dev Total token distributed to the vesting pools.
     */
    uint256 public totalDistributed;
    /**
     * @dev Address of the token for vesting.
     */
    address public constant token = 0x37C997B35C619C21323F3518B9357914E8B99525;
    /**
     * @dev Immutable reference to the token being used in the vesting pools.
     */
    IERC20 private immutable _token;
    /**
     * @dev Maximum percentage allowed for a single vesting pool.
     */
    uint256 private _maxPercentage = 100e18;
    /**
     * @dev Modifier to check that the overall percentage share for a new vesting pool does not exceed 100%.
     */

    modifier checkPercent(uint256 poolShare) {
        if (poolShare == 0) revert InvalidPoolShare();
        if (poolTotalPercent + poolShare > _maxPercentage) revert PoolAmountExceeded();
        _;
    }
    /**
     * @notice Creates a new VestingFactory contract instance.
     */

    constructor() Ownable() {
        _token = IERC20(token);
    }
    /**
     * @notice Creates a new vesting pool with the specified parameters.
     * @param poolShare The percentage share to be allotted for the pool.
     * @param poolName The name of the pool.
     * @return poolAddress The address of the created pool.
     */

    function createPool(
        uint256 poolShare,
        string memory poolName
    )
        external
        onlyOwner
        checkPercent(poolShare)
        returns (address)
    {
        address poolAddress = address(
            new VestingPool{
                salt: keccak256(
                    abi.encodePacked(
                        poolShare,
                        address(this),
                        poolName
                    )
                )
            }(msg.sender)
        );
        poolTotalPercent += poolShare;
        _pools[poolAddress] = PoolInfo(poolShare, 0, poolName);
        emit PoolCreated(poolAddress, poolShare, poolName);
        return poolAddress;
    }
    /**
     * @dev Initializes a vesting pool by transferring the required tokens to the pool contract.
     * @param pool The address of the vesting pool contract to be initialized.
     * @notice The vesting pool must have been created before it can be initialized.
     * @notice The pool must have a positive percentage share and the contract must have enough tokens to initialize the
     * pool.
     */

    function initPool(address pool, uint256 amount) external onlyOwner {
        PoolInfo storage poolInfo = _pools[pool];
        if (poolInfo.poolShare == 0) revert InvalidPoolAddress();
        if (balanceOf() == 0) revert InsufficientTokenAmounts();
        poolInfo.poolAmount = _getPoolShareAmount(poolInfo.poolShare, amount);
        _token.transfer(pool, poolInfo.poolAmount);
        totalDistributed += poolInfo.poolAmount;
        emit PoolInitialized(pool, poolInfo.poolShare, poolInfo.poolAmount);
    }

    /**
     * @dev Recovers ERC20 tokens that were mistakenly sent to the contract.
     * @param tokenAddress The address of the ERC20 token to be recovered.
     * @param tokenAmount The amount of tokens to be recovered.
     * @notice Only the contract owner can recover ERC20 tokens.
     */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }
    /**
     * @dev Returns the PoolInfo struct of a given vesting pool.
     * @param pool The address of the vesting pool contract to get information about.
     * @return The PoolInfo struct of the given vesting pool.
     */

    function getPoolInfo(address pool) external view returns (PoolInfo memory) {
        return _pools[pool];
    }
    /**
     * @dev Returns the balance of the token held by the contract.
     * @return The balance of the token held by the contract.
     */

    function balanceOf() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
    /**
     * @dev Calculates the amount of tokens to be held by a vesting pool based on its percentage share.
     * @param poolShare The percentage share of the token to be alloted for the pool.
     * @return The amount of tokens to be held by the vesting pool.
     */

    function _getPoolShareAmount(uint256 poolShare, uint256 amount) private view returns (uint256) {
        return amount * poolShare / _maxPercentage;
    }
}