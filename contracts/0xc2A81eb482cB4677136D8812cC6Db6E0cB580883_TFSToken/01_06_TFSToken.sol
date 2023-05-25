// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TFS token
/// @notice Initial hard cap for 10M tokens.
contract TFSToken is ERC20, Ownable {

    uint256 public cap = 2500000000 * (10 ** 18);
    /// @notice Contract's constructor
    /// @dev Mints 10M tokens for the deployer
    constructor () public ERC20("Fairspin Token", "TFS") {
    }

    /// @notice Mint method for the exceptional cases
    /// @param _amount Amount of TFS tokens (with decimals) to be minted for the caller
    function mint(address _receiver, uint256 _amount) external onlyOwner {
        require(_receiver != address(0), "Zero address");
        require(_amount > 0, "Incorrect amount");
        require(totalSupply().add(_amount) <= cap, "Total supply exceeds cap");
        _mint(_receiver, _amount);        
    }
}