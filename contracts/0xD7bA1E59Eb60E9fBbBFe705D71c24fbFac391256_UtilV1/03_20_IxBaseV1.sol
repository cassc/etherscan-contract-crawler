//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libs/@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./libs/@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./libs/@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract IxBaseV1 is BaseRelayRecipient, AccessControlEnumerable, ReentrancyGuard {
    event ContractClosed(address indexed owner);

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    modifier nonRelayable() {
        require(!isTrustedForwarder(msg.sender), "IxBaseV1: meta transaction not allowed");

        _;
    }

    modifier nonInternalCall() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "IxBaseV1: internal call not allowed");

        _;
    }

    constructor(address admin, address forwarder) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OWNER_ROLE, admin);

        _setTrustedForwarder(forwarder);
    }

    function setForwarderAddress(address forwarder) external onlyRole(OWNER_ROLE) {
        _setTrustedForwarder(forwarder);
    }

    /**
     * close this contract
     * expected to be used when this contract is no longer needed,
     * due to contract upgrade and re-deployment
     */
    function finalize() external onlyRole(OWNER_ROLE) {
        address payable owner = payable(_msgSender());

        emit ContractClosed(owner);

        selfdestruct(owner);
    }

    /**
     * return the sender of this call.
     * should be used in the contract anywhere instead of msg.sender
     * this contract inherits two contracts wth _msgSender() (one from opengs, one from openzeppelin)
     * so specify how to override the function here.
     */
    function _msgSender()
        internal
        view
        override(BaseRelayRecipient, Context)
        returns (address ret)
    {
        return BaseRelayRecipient._msgSender();
    }

    /**
     * return the msg.data of this call.
     * should be used in the contract instead of msg.data, where this difference matters.
     * this contract inherits two contracts wth _msgSender(), so specify how to override the function here.
     */
    function _msgData()
        internal
        view
        override(BaseRelayRecipient, Context)
        returns (bytes calldata ret)
    {
        return BaseRelayRecipient._msgData();
    }

    function versionRecipient() external pure virtual override returns (string memory) {
        return "intella-base-v1;opengsn-2.2.5";
    }
}