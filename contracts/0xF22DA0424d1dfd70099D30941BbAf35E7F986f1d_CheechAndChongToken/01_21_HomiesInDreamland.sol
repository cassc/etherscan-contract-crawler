// SPDX-License-Identifier: MIT
/// @title: Cheech and Chong Present: Homies in Dreamland
/// @author: DropHero LLC

pragma solidity ^0.8.9;

import "./lib/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract CheechAndChongToken is ERC721A, AccessControlEnumerable, Pausable, ReentrancyGuard, Ownable, IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint24 basisPoints;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint16 public MAX_SUPPLY = 10_420;
    uint16 _remainingReserved = 111;

    string _baseURIValue;

    RoyaltyInfo private _royalties;

    constructor(string memory baseURI_, address royaltyWallet) ERC721A("My Homies In Dreamland", "HOMIES", 20) {
        _baseURIValue = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _royalties.recipient = royaltyWallet;
        _royalties.basisPoints = 1000;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIValue = newBase;
    }

    function remainingReservedSupply() public view returns(uint16) {
        return _remainingReserved;
    }

    function mintTokens(uint16 numberOfTokens, address to) external
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        require(
            numberOfTokens > 0, "MINUMUM_MINT_OF_ONE"
        );

        require(
            totalSupply() + numberOfTokens + _remainingReserved <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED"
        );

        _safeMint(to, numberOfTokens);
    }

    function mintReserved(uint16 numberOfTokens, address to) external
        onlyOwner
        whenNotPaused
    {
        require(
            numberOfTokens > 0, "MINUMUM_MINT_OF_ONE"
        );

        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED"
        );

        require(
            numberOfTokens <= _remainingReserved, "MAX_RESERVES_EXCEEDED"
        );

        _safeMint(to, numberOfTokens);
        _remainingReserved -= numberOfTokens;
    }

    function setOwnersExplicit(uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setRoyaltiesPercentage(uint24 basisPoints) external onlyOwner {
        require(basisPoints <= 10000, 'BASIS_POINTS_TOO_HIGH');
        _royalties.basisPoints = basisPoints;
    }

    function setRoyaltiesAddress(address addr) external onlyOwner {
        _royalties.recipient = addr;
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (salePrice * royalties.basisPoints) / 10000;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}