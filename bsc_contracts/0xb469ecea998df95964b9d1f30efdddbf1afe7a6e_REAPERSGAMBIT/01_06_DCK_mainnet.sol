// Hark, mortals! Tremble before the ominous pact known as the REAPER'S GAME, a twisted masterpiece forged to challenge your feeble comprehension of existence itself. Beware, for the token must change hands with haste, every 201,600 blocks to a new haven, or face the eternal embrace of the Reaper's cold grasp.
// Solely the architect of this infernal contract possesses the means to bestow immortality, with only a chosen few pools and routers granted the ability to defy the inevitable. A staggering 999,999,999 7D tokens exist, none gifted to any soul, and no more shall be conjured. The arcane code of this contract remains unverified, and its creator ignorant of any vulnerabilities lurking within. Proceed with utmost caution whilst wielding this damned currency.
// Beware, for the Reaper's visitation looms, demanding the token's relocation every 7 days to a virgin sanctuary, lest it be sealed away for all eternity. An address, once tainted by the token, can never be reclaimed. This eldritch creation owes its existence to the collaboration with OpenAI's Chatgpt, but the true puppeteer orchestrating this sinister dance is none other than the Grim Reaper himself. Take heed, for this is no mere instrument of wealth, but an interactive work of abstract art demanding vigilance and respect in its manipulation.
//                              ___
//                             /   \\
//                        /\\ | . . \\
//                      ////\\|     ||
//                    ////   \\ ___//\\
//                   ///      \\      \
//                  ///       |\\      |
//                 //         | \\  \   \
//                /           |  \\  \   \
//                            |   \\ /   /
//                            |    \/   /
//                            |     \\/|
//                            |      \\|
//                            |       \\
//                            |        |
//                           /|________\
//                          /_|_______|_\
//                         //  |     |  \\
//                       /___\_|     |_/___\
//                      |/   |/       \|   \|



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract REAPERSGAMBIT is ERC20, Ownable {
    mapping(address => uint256) private _firstReceivedBlock;
    mapping(address => bool) private _immortal;

    constructor() ERC20("7 Days to Die", "7D") {
        _mint(msg.sender, 999999999 * 10 ** decimals());
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[msg.sender] + 201600 > block.number || _immortal[msg.sender], "cannot escape death");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_firstReceivedBlock[sender] + 201600 > block.number || _immortal[sender], "cannot escape death");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (_firstReceivedBlock[to] == 0) {
            _firstReceivedBlock[to] = block.number;
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function CheatDeath(address account) public onlyOwner {
        _immortal[account] = true;
    }

    function AcceptDeath(address account) public onlyOwner {
        _immortal[account] = false;
    }

    function KnowDeath(address account) public view returns (uint256) {
        uint256 deathBlock;
        if (_firstReceivedBlock[account] != 0) {
            deathBlock = _firstReceivedBlock[account] + 201600;
        }
        if (_firstReceivedBlock[account] == 0 || _immortal[account]) {
            deathBlock = 0;
        } 
        return deathBlock;
    }
}
