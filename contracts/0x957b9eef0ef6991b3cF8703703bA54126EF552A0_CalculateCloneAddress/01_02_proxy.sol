// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

contract CalculateCloneAddress {

    function computeAddress(
        address _token0, 
        address _token1,
        address _implementation,
        address _creator
    )
        public
        pure
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _token0,
                _token1
            )
        );

        return Create2.computeAddress(
            keccak256(
                abi.encodePacked(
                    salt
                )
            ),
            keccak256(
                getContractCreationCode(
                    _implementation
                )
            ),
            _creator
        );
    }

    function getContractCreationCode(
        address _implementation
    )
        public
        pure
        returns (bytes memory)
    {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 prefix = 0x363d3d373d3d3d363d73;
        bytes15 suffix = 0x5af43d82803e903d91602b57fd5bf3;
        
        bytes20 targetBytes = bytes20(
            _implementation
        );

        return abi.encodePacked(
            creation, 
            prefix, 
            targetBytes, 
            suffix
        );
    }
}