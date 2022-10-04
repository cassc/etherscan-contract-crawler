// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/extendable/extensions/Extension.sol";

interface IEATVerifierConnector {
    function setVerifier(address verifier) external;

    function getVerifier() external returns (address);
}

abstract contract EATVerifierConnectorExtension is IEATVerifierConnector, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function setVerifier(address verifier) external;\n"
            "function getVerifier() external returns (address);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](2);
        functions[0] = IEATVerifierConnector.setVerifier.selector;
        functions[1] = IEATVerifierConnector.getVerifier.selector;

        interfaces[0] = Interface(type(IEATVerifierConnector).interfaceId, functions);
    }
}