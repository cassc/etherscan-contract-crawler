// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Modified Multiple Token VotingEscrow Contract
//The following changes have been made:
//1. Users can lock either 80-20 USH-unshETH BPT, Uniswapv2 style pool2 token, or single-sided USH
//2. Make sure deposit() and withdraw() funcs are correctly updated for the multi token model
//3. Give owner ability to update boost weight of BPT and Pool2 tokens
//4. Price everything in USH terms - this means pricing the BPT and Pool2 tokens in USH terms
//5. Make 1 USH = 1vdUSH max locked for single-sided.
//6. Pool2 included for easy migration of existing liquidity + enable locking in chains where BPT is not supported

/// basically, where tokenAmount is used, we need to use scaledtokenAmount1+weight*tokenAmount2
/**
@title Multi-Token Weighted Voting Escrow
@author @EIP_Alta1r, Original: Curve Finance, Solidity Rewrite: Stargate Finance
@license MIT
@notice Votes have a weight depending on time, so that users are
        committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
     more than `MAXTIME` (1 years).

# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (1 years?)
*/

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
}
/* We cannot really do block numbers per se b/c slope is per time, not per block
 * and per block could be fairly bad b/c Ethereum changes blocktimes.
 * What we can do is to extrapolate ***At functions */

struct LockedBalance {
    int128 amount; //weightedAmount
    uint256 amountA;
    uint256 amountB;
    uint256 amountC;
    uint end;
}

interface IPool2 {
    function getReserves() external view returns (uint112 _reserveA, uint112 _reserveB, uint32 _blockTimestampLast);
    function getPoolId() external view returns (bytes32);
}

interface IBPT {
    function getVault() external view returns (address);
    function getPoolId() external view returns (bytes32);
}

interface IBPTVault {
    function getPoolTokenInfo(
        bytes32 poolId,
        address token
    ) external view returns (uint256, uint256, uint256, address);
}

contract VotingEscrow is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    event Deposit(
        address indexed provider,
        uint valueA,
        uint valueB,
        uint valueC,
        uint indexed locktime,
        DepositType deposit_type,
        uint ts
    );
    event Withdraw(address indexed provider, uint valueA, uint valueB, uint valueC, uint ts);
    event Supply(uint prevSupply, uint supply);

    uint internal constant WEEK = 1 weeks;
    uint public constant MAXTIME = 53 weeks; //max lock 1 year
    int128 internal constant iMAXTIME = 53 weeks;
    uint public constant MINTIME = 4 weeks;
    uint internal constant MULTIPLIER = 1 ether;

    //a dynamic boost weight that is configurable
    uint256 public bpt_boost_weight;
    uint256 public pool2_boost_weight;

    address public immutable tokenA; //BPT
    address public immutable tokenB; //Pool2 LP Token
    address public immutable tokenC; //Single-sided USH Token
    uint public supply;
    bool public unlocked;

    mapping(address => LockedBalance) public locked; //weighted locked balance

    uint public epoch;
    mapping(uint => Point) public point_history; // epoch -> unsigned point
    mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint) public user_point_epoch;
    mapping(uint => int128) public slope_changes; // time -> signed slope change

    // Aragon's view methods for compatibility
    address public controller;
    bool public transfersEnabled;

    string public constant name = "vdUSH";
    string public constant symbol = "vdUSH";
    string public constant version = "1.0.0";
    uint8 public constant decimals = 18;

    // Whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    mapping(address => bool) public contracts_whitelist;

    /// @notice Contract constructor
    /// @param tokenA_addr BPT
    /// @param tokenB_addr Pool2 LP token
    /// @param tokenC_addr USH token
    constructor(address tokenA_addr, address tokenB_addr, address tokenC_addr) {
        tokenA = tokenA_addr;
        tokenB = tokenB_addr;
        tokenC = tokenC_addr;
        bpt_boost_weight = 2.5 ether;
        pool2_boost_weight = 3.5 ether;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
        controller = msg.sender;
        transfersEnabled = true;
    }

    modifier onlyUserOrWhitelist() {
        if (msg.sender != tx.origin) {
            require(contracts_whitelist[msg.sender], "Smart contract not allowed");
        }
        _;
    }

    modifier notUnlocked() {
        require(!unlocked, "unlocked globally");
        _;
    }

    //helper unit conversion funcs
    function bpt_amount_to_ush_units(uint256 amount) internal view returns (uint256) {
        //get the contract address of the BPT pool token
        address bpt_address = tokenA;
        //get vault and pool info
        address balancer_vault = IBPT(bpt_address).getVault();
        bytes32 pool_id = IBPT(bpt_address).getPoolId();
        //get the balance of token A in the BPT pool
        (uint256 ush_balance, , , ) = IBPTVault(balancer_vault).getPoolTokenInfo(pool_id, tokenC);
        //get the total supply of the BPT pool
        uint256 total_supply = IERC20(bpt_address).totalSupply();
        //calculate the amount of token C units
        return (amount * ush_balance) / total_supply;
    }

    function pool2_amount_to_ush_units(uint256 amount) internal view returns (uint256) {
        //get the contract address of the BPT pool token
        address pool2_address = tokenB;
        //get vault and pool info
        (uint256 ush_balance, , ) = IPool2(pool2_address).getReserves();

        console.log(ush_balance);
        //get the total supply of the pool2
        uint256 total_supply = IERC20(pool2_address).totalSupply();
        console.log(total_supply);
        //calculate the amount of token C units
        return (amount * ush_balance) / total_supply;
    }

    function update_bpt_boost_weight(uint256 weight) external onlyOwner {
        require(weight > 0, "Cannot set zero boost weight!");
        bpt_boost_weight = weight;
    }

    function update_pool2_boost_weight(uint256 weight) external onlyOwner {
        require(weight > 0, "Cannot set zero boost weight!");
        pool2_boost_weight = weight;
    }

    function weighted_amount(uint256 bptAmount, uint256 pool2Amount, uint256 tokenAmount) public view returns (uint256) {

        uint256 scaled_bpt_amount = tokenA == address(0) ? 0 : bpt_amount_to_ush_units(bptAmount);

        uint256 scaled_pool2_amount = pool2_amount_to_ush_units(pool2Amount);

        return (scaled_bpt_amount * bpt_boost_weight) / 1e18 + (scaled_pool2_amount * pool2_boost_weight) / 1e18 + tokenAmount;
    }

    function int_weighted_amount(uint256 _valueA, uint256 _valueB, uint256 _valueC) internal view returns (int128) {
        return int128(int(weighted_amount(_valueA, _valueB, _valueC)));
    }

    /// @notice Add address to whitelist smart contract depositors `addr`
    /// @param addr Address to be whitelisted
    function add_to_whitelist(address addr) external onlyOwner {
        require(!contracts_whitelist[addr], "Address already whitelisted");
        contracts_whitelist[addr] = true;
    }

    /// @notice Remove a smart contract address from whitelist
    /// @param addr Address to be removed from whitelist
    function remove_from_whitelist(address addr) external onlyOwner {
        require(contracts_whitelist[addr], "Address not whitelisted");
        contracts_whitelist[addr] = false;
    }

    /// @notice Unlock all locked balances
    function unlock() external onlyOwner {
        unlocked = true;
    }

    /// @notice Get the most recently recorded rate of voting power decrease for `_addr`
    /// @param addr Address of the user wallet
    /// @return Value of the slope
    function get_last_user_slope(address addr) external view returns (int128) {
        uint uepoch = user_point_epoch[addr];
        return user_point_history[addr][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_addr`
    /// @param _addr User wallet address
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function user_point_history__ts(address _addr, uint _idx) external view returns (uint) {
        return user_point_history[_addr][_idx].ts;
    }

    /// @notice Get timestamp when `_addr`'s lock finishes
    /// @param _addr User wallet address
    /// @return Epoch time of the lock end
    function locked__end(address _addr) external view returns (uint) {
        return locked[_addr].end;
    }

    function locked__amountA(address user) external view returns (uint) {
        return locked[user].amountA;
    }

    function locked__amountB(address user) external view returns (uint) {
        return locked[user].amountB;
    }

    function locked__amountC(address user) external view returns (uint) {
        return locked[user].amountC;
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _addr User's wallet address. No user checkpoint if 0x0
    /// @param old_locked Pevious locked amount / end lock time for the user
    /// @param new_locked New locked amount / end lock time for the user
    function _checkpoint(
        address _addr,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint _epoch = epoch;

        //make sure we are using the most current BPT boost weights
        //and then make sure the new_locked that was passed in has had the most current boost weights applied (do that elsewhere)
        old_locked.amount = int_weighted_amount(old_locked.amountA, old_locked.amountB, old_locked.amountC);

        if (_addr != address(0x0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / iMAXTIME;
                u_old.bias = u_old.slope * int128(int(old_locked.end - block.timestamp));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / iMAXTIME;
                u_new.bias = u_new.slope * int128(int(new_locked.end - block.timestamp));
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

        Point memory last_point = Point({ bias: 0, slope: 0, ts: block.timestamp, blk: block.number });
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }
        uint last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract

        uint initial_last_point_ts = last_point.ts;
        uint initial_last_point_blk = last_point.blk;

        uint block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
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
            last_point.bias -= last_point.slope * int128(int(t_i - last_checkpoint));
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
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point_blk +
                (block_slope * (t_i - initial_last_point_ts)) /
                MULTIPLIER;

            _epoch += 1;
            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[_epoch] = last_point;
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_addr != address(0x0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (_addr != address(0x0)) {
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
            address addr = _addr;
            uint user_epoch = user_point_epoch[addr] + 1;

            user_point_epoch[addr] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr][user_epoch] = u_new;
        }
    }

    /// @notice Record global data to checkpoint
    function checkpoint() external notUnlocked {
        _checkpoint(
            address(0x0),
            LockedBalance(int_weighted_amount(0, 0, 0), 0, 0, 0, 0),
            LockedBalance(int_weighted_amount(0, 0, 0), 0, 0, 0, 0)
        );
    }

    function deposit_for(address _addr, uint _valueA, uint _valueB, uint _valueC) external nonReentrant {
        LockedBalance memory _locked = locked[_addr];

        require(_valueA > 0 || _valueB > 0 || _valueC > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");
        _deposit_for(_addr, _valueA, _valueB, _valueC, 0, _locked, DepositType.DEPOSIT_FOR_TYPE);
    }

    function _deposit_for(
        address _addr,
        uint _valueA,
        uint _valueB,
        uint _valueC,
        uint unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;

        supply = supply_before + weighted_amount(_valueA, _valueB, _valueC);
        LockedBalance memory old_locked;
        //NOTE: need to be checked
        _locked.amount = int128(int(weighted_amount(_locked.amountA, _locked.amountB, _locked.amountC)));
        // old_locked.amount = int128(int(weighted_amount(old_locked.amountA, old_locked.amountB)));
        (old_locked.amount, old_locked.end) = (_locked.amount, _locked.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int(weighted_amount(_valueA, _valueB, _valueC)));
        _locked.amountA += _valueA;
        _locked.amountB += _valueB;
        _locked.amountC += _valueC;

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_addr] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_addr, old_locked, _locked);

        if (_valueA != 0) {
            IERC20(tokenA).safeTransferFrom(msg.sender, address(this), _valueA);
        }

        if (_valueB != 0) {
            IERC20(tokenB).safeTransferFrom(msg.sender, address(this), _valueB);
        }

        if (_valueC != 0) {
            IERC20(tokenC).safeTransferFrom(msg.sender, address(this), _valueC);
        }

        emit Deposit(_addr, _valueA, _valueB, _valueC, _locked.end, deposit_type, block.timestamp);
        emit Supply(supply_before, supply_before + weighted_amount(_valueA, _valueB, _valueC));
    }

    /// @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    /// @param _valueA Amount to deposit of BPT
    /// @param _valueB amount to deposit of pool2
    /// @param _valueC amount to deposit of token
    /// @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    function _create_lock(uint _valueA, uint _valueB, uint _valueC, uint _unlock_time) internal {
        require(_valueA > 0 || _valueB > 0 || _valueC > 0); // dev: need non-zero value

        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount == 0, "Withdraw old tokens first");

        require(_unlock_time >= block.timestamp + MINTIME, "Voting lock must be at least MINTIME");
        //NOTE:MAXTIME is set to 1 year, may be changed to 3 years
        require(_unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 1 year max");
        //NOTE: calc only if valid time to save on gas
        uint unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

        _deposit_for(msg.sender, _valueA, _valueB, _valueC, unlock_time, _locked, DepositType.CREATE_LOCK_TYPE);
    }

    /// @notice External function for _create_lock
    /// @param _valueA Amount to deposit of BPT
    /// @param _valueB amount to deposit of pool2
    /// @param _valueC amount to deposit of token
    /// @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    function create_lock(
        uint _valueA,
        uint _valueB,
        uint _valueC,
        uint _unlock_time
    ) external nonReentrant onlyUserOrWhitelist notUnlocked {
        _create_lock(_valueA, _valueB, _valueC, _unlock_time);
    }

    /// @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
    /// @param _valueA Amount to deposit of BPT
    /// @param _valueB amount to deposit of pool2
    /// @param _valueC amount to deposit of token
    function increase_amount(
        uint _valueA,
        uint _valueB,
        uint _valueC
    ) external nonReentrant onlyUserOrWhitelist notUnlocked {
        _increase_amount(_valueA, _valueB, _valueC);
    }

    function _increase_amount(uint _valueA, uint _valueB, uint _valueC) internal {
        LockedBalance memory _locked = locked[msg.sender];

        require(_valueA > 0 || _valueB > 0 || _valueC > 0); // dev: need non-zero value
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(msg.sender, _valueA, _valueB, _valueC, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    /// @param _unlock_time New epoch time for unlocking
    function increase_unlock_time(uint _unlock_time) external nonReentrant onlyUserOrWhitelist notUnlocked {
        _increase_unlock_time(_unlock_time);
    }

    function _increase_unlock_time(uint _unlock_time) internal {
        LockedBalance memory _locked = locked[msg.sender];
        uint unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 3 years max");

        _deposit_for(msg.sender, 0, 0, 0, unlock_time, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }

    /// @notice Extend the unlock time and/or for `msg.sender` to `_unlock_time`
    /// @param _unlock_time New epoch time for unlocking
    function increase_amount_and_time(
        uint _valueA,
        uint _valueB,
        uint _valueC,
        uint _unlock_time
    ) external nonReentrant onlyUserOrWhitelist notUnlocked {
        require((_valueA > 0 || _valueB > 0 || _valueC > 0) || _unlock_time > 0, "Value and Unlock cannot both be 0");
        if ((_valueA > 0 || _valueB > 0 || _valueC > 0) && _unlock_time > 0) {
            _increase_amount(_valueA, _valueB, _valueC);
            _increase_unlock_time(_unlock_time);
        } else if ((_valueA > 0 || _valueB > 0 || _valueC > 0) && _unlock_time == 0) {
            _increase_amount(_valueA, _valueB, _valueC);
        } else {
            _increase_unlock_time(_unlock_time);
        }
    }

    /// @notice Withdraw all tokens for `msg.sender`
    /// @dev Only possible if the lock has expired
    function _withdraw() internal {
        LockedBalance memory _locked = locked[msg.sender];
        uint256 token_a_balance = _locked.amountA;
        uint256 token_b_balance = _locked.amountB;
        uint256 token_c_balance = _locked.amountC;
        uint value = uint(int(_locked.amount));

        if (!unlocked) {
            require(block.timestamp >= _locked.end, "The lock didn't expire");
        }

        locked[msg.sender] = LockedBalance(0, 0, 0, 0, 0);
        uint supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _locked, LockedBalance(0, 0, 0, 0, 0));

        if(token_a_balance > 0) {
            IERC20(tokenA).safeTransfer(msg.sender, token_a_balance);
        }
        if(token_b_balance > 0) {
            IERC20(tokenB).safeTransfer(msg.sender, token_b_balance);
        }
        if(token_c_balance > 0) {
            IERC20(tokenC).safeTransfer(msg.sender, token_c_balance);
        }
        emit Withdraw(msg.sender, token_a_balance, token_b_balance, token_c_balance, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function withdraw() external nonReentrant {
        _withdraw();
    }

    /// @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    /// @param _valueA Amount to deposit of BPT
    /// @param _valueB amount to deposit of pool2
    /// @param _valueC amount to deposit of token
    /// @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    function withdraw_and_create_lock(
        uint _valueA,
        uint _valueB,
        uint _valueC,
        uint _unlock_time
    ) external nonReentrant onlyUserOrWhitelist notUnlocked {
        _withdraw();
        _create_lock(_valueA, _valueB, _valueC, _unlock_time);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param max_epoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
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

    /// @notice Get the current voting power for `msg.sender`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param addr User wallet address
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOf(address addr, uint _t) internal view returns (uint) {
        uint _epoch = user_point_epoch[addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[addr][_epoch];
            last_point.bias -= last_point.slope * int128(int(_t) - int(last_point.ts));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint(int(last_point.bias));
        }
    }

    function balanceOfAtT(address addr, uint _t) external view returns (uint) {
        return _balanceOf(addr, _t);
    }

    function balanceOf(address addr) external view returns (uint) {
        return _balanceOf(addr, block.timestamp);
    }

    /// @notice Measure voting power of `addr` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param addr User's wallet address
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function balanceOfAt(address addr, uint _block) external view returns (uint) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number);

        // Binary search
        uint _min = 0;
        uint _max = user_point_epoch[addr];
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint max_epoch = epoch;
        uint _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint d_block = 0;
        uint d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int(block_time - upoint.ts));
        if (upoint.bias >= 0) {
            return uint(uint128(upoint.bias));
        } else {
            return 0;
        }
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
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
            last_point.bias -= last_point.slope * int128(int(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint(uint128(last_point.bias));
    }

    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function _totalSupply(uint t) internal view returns (uint) {
        uint _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return _supply_at(last_point, t);
    }

    function totalSupplyAtT(uint t) external view returns (uint) {
        return _totalSupply(t);
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply(block.timestamp);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _block Block to calculate the total voting power at
    /// @return Total voting power at `_block`
    function totalSupplyAt(uint _block) external view returns (uint) {
        require(_block <= block.number);
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
            if (point.blk != block.number) {
                dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supply_at(point, point.ts + dt);
    }

    // Dummy methods for compatibility with Aragon
    function changeController(address _newController) external {
        require(msg.sender == controller);
        controller = _newController;
    }
}