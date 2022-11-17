//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./Policy.sol";
import "../interfaces/ICNSController.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AllowlistPolicy is Policy, EIP712 {
    constructor(
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr,
        address _cnsControllerAddr,
        string memory _name,
        string memory _version
    )
        Policy(_ensAddr, _baseRegistrarAddr, _resolverAddr, _cnsControllerAddr)
        EIP712(_name, _version)
    {
        require(_ensAddr != address(0), "Invalid address");
        require(_baseRegistrarAddr != address(0), "Invalid address");
        require(_resolverAddr != address(0), "Invalid address");
        require(_cnsControllerAddr != address(0), "Invalid address");
    }

    function registerSubdomain(
        string memory _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        bytes memory signature
    ) public {
        require(
            _verify(_hash(_node, msg.sender), signature) ==
                cnsController.getOwner(_node),
            "Invalid signature"
        );
        cnsController.registerSubdomain(
            _subdomainLabel,
            _node,
            _subnode,
            msg.sender
        );
    }

    function subDomainForOwner(
        string memory _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(cnsController.getOwner(_node) == msg.sender, "Not Owner");
        cnsController.registerSubdomain(
            _subdomainLabel,
            _node,
            _subnode,
            msg.sender
        );
    }

    function unRegisterSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ) || (cnsController.getSubDomainOwner(_subnode) == msg.sender),
            "Not owner"
        );
        cnsController.unRegisterSubdomain(_subDomainLabel, _node, _subnode);
    }

    function _hash(bytes32 node, address allowAddress)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Allowlist(bytes32 node,address allowAddress)"
                        ),
                        node,
                        allowAddress
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(digest, signature);
    }
}