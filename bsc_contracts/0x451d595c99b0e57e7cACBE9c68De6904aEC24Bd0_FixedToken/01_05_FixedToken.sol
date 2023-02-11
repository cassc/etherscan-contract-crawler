/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/simple-token/?utm=code



// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "ERC20.sol";

/**
 * @title Simple Token
 * @author Breakthrough Labs Inc.
 * @notice Token, ERC20, Fixed Supply
 * @custom:version 1.0.7
 * @custom:address 4
 * @custom:default-precision 18
 * @custom:simple-description Simple Token. A fixed supply is minted on deployment, and
 * new tokens can never be created.
 * @dev ERC20 token with the following features:
 *
 *  - Premint your total supply.
 *  - No minting function. This allows users to comfortably know the future supply of the token.
 *
 */

contract FixedToken is ERC20 {
    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Token Supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }
}