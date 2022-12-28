// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./vendor/openzeppelin-contracts-4.8.0-49c0e4370d0cc50ea6090709e3835a3091e33ee2/contracts/interfaces/IERC2981.sol";
import "./vendor/openzeppelin-contracts-4.8.0-49c0e4370d0cc50ea6090709e3835a3091e33ee2/contracts/utils/introspection/ERC165.sol";

/// @title  Three-party access control inspired by CryptoKitties. By default, the highest-privileged account will be the
///         same account that deploys this contract. ERC-2981 designates royalties to the CFO account. Uses an ownable
///         function to show who is the CEO.
/// @dev    Keep the CEO wallet stored offline, I warned you.
///         Subclassing notes:
///          - Use inheritance to gain functionality from `ThreeChiefOfficers`.
///          - Modify your functions with `onlyOperatingOfficer` to restrict access as needed.
/// @author William Entriken (https://phor.net) from Solidity-Template
abstract contract ThreeChiefOfficersWithRoyalties is IERC2981, ERC165 {
    /// @notice The account that can only reassign officer accounts
    address private _executiveOfficer;

    /// @notice The account that can perform privileged actions
    address private _operatingOfficer;

    /// @notice The account that can collect Ether from this contract
    address payable private _financialOfficer;

    /// @notice The account of recommended royalties for this contract
    uint256 internal _royaltyFraction;

    uint256 internal _royaltyDenominator = 10000;

    /// @dev Revert with an error when attempting privileged access without being executive officer.
    error NotExecutiveOfficer();

    /// @dev Revert with an error when attempting privileged access without being operating officer.
    error NotOperatingOfficer();

    /// @dev Revert with an error when attempting privileged access without being financial officer.
    error NotFinancialOfficer();

    /// @dev The withdrawal operation failed on the receiving side.
    error WithdrawFailed();

    /// @dev This throws unless called by the owner.
    modifier onlyOperatingOfficer() {
        if (msg.sender != _operatingOfficer) {
            revert NotOperatingOfficer();
        }
        _;
    }

    constructor(address payable newFinancialOfficer, uint256 newRoyaltyFraction) {
        _executiveOfficer = msg.sender;
        _financialOfficer = newFinancialOfficer;
        _royaltyFraction = newRoyaltyFraction;
    }

    /// @notice Reassign the executive officer role
    /// @param  newExecutiveOfficer new officer address
    function setExecutiveOfficer(address newExecutiveOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _executiveOfficer = newExecutiveOfficer;
    }

    /// @notice Reassign the operating officer role
    /// @param  newOperatingOfficer new officer address
    function setOperatingOfficer(address payable newOperatingOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _operatingOfficer = newOperatingOfficer;
    }

    /// @notice Reassign the financial officer role
    /// @param  newFinancialOfficer new officer address
    function setFinancialOfficer(address payable newFinancialOfficer) external {
        if (msg.sender != _executiveOfficer) {
            revert NotExecutiveOfficer();
        }
        _financialOfficer = newFinancialOfficer;
    }

    /// @notice Collect Ether from this contract
    function withdrawBalance() external {
        if (msg.sender != _financialOfficer) {
            revert NotFinancialOfficer();
        }
        (bool success, ) = _financialOfficer.call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// @notice Get the chief executive officer
    /// @return The chief executive officer account
    function executiveOfficer() public view returns (address) {
        return _executiveOfficer;
    }

    /// @notice Get the chief operating officer
    /// @return The chief operating officer account
    function operatingOfficer() public view returns (address) {
        return _operatingOfficer;
    }

    /// @notice Get the chief financial officer
    /// @return The chief financial officer account
    function financialOfficer() public view returns (address) {
        return _financialOfficer;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 _salePrice) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * _royaltyFraction) / _royaltyDenominator;
        return (_financialOfficer, royaltyAmount);
    }

    /// @notice EIP-5313 implementation
    /// @return The account that can control this contract
    function owner() public view returns (address) {
        return _executiveOfficer;
    }
}