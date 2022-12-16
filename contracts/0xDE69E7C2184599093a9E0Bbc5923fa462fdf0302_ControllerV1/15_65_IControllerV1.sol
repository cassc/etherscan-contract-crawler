pragma solidity ^0.8.7;

import "./IControllerBase.sol";

interface IControllerV1 is IControllerBase {
    function updatePodEnsRegistrar(address _podEnsRegistrar) external;

    /**
     * @param _members The addresses of the members of the pod
     * @param threshold The number of members that are required to sign a transaction
     * @param _admin The address of the pod admin
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPod(
        address[] memory _members,
        uint256 threshold,
        address _admin,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external;

    /**
     * @dev Used to create a pod with an existing safe
     * @dev Will automatically distribute membership NFTs to current safe members
     * @param _admin The address of the pod admin
     * @param _safe The address of existing safe
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function createPodWithSafe(
        address _admin,
        address _safe,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) external;

    function podIdToSafe(uint256 _podId) external view returns (address);

    /**
     * @dev Allows admin to unlock the safe modules and allow them to be edited by members
     * @param _podId The id number of the pod
     * @param _isLocked true - pod modules cannot be added/removed
     */
    function setPodModuleLock(uint256 _podId, bool _isLocked) external;

    /**
     * @param _podId The id number of the pod
     * @param _isTransferLocked The address of the new pod admin
     */
    function setPodTransferLock(uint256 _podId, bool _isTransferLocked)
        external;

    /**
     * @param _podId The id number of the pod
     * @param _newAdmin The address of the new pod admin
     */
    function updatePodAdmin(uint256 _podId, address _newAdmin) external;

    /**
     * @dev This will nullify all pod state on this controller
     * @dev Update state on _newController
     * @dev Update controller to _newController in Safe and MemberToken
     * @param _podId The id number of the pod
     * @param _newController The address of the new pod controller
     * @param _prevModule The module that points to the orca module in the safe's ModuleManager linked list
     */
    function migratePodController(
        uint256 _podId,
        address _newController,
        address _prevModule
    ) external;

    function ejectSafe(
        uint256 podId,
        bytes32 label,
        address previousModule
    ) external;
}