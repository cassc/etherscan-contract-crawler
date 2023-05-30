// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ReturnIncorrect.sol";


abstract contract ReturnIncorrectERC20 is AccessControl, ReturnIncorrect {
    using Address for address;

    event ReturnERC20Transfer(address indexed operator, address indexed contract_, address indexed recipient, address sender, uint256 amount, bytes returndata);

    function returnERC20Transfer(
        address erc20, address recipient, uint256 amount
    ) public virtual onlyRole(RETURNER_ROLE) {
        bytes memory returndata = erc20.functionCall(
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            "ReturnIncorrectERC20: failed to call transfer(address,uint256)"
        );
        emit ReturnERC20Transfer(_msgSender(), erc20, recipient, address(this), amount, returndata);
    }
}