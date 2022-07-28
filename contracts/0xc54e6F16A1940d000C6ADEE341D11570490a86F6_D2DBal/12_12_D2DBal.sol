// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title D2DBal token
/// @dev Ownership is transfered to BalDepositor smart contract after it is deployed
contract D2DBal is ERC20Permit, Ownable {
    // solhint-disable-next-line
    constructor() ERC20Permit("D2DBal") ERC20("D2DBal", "D2DBAL") {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }
}