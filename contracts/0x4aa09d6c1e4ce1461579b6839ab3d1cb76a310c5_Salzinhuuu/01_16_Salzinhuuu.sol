// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./OlimpoPass.sol";

contract Salzinhuuu {
    address private olimpoPass;

    function getCreated2Addr() public view returns (address) {
        return olimpoPass;
    }

    function createDSalted(
        address _saltAddr,
        bytes32 _salt,
        address _treasury,
        address _dev,
        address _admin
    ) public pure returns (address) {
        // This complicated expression just tells you how the address
        // can be pre-computed. It is just there for illustration.
        // You actually only need ``new D{salt: salt}(arg)``.
        address predictedAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            _saltAddr,
                            _salt,
                            keccak256(
                                abi.encodePacked(
                                    type(OlimpoPass).creationCode,
                                    abi.encode(_treasury, _dev, _admin)
                                )
                            )
                        )
                    )
                )
            )
        );

        return predictedAddress;
    }

    function deploy(
        address _treasury,
        address _dev,
        address _admin,
        bytes32 _salt
    ) public payable returns (address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        OlimpoPass _olimpoPass = new OlimpoPass{salt: _salt}(
            _treasury,
            _dev,
            _admin
        );
        olimpoPass = address(_olimpoPass);
        return address(_olimpoPass);
    }
}