// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// +─────────+──────────────────────────────────────────────────────────+
// | NAME    | TESTNET SPARKS                                           |
// +─────────+──────────────────────────────────────────────────────────+
// | TOKEN   | SPARK                                                    |
// +─────────+──────────────────────────────────────────────────────────+
// | WEBSITE | https://sparks.dev                                       |
// +─────────+──────────────────────────────────────────────────────────+
// | LINKS   | https://linktree.sparks.dev                              |
// +─────────+──────────────────────────────────────────────────────────+
// | MISSION | Form, align and empower distributed communities toward   |
// |         | pragmatic, tangible and impactful real world outcomes.   |
// +─────────+──────────────────────────────────────────────────────────+
// | VISION  | A world where decentralized communities come together,   |
// |         | align their strengths, set their compass toward a better |
// |         | world... then make it happen.                            |
// +─────────+──────────────────────────────────────────────────────────+
// | VALUES  | Community · Utility · Impact                             |
// +─────────+──────────────────────────────────────────────────────────+
// | TOKEN   | TOTAL SUPPLY | 100,000,000                               |
// |         | OWNABLE      | NO                                        |
// |         | MINTABLE     | NO                                        |
// |         | BURNABLE     | YES                                       |
// +─────────+──────────────────────────────────────────────────────────+

contract SPARKS is ERC20, ERC20Burnable {
    constructor() ERC20("SPARKS", "SPARK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}