pragma solidity ^0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

error PermitFailed();
error TransferEthFailed();

library Utils {
    function permit(IERC20 token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = address(token).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            if (!success) {
                revert PermitFailed();
            }
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount }("");
            if (!result) {
                revert TransferEthFailed();
            }
        }
    }
}