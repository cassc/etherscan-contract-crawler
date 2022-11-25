/*                                                                                        
██╗    ██╗██╗     ██╗     
██║    ██║██║     ██║     
██║ █╗ ██║██║     ██║     
██║███╗██║██║     ██║     
╚███╔███╔╝███████╗███████╗
 ╚══╝╚══╝ ╚══════╝╚══════╝                                                                                                       
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./erc721a/extensions/ERC721AQueryable.sol";
import "./erc721a/IERC721A.sol";

import "./IWLLCardMetadata.sol";

abstract contract WLLCard is ERC2981, ERC721AQueryable, Ownable {
    string private _baseTokenURI = "";
    // metdata contract
    IWLLCardMetadata internal metadataContract;
    // mint roles mapping
    mapping(address => bool) public mintRoles;

    mapping(uint256 => uint256) public tokenIdToItemId;
    mapping(uint256 => uint256) public tokenIdToCampaignId;
    mapping(uint256 => uint256) public tokenIdToSeqNumber;
    mapping(uint256 => uint256) public campaignIdToMinted;

    // ============== Events ====================

    event WLLCardLegendaryMinted(
        uint256 indexed campaignId,
        address indexed owner,
        uint256 indexed tokenId
    );

    event WLLCardRareMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed itemId
    );

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        setFeeNumerator(800); // set default royalty to 8%
    }

    function mintLegendary(address to, uint256 quantity) external {
        require(mintRoles[msg.sender], "WLL: Not authorized to mint");

        _safeMint(to, quantity);
    }

    function mintLegendaryCampaign(
        address to,
        uint256 campaignId,
        uint256 quantity
    ) external {
        require(mintRoles[msg.sender], "WLL: Not authorized to mint");

        uint256 tokenId = _nextTokenId();
        uint256 minted = campaignIdToMinted[campaignId] + 1;
        for (uint256 i = 0; i < quantity; i++) {
            tokenIdToCampaignId[tokenId + i] = campaignId;
            tokenIdToSeqNumber[tokenId + i] = minted + i;

            emit WLLCardLegendaryMinted(campaignId, to, tokenId + i);
        }
        campaignIdToMinted[campaignId] += quantity;
        _safeMint(to, quantity);
    }

    function mintCardsWithItemIds(address to, uint256[] memory itemIds)
        external
    {
        require(mintRoles[msg.sender], "WLL: Unauthorized mint");
        require(
            itemIds.length > 0,
            "WLL: itemIds array length must be greater than 0"
        );

        uint256 nextTokenId = _nextTokenId();
        // write itemIds to aux data
        for (uint256 i = 0; i < itemIds.length; i++) {
            tokenIdToItemId[nextTokenId + i] = itemIds[i];

            emit WLLCardRareMinted(nextTokenId + i, to, itemIds[i]);
        }

        _safeMint(to, itemIds.length);
    }

    function setMetadataAddress(address _metadataContract) external onlyOwner {
        require(_metadataContract != address(0), "WLL: invalid address");
        metadataContract = IWLLCardMetadata(_metadataContract);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setAuthorizedMintAddress(address _mintContract, bool _status)
        external
        onlyOwner
    {
        require(_mintContract != address(0), "WLL: invalid address");
        mintRoles[_mintContract] = _status;
    }

    /**
        Override
    */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    RoyaltyInfo
    */

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    /**
        Supports interfaces
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
        receive and withdraw
    */

    receive() external payable {}

    function withdraw(uint256 amt) external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: amt}("");
        require(sent, "Failed");
    }
}