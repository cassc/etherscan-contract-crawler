// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FXBFactory ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Timelock2Step } from "frax-std/access-control/v2/Timelock2Step.sol";
import { BokkyPooBahsDateTimeLibrary as DateTimeLibrary } from "./utils/BokkyPooBahsDateTimeLibrary.sol";
import { FXB } from "./FXB.sol";

/// @title FXBFactory
/// @notice  Deploys FXB FXB ERC20 contracts
contract FXBFactory is Timelock2Step {
    using Strings for uint256;

    // =============================================================================================
    // Storage
    // =============================================================================================

    // Core
    /// @notice The Frax token contract
    address public immutable FRAX;

    /// @notice Array of bond addresses
    address[] public allBonds;

    /// @notice Whether a given address is an FXB
    mapping(address _fxb => bool _isFXB) public isFXB;

    /// @notice Whether a given timestamp has an FXB deployed
    mapping(uint256 _timestamp => bool _isFXB) public isTimestampFXB;

    // =============================================================================================
    // Constructor
    // =============================================================================================

    /// @notice Constructor
    /// @param _timelockAddress The owner of this contract
    constructor(address _timelockAddress, address _fraxErc20) Timelock2Step(_timelockAddress) {
        FRAX = _fraxErc20;
    }

    //==============================================================================
    // Helper Functions
    //==============================================================================

    /// @notice The ```_monthNames``` function returns the 3 letter names of the months given an index
    /// @param _monthIndex The index of the month
    /// @return _monthName The name of the month
    function _monthNames(uint256 _monthIndex) internal pure returns (string memory _monthName) {
        if (_monthIndex == 1) return "JAN";
        if (_monthIndex == 2) return "FEB";
        if (_monthIndex == 3) return "MAR";
        if (_monthIndex == 4) return "APR";
        if (_monthIndex == 5) return "MAY";
        if (_monthIndex == 6) return "JUN";
        if (_monthIndex == 7) return "JUL";
        if (_monthIndex == 8) return "AUG";
        if (_monthIndex == 9) return "SEP";
        if (_monthIndex == 10) return "OCT";
        if (_monthIndex == 11) return "NOV";
        if (_monthIndex == 12) return "DEC";
        revert InvalidMonthNumber();
    }

    // =============================================================================================
    // View functions
    // =============================================================================================

    /// @notice Returns the total number of bonds created
    /// @return _length uint256 Number of bonds created
    function allBondsLength() public view returns (uint256 _length) {
        return allBonds.length;
    }

    /// @notice Generates the bond symbol in the format FXB_YYYYMMDD
    /// @param _maturityTimestamp Date the bond will mature
    /// @return _bondName The name of the bond
    function _generateBondSymbol(uint256 _maturityTimestamp) internal pure returns (string memory _bondName) {
        // Maturity date
        uint256 _maturityMonth = DateTimeLibrary.getMonth(_maturityTimestamp);
        uint256 _maturityDay = DateTimeLibrary.getDay(_maturityTimestamp);
        uint256 _maturityYear = DateTimeLibrary.getYear(_maturityTimestamp);

        string memory maturityMonthString;
        if (_maturityMonth > 9) {
            maturityMonthString = _maturityMonth.toString();
        } else {
            maturityMonthString = string.concat("0", _maturityMonth.toString());
        }

        string memory maturityDayString;
        if (_maturityDay > 9) {
            maturityDayString = _maturityDay.toString();
        } else {
            maturityDayString = string.concat("0", _maturityDay.toString());
        }

        // Assemble all the strings into one
        _bondName = string(
            abi.encodePacked("FXB", "_", _maturityYear.toString(), maturityMonthString, maturityDayString)
        );
    }

    /// @notice Generates the bond name in the format (e.g. FXB_4_MMMDDYYYY)
    /// @param _bondId The id of the bond
    /// @param _maturityTimestamp Date the bond will mature
    /// @return _bondName The name of the bond
    function _generateBondName(
        uint256 _bondId,
        uint256 _maturityTimestamp
    ) internal pure returns (string memory _bondName) {
        // Maturity date
        uint256 _maturityMonth = DateTimeLibrary.getMonth(_maturityTimestamp);
        uint256 _maturityDay = DateTimeLibrary.getDay(_maturityTimestamp);
        uint256 _maturityYear = DateTimeLibrary.getYear(_maturityTimestamp);

        string memory maturityDayString;
        if (_maturityDay > 9) {
            maturityDayString = _maturityDay.toString();
        } else {
            maturityDayString = string(abi.encodePacked("0", _maturityDay.toString()));
        }

        // Assemble all the strings into one
        _bondName = string(
            abi.encodePacked(
                "FXB",
                "_",
                _bondId.toString(),
                "_",
                _monthNames(_maturityMonth),
                maturityDayString,
                _maturityYear.toString()
            )
        );
    }

    // =============================================================================================
    // Configurations / Privileged functions
    // =============================================================================================

    /// @notice Generates a new bond contract
    /// @param _maturityTimestamp Date the bond will mature and be redeemable
    /// @return _bondAddress The address of the new bond
    /// @return _bondId The id of the new bond
    function createBond(uint256 _maturityTimestamp) public returns (address _bondAddress, uint256 _bondId) {
        _requireSenderIsTimelock();

        // Set the bond id
        _bondId = allBondsLength();

        // Coerce the timestamp to 00:00 UTC
        uint256 _coercedMaturityTimestamp = (_maturityTimestamp / 86_400) * 86_400;

        // Get the new symbol and name
        string memory _bondSymbol = _generateBondSymbol({ _maturityTimestamp: _coercedMaturityTimestamp });
        string memory _bondName = _generateBondName({
            _bondId: _bondId,
            _maturityTimestamp: _coercedMaturityTimestamp
        });

        // Create the new contract
        FXB fxb = new FXB({
            _symbol: _bondSymbol,
            _name: _bondName,
            _maturityTimestamp: _coercedMaturityTimestamp,
            _fraxErc20: FRAX
        });
        _bondAddress = address(fxb);

        // Add the new bond address to the array and update the map
        allBonds.push(_bondAddress);
        isFXB[_bondAddress] = true;

        // Ensure bond maturity is unique
        if (isTimestampFXB[_coercedMaturityTimestamp]) {
            revert BondMaturityAlreadyExists();
        }
        isTimestampFXB[_coercedMaturityTimestamp] = true;

        emit BondCreated({
            newAddress: _bondAddress,
            newId: _bondId,
            newSymbol: _bondSymbol,
            newName: _bondName,
            maturityTimestamp: _coercedMaturityTimestamp
        });
    }

    // ==============================================================================
    // Events
    // ==============================================================================

    /// @notice The ```BondCreated``` event is emitted when a new bond is created
    /// @param newAddress Address of the bond
    /// @param newId The ID of the bond
    /// @param newSymbol The bond's symbol
    /// @param newName Name of the bond
    /// @param maturityTimestamp Date the bond will mature
    event BondCreated(address newAddress, uint256 newId, string newSymbol, string newName, uint256 maturityTimestamp);

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice The ```InvalidMonthNumber``` error is thrown when an invalid month number is passed
    error InvalidMonthNumber();

    /// @notice The ```BondMaturityAlreadyExists``` error is thrown when a bond with the same maturity already exists
    error BondMaturityAlreadyExists();
}