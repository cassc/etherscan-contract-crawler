// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EclipseAccess} from "../access/EclipseAccess.sol";

/**
 * Eclipse {EclipsePaymentSplitter} contract factory
 */

contract EclipsePaymentSplitterFactory is EclipseAccess {
    struct Payment {
        address[] payees;
        uint24[] shares;
    }
    address public implementation;

    event Created(
        address contractAddress,
        address artist,
        address[] payeesMint,
        address[] payeesRoyalties,
        uint24[] sharesMint,
        uint24[] sharesRoyalties
    );

    constructor(address implementation_) EclipseAccess() {
        implementation = implementation_;
    }

    /**
     * @dev Intenal helper method to create initializer
     */
    function _createInitializer(
        address owner,
        address platformPayout,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint24[] memory sharesMint,
        uint24[] memory sharesRoyalties
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address,address[],address[],uint24[],uint24[])",
                owner,
                platformPayout,
                payeesMint,
                payeesRoyalties,
                sharesMint,
                sharesRoyalties
            );
    }

    /**
     * @dev Cone a {PaymentSplitter} implementation contract
     */
    function clone(
        address owner,
        address platformPayout,
        address artist,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint24[] memory sharesMint,
        uint24[] memory sharesRoyalties
    ) external onlyAdmin returns (address) {
        bytes memory initializer = _createInitializer(
            owner,
            platformPayout,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        address instance = Clones.clone(implementation);
        Address.functionCall(instance, initializer);
        emit Created(
            instance,
            artist,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        return instance;
    }

    /**
     * @dev Set the {EclipsePaymentSplitter} implementation
     */
    function setImplementation(address implementation_) external onlyAdmin {
        implementation = implementation_;
    }
}