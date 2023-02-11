// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chocolate-factory/contracts/royalties/RoyaltiesUpgradable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IERC721Token.sol";

contract HelixClaims is
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    RoyaltiesUpgradable,
    DefaultOperatorFiltererUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    /*
        HELIX Legal Terms
        1. HELIX Terms of Service [https://helixmetaverse.com/tos/]
        2. HELIX Privacy Policy [https://helixmetaverse.com/privacy/]
    */

    string public constant name = "HELIX - Collectables";

    address public signer;
    IERC721Token public passToken;
    IERC721Token public landToken;
    mapping(uint256 => mapping(address => uint256)) private _accountClaims;
    mapping(uint256 => mapping(uint256 => uint256)) private _landClaims;
    mapping(uint256 => mapping(uint256 => uint256)) private _passClaims;

    struct QueryClaimsRequest {
        AccountQuery account;
        LandQuery[] lands;
        PassQuery[] passes;
    }

    struct AccountQuery {
        address account;
        uint256[] ids;
    }

    struct LandQuery {
        uint256 landId;
        uint256[] ids;
    }

    struct PassQuery {
        uint256 passId;
        uint256[] ids;
    }

    struct Claims {
        AccountClaims accountClaims;
        LandClaims[] landsClaims;
        PassClaims[] passesClaims;
    }

    struct AccountClaims {
        address account;
        uint256[] ids;
        uint256[] amounts;
    }

    struct LandClaims {
        uint256 landId;
        uint256[] ids;
        uint256[] amounts;
    }

    struct PassClaims {
        uint256 passId;
        uint256[] ids;
        uint256[] amounts;
    }

    bytes32 private constant CLAIMS_TYPE_HASH =
        keccak256(
            "Claims(AccountClaims accountClaims,LandClaims[] landsClaims,PassClaims[] passesClaims)AccountClaims(address account,uint256[] ids,uint256[] amounts)LandClaims(uint256 landId,uint256[] ids,uint256[] amounts)PassClaims(uint256 passId,uint256[] ids,uint256[] amounts)"
        );

    bytes32 private constant ACCOUNT_CLAIMS_TYPE_HASH =
        keccak256(
            "AccountClaims(address account,uint256[] ids,uint256[] amounts)"
        );

    bytes32 private constant LAND_CLAIMS_TYPE_HASH =
        keccak256("LandClaims(uint256 landId,uint256[] ids,uint256[] amounts)");

    bytes32 private constant PASS_CLAIMS_TYPE_HASH =
        keccak256("PassClaims(uint256 passId,uint256[] ids,uint256[] amounts)");

    function initialize(
        address royaltiesRecipient_,
        uint256 royaltiesValue_,
        string calldata uri_,
        address signer_,
        address passTokenAddress_,
        address landTokenAddress_
    ) public initializer {
        __Ownable_init_unchained();
        __ERC1155_init_unchained(uri_);
        __AdminManager_init_unchained();
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
        __DefaultOperatorFilterer_init();
        __EIP712_init_unchained("", "");
        setSigner(signer_);
        setPassToken(passTokenAddress_);
        setLandToken(landTokenAddress_);
    }

    function queryClaims(
        QueryClaimsRequest calldata request_
    ) external view returns (Claims memory) {
        Claims memory claims;

        uint256[] calldata accountIds = request_.account.ids;
        claims.accountClaims.account = request_.account.account;
        claims.accountClaims.ids = new uint256[](accountIds.length);
        claims.accountClaims.amounts = new uint256[](accountIds.length);
        for (uint256 i = 0; i < accountIds.length; i++) {
            uint256 id = accountIds[i];
            claims.accountClaims.ids[i] = id;
            claims.accountClaims.amounts[i] = _accountClaims[id][
                request_.account.account
            ];
        }

        claims.landsClaims = new LandClaims[](request_.lands.length);
        for (uint256 i = 0; i < request_.lands.length; i++) {
            LandQuery memory landQuery = request_.lands[i];
            uint256[] memory landIds = landQuery.ids;
            claims.landsClaims[i].landId = landQuery.landId;
            claims.landsClaims[i].ids = new uint256[](landIds.length);
            claims.landsClaims[i].amounts = new uint256[](landIds.length);
            for (uint256 j = 0; j < landIds.length; j++) {
                uint256 id = landIds[j];
                claims.landsClaims[i].ids[j] = id;
                claims.landsClaims[i].amounts[j] = _landClaims[id][
                    landQuery.landId
                ];
            }
        }

        claims.passesClaims = new PassClaims[](request_.passes.length);
        for (uint256 i = 0; i < request_.passes.length; i++) {
            PassQuery memory passQuery = request_.passes[i];
            uint256[] memory passIds = passQuery.ids;
            claims.passesClaims[i].passId = passQuery.passId;
            claims.passesClaims[i].ids = new uint256[](passIds.length);
            claims.passesClaims[i].amounts = new uint256[](passIds.length);
            for (uint256 j = 0; j < passIds.length; j++) {
                uint256 id = passIds[j];
                claims.passesClaims[i].ids[j] = id;
                claims.passesClaims[i].amounts[j] = _passClaims[id][
                    passQuery.passId
                ];
            }
        }

        return claims;
    }

    function claim(
        uint256 claimSize_,
        Claims calldata claims_,
        bytes calldata signature_
    ) external onlyAuthorized(claims_, signature_) nonReentrant {
        require(tx.origin == msg.sender, "Only EOA allowed");

        uint256 index;
        uint256[] memory ids = new uint256[](claimSize_);
        uint256[] memory amounts = new uint256[](claimSize_);
        AccountClaims calldata accountClaims = claims_.accountClaims;
        require(
            accountClaims.account == msg.sender,
            "Unauthorized account claim"
        );

        for (uint256 i = 0; i < accountClaims.ids.length; i++) {
            uint256 id = accountClaims.ids[i];
            uint256 amount = accountClaims.amounts[i] -
                _accountClaims[id][accountClaims.account];
            if (amount > 0) {
                ids[index] = id;
                amounts[index] = amount;
                index++;
                _accountClaims[id][accountClaims.account] += amount;
            }
        }

        for (uint256 i = 0; i < claims_.landsClaims.length; i++) {
            LandClaims calldata landClaims = claims_.landsClaims[i];
            uint256 tokenId = landClaims.landId;
            require(
                landToken.ownerOf(tokenId) == msg.sender,
                "Unauthorized land claim"
            );

            for (uint256 j = 0; j < landClaims.ids.length; j++) {
                uint256 id = landClaims.ids[j];
                uint256 amount = landClaims.amounts[j] -
                    _landClaims[id][tokenId];
                if (amount > 0) {
                    ids[index] = id;
                    amounts[index] = amount;
                    index++;
                    _landClaims[id][tokenId] += amount;
                }
            }
        }

        for (uint256 i = 0; i < claims_.passesClaims.length; i++) {
            PassClaims calldata passClaims = claims_.passesClaims[i];
            uint256 tokenId = passClaims.passId;
            require(
                passToken.ownerOf(tokenId) == msg.sender,
                "Unauthorized pass claim"
            );

            for (uint256 j = 0; j < passClaims.ids.length; j++) {
                uint256 id = passClaims.ids[j];
                uint256 amount = passClaims.amounts[j] -
                    _passClaims[id][tokenId];
                if (amount > 0) {
                    ids[index] = id;
                    amounts[index] = amount;
                    index++;
                    _passClaims[id][tokenId] += amount;
                }
            }
        }

        require(ids[0] != 0, "Empty claims");
        _mintBatch(msg.sender, ids, amounts, "");
    }

    modifier onlyAuthorized(
        Claims calldata claims_,
        bytes calldata signature_
    ) {
        bytes32 structHash = hashTypedData(claims_);
        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature_);
        require(recoveredSigner == signer, "Unauthorized claim");
        _;
    }

    function hashTypedData(
        Claims calldata claims_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMS_TYPE_HASH,
                    hashTypedData(claims_.accountClaims),
                    hashTypedData(claims_.landsClaims),
                    hashTypedData(claims_.passesClaims)
                )
            );
    }

    function hashTypedData(
        PassClaims[] calldata passesClaims_
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](passesClaims_.length);
        for (uint256 i = 0; i < passesClaims_.length; i++) {
            hashes[i] = hashTypedData(passesClaims_[i]);
        }
        return keccak256(abi.encodePacked(hashes));
    }

    function hashTypedData(
        PassClaims calldata passClaims_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PASS_CLAIMS_TYPE_HASH,
                    passClaims_.passId,
                    keccak256(abi.encodePacked(passClaims_.ids)),
                    keccak256(abi.encodePacked(passClaims_.amounts))
                )
            );
    }

    function hashTypedData(
        LandClaims[] calldata landsClaims_
    ) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](landsClaims_.length);
        for (uint256 i = 0; i < landsClaims_.length; i++) {
            hashes[i] = hashTypedData(landsClaims_[i]);
        }
        return keccak256(abi.encodePacked(hashes));
    }

    function hashTypedData(
        LandClaims calldata landClaims_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LAND_CLAIMS_TYPE_HASH,
                    landClaims_.landId,
                    keccak256(abi.encodePacked(landClaims_.ids)),
                    keccak256(abi.encodePacked(landClaims_.amounts))
                )
            );
    }

    function hashTypedData(
        AccountClaims calldata struct_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ACCOUNT_CLAIMS_TYPE_HASH,
                    struct_.account,
                    keccak256(abi.encodePacked(struct_.ids)),
                    keccak256(abi.encodePacked(struct_.amounts))
                )
            );
    }

    function setSigner(address signer_) public onlyAdmin {
        signer = signer_;
    }

    function setPassToken(address passTokenAddress_) public onlyAdmin {
        passToken = IERC721Token(passTokenAddress_);
    }

    function setLandToken(address landTokenAddress_) public onlyAdmin {
        landToken = IERC721Token(landTokenAddress_);
    }

    function setURI(string calldata uri_) external onlyAdmin {
        _setURI(uri_);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _EIP712NameHash() internal pure override returns (bytes32) {
        return keccak256(bytes("HELIX"));
    }

    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes("0.1.0"));
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(RoyaltiesUpgradable, ERC1155Upgradeable)
        returns (bool)
    {
        return
            RoyaltiesUpgradable.supportsInterface(interfaceId) ||
            ERC1155Upgradeable.supportsInterface(interfaceId);
    }
}