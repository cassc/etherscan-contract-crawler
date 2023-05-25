//SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title AURORA Token
/// @author Aurora team
/// @notice This contract is managed by Aurora DAO.
/// @dev This is the official Aurora ERC20 contract.
contract AuroraToken is ERC20 {
    uint8 constant _DECIMALS = 18;
    uint256 constant _TOTALCAP = 1000000000;

    constructor(
        string memory name,
        string memory symbol,
        address dao
    ) ERC20(name, symbol) {
        uint256 _maxSupply = _TOTALCAP * (uint256(10) ** _DECIMALS);
        _mint(dao, _maxSupply);
    }
}