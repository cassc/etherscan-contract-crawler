// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
import "../forwarder/Factory/CloneFactory.sol";
import "./SimpleMultiSigImpl.sol";

contract SimpleMultiSigFactory is CloneFactory {
    address public immutable implementationAddress;
    event SimpleMultiSigCreated(address newMultiSigAddress, address implementationAddress);

    constructor(address _implementationAddress) {
        implementationAddress = _implementationAddress;
    }

    // Params are the init params of MultiSigImpl
    function createSimpleMultiSig (uint threshold_, address[] memory owners_, uint chainId, bytes32 salt) external {
        address payable clone = createClone(implementationAddress, salt);
        SimpleMultiSigImpl(clone).init(threshold_, owners_, chainId);

        emit SimpleMultiSigCreated(clone, implementationAddress);
    }
}