// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BossBeauties is
    ERC721,
    ERC721Enumerable,
    Ownable,
    AccessControl,
    PaymentSplitter
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    using Address for address;
    using SafeMath for uint256;

    uint256 public _maxSupply;
    uint256 public _price;
    string internal _tokenBaseURI;

    mapping(address => bool) internal _presaleAllowed;
    mapping(address => bool) internal _presaleMinted;

    bool public presaleActive = false;
    bool public publicSaleActive = false;

    constructor(
        uint256 maxSupply,
        uint256 price,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721("Boss Beauties", "BOSSB") PaymentSplitter(payees, shares) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _maxSupply = maxSupply;
        _price = price;
    }

    // Modifiers
    modifier requireMint(uint256 numberOfTokens, uint256 maxPerMint) {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(numberOfTokens <= maxPerMint, "Cannot mint more than max");
        require(
            totalSupply().add(numberOfTokens) < _maxSupply,
            "Exceeded max supply"
        );
        require(
            _price.mul(numberOfTokens) == msg.value,
            "Value is not correct"
        );
        _;
    }

    // Admin
    function addPresale(address[] calldata addresses)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleAllowed[addresses[i]] = true;
        }
    }

    function startPresale() public onlyRole(ADMIN_ROLE) {
        require(presaleActive == false, "Presale is already active");

        presaleActive = true;
    }

    function pausePreale() public onlyRole(ADMIN_ROLE) {
        require(presaleActive == true, "Presale is already paused");

        presaleActive = false;
    }

    function startPublicSale() public onlyRole(ADMIN_ROLE) {
        require(publicSaleActive == false, "Sale is already active");

        publicSaleActive = true;
    }

    function pausePublicSale() public onlyRole(ADMIN_ROLE) {
        require(publicSaleActive == true, "Sale is already paused");

        publicSaleActive = false;
    }

    function setBaseURI(string memory baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenBaseURI = baseURI;
    }

    function superMint(uint256 numberOfTokens, address recipient)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(numberOfTokens > 0, "Must be greater than 0");
        require(
            totalSupply().add(numberOfTokens) < _maxSupply,
            "Exceeded max supply"
        );

        _mint(numberOfTokens, recipient);
    }

    // Presale
    function presaleMint(uint256 numberOfTokens)
        public
        payable
        requireMint(numberOfTokens, 20)
    {
        require(presaleActive == true, "Presale must be active");
        require(_presaleAllowed[_msgSender()] == true, "Not in presale");
        require(_presaleMinted[_msgSender()] == false, "Already minted");

        _presaleMinted[_msgSender()] = true;
        _mint(numberOfTokens, _msgSender());
    }

    // Public Sale
    function mint(uint256 numberOfTokens)
        public
        payable
        requireMint(numberOfTokens, 10)
    {
        require(publicSaleActive == true, "Sale must be active");

        _mint(numberOfTokens, _msgSender());
    }

    // Utility
    function presaleAllowed(address presaleAddress) public view returns (bool) {
        return _presaleAllowed[presaleAddress];
    }

    function presaleMinted(address presaleAddress) public view returns (bool) {
        return _presaleMinted[presaleAddress];
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mint(uint256 numberOfTokens, address sender) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(sender, mintIndex);
        }
    }

    // The following functions are overrides required by Solidity.
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
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}