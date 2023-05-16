// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMarketplace.sol";

contract KompeteMarketplaceManager is AccessControl {
    enum ActionRequestType {
        // operator actions
        SetFeeRecipient,
        SetMintRecipient,
        AddCollection,
        RemoveCollection,
        SetLockDuration,
        // admin actions
        GrantAdmin,
        RevokeAdmin,
        GrantOperator,
        RevokeOperator,
        GrantPauser,
        RevokePauser,
        TransferOwnership
    }

    enum ActionRequestStatus {
        Submitted,
        Executed,
        Canceled
    }

    struct ActionRequest {
        ActionRequestType action;
        ActionRequestStatus status;
        uint256 date;
        uint256[] values;
        address[] addresses;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IMarketplace public immutable marketplace;

    uint256 public lockDuration;

    uint256 private _requestsCount;
    mapping(uint256 => ActionRequest) public requests;

    event ActionSubmitted(address indexed by, uint256 indexed requestId);
    event ActionExecuted(address indexed by, uint256 indexed requestId);
    event ActionCanceled(address indexed by, uint256 indexed requestId);

    event LockDurationChanged(address indexed by, uint256 duration);

    modifier onlyPausers() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Pauser role required");
        _;
    }

    constructor(IMarketplace marketplace_, address admin_) {
        require(address(marketplace_) != address(0), "Invalid marketplace address");
        require(admin_ != address(0), "Invalid admin address");

        marketplace = marketplace_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
        _setupRole(PAUSER_ROLE, admin_);
    }

    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0), "Invalid address");
        marketplace.transferOwnership(newOwner);
    }

    function _setLockDuration(uint256 duration) private {
        lockDuration = duration;
        emit LockDurationChanged(msg.sender, duration);
    }

    function _setFeeRecipient(address recipient) private {
        require(recipient != address(0), "Invalid address");
        marketplace.setProtocolFeeRecipient(recipient);
    }

    function _setMintRecipient(address collection, address recipient) private {
        marketplace.setMintFeeRecipient(collection, recipient);
    }

    function _toggleCollection(address collection, bool allowed) private {
        marketplace.toggleCollection(collection, allowed);
    }

    function submit(
        ActionRequestType action,
        address[] calldata addresses,
        uint256[] calldata values
    ) external returns (uint256) {
        bool isAdmin = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
        if (isAdmin) {
            if (action == ActionRequestType.RevokeAdmin) {
                // prevent revoking self
                for (uint256 i = 0; i < addresses.length; i++) {
                    require(addresses[i] != msg.sender, "Can't revoke self admin");
                }
            }
        } else {
            require(action <= ActionRequestType.SetLockDuration, "Admin role required");
            require(hasRole(OPERATOR_ROLE, _msgSender()), "Admin or operator role required");
        }

        _requestsCount += 1;
        uint256 requestId = _requestsCount;

        requests[requestId] = ActionRequest({
            action: action,
            status: ActionRequestStatus.Submitted,
            date: block.number,
            values: values,
            addresses: addresses
        });

        emit ActionSubmitted(msg.sender, requestId);
        return requestId;
    }

    function execute(uint256 requestId) external {
        require(requests[requestId].status == ActionRequestStatus.Submitted, "Invalid Status");
        require(requests[requestId].date + lockDuration <= block.number, "Too soon");

        requests[requestId].status = ActionRequestStatus.Executed;
        ActionRequestType action = requests[requestId].action;

        if (action == ActionRequestType.SetFeeRecipient) {
            _setFeeRecipient(requests[requestId].addresses[0]);
        } else if (action == ActionRequestType.SetMintRecipient) {
            _setMintRecipient(requests[requestId].addresses[0], requests[requestId].addresses[1]);
        } else if (action == ActionRequestType.AddCollection) {
            _toggleCollection(requests[requestId].addresses[0], true);
        } else if (action == ActionRequestType.RemoveCollection) {
            _toggleCollection(requests[requestId].addresses[0], false);
        } else if (action == ActionRequestType.SetLockDuration) {
            _setLockDuration(requests[requestId].values[0]);
        }
        // admin
        else if (action == ActionRequestType.GrantAdmin) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _grantRole(DEFAULT_ADMIN_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.RevokeAdmin) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _revokeRole(DEFAULT_ADMIN_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.GrantOperator) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _grantRole(OPERATOR_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.RevokeOperator) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _revokeRole(OPERATOR_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.GrantPauser) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _grantRole(PAUSER_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.RevokePauser) {
            for (uint256 i = 0; i < requests[requestId].addresses.length; i++) {
                _revokeRole(PAUSER_ROLE, requests[requestId].addresses[i]);
            }
        } else if (action == ActionRequestType.TransferOwnership) {
            _transferOwnership(requests[requestId].addresses[0]);
        }
        // revert
        else {
            revert("Invalid action");
        }

        emit ActionExecuted(msg.sender, requestId);
    }

    function cancel(uint256 requestId) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "Admin or operator role required"
        );
        require(requests[requestId].status == ActionRequestStatus.Submitted, "Invalid Status");

        requests[requestId].status = ActionRequestStatus.Canceled;
        emit ActionCanceled(msg.sender, requestId);
    }

    function pauseMarketplace() external onlyPausers {
        marketplace.pause();
    }

    function unpauseMarketplace() external onlyPausers {
        marketplace.unpause();
    }

    function grantRole(bytes32 role, address account) public override {
        revert("Must use submit!");
    }

    function revokeRole(bytes32 role, address account) public override {
        revert("Must use submit!");
    }

    function renounceRole(bytes32 role, address account) public override {
        revert("Must use submit!");
    }
}