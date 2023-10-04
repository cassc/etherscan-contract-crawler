// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IMiraiItem.sol";

contract MiraiItem is IMiraiItem, ERC1155, AccessControl, ERC1155Supply {
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 private _DOMAIN_SEPARATOR;
    address private signature_generator;
    string private _baseMetadataURI;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct BurnRequest {
        address account;
        uint256 tokenId;
        uint256[] ids;
        uint256 deadline;
        uint256 nonce;
    }

    mapping(address => uint256) public nonces;

    constructor(string memory _uri, address _generator) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        signature_generator = _generator;
        _baseMetadataURI = _uri;
        // Initialize the EIP-712 domain separator
        uint chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("MiraiItem")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(_baseMetadataURI).length > 0 ? string(abi.encodePacked(_baseMetadataURI, tokenId.toString())) : "";
    }

    function setURI(string memory newuri) external onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
        _baseMetadataURI = newuri;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, bytes memory data)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
        }
        _mintBatch(to, ids, amounts, data);
    }

    function burnBatch(
        address account,
        uint256 tokenId,
        uint256[] memory ids,
        uint256 deadline,
        bytes memory signature
    ) external override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        require(block.timestamp <= deadline, "MiraiItem: signature expired");

        BurnRequest memory request = _encodeBurnRequest(account, tokenId, ids, deadline);
        require(request.nonce >= nonces[account], "MiraiItem: request nonce must be greater than previous nonce");

        bytes32 digest = _hashTypedDataV4(request);
        address signer = digest.recover(signature);
        require(signer == signature_generator, "MiraiItem: invalid signature");

        nonces[account] = request.nonce;
        emit BurnBatch(account, tokenId, ids, deadline, request.nonce, signature);

        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
        }
        _burnBatch(account, ids, amounts);
    }

    function setSignatureGenerator(address _signature_generator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signature_generator = _signature_generator;
    }

    function _encodeBurnRequest(address account, uint256 tokenId, uint256[] memory ids, uint256 deadline) private returns (BurnRequest memory) {
        BurnRequest memory request = BurnRequest({
            account: account,
            tokenId: tokenId,
            ids: ids,
            deadline: deadline,
            nonce: ++nonces[account]
        });
        return request;
    }

    function _hashTypedDataV4(BurnRequest memory request) private view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("BurnRequest(address account,uint256 tokenId,uint256[] ids,uint256 deadline,uint256 nonce)"),
                request.account,
                request.tokenId,
                keccak256(abi.encodePacked(request.ids)),
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

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}