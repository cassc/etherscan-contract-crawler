// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/MintableERC20.sol";

/// @title MGP
/// @author Magpie Team
contract MGP is MintableERC20 {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public minter;

    /* ============ Errors ============ */

    error OnlyMinter();

    /* ============ Constructor ============ */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialMint,
        address _initialMintTo
    ) MintableERC20(_name, _symbol) {
        _mint(_initialMintTo, _initialMint);
    }

    /* ============ Modifiers ============ */

    modifier onlyMinter() {
        if (msg.sender != minter)
            revert OnlyMinter();
        _;
    }

    /* ============ Admin functions ============ */

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    // MGP is owned by the Masterchief of the protocol, forbidding misuse of this function
    function mint(address _to, uint256 _amount) public override onlyMinter {
        _mint(_to, _amount);
    }

}