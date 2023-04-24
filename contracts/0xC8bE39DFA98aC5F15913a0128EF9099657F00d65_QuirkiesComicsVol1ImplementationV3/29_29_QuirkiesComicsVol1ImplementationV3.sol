// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// developed by @rev3studios
// authored by @hexzerodev

import {IERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";

interface IQuirkiesComicsVol1 is IERC721 {
    function claimedTokens(uint256 tokenID) external returns (uint256);
}

library QuirkiesComicsV1Storage {
    struct Layout {
        address comicsV1Address;
        address quirkiesV1Address;
        address quirklingsV1Address;
        address quirkiesV2Address;
        address quirklingsV2Address;
        bool claimOpen;
        bool migrateOpen;
        uint256 totalSupply;
        string baseURI;
        mapping(uint256 => bool) claimedTokens;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("QuirklingsImplV1.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract QuirkiesComicsVol1ImplementationV3 is
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrClaimNotOpen();
    error ErrNotV2Owner();
    error ErrAlreadyClaimed();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event EvClaimedV2(address indexed sender, uint256[] tokenIDs_);

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    function initialize(
        address comicsV1Address_,
        address quirkiesV1Address_,
        address quirklingsV1Address_,
        address quirkiesV2Address_,
        address quirklingsV2Address_,
        string memory baseURI_,
        address teamWallet_
    ) public initializer {
        __ERC721_init("QuirkiesComicsVol1", "QRKC");
        __DefaultOperatorFilterer_init();
        __Ownable_init();
        __ERC2981_init();

        // initial states
        QuirkiesComicsV1Storage.layout().comicsV1Address = comicsV1Address_;
        QuirkiesComicsV1Storage.layout().quirkiesV1Address = quirkiesV1Address_;
        QuirkiesComicsV1Storage
            .layout()
            .quirklingsV1Address = quirklingsV1Address_;
        QuirkiesComicsV1Storage.layout().quirkiesV2Address = quirkiesV2Address_;
        QuirkiesComicsV1Storage
            .layout()
            .quirklingsV2Address = quirklingsV2Address_;
        QuirkiesComicsV1Storage.layout().baseURI = baseURI_;

        // erc2981 royalty - 7%
        _setDefaultRoyalty(teamWallet_, 700);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Claim token for owning V2 alpha sets (Quirkies & Quirklings with identical tokenID)
     * @param tokenIDs_ TokenIDs of posssessed Quirkies & Quirklings
     */
    function claimV2(uint256[] memory tokenIDs_) external {
        // check claimOpen
        if (!QuirkiesComicsV1Storage.layout().claimOpen) {
            revert ErrClaimNotOpen();
        }

        // loop
        for (uint256 i = 0; i < tokenIDs_.length; i++) {
            uint256 __tokenID = tokenIDs_[i];

            // check alphaSet (quirkies & quirklings same tokenID)
            if (
                !(IERC721(QuirkiesComicsV1Storage.layout().quirkiesV2Address)
                    .ownerOf(__tokenID) ==
                    msg.sender &&
                    IERC721(
                        QuirkiesComicsV1Storage.layout().quirklingsV2Address
                    ).ownerOf(__tokenID) ==
                    msg.sender)
            ) {
                revert ErrNotV2Owner();
            }

            // check claimed
            if (QuirkiesComicsV1Storage.layout().claimedTokens[__tokenID]) {
                revert ErrAlreadyClaimed();
            }

            // update state
            QuirkiesComicsV1Storage.layout().claimedTokens[__tokenID] = true;

            // mint
            _mint(msg.sender, __tokenID);
        }

        // update totalSupply
        QuirkiesComicsV1Storage.layout().totalSupply += tokenIDs_.length;

        emit EvClaimedV2(msg.sender, tokenIDs_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function toggleClaimOpen() external onlyOwner {
        QuirkiesComicsV1Storage.layout().claimOpen = !QuirkiesComicsV1Storage
            .layout()
            .claimOpen;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        QuirkiesComicsV1Storage.layout().baseURI = baseURI_;
    }

    /**
     * @dev Sets the default recommended creator royalty according to ERC2981
     * @param receiver The address for royalties to be sent to
     * @param feeNumerator Royalty in basis point (e.g. 1 == 0.01%, 500 == 5%)
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    struct Holder {
        address addr;
        uint256 tokenID;
    }

    /**
     * @dev Airdrop V1 quirkiesComics holders based on snapshot
     * @param holders_ Array of holders to airdrop
     */
    function airdrop(Holder[] memory holders_) external onlyOwner {
        // loop holders
        for (uint i = 0; i < holders_.length; ) {
            Holder memory __holder = holders_[i];
            _mint(__holder.addr, __holder.tokenID);
            unchecked {
                i++;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function baseURI() external view returns (string memory) {
        return QuirkiesComicsV1Storage.layout().baseURI;
    }

    function claimOpen() external view returns (bool) {
        return QuirkiesComicsV1Storage.layout().claimOpen;
    }

    function migrateOpen() external view returns (bool) {
        return QuirkiesComicsV1Storage.layout().migrateOpen;
    }

    function isClaimed(uint256 tokenID_) external view returns (bool) {
        return QuirkiesComicsV1Storage.layout().claimedTokens[tokenID_];
    }

    function totalSupply() external view returns (uint256) {
        return 2149 + QuirkiesComicsV1Storage.layout().totalSupply;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC721                                   */
    /* -------------------------------------------------------------------------- */
    function _baseURI() internal view virtual override returns (string memory) {
        return QuirkiesComicsV1Storage.layout().baseURI;
    }

    /* -------------------------------------------------------------------------- */
    /*                              erc165 overrides                              */
    /* -------------------------------------------------------------------------- */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                         operator filterer overrides                        */
    /* -------------------------------------------------------------------------- */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}