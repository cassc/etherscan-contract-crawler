// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/iNft.sol";

contract Nft is iNft, ERC721Enumerable, IERC2981, Ownable, Pausable, ReentrancyGuard {

    constructor() ERC721("POPSTEAK", "POP") {
        _pause();
    }

    /** EVENTS */
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenBurned(address indexed owner, uint256 indexed tokenId);

    /** PUBLIC VARS */
    // max number of tokens that can be minted
    uint256 public override maxTokens = 3_000;
    // number of tokens that have been minted
    uint16 public override totalMinted;
    // address which receives the royalties
    address public royaltyAddress;
    // uri to the nft licnese
    string public licenseURI;

    /** PRIVATE VARS */
    // addresses of admins
    mapping(address => bool) private _admins;
    // nft traits
    mapping(uint256 => Trait) private _tokenTraits;
    // uri before revealing the nfts
    string private _tokenPreRevealBaseURI;
    // uri after revealing the nfts
    string private _tokenRevealBaseURI;
    // royalty permille (to support 1 decimal place)
    uint256 private _royaltyPermille = 100;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "NFT: Only admins can call this");
        _;
    }

    /** PUBLIC FUNCTIONS */
    // owner can burn their token at any time (it's their right)
    function burn(uint256 tokenId) external override nonReentrant {
        require(ownerOf(tokenId) == _msgSender(), "NFT: You are not the owner");
        emit TokenBurned(ownerOf(tokenId), tokenId);
        _burn(tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, salePrice * _royaltyPermille/1000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'NFT: Token does not exist');

        if (bytes(_tokenRevealBaseURI).length <= 0) {
            // pre reveal phase
            return _tokenPreRevealBaseURI;
        } else {
            // post reveal phase
            Trait memory tokenTraits = _tokenTraits[tokenId];
            return string(abi.encodePacked(_tokenRevealBaseURI, Strings.toString(tokenTraits.tokenType), ".json?tokenId=", Strings.toString(tokenId)));
        }
    }

    function getWalletOfOwner(address owner) external view override returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }

    function getLicenseURI() external view override returns (string memory) {
        return licenseURI;
    }

    /** ADMIN ONLY FUNCTIONS */
    function mint(address recipient, uint8 tokenType) external override whenNotPaused nonReentrant onlyAdmin {
        require(bytes(licenseURI).length > 0, "NFT: License URI has to be set");
        require(totalMinted + 1 <= maxTokens, "NFT: All tokens minted");
        require(tokenType == 1 || tokenType == 2, "NFT: Token type must be either 1 or 2");
        
        // increase mint counter
        totalMinted++;

        // add to traits
        _tokenTraits[totalMinted] = Trait({
            tokenId: totalMinted,
            tokenType: tokenType
        });

        // mint the NFT
        _safeMint(recipient, totalMinted);

        emit TokenMinted(recipient, totalMinted);
    }

    function getTokenTraits(uint256 tokenId) public view returns (Trait memory) {
        return _tokenTraits[tokenId];
    }

    function isAdmin(address addr) external view onlyAdmin returns(bool) {
        if (_admins[addr]) return true;
        return false;
    }

    /** OWNER ONLY FUNCTIONS */
    function setPreRevealBaseURI(string calldata uri) external onlyOwner {
        _tokenPreRevealBaseURI = uri;
    }

    function setRevealBaseURI(string calldata uri) external onlyOwner {
        _tokenRevealBaseURI = uri;
    }

    function unsetRevealBaseURI() external onlyOwner {
        _tokenRevealBaseURI = "";
    }

    function setPaused(bool _paused) external onlyOwner {
        require(royaltyAddress != address(0), "NFT: Royalty address must be set");
        require(bytes(licenseURI).length > 0, "NFT: License URI has to be set");
        require(bytes(_tokenPreRevealBaseURI).length > 0 || bytes(_tokenRevealBaseURI).length > 0, "NFT: PreReveal or Reveal URI must be set");
        if (_paused) _pause();
        else _unpause();
    }

    function setRoyaltyPermille(uint256 number) external onlyOwner {
        _royaltyPermille = number;
    }

    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
    }

    function setLicenseURI(string memory uri) external onlyOwner {
        licenseURI = uri;
    }

    function setMaxTokens(uint256 amount) external onlyOwner {
        require(amount <= 3_000, "NFT: Cannot inflate the supply");
        maxTokens = amount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }
}