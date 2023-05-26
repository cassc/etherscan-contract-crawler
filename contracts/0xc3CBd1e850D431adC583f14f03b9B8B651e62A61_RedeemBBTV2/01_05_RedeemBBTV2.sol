// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20     } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { Owned      } from "solmate/auth/Owned.sol";
import { ICNV       } from "./ICNV.sol";
import { IRedeemBBT } from "./IRedeemBBT.sol";

contract RedeemBBTV2 is Owned {

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    // @notice Emitted when a BBT redemption happens.
    event Redemption(
        address indexed _from,
        uint256 indexed _amount
    );

    // @notice Emitted when contract is paused/unpaused
    event Paused (
        address indexed caller,
        bool isPaused
    );

    ////////////////////////////////////////////////////////////////////////////
    // MUTABLE STATE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice address of bbtCNV Token
    address public immutable bbtCNV;
    /// @notice address of CNV Token
    address public immutable CNV;
    /// @notice address of RedeemBBT V1
    address public immutable redeemBBTV1;
    /// @notice mapping of how many CNV tokens a bbtCNV holder has redeemed
    mapping(address => uint256) public redeemed;
    /// @notice redeem paused;
    bool public paused;
    
    ////////////////////////////////////////////////////////////////////////////
    // IMMUTABLE STATE
    ////////////////////////////////////////////////////////////////////////////
    
    string internal constant NONE = "NONE LEFT";
    uint256 internal constant JUNE_5_2022 = 1654387200;
    uint256 internal constant APRIL_1_2023 = 1680307200;


    ////////////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////////////////////
    
    // Better to use cosntants for production here. 
    constructor(
        address _bbtCNV, 
        address _CNV, 
        address _redeemBBTV1
    ) Owned(msg.sender) {
        bbtCNV = _bbtCNV;
        CNV = _CNV;
        redeemBBTV1 = _redeemBBTV1;
    }

    ////////////////////////////////////////////////////////////////////////////
    // ADMIN/MGMT
    ////////////////////////////////////////////////////////////////////////////

    function setPause(
        bool _paused
    ) external onlyOwner {
        paused = _paused;
        emit Paused(msg.sender, _paused);
    }

    ////////////////////////////////////////////////////////////////////////////
    // ACTIONS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice             redeem bbtCNV for CNV following vesting schedule
    /// @param  _amount     amount of CNV to redeem, irrelevant if _max = true
    /// @param  _to         address to which to mint CNV
    /// @param  _max        whether to redeem maximum amount possible
    /// @return amountOut   amount of CNV tokens to be minted to _to
    function redeem(
        uint256 _amount, 
        address _to, 
        bool _max
    ) external returns (uint256 amountOut) {
        // Check if it's paused
        require(!paused, "PAUSED");
        // Get user bbtCNV balance, and get amount already redeemed.
        // If already redeemed full balance - revert on "FULLY_REDEEMED" since
        // all balance has already been redeemed.
        uint256 bbtCNVBalance = IERC20(bbtCNV).balanceOf(msg.sender);
        uint256 amountRedeemed = redeemed[msg.sender] + IRedeemBBT(redeemBBTV1).redeemed(msg.sender);
        require(bbtCNVBalance > amountRedeemed, NONE);

        // Check how much is currently vested for user.
        // Revert if currently no more available to redeem.
        uint256 currentTime = block.timestamp;
        require(currentTime >= JUNE_5_2022, "NOT_VESTED");
        uint256 amountVested;
        
        if (currentTime > APRIL_1_2023) {
            amountVested = bbtCNVBalance;
        } else {
            uint256 vpct = vestedPercent(currentTime);
            amountVested = bbtCNVBalance * vpct / 1e18;
        }
        
        require(amountVested > amountRedeemed, NONE);

        // Calculate amount redeemable as the amountVested minus the amount that
        // has previously been redeemed.
        // If _max was not selected and thus a specified amount is to be
        // redeemed, ensure this amount doesn't exceed amountRedeemable.
        uint256 amountRedeemable = amountVested - amountRedeemed;
        amountOut = amountRedeemable;
        if (!_max) {
            require(amountRedeemable >= _amount,"EXCEEDS");
            amountOut = _amount;
        }

        // Update state to reflect redemption.
        redeemed[msg.sender] += amountOut;

        // Transfer CNV
        ICNV(CNV).transfer(_to, amountOut);

        emit Redemption(msg.sender, amountOut);
    }

    ////////////////////////////////////////////////////////////////////////////
    // VIEW
    ////////////////////////////////////////////////////////////////////////////

    /// @notice         to view how much a holder has redeemable
    /// @param  _who    bbtHolder address
    /// @return         amount redeemable
    function redeemable(
        address _who
    ) external view returns (uint256) {
        uint256 bbtCNVBalance = IERC20(bbtCNV).balanceOf(_who);
        uint256 amountRedeemed = redeemed[_who] + IRedeemBBT(redeemBBTV1).redeemed(_who);
        if (bbtCNVBalance == amountRedeemed) return 0;

        uint256 currentTime = block.timestamp;
        if (currentTime < JUNE_5_2022) return 0;

        uint256 amountVested;
        if (currentTime > APRIL_1_2023) {
            amountVested = bbtCNVBalance;
        } else {
            uint256 vpct = vestedPercent(currentTime);
            amountVested = bbtCNVBalance * vpct / 1e18;
        }
        if (amountVested <= amountRedeemed) return 0;

        return amountVested - amountRedeemed;
    }

    /// @notice         returns the percent of holdings vested for a given point
    ///                 in time.
    /// @param  _time   point in time
    /// @return vpct    percent of holdings vested
    function vestedPercent(
        uint256 _time
    ) public pure returns (uint256 vpct) {
        // Hardcode variables in method to avoid state reads and save gas.
        //
        // vestingTimeStart
        // - time vesting begins: JUNE_5_2022 (Sun Jun 05 2022 00:00:00 GMT+0000)
        //
        // vestingTimeLength
        // - duration of vesting: 25920000 (10 30-day months)
        //
        // vestingAmountStart
        // - vesting begins at 2%
        //
        // vestingAmountLength
        // - vesting grows to 100%, thus has a length of 98

        uint256 vestingTimeStart    = JUNE_5_2022;
        uint256 vestingTimeLength   = 25920000;
        uint256 vestingAmountStart  = 2e16;
        uint256 vestingAmountLength = 98e16;

        uint256 pctOf = _percentOf(vestingTimeStart, _time, vestingTimeLength);
        vpct = _linearMapping(vestingAmountStart, pctOf, vestingAmountLength);
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
    ) internal pure returns(uint256 elapsedPct) {
        uint256 elapsed             = _point - _start;
                elapsedPct          = elapsed * 1e18 / _length;
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
        uint256 elapsed             = _length * _pct / 1e18;
                point               = _start + elapsed;
    }
}