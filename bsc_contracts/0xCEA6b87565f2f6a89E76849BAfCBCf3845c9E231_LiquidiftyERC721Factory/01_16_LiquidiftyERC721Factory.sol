// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./LiquidiftyERC721Master.sol";

contract LiquidiftyERC721Factory {
    address public impl;
    event CloneCreated(address indexed cloned);

    constructor(address _impl) {
        impl = _impl;
    }

    /**
     * @notice creates clone of impl and initializes it with given arguments
     * @param _name name of cloned collection
     * @param _symbol symbol
     * @param _tokenBaseURI tokenBaseURI
     * @param _contractURI contractURI
     * @param _collectionCreator creator
     */
    function cloneCollection(
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        string memory _tokenBaseURI,
        address _collectionCreator
    ) public {
        address cloneAddress = Clones.clone(impl);
        LiquidiftyERC721Master lcCloned = LiquidiftyERC721Master(
            cloneAddress
        );

        lcCloned.initialize(
            _name,
            _symbol,
            _tokenBaseURI,
            _contractURI,
            _collectionCreator
        );
        emit CloneCreated(cloneAddress);
    }
}