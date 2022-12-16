// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1271} from "./../cryptography/interfaces/IERC1271.sol";
import {IForwarderRegistry} from "./interfaces/IForwarderRegistry.sol";
import {IERC2771} from "./interfaces/IERC2771.sol";
import {ERC2771Calldata} from "./libraries/ERC2771Calldata.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Universal Meta-Transactions Forwarder Registry.
/// @notice Users can allow specific EIP-2771 forwarders to forward meta-transactions on their behalf.
/// @dev This contract should be deployed uniquely per network, in a non-upgradeable way.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
contract ForwarderRegistry is IForwarderRegistry, IERC2771 {
    using Address for address;
    using ECDSA for bytes32;

    struct Forwarder {
        uint248 nonce;
        bool approved;
    }

    error ForwarderNotApproved(address sender, address forwarder);
    error InvalidEIP1271Signature();
    error WrongSigner();

    bytes4 private constant EIP1271_MAGICVALUE = 0x1626ba7e;
    bytes32 private constant EIP712_DOMAIN_NAME = keccak256("ForwarderRegistry");
    bytes32 private constant APPROVAL_TYPEHASH = keccak256("ForwarderApproval(address sender,address forwarder,bool approved,uint256 nonce)");

    mapping(address => mapping(address => Forwarder)) private _forwarders;

    uint256 private immutable _deploymentChainId;
    bytes32 private immutable _deploymentDomainSeparator;

    /// @notice Emitted when a forwarder is approved or disapproved.
    /// @param sender The account for which `forwarder` is approved or disapproved.
    /// @param forwarder The account approved or disapproved as forwarder.
    /// @param approved True for an approval, false for a disapproval.
    /// @param nonce The `sender`'s account nonce before the approval change.
    event ForwarderApproval(address indexed sender, address indexed forwarder, bool approved, uint256 nonce);

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _deploymentChainId = chainId;
        _deploymentDomainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @notice Disapproves a forwarder for the sender.
    /// @dev Emits a {ForwarderApproval} event.
    /// @param forwarder The address of the forwarder to disapprove.
    function removeForwarderApproval(address forwarder) external {
        Forwarder storage forwarderData = _forwarders[msg.sender][forwarder];
        _setForwarderApproval(forwarderData, msg.sender, forwarder, false, forwarderData.nonce);
    }

    /// @notice Approves or disapproves a forwarder using a signature.
    /// @dev Reverts with {InvalidEIP1271Signature} if `isEIP1271Signature` is true and the signature is reported invalid by the `sender` contract.
    /// @dev Reverts with {WrongSigner} if `isEIP1271Signature` is false and `sender` is not the actual signer.
    /// @dev Emits a {ForwarderApproval} event.
    /// @param sender The address which signed the approval of the approval.
    /// @param forwarder The address of the forwarder to change the approval of.
    /// @param approved Whether to approve or disapprove the forwarder.
    /// @param signature Signature by `sender` for approving forwarder.
    /// @param isEIP1271Signature True if `sender` is a contract that provides authorization via EIP-1271.
    function setForwarderApproval(address sender, address forwarder, bool approved, bytes calldata signature, bool isEIP1271Signature) public {
        Forwarder storage forwarderData = _forwarders[sender][forwarder];
        uint256 nonce = forwarderData.nonce;

        _requireValidSignature(sender, forwarder, approved, nonce, signature, isEIP1271Signature);
        _setForwarderApproval(forwarderData, sender, forwarder, approved, nonce);
    }

    /// @notice Forwards the meta-transaction using EIP-2771.
    /// @dev Reverts with {ForwarderNotApproved} if the caller has not been previously approved as a forwarder by the sender.
    /// @param target The destination of the call (that will receive the meta-transaction).
    /// @param data The content of the call (the `sender` address will be appended to it according to EIP-2771).
    function forward(address target, bytes calldata data) external payable {
        address sender = ERC2771Calldata.msgSender();
        if (!_forwarders[sender][msg.sender].approved) revert ForwarderNotApproved(sender, msg.sender);
        target.functionCallWithValue(abi.encodePacked(data, sender), msg.value);
    }

    /// @notice Approves the forwarder and forwards the meta-transaction using EIP-2771.
    /// @dev Reverts with {InvalidEIP1271Signature} if `isEIP1271Signature` is true and the signature is reported invalid by the `sender` contract.
    /// @dev Reverts with {WrongSigner} if `isEIP1271Signature` is false and `sender` is not the actual signer.
    /// @dev Emits a {ForwarderApproval} event.
    /// @param signature Signature by `sender` for approving the forwarder.
    /// @param isEIP1271Signature True if `sender` is a contract that provides authorization via EIP-1271.
    /// @param target The destination of the call (that will receive the meta-transaction).
    /// @param data The content of the call (the `sender` address will be appended to it according to EIP-2771).
    function approveAndForward(bytes calldata signature, bool isEIP1271Signature, address target, bytes calldata data) external payable {
        address sender = ERC2771Calldata.msgSender();
        setForwarderApproval(sender, msg.sender, true, signature, isEIP1271Signature);
        target.functionCallWithValue(abi.encodePacked(data, sender), msg.value);
    }

    /// @notice Returns the EIP-712 DOMAIN_SEPARATOR.
    /// @return domainSeparator The EIP-712 domain separator.
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // in case a fork happens, to support the chain that had to change its chainId, we compute the domain operator
        return chainId == _deploymentChainId ? _deploymentDomainSeparator : _calculateDomainSeparator(chainId);
    }

    /// @notice Gets the current nonce for the sender/forwarder pair.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return nonce The current nonce for the `sender`/`forwarder` pair.
    function getNonce(address sender, address forwarder) external view returns (uint256 nonce) {
        return _forwarders[sender][forwarder].nonce;
    }

    /// @inheritdoc IForwarderRegistry
    function isApprovedForwarder(address sender, address forwarder) external view override returns (bool) {
        return _forwarders[sender][forwarder].approved;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address) external pure override returns (bool) {
        return true;
    }

    function _requireValidSignature(
        address sender,
        address forwarder,
        bool approved,
        uint256 nonce,
        bytes calldata signature,
        bool isEIP1271Signature
    ) private view {
        bytes memory data = abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            keccak256(abi.encode(APPROVAL_TYPEHASH, sender, forwarder, approved, nonce))
        );
        if (isEIP1271Signature) {
            if (IERC1271(sender).isValidSignature(keccak256(data), signature) != EIP1271_MAGICVALUE) revert InvalidEIP1271Signature();
        } else {
            if (keccak256(data).recover(signature) != sender) revert WrongSigner();
        }
    }

    function _setForwarderApproval(Forwarder storage forwarderData, address sender, address forwarder, bool approved, uint256 nonce) private {
        forwarderData.approved = approved;
        unchecked {
            forwarderData.nonce = uint248(nonce + 1);
        }
        emit ForwarderApproval(sender, forwarder, approved, nonce);
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
                    EIP712_DOMAIN_NAME,
                    chainId,
                    address(this)
                )
            );
    }
}