// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.19;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IMasterPenpie } from "../interfaces/IMasterPenpie.sol";

/// @title PenpieReceiptToken is to represent a Pendle Market deposited to penpie posistion. PenpieReceiptToken is minted to user who deposited Market token
///        on pendle staking to increase defi lego
///         
///         Reward from Magpie and on BaseReward should be updated upon every transfer.
///
/// @author Magpie Team
/// @notice Mater penpie emit `PNP` reward token based on Time. For a pool, 

contract PenpieReceiptToken is ERC20, Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    address public underlying;
    address public immutable masterPenpie;


    /* ============ Errors ============ */

    /* ============ Events ============ */

    constructor(address _underlying, address _masterPenpie, string memory name, string memory symbol) ERC20(name, symbol) {
        underlying = _underlying;
        masterPenpie = _masterPenpie;
    } 

    // should only be called by 1. pendleStaking for Pendle Market deposits 2. masterPenpie for other general staking token such as mPendleOFT or PNP-ETH Lp tokens
    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    // should only be called by 1. pendleStaking for Pendle Market deposits 2. masterPenpie for other general staking token such as mPendleOFT or PNP-ETH Lp tokens
    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }

    // rewards are calculated based on user's receipt token balance, so reward should be updated on master penpie before transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        IMasterPenpie(masterPenpie).beforeReceiptTokenTransfer(from, to, amount);
    }

    // rewards are calculated based on user's receipt token balance, so balance should be updated on master penpie before transfer
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        IMasterPenpie(masterPenpie).afterReceiptTokenTransfer(from, to, amount);
    }

}