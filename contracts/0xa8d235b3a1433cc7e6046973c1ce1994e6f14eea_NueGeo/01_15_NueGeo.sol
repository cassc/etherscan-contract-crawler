// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NueGeo is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor() ERC721("Nue Geo", "NGEO") {}

    /** READING OPEN PALETTES */

    address public openPaletteAddress;

    function setOpenPaletteAddress(address _address) public onlyOwner {
        openPaletteAddress = _address;
    }

    function requirePaletteOwner(uint256 openPaletteId) private view {
        ERC721 openPaletteContract = ERC721(openPaletteAddress);

        require(
            openPaletteContract.ownerOf(openPaletteId) == _msgSender(),
            "Palette not owned"
        );
    }

    /** ACTIVATING THE SALE **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool isActive) public onlyOwner {
        saleIsActive = isActive;
    }

    /** LIMIT MINTING PER ADDRESS **/

    bool public unlimitedMinting = false;

    mapping(address => bool) private didMint;

    function setUnlimitedMinting(bool value) public onlyOwner {
        unlimitedMinting = value;
    }

    function canMint(address minter, uint256 count)
        private
        view
        returns (bool)
    {
        return unlimitedMinting || (!didMint[minter] && count == 1);
    }

    function setDidMint(address minter) private {
        didMint[minter] = true;
    }

    /** MINTING **/

    uint256 public constant PRICE = 25000000000000000; // 0.025 ETH
    uint256 public constant MAX_TOKENS = 1950;
    uint256 public constant MULTI_MINT_AMOUNT = 5;

    Counters.Counter private _counter;

    function getMintCount() public view returns (uint256) {
        return _counter.current();
    }

    function mint(uint256[] calldata paletteIds) public payable nonReentrant {
        uint256 count = paletteIds.length;

        require(canMint(_msgSender(), count), "Minting currently limited");
        require(count <= MULTI_MINT_AMOUNT, "Multimint max is 5");
        require(
            _counter.current() + count - 1 < MAX_TOKENS,
            "Exceeds max supply"
        );
        require(saleIsActive, "Sale not active");
        require(
            PRICE * count <= msg.value,
            "Insufficient payment, 0.025 ETH per item"
        );
        for (uint256 i = 0; i < count; i++) {
            requirePaletteOwner(paletteIds[i]);
        }

        // Preconditions OK, let's mint!

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), paletteIds[i]);

            _counter.increment();
        }

        setDidMint(_msgSender());
    }

    /** OWNER */

    uint256 public constant MAX_OWNER_TOKENS = 50;

    Counters.Counter private _ownerCounter;

    function getOwnerMintCount() public view returns (uint256) {
        return _ownerCounter.current();
    }

    function ownerMint(uint256[] calldata paletteIds)
        public
        nonReentrant
        onlyOwner
    {
        uint256 count = paletteIds.length;
        require(
            _ownerCounter.current() + count - 1 < MAX_OWNER_TOKENS,
            "Exceeds max supply"
        );
        for (uint256 i = 0; i < count; i++) {
            requirePaletteOwner(paletteIds[i]);
        }

        // Preconditions OK, let's mint!

        for (uint256 i = 0; i < count; i++) {
            _safeMint(_msgSender(), paletteIds[i]);

            _ownerCounter.increment();
        }
    }

    /** WITHDRAWING **/

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /** URI HANDLING **/

    string private customBaseURI;

    function setBaseURI(string memory baseURI) external onlyOwner {
        customBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** REQUIRED OVERRIDES **/

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