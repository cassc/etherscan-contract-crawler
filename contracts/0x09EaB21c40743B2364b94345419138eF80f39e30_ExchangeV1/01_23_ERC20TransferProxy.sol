pragma solidity ^0.5.0;

import "./roles/OwnableOperatorRole.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract ERC20TransferProxy is OwnableOperatorRole {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}