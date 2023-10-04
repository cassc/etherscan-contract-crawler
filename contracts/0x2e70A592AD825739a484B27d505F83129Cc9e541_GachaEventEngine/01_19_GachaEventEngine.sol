// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interface/IGachaEventEngine.sol";
import "./interface/IMiraiItem.sol";

contract GachaEventEngine is IGachaEventEngine, Pausable, AccessControl {
    using ECDSA for bytes32;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private _DOMAIN_SEPARATOR;
    address private signature_generator;

    ERC1155Burnable public ticket;
    IMiraiItem public item;

    mapping(address => uint256) public nonces;

    struct Request {
        address user;
        uint256[] itemsId;
        uint256 deadline;
        uint256 nonce;
    }

    constructor(address signatureGenerator, ERC1155Burnable ticketContract, IMiraiItem itemContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());

        require(signatureGenerator != address(0), "GachaEventEngine: invalid signature generator");
        signature_generator = signatureGenerator;

        require(address(ticketContract) != address(0), "GachaEventEngine: invalid ticket contract");
        ticket = ticketContract;

        require(address(itemContract) != address(0), "GachaEventEngine: invalid item contract");
        item = itemContract;

        // Initialize the EIP-712 domain separator
        uint chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("GachaEventEngine")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function execute(address user, uint256[] memory itemsId, uint256 deadline, bytes memory signature) external override whenNotPaused {
        require(block.timestamp <= deadline, "GachaEventEngine: signature expired");

        Request memory request = _encodeRequest(user, itemsId, deadline);
        require(request.nonce >= nonces[user], "GachaEventEngine: request nonce must be greater than previous nonce");

        bytes32 digest = _hashTypedDataV4(request);
        address signer = digest.recover(signature);
        require(signer == signature_generator, "GachaEventEngine: invalid signature");


        nonces[user] = request.nonce;
        item.mintBatch(user, itemsId, "");

        emit Executed(user, itemsId, deadline, request.nonce, signature);
    }

    function _encodeRequest(address user, uint256[] memory itemsId, uint256 deadline) private returns (Request memory) {
        Request memory request = Request({
            user: user,
            itemsId: itemsId,
            deadline: deadline,
            nonce: ++nonces[user]
        });

        return request;
    }

    function _hashTypedDataV4(Request memory request) private view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Request(address user,uint256[] itemsId,uint256 deadline,uint256 nonce)"),
                request.user,
                keccak256(abi.encodePacked(request.itemsId)),
                request.deadline,
                request.nonce
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                _DOMAIN_SEPARATOR,
                structHash
            )
        );
        return digest;
    }

    function setSignatureGenerator(address _signature_generator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signature_generator = _signature_generator;
    }

    function setItemAddress(IMiraiItem _item) public onlyRole(DEFAULT_ADMIN_ROLE) {
        item = _item;
    }

    function setTicketAddress(ERC1155Burnable _ticket) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ticket = _ticket;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}