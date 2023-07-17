// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {DefaultOperatorFiltererUpgradeable} from
    "operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import {OperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/OperatorFiltererUpgradeable.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator-filter-registry/lib/Constants.sol";
import {IOperatorFilterRegistry} from "operator-filter-registry/IOperatorFilterRegistry.sol";
import {ERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

library ItemStorage {
    struct Layout {
        mapping(address => bool) claimableAddresses;
        uint256 orbTotalSupply;
        uint256 keyTotalSupply;
        uint256 hourglassTotalSupply;
        uint256 skateboardTotalSupply;
        string baseURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("quirkies.item.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract ItemImplementationV1 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using ItemStorage for ItemStorage.Layout;

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrNotAuthorized();
    error ErrExceedsMaxSupply();

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    uint256 constant ITEM_TYPE_MAX_SUPPLY = 5000;
    uint256 constant ORB_STARTING_ID = 0;
    uint256 constant KEY_STARTING_ID = 5000;
    uint256 constant HOURGLASS_STARTING_ID = 10000;
    uint256 constant SKATEBOARD_STARTING_ID = 15000;

    /* -------------------------------------------------------------------------- */
    /*                                    types                                   */
    /* -------------------------------------------------------------------------- */
    enum ItemType {
        Orb,
        Key,
        Hourglass,
        Skateboard
    }

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    function initialize() public initializer {
        __ERC721_init("Item", "ITEM");
        __Ownable_init();
    }

    function setupRoyalty(address teamWallet_) public onlyOwner {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isRegistered(address(this))) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), CANONICAL_CORI_SUBSCRIPTION);
            }
        }

        // erc2981 royalty - 7%
        _setDefaultRoyalty(teamWallet_, 700);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721                                   */
    /* -------------------------------------------------------------------------- */
    function _baseURI() internal view virtual override returns (string memory) {
        return ItemStorage.layout().baseURI;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    claim                                   */
    /* -------------------------------------------------------------------------- */
    function claim(address receiver_, ItemType itemType_) external {
        // check
        if (!ItemStorage.layout().claimableAddresses[msg.sender]) {
            revert ErrNotAuthorized();
        }

        // mint orb
        if (itemType_ == ItemType.Orb) {
            uint256 __orbTotalSupply = ItemStorage.layout().orbTotalSupply;
            if (__orbTotalSupply + 1 > ITEM_TYPE_MAX_SUPPLY) {
                revert ErrExceedsMaxSupply();
            }
            _mint(receiver_, ORB_STARTING_ID + __orbTotalSupply);
            ItemStorage.layout().orbTotalSupply = __orbTotalSupply + 1;
        }
        // mint key
        else if (itemType_ == ItemType.Key) {
            uint256 __keyTotalSupply = ItemStorage.layout().keyTotalSupply;
            if (__keyTotalSupply + 1 > ITEM_TYPE_MAX_SUPPLY) {
                revert ErrExceedsMaxSupply();
            }
            _mint(receiver_, KEY_STARTING_ID + __keyTotalSupply);
            ItemStorage.layout().keyTotalSupply = __keyTotalSupply + 1;
        }
        // mint hourglass
        else if (itemType_ == ItemType.Hourglass) {
            uint256 __hourglassTotalSupply = ItemStorage.layout().hourglassTotalSupply;
            if (__hourglassTotalSupply + 1 > ITEM_TYPE_MAX_SUPPLY) {
                revert ErrExceedsMaxSupply();
            }
            _mint(receiver_, HOURGLASS_STARTING_ID + __hourglassTotalSupply);
            ItemStorage.layout().hourglassTotalSupply = __hourglassTotalSupply + 1;
        }
        // mint skateboard
        else if (itemType_ == ItemType.Skateboard) {
            uint256 __skateboardTotalSupply = ItemStorage.layout().skateboardTotalSupply;
            if (__skateboardTotalSupply + 1 > ITEM_TYPE_MAX_SUPPLY) {
                revert ErrExceedsMaxSupply();
            }
            _mint(receiver_, SKATEBOARD_STARTING_ID + __skateboardTotalSupply);
            ItemStorage.layout().skateboardTotalSupply = __skateboardTotalSupply + 1;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setClaimingAddress(address addr_, bool claimable_) external onlyOwner {
        ItemStorage.layout().claimableAddresses[addr_] = claimable_;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        ItemStorage.layout().baseURI = baseURI_;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function totalSupply() external view returns (uint256) {
        return ItemStorage.layout().orbTotalSupply + ItemStorage.layout().keyTotalSupply
            + ItemStorage.layout().hourglassTotalSupply + ItemStorage.layout().skateboardTotalSupply;
    }

    /* -------------------------------------------------------------------------- */
    /*                              erc165 overrides                              */
    /* -------------------------------------------------------------------------- */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                         operator filterer overrides                        */
    /* -------------------------------------------------------------------------- */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}