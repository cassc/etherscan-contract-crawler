// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title PB_BurnToken
/// @author Hifi
/// @notice Manages the mint and distribution of BURN tokens in exchange for burned BOTS.
contract PB_BurnToken is ERC20Burnable, ERC20Capped, Ownable {
    IERC721 public bots;

    constructor() ERC20("Pawn Bots Burn Token", "BURN") ERC20Capped(8888 * 10**decimals()) {
        bots = IERC721(0x28F0521c77923F107E29a5502a5a1152517F9000);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    function adminMint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function updateBots(address newBots) external onlyOwner {
        bots = IERC721(newBots);
    }

    function mint(uint256[] memory botIds) external {
        for (uint256 i; i < botIds.length; ) {
            bots.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, botIds[i]);
            unchecked {
                i++;
            }
        }
        _mint(msg.sender, botIds.length * 10**decimals());
    }
}