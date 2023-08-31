// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@chocolate-factory/contracts/uri-manager/UriManagerUpgradable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../interfaces/ITengriaToken.sol";

contract TengriaToken is
    ITengriaToken,
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable,
    UriManagerUpgradable,
    DefaultOperatorFiltererUpgradeable
{
    address public auctionHouseAddress;

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata prefix_,
        string calldata suffix_,
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_
    ) external initializer {
        __Ownable_init();
        __ERC721_init(name_, symbol_);
        __ERC2981_init();
        __UriManager_init(prefix_, suffix_);
        __DefaultOperatorFilterer_init();
        _setDefaultRoyalty(royaltyReceiver_, royaltyFeeNumerator_);
    }

    function mint(address to_, uint256 tokenId_) external onlyFromAuctionHouse {
        _mint(to_, tokenId_);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _buildUri(tokenId);
    }

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

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setAuctionHouseAddress(
        address auctionHouseAddress_
    ) external onlyAdmin {
        auctionHouseAddress = auctionHouseAddress_;
    }

    modifier onlyFromAuctionHouse() {
        require(
            auctionHouseAddress == msg.sender,
            "Mint only allowed from auction house"
        );
        _;
    }
}