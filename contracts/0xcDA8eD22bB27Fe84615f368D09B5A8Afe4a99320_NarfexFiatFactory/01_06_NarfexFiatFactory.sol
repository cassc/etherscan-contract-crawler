//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./NarfexFiat.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Narfex Fiat Factory
/// @author Danil Sakhinov
/// @notice Factory for creating fiat tokens for internal use in the Narfex exchange
/// @notice Factory owner and router have access to user funds management
contract NarfexFiatFactory is Ownable {
    using Address for address;

    /// Router address to provide access to tokens to a third-party contract
    address private _router;
    /// Mapping TokenSymbol=>Address
    mapping(string => NarfexFiat) public fiats;
    /// All created fiats
    NarfexFiat[] public fiatsList;

    event SetRouter(address router);
    event CreateFiat(string tokenName, string tokenSymbol, NarfexFiat tokenAddress);

    /// @notice only factory owner and router have full access
    modifier fullAccess {
        require(isHaveFullAccess(_msgSender()), "You have no access");
        _;
    }

    /// @notice Returns the router address
    /// @return Router address
    function getRouter() public view returns (address) {
        return _router;
    }

    /// @notice Sets the router address
    /// @param router Router address
    function setRouter(address router) public onlyOwner {
        _router = router;
        emit SetRouter(router);
    }

    /// @notice Returns true if the specified address have full access to user funds management
    /// @param account Account address
    /// @return Boolean
    function isHaveFullAccess(address account) internal view returns (bool) {
        return account == owner() || account == getRouter();
    }

    /// @notice Creates a new fiat token contract
    /// @param tokenName Description of the token
    /// @param tokenSymbol Token short tag. Better be uppercase
    /// @dev Method available only for owners
    function createFiat(
        string memory tokenName,
        string memory tokenSymbol
    ) public fullAccess {
        NarfexFiat fiat = new NarfexFiat(tokenName, tokenSymbol, address(this));
        fiats[tokenSymbol] = fiat;
        fiatsList.push(fiat);
        emit CreateFiat(tokenName, tokenSymbol, fiat);
    }

    /// @notice Returns a count of created fiats
    /// @return Number of tokens
    function getFiatsQuantity() public view returns (uint) {
        return fiatsList.length;
    }

    /// @notice Returns all fiats in a list
    /// @return Fiats addresses in array
    function getFiats() public view returns (NarfexFiat[] memory) {
        return fiatsList;
    }
    
}