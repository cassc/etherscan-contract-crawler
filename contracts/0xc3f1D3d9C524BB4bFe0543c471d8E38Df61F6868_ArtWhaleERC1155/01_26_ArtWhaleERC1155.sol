// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// solhint-disable no-empty-blocks, func-name-mixedcase

// inheritance
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./lib/TokenOperatorUpgradeable.sol";
import "./lib/RoyaltyUpgradeable.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract ArtWhaleERC1155 is
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    TokenOperatorUpgradeable,
    RoyaltyUpgradeable
{
    using AddressUpgradeable for address payable;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public constant MINT_TYPEHASH =
        keccak256(
            "Mint(address target,uint256 tokenId,uint256 tokenAmount,uint256 mintPrice,uint256 nonce,uint256 deadline)"
        );

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(uint256 => bool) public nonces;

    event Mint(
        address indexed target,
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        uint256 mintPrice,
        uint256 nonce,
        uint256 deadline,
        bytes signature
    );

    //
    // proxy constructor
    //

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address operator_,
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) external initializer {
        __ArtWhaleERC1155_init(
            name_,
            symbol_,
            uri_,
            operator_,
            defaultRoyaltyInfo_
        );
    }

    function __ArtWhaleERC1155_init(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address operator_,
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
        __ERC1155Supply_init_unchained();
        __EIP712_init_unchained(name_, "1");
        __Ownable_init_unchained();
        __DefaultOperatorFilterer_init();
        __TokenOperator_init_unchained();
        __Royalty_init_unchained();

        __ArtWhaleERC1155_init_unchained(
            name_,
            symbol_,
            uri_,
            operator_,
            defaultRoyaltyInfo_
        );
    }

    function __ArtWhaleERC1155_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory,
        address operator_,
        RoyaltyInfo[] memory defaultRoyaltyInfo_
    ) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        _setOperator(operator_);
        _setDefaultRoyalty(defaultRoyaltyInfo_);
    }

    //
    // external methods
    //

    function setURI(string memory newuri) public virtual onlyOperator {
        _setURI(newuri);
    }

    function mint(
        address target_,
        uint256 tokenId_,
        uint256 tokenAmount_,
        uint256 mintPrice_,
        uint256 nonce_,
        uint256 deadline_,
        bytes memory signature_
    ) public payable virtual {
        require(!nonces[nonce_], "ArtWhaleERC1155: nonce already used");
        require(
            block.timestamp <= deadline_,
            "ArtWhaleERC1155: expired deadline"
        );
        require(msg.value == mintPrice_, "ArtWhaleERC1155: wrong mint price");

        payable(operator()).sendValue(msg.value);

        bytes32 structHash = keccak256(
            abi.encode(
                MINT_TYPEHASH,
                target_,
                tokenId_,
                tokenAmount_,
                mintPrice_,
                nonce_,
                deadline_
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                operator(),
                digest,
                signature_
            ),
            "ArtWhaleERC1155: invalid signature"
        );

        nonces[nonce_] = true;
        _mint(target_, tokenId_, tokenAmount_, "0x");

        emit Mint({
            target: target_,
            tokenId: tokenId_,
            tokenAmount: tokenAmount_,
            mintPrice: mintPrice_,
            nonce: nonce_,
            deadline: deadline_,
            signature: signature_
        });
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC1155Upgradeable) returns (bool) {
        return
            interfaceId_ == type(IRoyalty).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    //
    // overridden methods for creator fees (https://support.opensea.io/hc/en-us/articles/1500009575482)
    //

    function setApprovalForAll(
        address operator_,
        bool approved_
    ) public virtual override onlyAllowedOperatorApproval(operator_) {
        super.setApprovalForAll(operator_, approved_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        bytes memory data_
    ) public virtual override onlyAllowedOperator(from_) {
        super.safeTransferFrom(from_, to_, tokenId_, amount_, data_);
    }

    function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) public virtual override onlyAllowedOperator(from_) {
        super.safeBatchTransferFrom(from_, to_, ids_, amounts_, data_);
    }

    //
    // internal methods
    //

    function _beforeTokenTransfer(
        address operator_,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator_, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < amounts.length; ++i) {
                totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < amounts.length; ++i) {
                totalSupply -= amounts[i];
            }
        }
    }
}