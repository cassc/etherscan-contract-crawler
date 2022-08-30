//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./CurationManager.sol";

contract CurationManagerFactory {

    event CreatedCurationManager(
        address indexed creator,
        address indexed curationContractAddress
    );

    function createCurationManager(
        string memory _title,
        IERC721 _curationPass, 
        uint256 _curationLimit,
        bool _isActive 
    )   external returns (address) 
    {
        CurationManager newCurationManager = new CurationManager(
            _title,
            _curationPass,
            _curationLimit,
            _isActive
        );

        emit CreatedCurationManager(
            msg.sender,
            address(newCurationManager)
        );

        return address(newCurationManager);
    }
}