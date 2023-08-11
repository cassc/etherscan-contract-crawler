// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface ITokenMinter {
    function mint(address _gauge) external;

    function token() external view returns (address);

    function minted(address _gauge, address _account) external view returns (uint256);
}