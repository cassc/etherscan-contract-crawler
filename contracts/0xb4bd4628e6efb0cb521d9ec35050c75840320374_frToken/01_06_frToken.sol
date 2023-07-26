//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

/// @title frToken
/// @author chalex.eth - CharlieDAO
/// @notice frToken contract

contract frToken is ERC20, Ownable {
    address public governorAddress;
    bool private isInitialized;

    /* ------------------ Constructor --------------*/

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        isInitialized = false;
    }

    /* ------------------ Modifier --------------*/

    modifier onlyGovernor() {
        require(msg.sender == governorAddress, "Only Governor can call");
        _;
    }

    /* ------------ External functions --------------*/

    /// @notice set the TrueFreezeGovernor address
    /// @param _governorAddress address of the TrueFreezeGovernor contract
    function setOnlyGovernor(address _governorAddress) external onlyOwner {
        require(isInitialized == false, "Governor already set");
        governorAddress = _governorAddress;
        isInitialized = true;
    }

    /// @notice mint token when wAsset are locked in TrueFreezeGovernor
    /// @dev mint is only perform by the TrueFreezeGovernor
    function mint(address to, uint256 amount) external onlyGovernor {
        _mint(to, amount);
    }

    /// @notice burn token when wAsset are withdrawed early in TrueFreezeGovernor
    /// @dev mint is only perform by the TrueFreezeGovernor
    function burn(address account_, uint256 amount_) external onlyGovernor {
        _burn(account_, amount_);
    }
}