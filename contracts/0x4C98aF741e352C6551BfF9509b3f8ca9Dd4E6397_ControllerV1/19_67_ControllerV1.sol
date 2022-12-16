pragma solidity ^0.8.7;

import "lib/ens-contracts/contracts/registry/ENS.sol";
import "lib/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import "lib/ens-contracts/contracts/resolvers/Resolver.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./interfaces/IControllerV1.sol";
import "./interfaces/IMemberToken.sol";
import "./interfaces/IControllerRegistry.sol";
import "./SafeTeller.sol";
import "./MemberTeller.sol";
import "./ens/IPodEnsRegistrar.sol";
import {BaseGuard, Enum} from "lib/safe-contracts/contracts/base/GuardManager.sol";

contract ControllerV1 is
    IControllerV1,
    SafeTeller,
    MemberTeller,
    BaseGuard,
    Ownable
{
    event CreatePod(uint256 podId, address safe, address admin, string ensName);
    event UpdatePodAdmin(uint256 podId, address admin);
    event DeregisterPod(uint256 podId);

    IControllerRegistry public immutable controllerRegistry;
    IPodEnsRegistrar public podEnsRegistrar;

    string public constant VERSION = "1.3.0";

    mapping(address => uint256) public safeToPodId;
    mapping(uint256 => address) public override podIdToSafe;
    mapping(uint256 => address) public podAdmin;
    mapping(uint256 => bool) public isTransferLocked;

    uint8 internal constant CREATE_EVENT = 0x01;

    /**
     * @dev Will instantiate safe teller with gnosis master and proxy addresses
     * @param _memberToken The address of the MemberToken contract
     * @param _controllerRegistry The address of the ControllerRegistry contract
     * @param _proxyFactoryAddress The proxy factory address
     * @param _gnosisMasterAddress The gnosis master address
     */
    constructor(
        address _owner,
        address _memberToken,
        address _controllerRegistry,
        address _proxyFactoryAddress,
        address _gnosisMasterAddress,
        address _podEnsRegistrar,
        address _fallbackHandlerAddress
    )
        SafeTeller(
            _proxyFactoryAddress,
            _gnosisMasterAddress,
            _fallbackHandlerAddress
        )
        MemberTeller(_memberToken)
    {
        require(_owner != address(0), "Invalid address");
        require(_memberToken != address(0), "Invalid address");
        require(_controllerRegistry != address(0), "Invalid address");
        require(_proxyFactoryAddress != address(0), "Invalid address");
        require(_gnosisMasterAddress != address(0), "Invalid address");
        require(_podEnsRegistrar != address(0), "Invalid address");
        require(_fallbackHandlerAddress != address(0), "Invalid address");

        // Set owner separately from msg.sender.
        transferOwnership(_owner);

        controllerRegistry = IControllerRegistry(_controllerRegistry);
        podEnsRegistrar = IPodEnsRegistrar(_podEnsRegistrar);
    }

    function updatePodEnsRegistrar(address _podEnsRegistrar)
        external
        override
        onlyOwner
    {
        require(_podEnsRegistrar != address(0), "Invalid address");
        podEnsRegistrar = IPodEnsRegistrar(_podEnsRegistrar);
    }

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
    ) external override {
        address safe = createSafe(_members, threshold, expectedPodId);

        _createPod(
            _members,
            safe,
            _admin,
            _label,
            _ensString,
            expectedPodId,
            _imageUrl
        );
    }

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
    ) external override {
        require(_safe != address(0), "invalid safe address");
        // safe must have zero'd pod id
        if (safeToPodId[_safe] == 0) {
            // if safe has zero pod id make sure its not set at pod id zero
            require(_safe != podIdToSafe[0], "safe already in use");
        } else {
            revert("safe already in use");
        }
        require(safeToPodId[_safe] == 0, "safe already in use");
        require(isSafeModuleEnabled(_safe), "safe module must be enabled");
        require(
            isSafeMember(_safe, msg.sender) || msg.sender == _safe,
            "caller must be safe or member"
        );

        address[] memory members = getSafeMembers(_safe);

        _createPod(
            members,
            _safe,
            _admin,
            _label,
            _ensString,
            expectedPodId,
            _imageUrl
        );
    }

    /**
     * @param _members The addresses of the members of the pod
     * @param _admin The address of the pod admin
     * @param _safe The address of existing safe
     * @param _label label hash of pod name (i.e labelhash('mypod'))
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function _createPod(
        address[] memory _members,
        address _safe,
        address _admin,
        bytes32 _label,
        string memory _ensString,
        uint256 expectedPodId,
        string memory _imageUrl
    ) internal {
        // add create event flag to token data
        bytes memory data = new bytes(1);
        data[0] = bytes1(uint8(CREATE_EVENT));

        uint256 podId = memberToken.createPod(_members, data);
        // The imageUrl has an expected pod ID, but we need to make sure it aligns with the actual pod ID
        require(podId == expectedPodId, "pod id didn't match, try again");

        emit CreatePod(podId, _safe, _admin, _ensString);
        emit UpdatePodAdmin(podId, _admin);

        // add controller as guard
        setSafeGuard(_safe, address(this));
        if (_admin != address(0)) {
            // will lock safe modules if admin exists
            setModuleLock(_safe, true);
            podAdmin[podId] = _admin;
        }
        podIdToSafe[podId] = _safe;
        safeToPodId[_safe] = podId;

        // setup pod ENS
        address reverseRegistrar = podEnsRegistrar.registerPod(
            _label,
            _safe,
            msg.sender
        );
        setupSafeReverseResolver(_safe, reverseRegistrar, _ensString);

        // Node is how ENS identifies names, we need that to setText
        bytes32 node = podEnsRegistrar.getEnsNode(_label);
        podEnsRegistrar.setText(node, "avatar", _imageUrl);
        podEnsRegistrar.setText(node, "podId", Strings.toString(podId));
    }

    /**
     * @dev Allows admin to unlock the safe modules and allow them to be edited by members
     * @param _podId The id number of the pod
     * @param _isLocked true - pod modules cannot be added/removed
     */
    function setPodModuleLock(uint256 _podId, bool _isLocked)
        external
        override
    {
        require(
            msg.sender == podAdmin[_podId],
            "Must be admin to set module lock"
        );
        setModuleLock(podIdToSafe[_podId], _isLocked);
    }

    /**
     * @param _podId The id number of the pod
     * @param _newAdmin The address of the new pod admin
     */
    function updatePodAdmin(uint256 _podId, address _newAdmin)
        external
        override
    {
        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        require(safe != address(0), "Pod doesn't exist");

        // if there is no admin it can only be added by safe
        if (admin == address(0)) {
            require(msg.sender == safe, "Only safe can add new admin");
        } else {
            require(msg.sender == admin, "Only admin can update admin");
        }
        // set module lock to true for non zero _newAdmin
        setModuleLock(safe, _newAdmin != address(0));

        podAdmin[_podId] = _newAdmin;

        emit UpdatePodAdmin(_podId, _newAdmin);
    }

    /**
     * @param _podId The id number of the pod
     * @param _isTransferLocked The address of the new pod admin
     */
    function setPodTransferLock(uint256 _podId, bool _isTransferLocked)
        external
        override
    {
        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        // if no pod admin it can only be set by safe
        if (admin == address(0)) {
            require(msg.sender == safe, "Only safe can set transfer lock");
        } else {
            // if admin then it can be set by admin or safe
            require(
                msg.sender == admin || msg.sender == safe,
                "Only admin or safe can set transfer lock"
            );
        }

        // set podid to transfer lock bool
        isTransferLocked[_podId] = _isTransferLocked;
    }

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
    ) external override {
        require(_newController != address(0), "Invalid address");
        require(
            _newController != address(this),
            "Cannot migrate to same controller"
        );
        require(
            controllerRegistry.isRegistered(_newController),
            "Controller not registered"
        );

        address admin = podAdmin[_podId];
        address safe = podIdToSafe[_podId];

        require(
            msg.sender == admin || msg.sender == safe,
            "User not authorized"
        );

        IControllerBase newController = IControllerBase(_newController);

        // nullify current pod state
        podAdmin[_podId] = address(0);
        podIdToSafe[_podId] = address(0);
        safeToPodId[safe] = 0;
        // update controller in MemberToken
        memberToken.migrateMemberController(_podId, _newController);
        // update safe module to _newController
        migrateSafeTeller(safe, _newController, _prevModule);
        // update pod state in _newController
        newController.updatePodState(_podId, admin, safe);
    }

    /**
     * @dev This is called by another version of controller to migrate a pod to this version
     * @dev Will only accept calls from registered controllers
     * @dev Can only be called once.
     * @param _podId The id number of the pod
     * @param _podAdmin The address of the pod admin
     * @param _safeAddress The address of the safe
     */
    function updatePodState(
        uint256 _podId,
        address _podAdmin,
        address _safeAddress
    ) external override {
        require(_safeAddress != address(0), "Invalid address");
        require(
            controllerRegistry.isRegistered(msg.sender),
            "Controller not registered"
        );
        require(
            podAdmin[_podId] == address(0) &&
                podIdToSafe[_podId] == address(0) &&
                safeToPodId[_safeAddress] == 0,
            "Pod already exists"
        );
        // if there is a pod admin, set state and lock modules
        if (_podAdmin != address(0)) {
            podAdmin[_podId] = _podAdmin;
            setModuleLock(_safeAddress, true);
        }
        podIdToSafe[_podId] = _safeAddress;
        safeToPodId[_safeAddress] = _podId;

        // add controller as guard
        setSafeGuard(_safeAddress, address(this));

        emit UpdatePodAdmin(_podId, _podAdmin);
    }

    /**
     * Ejects a safe from the Orca ecosystem. Also handles clean up for safes
     * that have already been ejected.
     * Note that the reverse registry entry cannot be cleaned up if the safe has already been ejected.
     * @param podId - ID of pod being ejected
     * @param label - labelhash of pod ENS name, i.e., `labelhash("mypod")`
     * @param previousModule - previous module
     */
    function ejectSafe(
        uint256 podId,
        bytes32 label,
        address previousModule
    ) external override {
        address safe = podIdToSafe[podId];
        address admin = podAdmin[podId];

        require(safe != address(0), "pod not registered");

        if (admin != address(0)) {
            require(msg.sender == admin, "must be admin");
            setModuleLock(safe, false);
        } else {
            require(msg.sender == safe, "tx must be sent from safe");
        }

        Resolver resolver = Resolver(podEnsRegistrar.resolver());
        bytes32 node = podEnsRegistrar.getEnsNode(label);
        address addr = resolver.addr(node);
        require(addr == safe, "safe and label didn't match");
        podEnsRegistrar.setText(node, "avatar", "");
        podEnsRegistrar.setText(node, "podId", "");
        podEnsRegistrar.setAddr(node, address(0));
        podEnsRegistrar.register(label, address(0));

        // if module is already disabled, the safe must unset these manually
        if (isSafeModuleEnabled(safe)) {
            // remove controller as guard
            setSafeGuard(safe, address(0));
            // remove module and handle reverse registration clearing.
            disableModule(
                safe,
                podEnsRegistrar.reverseRegistrar(),
                previousModule
            );
        }

        // This needs to happen before the burn to skip the transfer check.
        podAdmin[podId] = address(0);
        podIdToSafe[podId] = address(0);
        safeToPodId[safe] = 0;

        // Burn member tokens
        address[] memory members = this.getSafeMembers(safe);
        memberToken.burnSingleBatch(members, podId);

        emit DeregisterPod(podId);
    }

    function batchMintAndBurn(
        uint256 _podId,
        address[] memory _mintMembers,
        address[] memory _burnMembers
    ) external {
        address safe = podIdToSafe[_podId];
        require(
            msg.sender == safe || msg.sender == podAdmin[_podId],
            "not authorized"
        );
        memberToken.mintSingleBatch(_mintMembers, _podId, bytes(" "));
        memberToken.burnSingleBatch(_burnMembers, _podId);
    }

    /**
     * @param operator The address that initiated the action
     * @param from The address sending the membership token
     * @param to The address recieveing the membership token
     * @param ids An array of membership token ids to be transfered
     * @param data Passes a flag for an initial creation event
     */
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory data
    ) external override {
        require(msg.sender == address(memberToken), "Not Authorized");

        // only recognise data flags from this controller
        if (operator == address(this)) {
            // if create or sync event than side effects have been pre-handled
            if (data.length > 0) {
                if (uint8(data[0]) == CREATE_EVENT) return;
                if (uint8(data[0]) == SYNC_EVENT) return;
            }
            // because 1155 burn doesn't allow data we use a burn sync flag to skip side effects
            if (BURN_SYNC_FLAG == true) {
                setBurnSyncFlag(false);
                return;
            }
        }

        for (uint256 i = 0; i < ids.length; i += 1) {
            uint256 podId = ids[i];
            address safe = podIdToSafe[podId];
            address admin = podAdmin[podId];

            // If safe is 0'd, it means we're deregistering the pod, so we can skip check
            if (safe == address(0) && to == address(0)) return;

            if (from == address(0)) {
                // mint event

                // there are no rules operator must be admin, safe or controller
                require(
                    operator == safe ||
                        operator == admin ||
                        operator == address(this),
                    "No Rules Set"
                );

                onMint(to, safe);
            } else if (to == address(0)) {
                // burn event

                // there are no rules  operator must be admin, safe or controller
                require(
                    operator == safe ||
                        operator == admin ||
                        operator == address(this),
                    "No Rules Set"
                );

                onBurn(from, safe);
            } else {
                // pod cannot be locked
                require(
                    isTransferLocked[podId] == false,
                    "Pod Is Transfer Locked"
                );
                // transfer event
                onTransfer(from, to, safe);
            }
        }
    }

    /**
     * @dev This will be called by the safe at execution time time
     * _param to Destination address of Safe transaction.
     * _param value Ether value of Safe transaction.
     * @param data Data payload of Safe transaction.
     * _param operation Operation type of Safe transaction.
     * _param safeTxGas Gas that should be used for the Safe transaction.
     * _param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * _param gasPrice Gas price that should be used for the payment calculation.
     * _param gasToken Token address (or 0 if ETH) that is used for the payment.
     * _param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * _param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
     * _param msgSender Account executing safe transaction
     */
    function checkTransaction(
        address,
        uint256,
        bytes memory data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external override {
        uint256 podId = safeToPodId[msg.sender];

        if (podId == 0) {
            address safe = podIdToSafe[podId];
            // if safe is 0 its deregistered and we can skip check to allow cleanup
            if (safe == address(0)) return;
            // else require podId zero is calling from safe
            require(safe == msg.sender, "Not Authorized");
        }

        if (data.length >= 4) {
            // if safe modules are locked perform safe check
            if (areModulesLocked[msg.sender]) {
                safeTellerCheck(data);
            }
            memberTellerCheck(podId, data);
        }
    }

    function checkAfterExecution(bytes32, bool) external pure override {
        return;
    }
}