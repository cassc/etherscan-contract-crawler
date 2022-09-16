// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAddressRegistry {
    function tokenRegistry() external view returns (address);
}

interface ITokenRegistry {
    function enabled(address) external returns (bool);
}

interface IOracle {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);
}

contract PriceFeed is Ownable {
    /// @notice keeps track of oracles for each tokens
    mapping(address => address) public oracles;

    /// @notice  address registry contract
    address public addressRegistry;

    /// @notice wrapped FTM contract
    address public wrappedToken;

    /// @notice Create new address registry
    /// @param _addressRegistry Address of the AddressRegistry contract
    /// @param _wrappedToken Wrapped  address
    constructor(address _addressRegistry, address _wrappedToken) {
        addressRegistry = _addressRegistry;
        wrappedToken = _wrappedToken;
    }

    /**
     @notice Register oracle contract to token
     @dev Only owner can register oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function registerOracle(address _token, address _oracle)
        external
        onlyOwner
    {
        ITokenRegistry tokenRegistry = ITokenRegistry(
            IAddressRegistry(addressRegistry).tokenRegistry()
        );
        require(tokenRegistry.enabled(_token), "invalid token");
        require(oracles[_token] == address(0), "oracle already set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Update oracle address for token
     @dev Only owner can update oracle
     @param _token ERC20 token address
     @param _oracle Oracle address
     */
    function updateOracle(address _token, address _oracle) external onlyOwner {
        require(oracles[_token] != address(0), "oracle not set");

        oracles[_token] = _oracle;
    }

    /**
     @notice Get current price for token
     @dev return current price or if oracle is not registered returns 0
     @param _token ERC20 token address
     */
    function getPrice(address _token) external view returns (int256, uint8) {
        if (oracles[_token] == address(0)) {
            return (0, 0);
        }

        IOracle oracle = IOracle(oracles[_token]);
        return (oracle.latestAnswer(), oracle.decimals());
    }

    /**
     @notice Update address registry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _addressRegistry)
        external
        onlyOwner
    {
        addressRegistry = _addressRegistry;
    }
}