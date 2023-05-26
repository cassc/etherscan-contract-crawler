// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ICNV} from "./interface/ICNV.sol";

contract pCNV is ERC20, Owned {
    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event Paused(bool indexed _paused);

    event Mint(uint256 indexed _amount);

    event Redemption(
        address indexed _from,
        address indexed _who,
        uint256 indexed _amount
    );

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANT
    ////////////////////////////////////////////////////////////////////////////

    /// @notice time vesting begins: 1656633600 (Fri Jul 01 2022 00:00:00 GMT+0000)
    uint256 public constant VESTING_TIME_START = 1656633600;
    /// @notice time linear-vesting begins: 1680307200 (Sat Apr 01 2023 00:00:00 GMT+0000)
    uint256 public constant LINEAR_VESTING_TIME_START = 1680307200;
    /// @notice time vesting ends: 1711929600 (Mon Apr 01 2024 00:00:00 GMT+0000)
    uint256 public constant VESTING_TIME_END = 1711929600;
    /// @notice duration of linear-vesting: 31622400
    uint256 public constant LINEAR_VESTING_TIME_LENGTH = 31622400;
    /// @notice vesting begins at 50%
    uint256 public constant VESTING_AMOUNT_START = 5e17;
    /// @notice vesting grows to 100%, thus has a length of 50
    uint256 public constant VESTING_AMOUNT_LENGTH = 5e17;
    /// @notice max supply of 33,300,000
    uint256 public constant MAX_SUPPLY = 333e23;

    ////////////////////////////////////////////////////////////////////////////
    // STATE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice address of CNV Token
    address public immutable CNV;
    /// @notice redeem paused;
    bool public paused;
    /// @notice total minted amount
    uint256 public totalMinted;
    /// @notice mapping of how many CNV tokens a pCNV holder has redeemed
    mapping(address => uint256) public redeemed;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////

    constructor(address _CNV)
        ERC20("Concave pCNV", "pCNV", 18)
        Owned(0x226e7AF139a0F34c6771DeB252F9988876ac1Ced)
    {
        CNV = _CNV;
    }

    ////////////////////////////////////////////////////////////////////////////
    // ADMIN/MGMT
    ////////////////////////////////////////////////////////////////////////////

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;

        emit Paused(paused);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        require(totalMinted + amount <= MAX_SUPPLY, "MAX_SUPPLY");

        // Cannot overflow because the total minted
        // can't exceed the max uint256 value.
        unchecked {
            totalMinted += amount;
        }

        _mint(to, amount);

        emit Mint(amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // ERC20 LOGIC
    ////////////////////////////////////////////////////////////////////////////

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // Update redeemed
        uint256 amountRedeemed = (redeemed[msg.sender] * amount) /
            balanceOf[msg.sender];

        redeemed[msg.sender] -= amountRedeemed;

        // Update balance
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            redeemed[to] += amountRedeemed;
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // Update allowance
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        // Update redeemed
        uint256 amountRedeemed = (redeemed[from] * amount) / balanceOf[from];

        redeemed[from] -= amountRedeemed;

        // Update balance
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            redeemed[to] += amountRedeemed;
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    ////////////////////////////////////////////////////////////////////////////
    // ACTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice             redeem pCNV for CNV following vesting schedule
    /// @param  _amount     amount of CNV to redeem, irrelevant if _max = true
    /// @param  _who        address of pCNV holder to redeem
    /// @param  _to         address to which to mint CNV
    /// @param  _max        whether to redeem maximum amount possible
    /// @return amountOut   amount of CNV tokens to be minted to _to
    function redeem(
        uint256 _amount,
        address _who,
        address _to,
        bool _max
    ) external returns (uint256 amountOut) {
        // Check if it's paused
        require(!paused, "PAUSED");

        // Get user pCNV balance
        // If empty balance - revert on "FULLY_REDEEMED" since
        // all balance has already been burnt to redeem.
        uint256 pCNVBalance = balanceOf[_who];
        require(pCNVBalance > 0, "NONE_LEFT");

        // Check how much is currently vested for user.
        uint256 currentTime = block.timestamp;
        require(currentTime >= VESTING_TIME_START, "!VESTING");
        uint256 amountRedeemed = redeemed[_who];
        uint256 amountVested;
        if (currentTime >= VESTING_TIME_END) {
            amountVested = pCNVBalance + amountRedeemed;
        } else {
            uint256 vpct = vestedPercent(currentTime);
            amountVested = ((pCNVBalance + amountRedeemed) * vpct) / 1e18;
        }
        require(amountVested > amountRedeemed, "NONE_LEFT");

        // If _max was not selected and thus a specified amount is to be
        // redeemed, ensure this amount doesn't exceed amountRedeemable.
        uint256 amountRedeemable = amountVested - amountRedeemed;
        if (!_max) {
            require(amountRedeemable >= _amount, "EXCEEDS");
            amountRedeemable = _amount;
        }

        // In case of vault calling on behalf of user, check that user has
        // allowed vault to redeem on behalf of user by checking allowance.
        if (_who != msg.sender) {
            uint256 allowed = allowance[_who][msg.sender];
            require(allowed >= amountRedeemable, "!ALLOWED");
            if (allowed != type(uint256).max)
                allowance[_who][msg.sender] = allowed - amountRedeemable;
        }

        // Update state to reflect redemption.
        redeemed[_who] = amountRedeemed + amountRedeemable;

        // Burn pCNV
        _burn(_who, amountRedeemable);

        // Calculate CNV amount out as total supply of pCNV represents a constant
        // claim on 0.1 (10%) of CNV's total supply.
        amountOut =
            (ICNV(CNV).totalSupply() * amountRedeemable) /
            (10 * MAX_SUPPLY);

        // Mint CNV
        ICNV(CNV).mint(_to, amountOut);

        emit Redemption(msg.sender, _who, amountOut);
    }

    ////////////////////////////////////////////////////////////////////////////
    // VIEW
    ////////////////////////////////////////////////////////////////////////////

    /// @notice         to view how much a holder has redeemable
    /// @param  _who    pHolder address
    /// @return         amount redeemable
    function redeemable(address _who) external view returns (uint256) {
        uint256 pCNVBalance = balanceOf[_who];
        if (pCNVBalance == 0) return 0;

        uint256 currentTime = block.timestamp;
        if (currentTime < VESTING_TIME_START) return 0;

        uint256 amountRedeemed = redeemed[_who];
        uint256 amountVested;
        if (currentTime >= VESTING_TIME_END) {
            amountVested = pCNVBalance + amountRedeemed;
        } else {
            uint256 vpct = vestedPercent(currentTime);
            amountVested = ((pCNVBalance + amountRedeemed) * vpct) / 1e18;
        }
        if (amountVested <= amountRedeemed) return 0;

        return amountVested - amountRedeemed;
    }

    /// @notice         returns the percent of holdings vested for a given point
    ///                 in time.
    /// @param  _time   point in time
    /// @return         percent of holdings vested
    function vestedPercent(uint256 _time) public pure returns (uint256) {
        // Before VestingTimeStart: 0%
        if (_time < VESTING_TIME_START) {
            return 0;
        }

        // VestingTimeStart ~ LinearVestingTimeStart: 50%
        if (_time <= LINEAR_VESTING_TIME_START) {
            return VESTING_AMOUNT_START;
        }

        // After VestingTimeEnd
        if (_time >= VESTING_TIME_END) {
            return 1e18;
        }

        // LinearVestingTimeStart ~ VestingTimeEnd: 50% ~ 100% (Linear)
        // LinearVestingTimeLength: duration of linear vesting
        uint256 pctOf = _percentOf(
            LINEAR_VESTING_TIME_START,
            _time,
            LINEAR_VESTING_TIME_LENGTH
        );
        return
            _linearMapping(VESTING_AMOUNT_START, pctOf, VESTING_AMOUNT_LENGTH);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice             returns the elapsed percentage of a point within
    ///                     a given range
    /// @param  _start      starting point
    /// @param  _point      current point
    /// @param  _length     lenght
    /// @return elapsedPct  percent from _start
    function _percentOf(
        uint256 _start,
        uint256 _point,
        uint256 _length
    ) internal pure returns (uint256 elapsedPct) {
        uint256 elapsed = _point - _start;
        elapsedPct = (elapsed * 1e18) / _length;
    }

    /// @notice             linearly maps a percentage point to a range
    /// @param  _start      starting point
    /// @param  _pct        percentage point
    /// @param  _length     lenght
    /// @return point       point
    function _linearMapping(
        uint256 _start,
        uint256 _pct,
        uint256 _length
    ) internal pure returns (uint256 point) {
        uint256 elapsed = (_length * _pct) / 1e18;
        point = _start + elapsed;
    }
}