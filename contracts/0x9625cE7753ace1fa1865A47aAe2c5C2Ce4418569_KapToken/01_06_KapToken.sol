// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Kapital DAO Token
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice 1 billion KAP tokens (plus 18 zeros) are minted in the constructor.
 * The total KAP supply cannot increase. However, the total KAP supply can
 * decrease via {burn}.
 */
contract KapToken is ERC20Burnable {
    constructor() ERC20("Kapital DAO Token", "KAP") {
        uint256 totalTokens = 1e9 * (10**decimals());
        _mint(0x4731E90300FF77f0b414A651a2626A25286fA13B, (totalTokens * 325) / 1000);
        _mint(0xbc450C9EcED158c6bD1AFfA8D37153E278e63e68, (totalTokens * 675) / 1000);
    }
}