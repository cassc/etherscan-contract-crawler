// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @dev For making the __Exchange_init method initializer
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ExchangeCore.sol";

/// @title Trading contract for exchanging combination of ETH or ERC-20 and ERC-721 or ERC-1155
/// @dev All the data are previously off chain except the actual transaction
contract Exchange is Initializable, ExchangeCore {
    /// @notice Initializes whitelist and exchange fee
    /// @dev msg.sender is owner as well as whitelisted member by default
    /// @param _exchangeFee Exchange fee that will be deducted for each transaction
    function __Exchange_init(uint16 _exchangeFee) external initializer {
        initializeWhitelist(msg.sender);
        __Exchange_Admin_init_unchained(_exchangeFee);
    }
}