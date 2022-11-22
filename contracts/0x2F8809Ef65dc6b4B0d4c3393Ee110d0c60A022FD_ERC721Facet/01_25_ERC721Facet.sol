// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LibDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../interfaces/IERC1155Burn.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../operatorFilterer/DefaultOperatorFiltererUpgradeable.sol";
import "./BaseFacet.sol";

contract ERC721Facet is
    BaseFacet,
    ERC721Upgradeable,
    IERC2981,
    DefaultOperatorFiltererUpgradeable
{
    using Strings for uint256;

    // Array with all token ids, used for enumeration
    uint256[] internal _allTokens;

    modifier supplyAvailable(uint256 quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(totalSupply() + quantity <= _as.maxSupply, "Max Supply");
        _;
    }

    function _msgSender()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    _as.baseTokenURI,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    // Not in use (see @DiamondCutAndLoupeFacet)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Take note of the initializer modifiers.
    function initialize() external initializer onlyOwner {
        __ERC721_init("DaoDon Cases", "CASE");
        __DefaultOperatorFilterer_init();
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(
        address _methodsExposureFacetAddress
    ) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.methodsExposureFacetAddress = _methodsExposureFacetAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = _baseTokenURI;
    }

    function setRoyaltiesRecipient(address _royaltiesRecipient)
        external
        onlyOwner
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints)
        external
        onlyOwner
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setMaxSupply(uint32 _maxSupply) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxSupply = _maxSupply;
    }

    function setClaimOpen(bool _claimOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.claimOpen = _claimOpen;
    }

    // ==================== Views ====================

    function maxSupply() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxSupply;
    }

    function baseTokenURI() external view returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.baseTokenURI;
    }

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    function claimOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.claimOpen;
    }

    function tokensOwned(address _owner)
        public
        view
        returns (uint256[] memory indexes)
    {
        uint256 numTokens = totalSupply();
        uint256[] memory tokenIndexes = new uint256[](numTokens);

        uint256 count;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = _allTokens[i];
            if (ownerOf(tokenId) == _owner) {
                tokenIndexes[count] = tokenId;
                count++;
            }
        }

        // copy over the data to a correct size array
        uint256[] memory _ownedTokensIndexes = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            _ownedTokensIndexes[i] = tokenIndexes[i];
        }

        return (_ownedTokensIndexes);
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (
            _as.royaltiesRecipient,
            (_salePrice * _as.royaltiesBasisPoints) /
                LibDiamond.PERCENTAGE_DENOMINATOR
        );
    }

    // =========== ERC721 ===========

    /*
        @dev
        Allowlist marketplaces to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == LibDiamond.OPENSEA_CONDUIT) {
            // Seaport's conduit contract
            try
                LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(
                    operator,
                    LibDiamond.appStorage().seaportAddress
                )
            returns (bool isOpen) {
                if (isOpen) {
                    return true;
                }
            } catch {}
        }
        if (
            operator == LibDiamond.LOOKSRARE_ERC721_TRANSFER_MANAGER ||
            operator == LibDiamond.X2Y2_ERC721_DELEGATE
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
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

    // =========== Claim ===========

    function claim(uint16[] calldata tokenIds)
        external
        supplyAvailable(tokenIds.length)
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.claimOpen, "Claim not open");

        for (uint16 i = 0; i < tokenIds.length; ++i) {
            if (
                IERC1155Burn(_as.daodonCardAddress).balanceOf(
                    msg.sender,
                    tokenIds[i]
                ) > 0
            ) {
                IERC1155Burn(_as.daodonCardAddress).burn(
                    msg.sender,
                    tokenIds[i],
                    1
                );
                _allTokens.push(tokenIds[i]);
                _mint(msg.sender, tokenIds[i]);
            }
        }
    }

    function claimFounders() external onlyOwner supplyAvailable(90) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        // mint tokens 795 - 884
        for (uint16 i = 795; i < 885; ++i) {
            _mint(_as.royaltiesRecipient, i);
        }
    }
}