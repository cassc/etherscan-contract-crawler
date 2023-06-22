// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../access/GenArtAccess.sol";

/**
 * GEN.ART {GenArtPaymentSplitter} contract factory
 */

contract GenArtPaymentSplitterFactory is GenArtAccess {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }
    mapping(uint8 => address) public implementations;

    event Created(
        address contractAddress,
        address artist,
        address[] payeesMint,
        address[] payeesRoyalties,
        uint256[] sharesMint,
        uint256[] sharesRoyalties
    );

    constructor(address implementation_) GenArtAccess() {
        implementations[0] = implementation_;
    }

    /**
     * @dev Intenal helper method to create initializer
     */
    function _createInitializer(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,address[],address[],uint256[],uint256[])",
                owner,
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
        address artist,
        uint8 implementation,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) external onlyAdmin returns (address) {
        bytes memory initializer = _createInitializer(
            owner,
            payeesMint,
            payeesRoyalties,
            sharesMint,
            sharesRoyalties
        );
        address instance = Clones.clone(implementations[implementation]);
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
     * @dev Set the {GenArtPaymentSplitter} implementation
     */
    function setImplementation(uint8 index, address implementation_)
        external
        onlyAdmin
    {
        implementations[index] = implementation_;
    }
}