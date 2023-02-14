// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Base is Ownable {
    address public treasury;

    function set_treasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}