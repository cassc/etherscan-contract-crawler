// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Interfaces/IFrigg.sol";

/// @title A token contract and a standard for Frigg Asset-backed Tokens (ABT)
/// @author Frigg team
/// @dev inherits the OpenZepplin ERC20Capped, AccessControl and Frigg token standard implementations
contract FriggToken is ERC20Capped, AccessControl, IFrigg {
    using SafeERC20 for ERC20;

    /// @dev ROUTER_ROLE has permission to mint and burn tokens
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    /// @dev The default value is false
    bool public isBondExpired;

    /// @dev The default value is true
    bool public primaryMarketActive = true;

    string private termsUrl;

    /// @notice Pass the dynamic set params of the bond
    constructor(
        address _multisig,
        address _router,
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        string memory _termsUrl
    ) ERC20(_name, _symbol) ERC20Capped(_amount * (10**18)) {
        /// Set DEFAULT_ADMIN_ROLE to a multisig address controlled by Frigg
        /// DEFAULT_ADMIN_ROLE is already implemented in AccessControl contract
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);

        /// Set MINTER_ROLE to router
        _grantRole(ROUTER_ROLE, _router);

        /// Set the termsUrl to the passed value
        termsUrl = _termsUrl;
    }

    /// @dev This function only allows router to mint new tokens during primary market sale
    function mint(address _to, uint256 _amount) external override onlyRole(ROUTER_ROLE) {
        _mint(_to, _amount);
    }

    /// @dev This function only allows router to burn existing tokens when tokens reach expiry
    function burn(address _from, uint256 _amount) external override onlyRole(ROUTER_ROLE) {
        _burn(_from, _amount);
    }

    /// @dev If totalSupply = cap, this function returns false
    function isPrimaryMarketActive() external view override returns (bool) {
        return totalSupply() < cap() && primaryMarketActive;
    }

    ///@dev Issuer can manually close out primary market buy
    function setPrimaryMarketActive(bool _setup) public onlyRole(DEFAULT_ADMIN_ROLE) {
        primaryMarketActive = _setup;
    }

    /// @dev Getter function for router contract to access variable
    function seeBondExpiryStatus() external view override returns (bool) {
        return isBondExpired;
    }

    /// @notice Terms will contain the terms of issue for this particular token
    function termsURL() external view override returns (string memory) {
        return termsUrl;
    }

    /// @dev Deployer of this contract can modify the value of isBondExpired
    function setBondExpiry() public onlyRole(DEFAULT_ADMIN_ROLE) {
        isBondExpired = true;
    }

    /// @notice Update ROUTER_ROLE to new router address
    /// @dev Only token multisig can update this address
    function setRouter(address _router) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ROUTER_ROLE, _router);
    }
}