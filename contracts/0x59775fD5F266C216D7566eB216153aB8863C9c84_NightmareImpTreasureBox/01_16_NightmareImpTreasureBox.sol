// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../util/Ownablearama.sol";

contract NightmareImpTreasureBox is
    ERC721Burnable,
    ERC721Enumerable,
    Ownablearama
{
    uint256 public constant MAX_MINTABLE_SUPPLY = 23100;
    uint256 public constant DEFAULT_MAX_SUPPLY_PER_PARTNER_COLLECTION = 500;

    uint256 public numMinted = 0;

    address public minter;

    mapping(address => uint256[]) public burnerToBurnedTokenIds;
    mapping(uint256 => address) public burnedTokenIdToBurner;

    mapping(address => uint256) public partnerCollectionToMaxSupplyOverride;
    mapping(address => uint256) public partnerCollectionToNumMinted;

    string public baseURI;

    constructor(string memory _baseURI)
        ERC721("NightmareImpTreasureBox", "IMPTREASURE")
    {
        setBaseURI(_baseURI);
    }

    function mint(address to, address partnerCollection) public {
        require(msg.sender == minter, "Only minter can mint");
        require(numMinted < MAX_MINTABLE_SUPPLY, "Max mintable supply reached");

        uint256 maxSupplyForCollection = partnerCollectionToMaxSupplyOverride[
            partnerCollection
        ] == 0
            ? DEFAULT_MAX_SUPPLY_PER_PARTNER_COLLECTION
            : partnerCollectionToMaxSupplyOverride[partnerCollection];
        require(
            partnerCollectionToNumMinted[partnerCollection] <
                maxSupplyForCollection,
            "Max mintable supply reached for partner collection"
        );

        partnerCollectionToNumMinted[partnerCollection]++;

        uint256 tokenId = numMinted;
        numMinted++;

        _mint(to, tokenId);
    }

    function ownerMint(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) public onlyOwner {
        // Note: we are not updating partner collection counts here as this is only for owner minting
        uint256 totalQuantity = 0;

        for (uint256 i = 0; i < quantities.length; i++) {
            totalQuantity += quantities[i];
        }

        require(
            numMinted + totalQuantity <= MAX_MINTABLE_SUPPLY,
            "Max mintable supply reached"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            for (uint256 j = 0; j < quantities[i]; j++) {
                uint256 tokenId = numMinted;
                numMinted++;

                _mint(recipient, tokenId);
            }
        }
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function burn(uint256 tokenId) public virtual override {
        burnedTokenIdToBurner[tokenId] = msg.sender;
        burnerToBurnedTokenIds[msg.sender].push(tokenId);

        super.burn(tokenId);
    }

    function unlockBoxes(uint256[] calldata tokenIds) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            burnedTokenIdToBurner[tokenId] = msg.sender;
            burnerToBurnedTokenIds[msg.sender].push(tokenId);

            super.burn(tokenId);
        }
    }

    function getBurnedTokenIdsByBurner(address burner)
        external
        view
        returns (uint256[] memory)
    {
        return burnerToBurnedTokenIds[burner];
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPartnerCollectionMaxSupplyOverride(
        address _partnerCollection,
        uint256 _maxSupply
    ) public onlyOwner {
        partnerCollectionToMaxSupplyOverride[_partnerCollection] = _maxSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}