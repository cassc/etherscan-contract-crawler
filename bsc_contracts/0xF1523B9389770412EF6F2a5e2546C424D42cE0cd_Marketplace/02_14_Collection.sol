// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract Collection is IERC1155 {
    mapping(uint256 => address) public creators;

    function getFeeRecipients(uint256 id)
    external
    view
    virtual
    returns (address payable[] memory);

    function getFeeBps(uint256 id)
    external
    view
    virtual
    returns (uint256[] memory);
}