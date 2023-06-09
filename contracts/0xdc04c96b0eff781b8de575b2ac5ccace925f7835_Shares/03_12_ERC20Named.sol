// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Flaggable.sol";
import "../utils/Ownable.sol";

contract ERC20Named is ERC20Flaggable, Ownable {

    string public override name;
    string public override symbol;

    constructor(string memory _symbol, string memory _name, uint8 _decimals, address _admin) ERC20Flaggable(_decimals) Ownable(_admin) {
        setNameInternal(_symbol, _name);
    }

    function setName(string memory _symbol, string memory _name) external onlyOwner {
        setNameInternal(_symbol, _name);
    }

    function setNameInternal(string memory _symbol, string memory _name) internal {
        symbol = _symbol;
        name = _name;
        emit NameChanged(_name, _symbol);
    }

}