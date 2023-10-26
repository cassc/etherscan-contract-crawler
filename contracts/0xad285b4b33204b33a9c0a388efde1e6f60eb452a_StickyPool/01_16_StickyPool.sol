pragma solidity 0.8.6;

/**
* @title Sticky Pool V1.1:
*
*              ,,,,
*            g@@@@@@K
*           l@@@@@@@@P
*            $@@@@@@@"                   l@@@  l@@@
*             "*NNM"                     l@@@  l@@@
*                                        l@@@  l@@@
*             ,g@@@g        ,,gg@gg,     l@@@  l@@@ ,ggg          ,ggg
*            @@@@@@@@p    g@@@EEEEE@@W   l@@@  l@@@  $@@g        ,@@@Y
*           l@@@@@@@@@   @@@P      ]@@@  l@@@  l@@@   $@@g      ,@@@Y
*           l@@@@@@@@@  $@@D,,,,,,,,]@@@ l@@@  l@@@   '@@@p     @@@Y
*           l@@@@@@@@@  @@@@EEEEEEEEEEEE l@@@  l@@@    "@@@p   @@@Y
*           l@@@@@@@@@  l@@K             l@@@  l@@@     '@@@, @@@Y
*            @@@@@@@@@   %@@@,    ,g@@@  l@@@  l@@@      ^@@@@@@Y
*            "@@@@@@@@    "N@@@@@@@@E'   l@@@  l@@@       "*@@@Y
*             "J@@@@@@        "**""       '''   '''        @@@Y
*    ,gg@@g    "J@@@P                                     @@@Y
*   @@@@@@@@p    J@@'                                    @@@Y
*   @@@@@@@@P    J@h                                    RNNY
*   'B@@@@@@     $P
*       "JE@@@p"'
*
*
*/

/**
* @author ProfWobble
* @dev
* - Staking Contract with veNFTs:
*   - Votes have a weight depending on time.
*   - Vote weight decays linearly over time. 
*   - Lock time cannot be more than `MAXTIME` (4 years).
*   - NFT attributes onchain via the descriptor.
*
* - Votes have a weight depending on time, so that users are committed
*   to the future of (whatever they are voting for).
* - The weight in this implementation is linear, and lock cannot be more than maxtime:
*
*  w ^
*  1 +        /
*    |      /
*    |    /
*    |  /
*    |/
*  0 +--------+------> time
*         maxtime (4 years?)
*
* @dev Based on Curve's Voting Escrow contracts
* @dev Based on Solidly and Frax ve contracts
* @author Curve Finance
*/

// TODO
// Add current and next period start timestamps

import "StickyPoolNFT.sol";
import "Base64.sol";
import { BoringMath } from "BoringMath.sol";
import "IERC20.sol";
import "IDescriptor.sol";
import "IJellyContract.sol";
import "IJellyAccessControls.sol";
import "IStickyPool.sol";
import "IJellyDocuments.sol";

import { Strings } from "Strings.sol";

interface IAddressChecker {
    function check(address) external returns (bool);
}

contract StickyPool is IJellyContract, IStickyPool, StickyPoolNFT {
    using Strings for uint256;
    using Strings for address;

    /// @notice Jelly template id for the pool factory.
    /// @dev For different pool types, this must be incremented.
    uint256 public override constant TEMPLATE_TYPE = 2;
    bytes32 public override constant TEMPLATE_ID = keccak256("STICKY_POOL");

    IJellyAccessControls public accessControls;
    IDescriptor public descriptor;
    IJellyDocuments public documents;
    IAddressChecker public checker;

    /// @notice Token to stake.
    address public override poolToken;

    struct PoolSettings {
        bool initialised;
        bool emergencyUnlockActive;
        bool transfersEnabled;
    }
    PoolSettings public poolSettings;

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    event Deposit(
        address indexed provider,
        uint tokenId,
        uint value,
        uint indexed locktime,
        DepositType deposit_type,
        uint ts
    );

    struct Point {
        int128 bias;
        int128 slope; //  -dweight / dt
        uint40 ts;
        uint40 blk; // block
        uint128 amt; // staked amount
    }

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    uint internal constant WEEK = 7 * 86400;
    uint internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint internal constant MULTIPLIER = 1 ether;
    uint internal constant VOTE_WEIGHT_MULTIPLIER =  4 - 1; // 4x gives 300% boost at 4 years
    int128 internal constant VOTE_WEIGHT_MULTIPLIER_I128 =  4 - 1; // 4x gives 300% boost at 4 years

    uint public supply;
    uint public epoch;

    mapping(uint => LockedBalance) public locked;
    mapping(uint => Point) public point_history; // epoch -> unsigned point
    mapping(uint => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]

    mapping(uint => uint) public user_point_epoch;
    mapping(uint => int128) public slope_changes; // time -> signed slope change

    mapping(uint => uint) public attachments;
    mapping(uint => bool) public voted;

    address public voter;
    address public owner;

    event Withdraw(address indexed provider, uint tokenId, uint value, uint ts);
    event Supply(uint prevSupply, uint supply);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state;

    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }

    constructor() {
    }


    //--------------------------------------------------------
    // Getters
    //-------------------------------------------------------- 
    /**
     * @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
     * @param _tokenId token of the NFT
     * @return Value of the slope
     */
    function get_last_user_slope(uint _tokenId) external view returns (int128) {
        uint uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch].slope;
    }
    /**
     * @notice Get the most recently recorded Point for `_tokenId`
     * @param _tokenId TokenId of the NFT
     * @return Latest Point for the tokenId
     */
    function get_last_user_point(uint _tokenId) external view returns (Point memory) {
        uint uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch];
    }
    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
     * @param _tokenId token of the NFT
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function user_point_history__ts(uint _tokenId, uint _idx) external view returns (uint) {
        return uint256(user_point_history[_tokenId][_idx].ts);
    }
    /**
     * @notice Get timestamp when `_tokenId`'s lock finishes
     * @param _tokenId User NFT
     * @return Epoch time of the lock end
     */
    function locked__end(uint _tokenId) external view returns (uint) {
        return locked[_tokenId].end;
    }
    /**
     * @notice Returns the owner address for Aragon compatability.
     * @return Controller address
    */
    function controller() external view returns (address) {
        return owner;
    }

    /**
     * @notice Setting for enabling NFT transfers.
     * @return Returns if transfers are enabled.
     */
    function transfersEnabled() external view returns (bool) {
        return poolSettings.transfersEnabled;
    }
    /**
     * @notice Get timestamp of current period
     */
    function curr_period_start() external view returns (uint) {
        return (block.timestamp / WEEK) * WEEK;
    }



    //--------------------------------------------------------
    // Setters
    //-------------------------------------------------------- 

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the admin.
     */
    function setDescriptor(address _descriptor) external {
        require(accessControls.hasAdminRole(msg.sender));
        descriptor = IDescriptor(_descriptor);
    }

    /**
     * @notice Set admin details of the NFT including token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTokenDetails(string memory _name, string memory _symbol) external {
        require(accessControls.hasAdminRole(msg.sender));
        name = _name;
        symbol = _symbol;
    }

    /**
     * @notice Set owner details for NFT and Aragon compatibility.
     * @dev Only callable by the admin.
     * @dev Doesnt actually control, control managed by accessControls
     */
    function changeController(address _owner) external {
        require(accessControls.hasAdminRole(msg.sender));
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    /**
     * @notice Admin can set the address checker contract.
     * @param _checker Address of the checker contract.
     * @dev Only callable by the admin.
     */
    function setAddressChecker(address _checker) external {
        require(accessControls.hasAdminRole(msg.sender));
        checker = IAddressChecker(_checker);
    }

    /**
     * @notice Set admin details of the NFT including owner, token name and symbol.
     * @dev Only callable by the admin.
     */
    function setTransfersEnabled(bool _enabled) external {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.transfersEnabled = _enabled;
    }

    //--------------------------------------------------------
    // Locks
    //--------------------------------------------------------
    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
     * @param _value Amount to deposit
     * @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
     */
    function create_lock(uint _value, uint _lock_duration) external nonreentrant returns (uint) {
        return _create_lock(_value, _lock_duration, msg.sender);
    }

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
     * @param _value Amount to deposit
     * @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
     * @param _to Address to deposit
     */
    function create_lock_for(uint _value, uint _lock_duration, address _to) external nonreentrant returns (uint) {
        return _create_lock(_value, _lock_duration, _to);
    }

    /**
     * @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
     * @param _value Amount to deposit
     * @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
     * @param _to Address to deposit
     */
    function _create_lock(uint _value, uint _lock_duration, address _to) internal returns (uint) {
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_value > 0, "Value must be > 0");
        require(unlock_time > block.timestamp, 'Cannot unlock in the past');
        require(unlock_time <= block.timestamp + MAXTIME, 'Voting lock can be 4 years max');

        ++tokenId;
        uint _tokenId = tokenId;
        _mint(_to, _tokenId);

        _deposit_for(_tokenId, _value, unlock_time, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /**
     * @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint _tokenId, uint _value) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0, "Value must be > 0");
        require(_locked.amount > 0, 'No existing lock found');
        require(_locked.end > block.timestamp, 'Expired lock. Withdraw');

        _deposit_for(_tokenId, _value, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /**
     * @notice Extend the unlock time for `_tokenId`
     * @param _lock_duration New number of seconds until tokens unlock
     */
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, 'Lock expired');
        require(_locked.amount > 0, 'Nothing is locked');
        require(unlock_time > _locked.end, 'Can only increase duration');
        require(unlock_time <= block.timestamp + MAXTIME, 'Voting lock is 4 years max');

        _deposit_for(_tokenId, 0, unlock_time, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }


    //--------------------------------------------------------
    // Deposit
    //--------------------------------------------------------
    /**
     * @notice Deposit and lock tokens for a user
     * @param _tokenId NFT that holds lock
     * @param _value Amount to deposit
     * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
     * @param locked_balance Previous locked amount / timestamp
     * @param deposit_type The type of deposit
     */
    function _deposit_for(
        uint _tokenId,
        uint _value,
        uint unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        address from = msg.sender;
        _checkAddress(from);
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (_locked.amount, _locked.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_tokenId] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, old_locked, _locked);

        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE) {
            assert(IERC20(poolToken).transferFrom(from, address(this), _value));
        }

        emit Deposit(from, _tokenId, _value, _locked.end, deposit_type, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    /**
     * @notice Merge two tokens for a user
     * @param _from NFT that will be burnt
     * @param _to NFT that will have been merged
     */
    function merge(uint _from, uint _to) external nonreentrant {
        require(attachments[_from] == 0 && !voted[_from], "attached");
        require(_from != _to);
        require(_isApprovedOrOwner(msg.sender, _from));
        require(_isApprovedOrOwner(msg.sender, _to));

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];
        uint value0 = uint(int256(_locked0.amount));
        uint end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

        locked[_from] = LockedBalance(0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0));
        _burn(_from);
        _deposit_for(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
    }

    //--------------------------------------------------------
    // Withdraw
    //--------------------------------------------------------
    /**
     * @notice Withdraw all tokens for `_tokenId`
     * @dev Only possible if the lock has expired
     */
    function withdraw(uint _tokenId) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");

        LockedBalance memory _locked = locked[_tokenId];
        require(block.timestamp >= _locked.end || poolSettings.emergencyUnlockActive, "The lock didn't expire");
        uint value = uint(int256(_locked.amount));

        locked[_tokenId] = LockedBalance(0,0);
        uint supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(0,0));

        assert(IERC20(poolToken).transfer(msg.sender, value));

        // Burn the NFT
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    /**
     * @notice Enables early unlock for contract migration
     * @dev Only callable by admin
     */
    function setEmergencyUnlockActive(bool _active) external {
        require(accessControls.hasAdminRole(msg.sender));
        poolSettings.emergencyUnlockActive = _active;
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
        // emit EmergencyUnlockToggled(_active);
    }

    //--------------------------------------------------------
    // Token Balances
    //--------------------------------------------------------
    /**
     * @notice Total voting power
     */
    function totalSupply() external view returns (uint) {
        return totalSupplyAtT(block.timestamp);
    }
    /**
     * @notice Total voting power of user based on held tokens
     * @param _user User with tokens
     */
    function voterBalance(address _user) external view returns (uint256) {
        uint256[] memory tokenIds = getOwnerTokens(_user);
        uint256 votes = 0;
        if (tokenIds.length > 0) {
            for(uint i = 0; i < tokenIds.length; i++) {
                if (ownership_change[tokenIds[i]] != block.number) {
                    votes += _balanceOfNFT(tokenIds[i], block.timestamp);
                }
            }
        }
        return votes;
    }

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function stakedBalance(uint256 _tokenId) external override view returns(uint256) {
        return uint256(int256(locked[_tokenId].amount));
    }

    function balanceOfNFT(uint _tokenId) external view returns (uint) {
        if (ownership_change[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint) {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint) {
        return _balanceOfNFT(_tokenId, _t);
    }

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupplyAtT(uint t) public view returns (uint) {
        uint _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return _supply_at(last_point, t);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint _block) external view returns (uint) {
        assert(_block <= block.number);
        uint _epoch = epoch;
        uint target_epoch = _find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint dt = 0;
        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
            }
        } else {
            if (uint256(point.blk) != block.number) {
                dt = ((BoringMath.to40(_block) - point.blk) * (BoringMath.to40(block.timestamp) - point.ts)) / (BoringMath.to40(block.number) - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supply_at(point, uint256(point.ts + dt));
    }

    /**
     * @notice Get the current voting power for `_tokenId`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _tokenId NFT for lock
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function _balanceOfNFT(uint _tokenId, uint _t) internal view returns (uint) {
        uint _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[_tokenId][_epoch];
            last_point.bias -= last_point.slope * int128(int256(_t) - int256(uint256(last_point.ts)));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            uint128 weighted_supply = uint128(last_point.bias);
            if (weighted_supply < last_point.amt) {
                weighted_supply = last_point.amt;
            }
            return uint256(weighted_supply);
        }
    }

    /**
     * @notice Measure voting power of `_tokenId` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param _tokenId User's wallet NFT
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function _balanceOfAtNFT(uint _tokenId, uint _block) internal view returns (uint) {

        assert(_block <= block.number);

        // Binary search
        uint _min = 0;
        uint _max = user_point_epoch[_tokenId];
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (user_point_history[_tokenId][_mid].blk <= BoringMath.to40(_block)) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        Point memory upoint = user_point_history[_tokenId][_min];
        uint max_epoch = epoch;
        uint _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint40 d_block = 0;
        uint40 d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = BoringMath.to40(block.number) - point_0.blk;
            d_t = BoringMath.to40(block.timestamp) - point_0.ts;
        }
        uint40 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (BoringMath.to40(_block) - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(uint256(block_time - upoint.ts)));

        if (upoint.bias >= 0 || upoint.amt >= 0 ) {
            return uint(uint128(upoint.bias));
        } else {
            return 0;
        }
    }


    //--------------------------------------------------------
    // Checkpoint
    //--------------------------------------------------------
    /**
     * @notice Checkpoint global data
     */
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }
    /**
     * @notice Record global and per-user data to checkpoint
     * @param _tokenId NFT token ID. No user checkpoint if 0
     * @param old_locked Pevious locked amount / end lock time for the user
     * @param new_locked New locked amount / end lock time for the user
     */
    function _checkpoint(
        uint _tokenId,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = (old_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / iMAXTIME;
                u_old.bias = old_locked.amount + (u_old.slope * int128(int256(old_locked.end - block.timestamp)));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = (new_locked.amount * VOTE_WEIGHT_MULTIPLIER_I128) / iMAXTIME;
                u_new.bias = new_locked.amount + (u_new.slope * int128(int256(new_locked.end - block.timestamp)));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: BoringMath.to40(block.timestamp), blk: BoringMath.to40(block.number), amt: 0});
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }

        uint last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint block_slope = 0; // dblock/dt
        if (block.timestamp > uint256(last_point.ts)) {
            block_slope = (MULTIPLIER * (block.number - uint256(last_point.blk))) / (block.timestamp - uint256(last_point.ts));
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = BoringMath.to40(t_i);
                last_point.blk = initial_last_point.blk + BoringMath.to40((block_slope * (t_i - uint256(initial_last_point.ts))) / MULTIPLIER);
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = BoringMath.to40(block.number);
                    break;
                } else {
                    point_history[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (new_locked.amount > old_locked.amount) {
                last_point.amt += BoringMath.to128(uint256(int256(new_locked.amount - old_locked.amount)));
            }
            if (new_locked.amount < old_locked.amount) {
                last_point.amt -= BoringMath.to128(uint256(int256(old_locked.amount - new_locked.amount)));

                if (new_locked.amount == 0 && !poolSettings.emergencyUnlockActive) {
                    last_point.bias -= old_locked.amount;
                }
            }

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint user_epoch = user_point_epoch[_tokenId] + 1;

            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = BoringMath.to40(block.timestamp);
            u_new.blk = BoringMath.to40(block.number);
            u_new.amt = BoringMath.to128(uint256(int256(locked[_tokenId].amount)));

            user_point_history[_tokenId][user_epoch] = u_new;
        }
    }

    //--------------------------------------------------------
    // Voting
    //--------------------------------------------------------
    /**
     * @notice Set the onchain voting contract.
     * @dev Only callable by the admin.
     */
    function setVoter(address _voter) external {
        require(accessControls.hasAdminRole(msg.sender));
        voter = _voter;
    }

    function voting(uint _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = true;
    }

    function abstain(uint _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = false;
    }

    function attach(uint _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId]+1;
    }

    function detach(uint _tokenId) external {
        require(msg.sender == voter);
        attachments[_tokenId] = attachments[_tokenId]-1;
    }

    //--------------------------------------------------------
    // Documents
    //--------------------------------------------------------
    /**
     * @notice Set the global document store.
     * @dev Only callable by the admin.
     */
    function setDocumentController(address _documents) external {
        require(accessControls.hasAdminRole(msg.sender));
        documents = IJellyDocuments(_documents);
    }
    /**
     * @notice Set the documents in the global store.
     * @dev Only callable by the admin and operator.
     * @param _name Document key.
     * @param _data Document value. Leave blank to remove document
     */
    function setDocument(string calldata _name, string calldata _data)
        external
    {
        require(accessControls.hasAdminRole(msg.sender) || accessControls.hasOperatorRole(msg.sender));
        if (bytes(_data).length > 0) {
            documents.setDocument(address(this), _name, _data);
        } else {
            documents.removeDocument(address(this), _name);
        }
    }

    //--------------------------------------------------------
    // Jelly Pool NFTs
    //--------------------------------------------------------
    /**
     * @dev Returns current token URI metadata
     * @param _tokenId Token ID to fetch URI for.
     */
    function tokenURI(uint _tokenId) external override view returns (string memory) {
        // require(idToOwner[_tokenId] != address(0), "Nonexistent token");
        if (address(descriptor) != address(0)) {
            return descriptor.tokenURI(_tokenId);
        }
        return "";
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(poolSettings.transfersEnabled && 
                attachments[_tokenId] == 0 && 
                !voted[_tokenId], "attached");
    }


    //--------------------------------------------------------
    // Helpers
    //--------------------------------------------------------
    /**
     * @notice Checks if an address is a smart contract and if so, valid
     */
    function _checkAddress(address _addr) internal returns (bool) {
        if (_addr != tx.origin && address(checker) != address(0)) {
            assert(checker.check(_addr));
        }
        return true;
    }

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param _block Block to find
     * @param max_epoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _find_block_epoch(uint _block, uint max_epoch) internal view returns (uint) {
        // Binary search
        uint _min = 0;
        uint _max = max_epoch;
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supply_at(Point memory point, uint t) internal view returns (uint) {
        Point memory last_point = point;
        uint t_i = (last_point.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * int128(int256(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = BoringMath.to40(t_i);
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        uint128 weighted_supply = uint128(last_point.bias);
        if (weighted_supply < last_point.amt) {
            weighted_supply = last_point.amt;
        }
        return uint256(weighted_supply);
    }

    receive() external payable {
        revert();
    }

    //--------------------------------------------------------
    // Factory
    //--------------------------------------------------------

    /**
     * @notice Initializes main contract variables.
     * @dev Init function.
     * @param _poolToken Address of the pool token.
     * @param _accessControls Access controls interface.

     */
    function initJellyPool(
        address _poolToken,
        address _accessControls
    ) public 
    {
        require(!poolSettings.initialised);
        poolToken = _poolToken;
        accessControls = IJellyAccessControls(_accessControls);
        point_history[0].blk = BoringMath.to40(block.number) ;
        point_history[0].ts = BoringMath.to40(block.timestamp);
        point_history[0].amt = 0;
        // point_history[0].bias = 0;
        // point_history[0].slope = 0;
        tokenId = 0;
        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
        epoch = 0;
        _entered_state = 1;

        // _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
        // mint-ish
        emit Transfer(address(0), address(this), tokenId);
        // burn-ish
        emit Transfer(address(this), address(0), tokenId);

        // poolSettings.emergencyUnlockActive = false;
        poolSettings.transfersEnabled = true;
        poolSettings.initialised = true;
    }

    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) external override {
        (
        address _poolToken,
        address _accessControls
        ) = abi.decode(_data, (address, address));

        initJellyPool(
                        _poolToken,
                        _accessControls
                    );
    }
}