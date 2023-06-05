// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {IERC20} from "src/interfaces/external/IERC20.sol";
import {ISpotStorage} from "src/spot/interfaces/ISpotStorage.sol";
import {ITrade} from "src/spot/uni/interfaces/ITrade.sol";
import {ISpot} from "src/spot/interfaces/ISpot.sol";
import {ISwap} from "src/spot/uni/interfaces/ISwap.sol";
import {Commands} from "test/spot/external/Commands.sol";

error ZeroAddress();
error CantOpen();
error CantClose();
error ZeroAmount();
error StillFundraising(uint256 desired, uint256 given);
error AddressMismatch();
error NoAccess(address desired, address given);
error BaseTokenNotApplicable();

/// @title Trade
/// @author 7811
/// @notice Trade contract for opening and closing a spot position
contract Trade is ITrade {
    // `Spot` contract
    ISpot public spot;
    // `Swap` contract
    ISwap public swap;

    /*//////////////////////////////////////////////////////////////
                            INITIALIZE
    //////////////////////////////////////////////////////////////*/

    constructor(ISpot _spot, ISwap _swap) {
        spot = _spot;
        swap = _swap;
    }

    function changeStfxSpot(address _spot) external {
        if (msg.sender != spot.owner()) revert NoAccess(spot.owner(), msg.sender);
        if (_spot == address(0)) revert ZeroAddress();
        spot = ISpot(_spot);
    }

    function changeStfxSwap(address _swap) external {
        if (msg.sender != spot.owner()) revert NoAccess(spot.owner(), msg.sender);
        if (_swap == address(0)) revert ZeroAddress();
        swap = ISwap(_swap);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Opens a spot position using the universal router (swaps from depositToken to baseToken)
    /// @dev Can only be called by the manager of the stf
    /// @param amount the total amount of depositToken which the manager wants to use to open a spot position (in 1e18)
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    /// @return received returns the total received amount of baseToken after swap in baseToken's decimal units
    function openSpot(uint96 amount, bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        override
        returns (uint96 received)
    {
        StfSpotInfo memory _stf = spot.getManagerCurrentStfInfo(msg.sender);
        uint256 swapAmount = _openSpotCheck(_stf, amount);

        received = _openSpotUpdate(_stf, amount, swapAmount, commands, inputs, deadline);

        emit OpenSpot(spot.managerCurrentStf(msg.sender), amount, swapAmount, received, commands, inputs, deadline);
    }

    /// @notice Closes a spot position using the universal router (swaps from baseToken to depositToken)
    /// @dev Can only be called by the manager of the stf
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    /// @return remaining returns the total remaining amount of depositToken after swap in 1e18 decimal units
    function closeSpot(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        override
        returns (uint96 remaining)
    {
        StfSpotInfo memory _stf = spot.getManagerCurrentStfInfo(msg.sender);
        _closeSpotCheck(_stf);

        uint96 remainingAfterClose = _closeSpotSwap(_stf, commands, inputs, deadline);
        (uint96 _remaining, uint96 _mFee, uint96 _pFee) = _distribute(_stf, remainingAfterClose);
        remaining = _remaining;

        emit CloseSpot(spot.managerCurrentStf(msg.sender), remaining, _mFee, _pFee, commands, inputs, deadline);
    }

    /// @notice Closes a spot position using the universal router (swaps from baseToken to depositToken) after a particular time from our keeper bot
    /// @dev Can only be called by the admin
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param salt the stv id
    /// @return remaining returns the total remaining amount of depositToken after swap in 1e18 decimal units
    function closeSpotByAdmin(bytes calldata commands, bytes[] calldata inputs, bytes32 salt)
        external
        override
        returns (uint96 remaining)
    {
        if (msg.sender != spot.admin()) revert NoAccess(spot.admin(), msg.sender);

        StfSpotInfo memory _stf = spot.getStfInfo(salt);

        uint96 remainingAfterClose = _closeSpotSwap(_stf, commands, inputs, 0);
        (uint96 _remaining, uint96 _mFee, uint96 _pFee) = _distribute(_stf, remainingAfterClose);
        remaining = _remaining;

        emit CloseSpot(salt, remaining, _mFee, _pFee, commands, inputs, 0);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Converts the amount from 1e18 units to the token's decimal units
    /// @param token address of the token which is going to be swapped
    /// @param amount the total amount in 1e18 units
    /// @return tokenAmount returns the amount in the token decimals unit
    function _tokenDecimalConversion(address token, uint96 amount) internal view returns (uint256 tokenAmount) {
        uint8 tokenDecimals = IERC20(token).decimals();
        if (tokenDecimals > 18) tokenAmount = amount * (10 ** (tokenDecimals - 18));
        else tokenAmount = amount / (10 ** (18 - tokenDecimals));
    }

    function _openSpotCheck(StfSpotInfo memory _stf, uint96 amount) internal view returns (uint256 swapAmount) {
        // check if the `msg.sender` is the manager of the stf
        if (msg.sender != _stf.manager) revert AddressMismatch();
        // check if the totalRaised is more than 0
        if (_stf.totalRaised < 1) revert ZeroAmount();
        // check if the amount given as input is less than the totalRaised
        if (amount > _stf.totalRaised) revert CantOpen();
        // check if the fundraising period is over
        if (_stf.endTime > block.timestamp) revert StillFundraising(_stf.endTime, block.timestamp);
        // check if the stf already has a spot position or not
        if (_stf.status != StfStatus.NOT_OPENED) revert CantOpen();
        // check if the baseToken is linked to this contract
        if (spot.getTradeMapping(_stf.baseToken) != address(this)) revert BaseTokenNotApplicable();

        // convert the amount from 1e18 to the deposit token's decimal units
        swapAmount = _tokenDecimalConversion(_stf.depositToken, amount);
    }

    function _openSpotUpdate(
        StfSpotInfo memory _stf,
        uint96 amount,
        uint256 swapAmount,
        bytes memory commands,
        bytes[] memory inputs,
        uint256 deadline
    ) internal returns (uint96 received) {
        // swap the `swapAmount` of depositToken to baseToken with the poolFee given by the manager
        // the baseToken received after swap will be sent to the Spot contract
        received = swap.swapUniversalRouter(
            _stf.depositToken, _stf.baseToken, uint160(swapAmount), commands, inputs, deadline, address(spot)
        );

        // update state in Spot contract
        spot.openSpot(amount, received, spot.managerCurrentStf(msg.sender));
    }

    function _closeSpotCheck(StfSpotInfo memory _stf) internal view {
        // check if the `msg.sender` is the manager of the stf
        if (msg.sender != _stf.manager) revert AddressMismatch();
        // check if there's a spot position already opened for the stf
        if (_stf.status != StfStatus.OPENED) revert CantClose();
    }

    function _closeSpotSwap(StfSpotInfo memory _stf, bytes memory commands, bytes[] memory inputs, uint256 deadline)
        internal
        returns (uint96 remainingAfterClose)
    {
        // swap the `totalReceived` baseToken to depositToken and send the receiving amount of tokens to this contract
        uint96 balanceBeforeSwap = uint96(IERC20(_stf.depositToken).balanceOf(address(this)));
        swap.swapUniversalRouter(
            _stf.baseToken, _stf.depositToken, _stf.totalReceived, commands, inputs, deadline, address(this)
        );
        uint96 balanceAfterSwap = uint96(IERC20(_stf.depositToken).balanceOf(address(this)));

        remainingAfterClose = balanceAfterSwap - balanceBeforeSwap;
    }

    function _distribute(StfSpotInfo memory _stf, uint96 _remainingAfterClose)
        internal
        returns (uint96 remaining, uint96 mFee, uint96 pFee)
    {
        // convert the remaining amount to follow 1e18 units
        uint8 tokenDecimals = IERC20(_stf.depositToken).decimals();
        uint96 remainingAfterClose = uint96(_remainingAfterClose * (10 ** (18 - tokenDecimals)));

        // check if there's a profit
        if (remainingAfterClose > _stf.totalRaised) {
            uint256 _profits = remainingAfterClose - _stf.totalRaised;
            uint256 _mFee = (_profits * spot.managerFee()) / 100e18;
            uint256 _pFee = (_profits * spot.protocolFee()) / 100e18;

            mFee = uint96(_tokenDecimalConversion(_stf.depositToken, uint96(_mFee)));
            pFee = uint96(_tokenDecimalConversion(_stf.depositToken, uint96(_pFee)));

            // transfer the manager and the protocol accordingly
            IERC20(_stf.depositToken).transfer(_stf.manager, mFee);
            IERC20(_stf.depositToken).transfer(spot.treasury(), pFee);

            // return the amount after deducting the manager fee and the protocol fee in case of a profit and assign it
            remaining = remainingAfterClose - uint96(_mFee) - uint96(_pFee);
        } else {
            // return the total amount received after swaping in case of a loss
            remaining = remainingAfterClose;
        }

        // update state in Spot contract
        spot.closeSpot(remaining, spot.managerCurrentStf(_stf.manager));
        // convert back to the depositToken's decimals
        remainingAfterClose = uint96(remaining / (10 ** (18 - tokenDecimals)));
        // transfer the remaining amount to the Spot contract for the investors to claim back
        IERC20(_stf.depositToken).transfer(address(spot), remainingAfterClose);
    }
}