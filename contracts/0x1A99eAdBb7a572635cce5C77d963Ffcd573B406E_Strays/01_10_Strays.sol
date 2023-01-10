// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Strays is ERC721A, IERC2981, Ownable {
    /* Events */

    /// @dev Emitted when Kittens are redeemed for a Stray.
    event StrayRescued(uint256 indexed firstKittenId, uint256 indexed secondKittenId);

    /* Enums */

    enum Sale {
        None,
        Kittens,
        Everyone
    }

    /* Storage */

    /// @notice Maximum number of Strays.
    uint256 immutable public totalStrays;

    /// @notice Kittens contract.
    IERC721 immutable public kittens;

    /// @notice What type of sale is active.
    Sale public sale;

    /// @notice Mapping of Kittens that have helped rescue a Stray.
    mapping(uint256 => bool) public rescuers;

    /// @notice Mapping of addresses that have rescued in the public adoption.
    mapping (address => bool) public adopters;

    /// @notice Count of minted Strays.
    uint256 public rescued;

    /// @notice Count of reserved Strays.
    uint256 public reserved;

    /// @notice Base token URI.
    string public straysURI;

    /// @notice Whether metadata and artwork have been revealed.
    bool public revealed;

    /// @notice Royalty percentage.
    uint256 public royalty;

    /// @notice Address of royalty recipient.
    address public treasury;

    /// @notice Placeholder metadata URI.
    string private placeholderURI;

    /* Constructor */

    constructor(address _kittens, uint256 _total) ERC721A("Stray", "STRAY") {
        kittens = IERC721(_kittens);
        totalStrays = _total;
    }

    /* Owner */

    function setSale(Sale _sale) external onlyOwner {
        sale = _sale;
    }

    function setReserved(uint256 _reserved) external onlyOwner {
        reserved = _reserved;
    }

    function setStraysURI(string calldata _uri) external onlyOwner {
        straysURI = _uri;
    }

    function setPlaceholderURI(string calldata _uri) external onlyOwner {
        placeholderURI = _uri;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /* Minting */

    function adopt() public {
        require(sale == Sale.Everyone, "Public adoption not ready");

        require(!adopters[msg.sender], "Already adopted a Stray");

        require(rescued + 1 <= totalStrays, "All Strays have been adopted");

        _adopt(msg.sender, 1);

        adopters[msg.sender] = true;
        rescued++;
    }

    function adoptWithKittens(uint256[] calldata kittenIds) public {
        require(sale == Sale.Kittens, "Kitten adoption not ready");

        uint256 amount = kittenIds.length;
        require(amount % 2 == 0, "Must adopt with an even amount of Kittens");

        // Can mint up to the total minus reserved count.
        uint256 toAdopt = amount / 2;
        uint256 available = totalStrays - reserved;
        require(rescued + toAdopt <= available, "Not enough Strays left for adoption");

        // Ensure Kittens haven't been used for adoption and are owned by caller.
        for (uint256 idx; idx < amount; ++idx) {
            uint256 kittenId = kittenIds[idx];
            require(!rescuers[kittenId], "Kitten already adopted a Stray");
            require(kittens.ownerOf(kittenId) == msg.sender, "Not your Kitten");

            rescuers[kittenId] = true;

            // Emit for every pair of Kittens.
            if (idx % 2 == 1) {
                emit StrayRescued(kittenIds[idx - 1], kittenId);
            }
        }

        _adopt(msg.sender, toAdopt);
        rescued += toAdopt;
    }

    function adoptFromOwner(address to, uint256 count) public onlyOwner {
        require(rescued + count <= totalStrays, "All Strays have been adopted");

        _adopt(to, count);
        rescued += count;
    }

    function _adopt(address to, uint256 count) internal {
        _mint(to, count);
    }

    function eligibleAdopters(uint256[] calldata kittenIds) external view returns (uint256[] memory) {
        uint256 length = kittenIds.length;
        uint256[] memory eligible = new uint256[](length);

        for (uint256 idx; idx < length; ++idx) {
            uint256 kittenId = kittenIds[idx];
            if (kittens.ownerOf(kittenId) == msg.sender && !rescuers[kittenId]) {
                eligible[idx] = kittenId;
            }
        }

        return eligible;
    }

    /* Overrides */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    /// @notice We start with token 1, to match the Kittens.
    function _startTokenId()
        internal
        pure
        override
        returns (uint256)
    {
        return 1;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return straysURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Stray hasn't been adopted");

        if (!revealed) {
            return placeholderURI;
        }

        return super.tokenURI(tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Stray hasn't been adopted");
        return (treasury, (salePrice * royalty) / 100);
    }
}