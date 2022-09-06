pragma solidity ^0.8.0;

import "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import "../../../dependencies/openzeppelin/contracts/Address.sol";

library SafeERC721 {
   using Address for address;

    function safeApprove(
        IERC721 token,
        address spender,
        uint256 tokenId
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, tokenId));
    }

    function safeSetApprovalForAll(
        IERC721 token,
        address operator,
        bool approved
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.setApprovalForAll.selector, operator, approved));

    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC721 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC721: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC721: ERC721 operation did not succeed");
        }
    }
}