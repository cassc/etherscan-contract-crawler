// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SFAToken is ERC20Upgradeable {
    bytes32[50] __gap;

    function initialize(address _sfaAdmin) external initializer {
        __ERC20_init("SFA Token", "SFA");
        _mint(_sfaAdmin, 150000000000000000000000000);
    }

}