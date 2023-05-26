/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

pragma solidity >=0.6.0;

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

pragma solidity ^0.8.7;

contract StakingHelper {
    struct Stake {
        uint256 id;
        uint256 stakedAmount;
        uint256 lockingPeriod;
        uint256 unlockTime;
        uint256 rewardAllocation;
    }

    mapping(address => Stake[]) private stakes;

    function addStake(address address_, Stake memory stake_) internal {
        stakes[address_].push(stake_);
    }

    function getStakeIDs(address user) public view returns (uint256[] memory) {
        uint256[] memory stakeIDs = new uint256[](stakes[user].length);

        for (uint256 i = 0; i < stakes[user].length; i++) {
            stakeIDs[i] = stakes[user][i].id;
        }

        return stakeIDs;
    }

    function getStakeOfUserById(address user, uint256 stakeId) public view returns (Stake memory) {
        Stake[] memory userStakes = stakes[user];

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].id == stakeId) {
                return userStakes[i];
            }
        }

        revert("Stake not found");
    }

    function removeStakeById(address address_, uint256 stakeId) internal {
        Stake[] storage userStakes = stakes[address_];

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (userStakes[i].id == stakeId) {
                // Move the last stake to the position of the stake to be removed
                userStakes[i] = userStakes[userStakes.length - 1];
                userStakes.pop();

                return;
            }
        }

        revert("Stake not found");
    }
}

pragma solidity ^0.8.7;

contract WeweStaking is StakingHelper, Ownable {
    address WeweErc20Address = 0x1e917e764BC34d3BC313fe8159a6bD9d9FFD450d;
    uint256 decimals = 18;
    uint256 totalSupply = 420690000000 * 10 ** decimals;
    uint256 stakingSupply = totalSupply * 5 /100;
    uint256 public stakedPool = 0;
    uint256 public rewardsPool = 0;
    uint256 public claimedPool = 0;
    uint256 oneYear = 365 days;
    uint256 private nonce;
    bool public active = false;

    function setWeweAddress(address address_) public onlyOwner {
        WeweErc20Address = address_;
    }

    function stake(uint256 amount, uint256 lockingPeriod) public {
        require(lockingPeriod == 0 || lockingPeriod == 1 || lockingPeriod == 2 || lockingPeriod == 3, "Invalid locking period.");
        uint256 amountDecimals = amount * 10 ** decimals;
        require(active, "Contract is not active");
        require(currentPool() > 0, "No funds in pool");
        require(IERC20(WeweErc20Address).balanceOf(msg.sender) >= amountDecimals, "Insufficient balance of caller");
        require(IERC20(WeweErc20Address).allowance(msg.sender, address(this)) >= amountDecimals, "Allowance not set for this contract.");
        
        uint256 rewardAllocation = calculateRewards(amount, lockingPeriod);
        require(rewardAllocation <= currentPool(), "Rewards exceed current pool");

        TransferHelper.safeTransferFrom(WeweErc20Address, msg.sender, address(this), amountDecimals);

        Stake memory newStake = Stake(getRandomID(), amountDecimals, lockingPeriod, block.timestamp + getLockingDuration(lockingPeriod), rewardAllocation);
        addStake(msg.sender, newStake);

        stakedPool = stakedPool + amountDecimals;
        rewardsPool = rewardsPool + rewardAllocation;
    }

    
    function claim(uint256 stakeId) public {
        require(active, "Contract is not active");
        Stake memory stake_ = getStakeOfUserById(msg.sender, stakeId);
        require(block.timestamp >= stake_.unlockTime, "Stake cannot be unlocked before locking period.");
        require(IERC20(WeweErc20Address).balanceOf(address(this)) >= (stake_.rewardAllocation + stake_.stakedAmount), "Amount is greater than contract balance.");
        TransferHelper.safeTransfer(WeweErc20Address, msg.sender, (stake_.rewardAllocation + stake_.stakedAmount));
        stakedPool = stakedPool - stake_.stakedAmount;
        rewardsPool = rewardsPool - stake_.rewardAllocation;
        claimedPool = claimedPool + stake_.rewardAllocation;
        removeStakeById(msg.sender, stake_.id);
    }

    function currentPool() public view returns (uint256) {
        return stakingSupply - (rewardsPool + claimedPool);
    }

    function calculateRewards(uint256 amount, uint256 lockingPeriod) public view returns (uint256) {
        uint256 apyMultiplier = getLockingApyMultiplier(lockingPeriod);
        uint256 lockingDuration = getLockingDuration(lockingPeriod); 

        uint256 amountDecimals = amount * 10 ** decimals;
        uint256 rewardsAllocation = amountDecimals  * lockingDuration * apyMultiplier * currentPool() / (oneYear * 100 * stakingSupply * 10);
        return rewardsAllocation;
    }

    function calculateApy(uint256 amount, uint256 lockingPeriod) public view returns (uint256) {
        uint256 rewards = calculateRewards(amount, lockingPeriod);
        uint256 lockingDuration = getLockingDuration(lockingPeriod); 

        uint256 amountDecimals = amount * 10 ** decimals;
        uint256 apy = rewards * oneYear * 100 * 100 / (amountDecimals * lockingDuration);
        return apy;
    }

    function getLockingApyMultiplier(uint256 lockingPeriod) internal pure returns (uint256) {
        return getLockingDetails(lockingPeriod)[0];
    }

    function getLockingDuration(uint256 lockingPeriod) public pure returns (uint256) {
        return getLockingDetails(lockingPeriod)[1];
    }

    function getLockingDetails(uint256 lockingPeriod) internal pure returns (uint256[2] memory) {
        uint256 initial = 60;
        uint256[2] memory lockingDetails;

        if (lockingPeriod == 0) {
            lockingDetails[0] = initial * 5;
            lockingDetails[1] = 3 days;
        } else if (lockingPeriod == 1) {
            lockingDetails[0] = initial * 7;
            lockingDetails[1] = 15 days;
        } else if (lockingPeriod == 2) {
            lockingDetails[0] = initial * 10;
            lockingDetails[1] = 30 days;
        } else if (lockingPeriod == 3) {
            lockingDetails[0] = initial * 20;
            lockingDetails[1] = 90 days;
        }

        return lockingDetails;
    }

    function getRandomID() internal returns (uint256) {
        nonce++;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, nonce)));
        return randomNumber;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address to, uint256 amount, address token_) public onlyOwner {
        IERC20 erc20 = IERC20(token_);
        require(amount <= erc20.balanceOf(address(this)), "Amount exceeds balance.");
        TransferHelper.safeTransfer(token_, to, amount);
    }

    function flipActive() public onlyOwner {
        active = !active;
    }

}