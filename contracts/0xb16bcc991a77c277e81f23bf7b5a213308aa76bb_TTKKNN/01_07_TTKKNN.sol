// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TTKKNN ERC20 Contract
/// @author 67ac2b3e1a1f71cdf69d11eb2baf93ad284264f20087ffc2866cfce01204fe91
/// @notice TTKKNN is a collection-agnostic staking token for the ERC721 ecosystem.
contract TTKKNN is ERC20 {
    constructor() ERC20("TTKKNN", "TTKKNN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}