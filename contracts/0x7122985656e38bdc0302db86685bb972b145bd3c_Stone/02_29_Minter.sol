// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Stone} from "./Stone.sol";
import {StoneVault} from "../StoneVault.sol";

contract Minter {
    // TODO: governable upgrade
    address public stone;
    address payable public vault;

    modifier onlyVault() {
        require(msg.sender == vault, "not vault");
        _;
    }

    constructor(address _stone, address payable _vault) {
        stone = _stone;
        vault = _vault;
    }

    function mint(address _to, uint256 _amount) external onlyVault {
        Stone(stone).mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyVault {
        Stone(stone).burn(_from, _amount);
    }

    function setNewVault(address _vault) external onlyVault {
        vault = payable(_vault);
    }

    function getTokenPrice() public returns (uint256 price) {
        price = StoneVault(vault).currentSharePrice();
    }
}