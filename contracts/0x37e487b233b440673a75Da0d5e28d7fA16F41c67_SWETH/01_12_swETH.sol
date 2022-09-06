//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./interfaces/ISWETH.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title Contract for SWNFT
contract SWETH is ISWETH, ERC20Permit {
    address public immutable minter;
    string constant swETHName = "Swell Ether";
    string constant swETHSymbol = "swETH";

    /// @notice initialise the contract to issue the token
    /// @param _minter address of the minter
    constructor(address _minter)
        ERC20(swETHName, swETHSymbol)
        ERC20Permit(swETHName)
    {
        require(_minter != address(0), "InvalidAddress");
        minter = _minter;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Minter only");
        _;
    }

    function mint(uint256 amount) external onlyMinter {
        _mint(minter, amount);
    }

    function burn(uint256 amount) external onlyMinter {
        _burn(minter, amount);
    }
}