//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title IXTokenWrapper
 * @author Swarm
 * @dev XTokenWrapper Interface.
 */
interface IXTokenWrapper is IERC1155Receiver {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);

    /**
     * @dev xToken to Token registry.
     */
    function xTokenToToken(address _xToken) external view returns (address);

    /**
     * @dev Wraps `_token` into its associated xToken.
     *
     */
    function wrap(address _token, uint256 _amount) external payable returns (bool);

    /**
     * @dev Unwraps `_xToken`.
     *
     */
    function unwrap(address _xToken, uint256 _amount) external returns (bool);
}