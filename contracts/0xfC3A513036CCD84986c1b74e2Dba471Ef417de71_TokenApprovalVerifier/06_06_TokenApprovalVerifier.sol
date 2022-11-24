// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ITokenApprovalVerifier.sol";

contract TokenApprovalVerifier is ITokenApprovalVerifier {
    string public constant name = "CIAN.TokenVerifier";
    bytes32 immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address account,addresses[] spenders,bool enable,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x5b81b3276291d9d72597588dc491860bfd4b6f4cec1758e357b430c3b4db0619;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => bool)) public approval_enable;
    mapping(address => mapping(address => uint256)) public approvals_deadline;

    constructor() {
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

    function approvals(address account, address spender)
        external
        view
        returns (uint256, bool)
    {
        return (
            approvals_deadline[account][spender],
            approval_enable[account][spender]
        );
    }

    function revoke(address account, address[] memory spenders) external {
        require(
            OwnableUpgradeable(account).owner() == msg.sender,
            "not the owner of the address"
        );
        for (uint256 i = 0; i < spenders.length; i++) {
            approvals_deadline[account][spenders[i]] = 0;
        }

        emit ApprovalUpdate(account, spenders, false);
    }

    function approve(
        address account,
        address[] memory spenders,
        bool enable,
        uint256 deadline
    ) external override {
        require(
            OwnableUpgradeable(account).owner() == msg.sender,
            "not the owner of the address"
        );
        for (uint256 i = 0; i < spenders.length; i++) {
            approvals_deadline[account][spenders[i]] = deadline;
            approval_enable[account][spenders[i]] = enable;
        }

        emit ApprovalUpdate(account, spenders, enable);
    }

    function permit(
        address account,
        address[] memory spenders,
        bool enable,
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
                        spenders,
                        enable,
                        nonces[account]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            OwnableUpgradeable(account).owner() == recoveredAddress &&
                recoveredAddress != address(0x0),
            "not the owner of the address"
        );
        for (uint256 i = 0; i < spenders.length; i++) {
            approvals_deadline[account][spenders[i]] = deadline;
            approval_enable[account][spenders[i]] = enable;
        }
        emit ApprovalUpdate(account, spenders, enable);
    }

    function isWhitelisted(address account, address spender)
        external
        view
        override
        returns (bool)
    {
        require(approval_enable[account][spender], "Not whitelisted!");
        if (approvals_deadline[account][spender] >= block.timestamp) {
            return true;
        }
        return false;
    }
}