// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Constants.sol";
import { PoolParams } from "./interfaces/Types.sol";
import "./interfaces/IVestingPools.sol";
import "./utils/Claimable.sol";
import "./utils/DefaultOwnable.sol";
import { DefaultOwnerAddress, TokenAddress, VestingPoolsAddress } from "./utils/Linking.sol";
import "./utils/ProxyFactory.sol";
import "./utils/SafeUints.sol";

/**
 * @title PoolStakes
 * @notice The contract claims (ERC-20) token from the "VestingPools" contract
 * and then let "stakeholders" withdraw token amounts prorate to their stakes.
 * @dev A few copy of this contract (i.e. proxies created via the {createProxy}
 * method) are supposed to run. Every proxy distributes its own "vesting pool",
 * so it (the proxy) must be registered with the "VestingPools" contract as the
 * "wallet" for that "vesting pool".
 */
contract PoolStakes is
    Claimable,
    SafeUints,
    ProxyFactory,
    DefaultOwnable,
    Constants
{
    // @dev "Stake" of a "stakeholder" in the "vesting pool"
    struct Stake {
        // token amount allocated for the stakeholder
        uint96 allocated;
        // token amount released to the stakeholder so far
        uint96 released;
    }

    /// @notice ID of the vesting pool this contract is the "wallet" for
    uint16 public poolId;
    /// @notice Token amount the vesting pool is set to vest
    uint96 public allocation;
    /// @notice Token amount allocated from {allocation} to stakeholders so far
    /// @dev It is the total amount of all {stakes[..].allocated}
    uint96 public allocated;

    /// @notice Token amount released to stakeholders so far
    /// @dev It is the total amount of all {stakes[..].released}
    uint96 public released;
    /// @notice Share of vested amount attributable to 1 unit of {allocation}
    /// @dev Stakeholder "h" may withdraw from the contract this token amount:
    ///     factor/SCALE * stakes[h].allocated - stakes[h].released
    uint160 public factor;

    // mapping from stakeholder address to stake
    mapping(address => Stake) public stakes;

    event VestingClaimed(uint256 amount);
    event Released(address indexed holder, uint256 amount);
    event StakeAdded(address indexed holder, uint256 allocated);
    event StakeSplit(
        address indexed holder,
        uint256 allocated,
        uint256 released
    );

    /// @notice Returns address of the token being vested
    function token() external view returns (address) {
        return address(_getToken());
    }

    /// @notice Returns address of the {VestingPool} smart contract
    function vestingPools() external view returns (address) {
        return address(_getVestingPools());
    }

    /// @notice Returns token amount the specified stakeholder may withdraw now
    function releasableAmount(address holder) external view returns (uint256) {
        Stake memory stake = _getStake(holder);
        return _releasableAmount(stake, uint256(factor));
    }

    /// @notice Returns token amount the specified stakeholder may withdraw now
    /// on top of the {releasableAmount} should {claimVesting} be called
    function unclaimedShare(address holder) external view returns (uint256) {
        Stake memory stake = _getStake(holder);
        uint256 unclaimed = _getVestingPools().releasableAmount(poolId);
        return (unclaimed * uint256(stake.allocated)) / allocation;
    }

    /// @notice Claims vesting to this contract from the vesting pool
    function claimVesting() external {
        _claimVesting();
    }

    /////////////////////
    //// StakeHolder ////
    /////////////////////

    /// @notice Sends the releasable amount to the message sender
    /// @dev Stakeholder only may call
    function withdraw() external {
        _withdraw(msg.sender); // throws if msg.sender is not a stakeholder
    }

    /// @notice Calls {claimVesting} and sends the releasable amount to the message sender
    /// @dev Stakeholder only may call
    function claimAndWithdraw() external {
        _claimVesting();
        _withdraw(msg.sender); // throws if msg.sender is not a stakeholder
    }

    /// @notice Allots a new stake out of the stake of the message sender
    /// @dev Stakeholder only may call
    function splitStake(address newHolder, uint256 newAmount) external {
        address holder = msg.sender;
        require(newHolder != holder, "PStakes: duplicated address");

        Stake memory stake = _getStake(holder);
        require(newAmount <= stake.allocated, "PStakes: too large allocated");

        uint256 updAmount = uint256(stake.allocated) - newAmount;
        uint256 updReleased = (uint256(stake.released) * updAmount) /
            uint256(stake.allocated);
        stakes[holder] = Stake(_safe96(updAmount), _safe96(updReleased));
        emit StakeSplit(holder, updAmount, updReleased);

        uint256 newVested = uint256(stake.released) - updReleased;
        stakes[newHolder] = Stake(_safe96(newAmount), _safe96(newVested));
        emit StakeSplit(newHolder, newAmount, newVested);
    }

    //////////////////
    //// Owner ////
    //////////////////

    /// @notice Inits the contract and adds stakes
    /// @dev Owner only may call on a proxy (but not on the implementation)
    function addStakes(
        uint256 _poolId,
        address[] calldata holders,
        uint256[] calldata allocations,
        uint256 unallocated
    ) external onlyOwner {
        if (allocation == 0) {
            _init(_poolId);
        } else {
            require(_poolId == poolId, "PStakes: pool mismatch");
        }

        uint256 nEntries = holders.length;
        require(nEntries == allocations.length, "PStakes: length mismatch");
        uint256 updAllocated = uint256(allocated);
        for (uint256 i = 0; i < nEntries; i++) {
            _throwZeroHolderAddress(holders[i]);
            require(
                stakes[holders[i]].allocated == 0,
                "PStakes: holder exists"
            );
            require(allocations[i] > 0, "PStakes: zero allocation");

            updAllocated += allocations[i];
            stakes[holders[i]] = Stake(_safe96(allocations[i]), 0);
            emit StakeAdded(holders[i], allocations[i]);
        }
        require(
            updAllocated + unallocated == allocation,
            "PStakes: invalid allocation"
        );
        allocated = _safe96(updAllocated);
    }

    /// @notice Calls {claimVesting} and sends releasable tokens to specified stakeholders
    /// @dev Owner may call only
    function massWithdraw(address[] calldata holders) external onlyOwner {
        _claimVesting();
        for (uint256 i = 0; i < holders.length; i++) {
            _withdraw(holders[i]);
        }
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev Owner may call only
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20 vestedToken = IERC20(address(_getToken()));
        if (claimedToken == address(vestedToken)) {
            uint256 balance = vestedToken.balanceOf(address(this));
            require(
                balance - amount >= allocation - released,
                "PStakes: too big amount"
            );
        }
        _claimErc20(claimedToken, to, amount);
    }

    /// @notice Removes the contract from blockchain when tokens are released
    /// @dev Owner only may call on a proxy (but not on the implementation)
    function removeContract() external onlyOwner {
        // avoid accidental removing of the implementation
        _throwImplementation();

        require(allocation == released, "PStakes: unpaid stakes");

        IERC20 vestedToken = IERC20(address(_getToken()));
        uint256 balance = vestedToken.balanceOf(address(this));
        require(balance == 0, "PStakes: non-zero balance");

        selfdestruct(payable(msg.sender));
    }

    //////////////////
    //// Internal ////
    //////////////////

    /// @dev Returns the address of the default owner
    // (declared `view` rather than `pure` to facilitate testing)
    function _defaultOwner() internal view virtual override returns (address) {
        return address(DefaultOwnerAddress);
    }

    /// @dev Returns Token contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getToken() internal view virtual returns (IERC20) {
        return IERC20(address(TokenAddress));
    }

    /// @dev Returns VestingPools contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getVestingPools() internal view virtual returns (IVestingPools) {
        return IVestingPools(address(VestingPoolsAddress));
    }

    /// @dev Returns the stake of the specified stakeholder reverting on errors
    function _getStake(address holder) internal view returns (Stake memory) {
        _throwZeroHolderAddress(holder);
        Stake memory stake = stakes[holder];
        require(stake.allocated != 0, "PStakes: unknown stake");
        return stake;
    }

    /// @notice Initialize the contract
    /// @dev May be called on a proxy only (but not on the implementation)
    function _init(uint256 _poolId) internal {
        _throwImplementation();
        require(_poolId < 2**16, "PStakes:unsafePoolId");

        IVestingPools pools = _getVestingPools();
        address wallet = pools.getWallet(_poolId);
        require(wallet == address(this), "PStakes:invalidPool");
        PoolParams memory pool = pools.getPool(_poolId);
        require(pool.sAllocation != 0, "PStakes:zeroPool");

        poolId = uint16(_poolId);
        allocation = _safe96(uint256(pool.sAllocation) * SCALE);
    }

    /// @dev Returns amount that may be released for the given stake and factor
    function _releasableAmount(Stake memory stake, uint256 _factor)
        internal
        pure
        returns (uint256)
    {
        uint256 share = (_factor * uint256(stake.allocated)) / SCALE;
        if (share > stake.allocated) {
            // imprecise division safeguard
            share = uint256(stake.allocated);
        }
        return share - uint256(stake.released);
    }

    /// @dev Claims vesting to this contract from the vesting pool
    function _claimVesting() internal {
        // (reentrancy attack impossible - known contract called)
        uint256 justVested = _getVestingPools().release(poolId, 0);
        factor += uint160((justVested * SCALE) / uint256(allocation));
        emit VestingClaimed(justVested);
    }

    /// @dev Sends the releasable amount of the specified placeholder
    function _withdraw(address holder) internal {
        Stake memory stake = _getStake(holder);
        uint256 releasable = _releasableAmount(stake, uint256(factor));
        require(releasable > 0, "PStakes: nothing to withdraw");

        stakes[holder].released = _safe96(uint256(stake.released) + releasable);
        released = _safe96(uint256(released) + releasable);

        // (reentrancy attack impossible - known contract called)
        require(_getToken().transfer(holder, releasable), "PStakes:E1");
        emit Released(holder, releasable);
    }

    function _throwZeroHolderAddress(address holder) private pure {
        require(holder != address(0), "PStakes: zero holder address");
    }
}