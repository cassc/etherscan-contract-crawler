//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IQuadPassportMigration {
    struct Attribute {
        bytes32 value;
        uint256 epoch;
    }

    function attributes(address, bytes32, address) external view returns (Attribute memory);

    function attributesByDID(bytes32, bytes32, address) external view returns (Attribute memory);

    function balanceOf(address, uint256) external view returns(uint256);
}