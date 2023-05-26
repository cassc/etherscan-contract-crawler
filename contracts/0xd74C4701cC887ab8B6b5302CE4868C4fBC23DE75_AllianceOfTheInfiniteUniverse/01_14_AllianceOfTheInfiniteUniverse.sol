// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract AllianceOfTheInfiniteUniverse is
    Ownable,
    ERC721A,
    ReentrancyGuard,
    Pausable
{
    event UpdateMaxPerTx(uint256 maxPerTx);
    event UpdateReserveTeamTokens(uint256 reserveTeamTokens);
    event UpdateTreasury(address treasury);
    event UpdateBaseURI(string baseURI);
    event UpdatePublicSalePrice(uint256 publicSalePrice);
    event UpdateMaxMintTotalPerAddress(uint256 maxMintTotalPerAddress);
    event UpdateCollectionSupply(uint256 collectionSupply);
    event UpdateEnableBurn(bool enableBurn);

    bool public enableBurn = false;

    uint256 public maxPerTx = 10000;
    uint256 public collectionSupply = 10000;
    uint256 public reserveTeamTokens = 100;
    uint256 public publicSalePrice = 0.05 ether;
    uint256 public maxMintTotalPerAddress = 10000;

    address public treasury;

    string public baseURI;

    constructor() ERC721A("Alliance of the Infinite Universe", "AIU") {
        _pause();
    }

    /* ======== MODIFIERS ======== */

    modifier callerIsTreasury() {
        require(treasury == _msgSender(), "The caller is another address");
        _;
    }

    modifier callerIsTreasuryOrOwner() {
        require(
            treasury == _msgSender() || owner() == _msgSender(),
            "The caller is another address"
        );
        _;
    }

    /* ======== SETTERS ======== */

    function setPaused(bool paused_) external onlyOwner {
        if (paused_) _pause();
        else _unpause();
    }

    function setPublicSalePrice(uint256 publicSalePrice_) external onlyOwner {
        publicSalePrice = publicSalePrice_;
        emit UpdatePublicSalePrice(publicSalePrice_);
    }

    function setCollectionSupply(uint256 collectionSupply_) external onlyOwner {
        collectionSupply = collectionSupply_;
        emit UpdateCollectionSupply(collectionSupply_);
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
        emit UpdateMaxPerTx(maxPerTx_);
    }

    function setEnableBurn(bool enableBurn_) external onlyOwner {
        enableBurn = enableBurn_;
        emit UpdateEnableBurn(enableBurn_);
    }

    function setReserveTeamTokens(uint256 reserveTeamTokens_)
        external
        onlyOwner
    {
        reserveTeamTokens = reserveTeamTokens_;
        emit UpdateReserveTeamTokens(reserveTeamTokens_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
        emit UpdateTreasury(treasury_);
    }

    function setMaxMintTotalPerAddress(uint256 maxMintTotalPerAddress_)
        external
        onlyOwner
    {
        maxMintTotalPerAddress = maxMintTotalPerAddress_;
        emit UpdateMaxMintTotalPerAddress(maxMintTotalPerAddress_);
    }

    /* ======== INTERNAL ======== */

    function _validateMint(uint256 quantity_) private {
        require(
            (totalSupply() + quantity_) <= collectionSupply,
            "AllianceOfTheInfiniteUniverse: Reached max supply"
        );
        require(
            quantity_ > 0 && quantity_ <= maxPerTx,
            "AllianceOfTheInfiniteUniverse: Reached max mint per tx"
        );
        require(
            (_numberMinted(_msgSender()) + quantity_) <= maxMintTotalPerAddress,
            "AllianceOfTheInfiniteUniverse: Reached max mint"
        );
        refundIfOver(publicSalePrice * quantity_);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /* ======== EXTERNAL ======== */

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicSaleMint(uint256 quantity_) external payable whenNotPaused {
        _validateMint(quantity_);
        _safeMint(_msgSender(), quantity_);
    }

    function teamTokensMint(address to_, uint256 quantity_)
        external
        callerIsTreasuryOrOwner
    {
        require(
            (totalSupply() + quantity_) <= collectionSupply,
            "AllianceOfTheInfiniteUniverse: Reached max supply"
        );
        require(
            (reserveTeamTokens - quantity_) >= 0,
            "AllianceOfTheInfiniteUniverse: Reached team tokens mint"
        );

        reserveTeamTokens = reserveTeamTokens - quantity_;
        emit UpdateReserveTeamTokens(reserveTeamTokens);

        _safeMint(to_, quantity_);
    }

    function withdrawEth() external callerIsTreasury nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    function withdrawPortionOfEth(uint256 withdrawAmount_)
        external
        callerIsTreasury
        nonReentrant
    {
        payable(address(treasury)).transfer(withdrawAmount_);
    }

    function burn(uint256 tokenId) external {
        require(!enableBurn, "AllianceOfTheInfiniteUniverse: !burn");

        address owner = ownerOf(tokenId);
        require(
            _msgSender() == owner,
            "AllianceOfTheInfiniteUniverse: Is not the owner of this token"
        );

        _burn(tokenId);
    }

    /* ======== OVERRIDES ======== */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }
}