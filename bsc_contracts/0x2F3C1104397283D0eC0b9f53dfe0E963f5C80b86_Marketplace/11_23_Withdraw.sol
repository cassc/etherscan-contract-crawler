// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../security/Administered.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Withdraw is Administered {
    /**
     * @dev Allow the owner of the contract to withdraw BNB Owner
     */
    function withdrawOwner(
        address _a1,
        uint256 _amount
    ) external payable onlyAdmin {
        require(payable(_a1).send(_amount));
    }
}