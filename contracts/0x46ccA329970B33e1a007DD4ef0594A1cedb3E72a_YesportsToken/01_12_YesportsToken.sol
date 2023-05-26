//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YesportsToken is ERC20Permit, Ownable {
    constructor() ERC20("Yesports", "YESP") ERC20Permit("Yesports") {
        _mint(owner(), 1000000000 * (10**18));
    }

}