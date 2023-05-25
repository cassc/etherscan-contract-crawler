// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GODS is ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _minter)
        ERC20("Gods Unchained","GODS")
        ERC20Capped(500000000000000000000000000)
    {
        _setupRole(MINTER_ROLE, _minter);
    }


    modifier checkRole(
        bytes32 role,
        address account,
        string memory message
    ) {
        require(hasRole(role, account), message);
        _;
    }

    function mint(address _to, uint256 _amount)
        external
        checkRole(MINTER_ROLE, msg.sender, "Caller is not a minter")
    {
        super._mint(_to, _amount);
    }
}