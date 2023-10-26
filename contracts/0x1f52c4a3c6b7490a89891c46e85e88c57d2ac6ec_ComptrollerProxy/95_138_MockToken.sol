// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockToken is ERC20Burnable {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        _mint(msg.sender, uint256(100000000).mul(10**uint256(_decimals)));
    }

    function mintFor(address _who, uint256 _amount) external {
        _mint(_who, _amount);
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}