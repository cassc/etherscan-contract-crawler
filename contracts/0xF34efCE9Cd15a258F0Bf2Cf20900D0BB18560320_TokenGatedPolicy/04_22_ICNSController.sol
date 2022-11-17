//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface ICNSController {
    function isRegister(bytes32 _node) external view returns (bool);

    function registerDomain(
        string calldata _name,
        bytes32 _node,
        uint256 _tokenId,
        address _policy
    ) external;

    function registerSubdomain(
        string calldata _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        address _owner
    ) external;

    function getDomain(bytes32)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            address
        );

    function isDomainOwner(uint256 _tokenId, address _account)
        external
        view
        returns (bool);

    function getTokenId(bytes32 _node) external view returns (uint256);

    function unRegisterDomain(bytes32 _node) external;

    function unRegisterSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) external;

    function unRegisterSubdomainAndBurn(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) external;

    function getOwner(bytes32 _node) external view returns (address);

    function getSubDomainOwner (bytes32 _subnode) external view returns (address);
}