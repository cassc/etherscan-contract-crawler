/// @title Price Feed
/// @notice contracts/PriceFeed.sol
// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract PriceFeed is
    Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Mapping between contract address to their price.
    mapping (address => uint256) private _priceFeed;

    /// @notice mapping the token adress to bool ]to keep track if the address available.
    mapping (address => bool) public isTokenAvailable;


    /// @notice Event for tracking when the price updated.
    /// @param tokenAddress: The token address.
    /// @param newPrice: The new price of the token.
    event PriceUpdated (
        address tokenAddress,
        uint256 newPrice
    );

    /// @notice Initilizing all the initial values.
    function initialize() initializer external {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    /// @notice Function to pause the contract.
    function pause() external {
        /// @notice Requirements.
        _requireOwner(msg.sender);

        /// @notice Pausing the contract.
        _pause();
    }

    /// @notice Function to unpause the contract.
    function unpause() external {
        /// @notice Requirements.
        _requireOwner(msg.sender);

        /// @notice Unpausing the contract.
        _unpause();
    }

    /**
     * @notice Getting the price based on contract address.
     * @param tokenAddress: The token address which you want to get price.
     */
    function getPrice(address tokenAddress) external view returns(uint256) {
        /// @notice Requirements.
        require(tokenAddress != address(0), "Token address should not be zero.");
        require(isTokenAvailable[tokenAddress], "Token address not available for price.");

        /// @notice Returning the price.
        return _priceFeed[tokenAddress];
    }

    /**
     * @notice Setting the price based on contract address.
     * @param tokenAddress: The token address which you want to get price.
     */
    function setPrice(address tokenAddress, uint256 price) external whenNotPaused {
        /// @notice Requirements.
        _requireOwner(msg.sender);
        require(tokenAddress != address(0), "Token address should not be zero.");

        /// @notice Updating the price.
        _priceFeed[tokenAddress] = price;

        /// @notice Setting the `isTokenAvailable` as true.
        if(!isTokenAvailable[tokenAddress])
            isTokenAvailable[tokenAddress] = true;

        /// @notice Emiting the event.
        emit PriceUpdated(tokenAddress, price);
    }

    /**
     * @notice Helper function for checking if the call is owner.
     * @param sender: The function caller address.
     */
    function _requireOwner(address sender) private view {
        require(sender == owner(), "Only Owner can call.");
    }
}