// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// developed by @rev3studios
// authored by @hexzerodev

import {IERC721} from "openzeppelin/token/ERC721/ERC721.sol";
import {ERC721Upgradeable} from "openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";

library QuirkiesV1Storage {
    struct Layout {
        address quirkiesV1Address;
        bool claimOpen;
        string baseURI;
        mapping(uint256 => bool) stakedMap_deprecated;
        mapping(address => bool) stakingContractsMap;
        mapping(uint256 => address) stakedMap;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("QuirkiesImplV1.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract QuirkiesImplementationV3 is
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrStaked();
    error ErrUnauthorizedStaker();
    error ErrNotStaked();

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    function initialize(
        address quirkiesV1Address_,
        string memory baseURI_,
        address teamWallet_
    ) public initializer {
        __ERC721_init("Quirkies", "QRKS");
        __DefaultOperatorFilterer_init();
        __Ownable_init();
        __ERC2981_init();

        // initial states
        QuirkiesV1Storage.layout().quirkiesV1Address = quirkiesV1Address_;
        QuirkiesV1Storage.layout().baseURI = baseURI_;

        // erc2981 royalty - 7%
        _setDefaultRoyalty(teamWallet_, 700);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        QuirkiesV1Storage.layout().baseURI = baseURI_;
    }

    function setStakingContract(
        address stakingContract_,
        bool isStakingContract_
    ) public onlyOwner {
        QuirkiesV1Storage.layout().stakingContractsMap[
            stakingContract_
        ] = isStakingContract_;
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

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function baseURI() external view returns (string memory) {
        return QuirkiesV1Storage.layout().baseURI;
    }

    function isStaked(uint256 tokenID_) external view returns (bool) {
        return QuirkiesV1Storage.layout().stakedMap[tokenID_] != address(0);
    }

    function isStakingContract(address address_) external view returns (bool) {
        return QuirkiesV1Storage.layout().stakingContractsMap[address_];
    }

    function totalSupply() external pure returns (uint256) {
        return 5000;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   staking                                  */
    /* -------------------------------------------------------------------------- */
    function setStaked(uint256 tokenID_, bool staked_) external {
        // check is authorized
        if (!QuirkiesV1Storage.layout().stakingContractsMap[msg.sender]) {
            revert ErrUnauthorizedStaker();
        }

        // stake
        if (staked_) {
            // check not staked
            if (QuirkiesV1Storage.layout().stakedMap[tokenID_] != address(0)) {
                revert ErrStaked();
            }

            QuirkiesV1Storage.layout().stakedMap[tokenID_] = msg.sender;
        }
        // unstake
        else {
            // check staked
            if (QuirkiesV1Storage.layout().stakedMap[tokenID_] != msg.sender) {
                revert ErrNotStaked();
            }

            delete QuirkiesV1Storage.layout().stakedMap[tokenID_];
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721                                   */
    /* -------------------------------------------------------------------------- */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 firstTokenId,
        uint256
    ) internal virtual override {
        if (QuirkiesV1Storage.layout().stakedMap[firstTokenId] != address(0)) {
            revert ErrStaked();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return QuirkiesV1Storage.layout().baseURI;
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