// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandToken is ERC20("Land Token", "LAND"), Ownable {
    /// @notice inherits ERC20 and mints the required amount of tokens to a
    /// specified beneficiary. No more tokens can be minted after token deployment.
    /// @param _beneficiary: address where to send minted tokens.
    /// @param _amount: total amount of tokens to be minted.
    constructor(address _beneficiary, uint256 _amount) public {
        _mint(_beneficiary, _amount);
    }

    function mint(address _beneficiary, uint256 _amount) public onlyOwner {
        _mint(_beneficiary, _amount);
    }
}