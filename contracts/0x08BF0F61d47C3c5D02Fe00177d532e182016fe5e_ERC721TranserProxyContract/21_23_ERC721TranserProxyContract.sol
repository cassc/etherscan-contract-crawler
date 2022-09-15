// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "../erc-721/IMarketToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "../erc-721/LibERC721LazyMint.sol";
import "../lib-part/LibAsset.sol";
import "./ITransferProxy.sol";

import "../erc-721/ContextMixin.sol";
import "../roles/OperatorRole.sol";

contract ERC721TranserProxyContract is
    EIP712Upgradeable,
    ITransferProxy,
    ContextMixin,
    OperatorRole
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    string private constant SIGNING_DOMAIN = "Market Token";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public constant REQUEST_TYPEHASH =
        keccak256(
            "Request(address contractAddress,uint8 requestType,address from,address to,uint256 tokenId)"
        );

    address private signer_;
    struct Request {
        address contractAddress;
        uint8 requestType;
        address from;
        address to;
        uint256 tokenId;
        string tokenHash;
        bytes signature;
    }

    function __ERC721ProxyContract_init(address _signer) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);

        signer_ = _signer;
    }

    function processRequest(Request memory request) public {
        require(request.signature.length == 65, "invalid signature");

        require(
            _verify(_getRequestHash(request), request.signature),
            "Signature invalid or unauthorized"
        );
        IMarketToken token = IMarketToken(request.contractAddress);
        if (request.requestType == 1) {
            token.mint(request.to, request.tokenId, request.tokenHash);
        } else if (request.requestType == 2) {
            token.transferFrom(request.from, request.to, request.tokenId);
        }
    }

    function processBatchRequest(Request[] memory requests) public {
        for (uint256 i = 0; i < requests.length; i++) {
            Request memory request = requests[i];
            require(request.signature.length == 65, "invalid signature");

            require(
                _verify(_getRequestHash(request), request.signature),
                "Signature invalid or unauthorized"
            );
            IMarketToken token = IMarketToken(request.contractAddress);
            if (request.requestType == 1) {
                token.mint(request.to, request.tokenId, request.tokenHash);
            } else if (request.requestType == 2) {
                token.transferFrom(request.from, request.to, request.tokenId);
            }
        }
    }

    function _getRequestHash(Request memory data)
        private
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        REQUEST_TYPEHASH,
                        data.contractAddress,
                        data.requestType,
                        data.from,
                        data.to,
                        data.tokenId
                    )
                )
            );
    }

    function _verify(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return signer_ == ECDSAUpgradeable.recover(digest, signature);
    }

    function transfer(LibAsset.Asset memory asset)
        external
        override
        onlyOperator
    {
        require(asset.value == 1, "erc721 value error");
        (address token, LibERC721LazyMint.Mint721Data memory data) = abi.decode(
            asset.assetType.data,
            (address, LibERC721LazyMint.Mint721Data)
        );
        IMarketToken(token).transferFromOrMint(data, asset.from, asset.to);
    }

    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}