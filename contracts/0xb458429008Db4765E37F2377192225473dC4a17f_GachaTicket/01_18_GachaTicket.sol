// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interface/IGachaTicket.sol";

contract GachaTicket is IGachaTicket, ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply {
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 private _DOMAIN_SEPARATOR;
    address private signature_generator;
    string private _baseMetadataURI;

    struct MintRequest {
        address minter;
        uint256 tokenId;
        uint256 amount;
        uint256 deadline;
        uint256 nonce;
    }

    mapping(address => uint256) public nonces;

    constructor(string memory _uri, address _generator) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);

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
                keccak256(bytes("GachaTicket")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function mint(address minter, uint256 tokenId, uint256 amount, uint256 deadline, bytes memory signature) external override {
        require(block.timestamp <= deadline, "GachaTicket: signature expired");

        MintRequest memory request = _encodeMintRequest(minter, tokenId, amount, deadline);
        require(request.nonce >= nonces[minter], "GachaTicket: request nonce must be greater than previous nonce");

        bytes32 digest = _hashTypedDataV4(request);
        address signer = digest.recover(signature);
        require(signer == signature_generator, "GachaTicket: invalid signature");

        nonces[minter] = request.nonce;
        emit Mint(minter, tokenId, amount, deadline, request.nonce, signature);
        _mint(minter, tokenId, amount, "");
    }

    function _encodeMintRequest(address minter, uint256 tokenId, uint256 amount, uint256 deadline) private returns (MintRequest memory) {
        MintRequest memory request = MintRequest({
            minter: minter,
            tokenId: tokenId,
            amount: amount,
            deadline: deadline,
            nonce: ++nonces[minter]
        });
        return request;
    }

    function _hashTypedDataV4(MintRequest memory request) private view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("MintRequest(address minter,uint256 tokenId,uint256 amount,uint256 deadline,uint256 nonce)"),
                request.minter,
                request.tokenId,
                request.amount,
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

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(_baseMetadataURI).length > 0 ? string(abi.encodePacked(_baseMetadataURI, tokenId.toString())) : "";
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
        _baseMetadataURI = newuri;
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