//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";
import "../libs/ENSController.sol";

contract Policy is ENSController {
    ICNSController public cnsController;

    constructor(
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr,
        address _cnsControllerAddr
    ) ENSController(_ensAddr, _baseRegistrarAddr, _resolverAddr) {
        require(_ensAddr != address(0), "Invalid address");
        require(_baseRegistrarAddr != address(0), "Invalid address");
        require(_resolverAddr != address(0), "Invalid address");
        cnsController = ICNSController(_cnsControllerAddr);
    }

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId
    ) public virtual {
        require(
            cnsController.isDomainOwner(_tokenId, msg.sender),
            "Already registered this Domain"
        );
        cnsController.registerDomain(_name, _node, _tokenId, msg.sender);
    }

    function unRegisterDomain(bytes32 _node) public virtual {
        require(
            cnsController.getOwner(_node) == msg.sender,
            "Only owner can unregister domain"
        );
        cnsController.unRegisterDomain(_node);
    }
}