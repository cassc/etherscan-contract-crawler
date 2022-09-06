// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { OnApprove } from "../interfaces/OnApprove.sol";
import { IERC20Receiver } from "../interfaces/IERC20Receiver.sol";

abstract contract ERC20ApproveAndCall  {
    using Address  for address;

    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC20Receiver(0).onERC20Received.selector`
    */
    bytes4 constant ERC20_RECEIVED = 0x4fc35859;

    function _callOnApprove(address owner, address spender, uint256 amount, bytes memory data) internal {
        bytes4 onApproveSelector = OnApprove(spender).onApprove.selector;

        require(ERC165Checker.supportsInterface(spender, onApproveSelector),"approveAndCall: spender doesn't support onApprove");

        (bool ok, bytes memory res) = spender.call(
            abi.encodeWithSelector(
                onApproveSelector,
                owner,
                spender,
                amount,
                data
            )
        );

        // check if low-level call reverted or not
        require(ok, string(res));

        assembly {
            ok := mload(add(res, 0x20))
        }

        // check if OnApprove.onApprove returns true or false
        require(ok, "approveAndCall: failed to call onApprove");
    }

     /**
     * @dev Internal function to invoke `onERC20Received` on a target address.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnERC20Received(address sender, address recipient, uint256 amount, bytes memory _data)
        internal returns (bool)
    {
        if (!recipient.isContract()) {
            return true;
        }

        bytes4 retval = IERC20Receiver(recipient).onERC20Received(msg.sender, sender, amount, _data);

        return (retval == ERC20_RECEIVED);
    }

}