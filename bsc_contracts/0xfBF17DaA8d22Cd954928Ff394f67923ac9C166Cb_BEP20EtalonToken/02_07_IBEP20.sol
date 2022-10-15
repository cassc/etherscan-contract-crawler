// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin-contracts-4.7.3-IERC20Metadata.sol";

interface IBEP20 is IERC20Metadata {

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

}
