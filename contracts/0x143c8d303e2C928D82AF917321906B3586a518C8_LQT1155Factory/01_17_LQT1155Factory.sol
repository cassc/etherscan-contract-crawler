// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./LQT1155Ownable.sol";

contract LQT1155Factory is Ownable {
    address public implementation;
    event CloneCreated(address indexed cloned);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @notice creates clone of impl and initializes it with given arguments
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
        LQT1155Ownable clone = LQT1155Ownable(
            cloneAddress
        );

        clone.initialize(
            name,
            symbol,
            contractURI,
            tokenBaseURI,
            collectionCreator
        );
        emit CloneCreated(cloneAddress);
    }
}