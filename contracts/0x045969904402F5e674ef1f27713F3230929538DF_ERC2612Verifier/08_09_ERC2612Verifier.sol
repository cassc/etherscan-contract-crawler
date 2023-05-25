// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IERC2612Verifier.sol";
import "../../adapters/IAdapterManager.sol";

contract ERC2612Verifier is IERC2612Verifier {
    using ECDSA for bytes32;
    string public constant name = "CIAN.ERC2612Verifier";
    bytes32 immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address account,address operator,bytes32 approvalType,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0xd29eae1810f9a3f065590ccfa473d6fdb29545b7a5e09c439cc6b0552ad6ed86;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => bytes32)) public approvals_types;
    mapping(address => mapping(address => uint256)) public approvals_deadline;
    address public adapterManager;

    constructor(address _adapterManager) {
        adapterManager = _adapterManager;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function approvals(address account, address operator)
        external
        view
        returns (uint256, bytes32)
    {
        return (
            approvals_deadline[account][operator],
            approvals_types[account][operator]
        );
    }

    function revoke(address account, address operator) external {
        require(
            OwnableUpgradeable(account).owner() == msg.sender,
            "not the owner of the address"
        );
        approvals_deadline[account][operator] = 0;
        emit OperatorUpdate(account, operator, bytes32(0));
    }

    function approve(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline
    ) external override {
        require(
            OwnableUpgradeable(account).owner() == msg.sender,
            "not the owner of the address"
        );
        approvals_deadline[account][operator] = deadline;
        approvals_types[account][operator] = approvalType;
        emit OperatorUpdate(account, operator, approvalType);
    }

    function permit(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "Permit: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        account,
                        operator,
                        approvalType,
                        nonces[account]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = digest.recover(v, r, s);
        require(
            OwnableUpgradeable(account).owner() == recoveredAddress &&
                recoveredAddress != address(0x0),
            "not the owner of the address"
        );
        approvals_deadline[account][operator] = deadline;
        approvals_types[account][operator] = approvalType;
        emit OperatorUpdate(account, operator, approvalType);
    }

    function isTxPermitted(
        address account,
        address operator,
        address adapter
    ) external view override returns (bool) {
        IAdapterManager manager = IAdapterManager(adapterManager);
        uint256 index = manager.adaptersIndex(adapter);
        require(index >= manager.maxReservedBits(), "adapter invalid!");
        uint256 types = uint256(approvals_types[account][operator]);
        require((types >> index) & 1 == 1, "Adapter: not allowed!");
        if (approvals_deadline[account][operator] >= block.timestamp) {
            return true;
        }
        return false;
    }

    function isTxPermitted(
        address account,
        address operator,
        uint256 operationIndex
    ) external view override returns (bool) {
        require(
            operationIndex < IAdapterManager(adapterManager).maxReservedBits(),
            "operation invalid!"
        );
        uint256 types = uint256(approvals_types[account][operator]);
        require((types >> operationIndex) & 1 == 1, "Basic: not allowed!");
        if (approvals_deadline[account][operator] >= block.timestamp) {
            return true;
        }
        return false;
    }
}