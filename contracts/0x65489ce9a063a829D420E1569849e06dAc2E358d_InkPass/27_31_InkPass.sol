// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./ERC721BaseUpgradeable.sol";

import {IInkPassAdmin} from "./InkPassAdmin.sol";
import {InkPassErrorsAndEvents} from "./InkPassErrorsAndEvents.sol";

// ********************************************************************************************************************** //
//                                                                                                                        //
//   IIIIIIIIII                kkkkkkkk           PPPPPPPPPPPPPPPPP                                                       //
//   I::::::::I                k::::::k           P::::::::::::::::P                                                      //
//   I::::::::I                k::::::k           P::::::PPPPPP:::::P                                                     //
//   II::::::II                k::::::k           PP:::::P     P:::::P                                                    //
//     I::::Innnn  nnnnnnnn     k:::::k    kkkkkkk  P::::P     P:::::Paaaaaaaaaaaaa      ssssssssss       ssssssssss      //
//     I::::In:::nn::::::::nn   k:::::k   k:::::k   P::::P     P:::::Pa::::::::::::a   ss::::::::::s    ss::::::::::s     //
//     I::::In::::::::::::::nn  k:::::k  k:::::k    P::::PPPPPP:::::P aaaaaaaaa:::::ass:::::::::::::s ss:::::::::::::s    //
//     I::::Inn:::::::::::::::n k:::::k k:::::k     P:::::::::::::PP           a::::as::::::ssss:::::ss::::::ssss:::::s   //
//     I::::I  n:::::nnnn:::::n k::::::k:::::k      P::::PPPPPPPPP      aaaaaaa:::::a s:::::s  ssssss  s:::::s  ssssss    //
//     I::::I  n::::n    n::::n k:::::::::::k       P::::P            aa::::::::::::a   s::::::s         s::::::s         //
//     I::::I  n::::n    n::::n k:::::::::::k       P::::P           a::::aaaa::::::a      s::::::s         s::::::s      //
//     I::::I  n::::n    n::::n k::::::k:::::k      P::::P          a::::a    a:::::assssss   s:::::s ssssss   s:::::s    //
//   II::::::IIn::::n    n::::nk::::::k k:::::k   PP::::::PP        a::::a    a:::::as:::::ssss::::::ss:::::ssss::::::s   //
//   I::::::::In::::n    n::::nk::::::k  k:::::k  P::::::::P        a:::::aaaa::::::as::::::::::::::s s::::::::::::::s    //
//   I::::::::In::::n    n::::nk::::::k   k:::::k P::::::::P         a::::::::::aa:::as:::::::::::ss   s:::::::::::ss     //
//   IIIIIIIIIInnnnnn    nnnnnnkkkkkkkk    kkkkkkkPPPPPPPPPP          aaaaaaaaaa  aaaa sssssssssss      sssssssssss       //
//                                                                                                                        //
// ********************************************************************************************************************** //

/// @custom:security-contact [email protected]
contract InkPass is ERC721BaseUpgradeable, InkPassErrorsAndEvents {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address immutable INKPASS_ADMIN;

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(uint256 => uint256) public tokenEditionId;
    mapping(uint256 => bool) public tokenRedeemed;

    struct Edition {
        uint128 maxSupply;
        uint128 mintedCount;
    }

    mapping(uint256 => Edition) public editions;
    mapping(uint256 => string) public editionURI;

    modifier onlyMinter() {
        address account = _msgSender();
        if (hasRole(MINTER_ROLE, account) || _isMinter(account)) {
            _;
        } else {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(MINTER_ROLE), 32)
                    )
                )
            );
        }
    }

    modifier onlyRedeemer(uint256 tokenId) {
        address account = _msgSender();
        if (hasRole(REDEMPTION_ROLE, account) || account == ownerOf(tokenId)) {
            _;
        } else {
            revert NotOwnerOrRedeemer();
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address admin) {
        INKPASS_ADMIN = admin;
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint96 feeNumerator,
        uint128[] memory editionMaxSupplies,
        string[] memory editionURIs
    ) public initializer {
        __ERC721Base_init(name, symbol);
        _setDefaultRoyalty(msg.sender, feeNumerator);

        for (uint256 i; i < editionMaxSupplies.length; ++i) {
            editions[i].maxSupply = editionMaxSupplies[i];
        }

        for (uint256 i; i < editionMaxSupplies.length; ++i) {
            editionURI[i] = editionURIs[i];
        }
    }

    // * PUBLIC * //

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);

        if (bytes(uri).length > 0) {
            return uri;
        }

        return editionURI[tokenEditionId[tokenId]];
    }

    // * MINTER * //

    function safeMint(
        uint256 editionId,
        address to
    ) public onlyMinter returns (uint256) {
        Edition memory edition = editions[editionId];
        if (edition.mintedCount >= edition.maxSupply) revert EditionSoldOut();

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        editions[editionId].mintedCount++;
        _setTokenEditionId(tokenId, editionId);

        _safeMint(to, tokenId);

        return tokenId;
    }

    // * ADMIN * //

    function redeem(uint256 tokenId) public onlyRedeemer(tokenId) {
        tokenRedeemed[tokenId] = true;
    }

    function setEditionMaxSupply(
        uint256 editionId,
        uint128 maxSupply
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        editions[editionId].maxSupply = maxSupply;
        emit EditionMaxSupply(editionId, maxSupply);
    }

    function setEditionURI(
        uint256 editionId,
        string memory uri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setEditionURI(editionId, uri);
    }

    function setTokenEditionIds(
        uint256[] memory tokenIds,
        uint256 editionId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < tokenIds.length; ++i) {
            _setTokenEditionId(tokenIds[i], editionId);
        }
    }

    function setTokenURI(
        uint256 tokenId,
        string memory uri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(tokenId, uri);
    }

    // * INTERNAL * //

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override onlyAllowedOperator(_msgSender()) {
        if (tokenRedeemed[tokenId]) revert TokenNotTransferable();
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _isMinter(address account) internal returns (bool) {
        return IInkPassAdmin(INKPASS_ADMIN).isMinter(account);
    }

    function _setEditionURI(uint256 editionId, string memory uri) internal {
        editionURI[editionId] = uri;
        emit EditionURI(editionId, uri);
    }

    function _setTokenEditionId(uint256 tokenId, uint256 editionId) internal {
        tokenEditionId[tokenId] = editionId;
    }
}