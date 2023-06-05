// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

interface IePHTR {
    function withdrawableAmount(uint _value) external view returns (uint);
    function mint(address _recipient) external;
    function burn(address _recipient) external;
    function sync() external;
}