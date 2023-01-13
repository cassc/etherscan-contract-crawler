// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./LQT721Ownable.sol";

contract LQT721Factory is Ownable {
    address public implementation;
    event CloneCreated(address indexed clone);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice creates clone of implementation and initializes it with given arguments
     * @param name name of cloned collection
     * @param symbol symbol
     * @param tokenBaseURI tokenBaseURI
     * @param contractURI contractURI
     * @param collectionCreator creator
     */
    function cloneCollection(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory tokenBaseURI,
        address collectionCreator
    ) public {
        address cloneAddress = Clones.clone(implementation);
        LQT721Ownable clone = LQT721Ownable(
            cloneAddress
        );

        clone.initialize(
            name,
            symbol,
            tokenBaseURI,
            contractURI,
            collectionCreator
        );
        emit CloneCreated(cloneAddress);
    }
}