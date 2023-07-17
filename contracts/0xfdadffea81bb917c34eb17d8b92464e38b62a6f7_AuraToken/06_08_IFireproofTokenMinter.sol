// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface IFireproofTokenMinter {
    function mint(address, uint256) external;

    // ITokenMinter has a burn function, but we don't.
    // function burn(address,uint256) external;
}