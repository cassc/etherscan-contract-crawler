// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./Mintable.sol";
import "./Wrappable.sol";

contract WERC20 is Wrappable, ERC20Burnable, IERC165, Mintable {

    uint8 private _decimals;

    constructor(uint16 originChain_, string memory originToken_, string memory name_, string memory symbol_, uint8 decimals_) Wrappable(originChain_, originToken_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId;
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

}