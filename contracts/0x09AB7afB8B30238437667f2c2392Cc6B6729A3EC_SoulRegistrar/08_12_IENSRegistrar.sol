// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IENSRegistrar {
    function changeRootNodeOwner(bytes32 rootNode_, address _newOwner) external;

    function register(
        string memory rootName_,
        bytes32 rootNode_,
        string calldata label_,
        address owner_
    )
    external;

    function changePermissionContract(address _newPermissionContract) external;

    function labelOwner(bytes32 rootNode_, string calldata label) external view returns (address);

    function changeLabelOwner(bytes32 rootNode_, string calldata label_, address newOwner_)
    external;
}