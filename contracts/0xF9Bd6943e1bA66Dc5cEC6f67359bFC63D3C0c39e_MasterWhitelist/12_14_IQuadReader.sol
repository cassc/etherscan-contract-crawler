// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

interface IQuadReader {
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    function queryFee(address _account, bytes32 _attribute)
        external
        view
        returns (uint256);

    function getAttributes(address _account, bytes32 _attribute)
        external
        payable
        returns (Attribute[] memory attributes);

    function balanceOf(address _account, bytes32 _attribute)
        external
        view 
        returns(uint256);
}