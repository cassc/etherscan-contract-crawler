// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IMediator.sol";

contract Mediator is IMediator, AccessControlEnumerable, EIP712 {
    using Counters for Counters.Counter;

    string public constant EIP712_DOMAIN_NAME = "SUPERLOTLS MEDIATOR";
    string public constant EIP712_DOMAIN_VERSION = "1";
    bytes32 public constant ERC721_TYPEHASH =
        keccak256(
            "ERC721Data(uint256 id,uint256 price,address token,address recipient,uint256 tokensCount,uint256 nonce)"
        );
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    SuperlotlsCollection public immutable collection;

    mapping(address => Counters.Counter) private _nonces;

    function supportsInterface(bytes4 interfaceId) public view override(AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner].current();
    }

    function recover(ERC721Data calldata data) external view returns (address) {
        return _recover(data);
    }

    constructor(address collection_) EIP712(EIP712_DOMAIN_NAME, EIP712_DOMAIN_VERSION) {
        require(collection_ != address(0), "Mediator: Collection is zero address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        collection = SuperlotlsCollection(collection_);
    }

    function tokenize(ERC721Data calldata data) external {
        address signer = _recover(data);
        require(hasRole(OPERATOR_ROLE, signer), "Mediator: Signature is invalid");
        collection.mintBatch(data.recipient, data.tokensCount);
        _nonces[data.recipient].increment();
        emit Tokenized(data);
    }

    function _hash(ERC721Data calldata data) internal view returns (bytes32) {
        uint256 nonce = _nonces[data.recipient].current();
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        ERC721_TYPEHASH,
                        data.id,
                        data.price,
                        data.token,
                        data.recipient,
                        data.tokensCount,
                        nonce
                    )
                )
            );
    }

    function _recover(ERC721Data calldata data) internal view returns (address) {
        bytes32 digest = _hash(data);
        return ECDSA.recover(digest, data.signature);
    }
}