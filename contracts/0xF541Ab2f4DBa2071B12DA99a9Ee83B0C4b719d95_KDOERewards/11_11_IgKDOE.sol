// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGKDOE {
    function depositForStaking(address account, uint256 amount)
        external
        returns (bool);

    function withdrawFromStaking(address account, uint256 amount)
        external
        returns (bool);
}