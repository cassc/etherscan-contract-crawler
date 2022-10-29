// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/INFTKEYMarketplaceRoyalty.sol";

// @author BadSeedsNFT
// @contact [email protected]
contract BadSeeds is
    ERC721Enumerable,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxSupply = 5000;

    string public baseURI;
    string public notRevealedUri =
        "ipfs://QmVV67WN58yJ2P3rwq1QXa9xDK5smpXrMhX24uq2Rywn8a/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleMintActive = false;
    bool public publicMintActive = false;

    uint256 public presaleAmountLimit = 3;
    mapping(address => uint256) public presaleSpotsAvailable;

    uint256 public pricePublic = 0.25 ether;
    uint256 public pricePresale = 0.2 ether;

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [50, 50]; // 2 PEOPLE IN THE TEAM
    address[] private _team = [
        0x927acE2556aa3Dd4eb66C8E6eF73d25A8AAd4318, // gets 50% of the total revenue
        0xd23b684c034dD0932e4c2D3D0878030aF7f835DD // gets 50% of the total revenue
    ];

    constructor()
        ERC721("BadSeeds", "BDSEED")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
    {
        setRoyaltyInfo(address(this), 200);
    }

    function mint(address to, uint256 _amount) external payable nonReentrant {
        require(!paused, "BadSeeds: Contract is paused");
        require(_amount > 0, "BadSeeds: zero amount");

        if (msg.sender == owner()) {
            // free mints for team contributors and giveaways
        } else if (publicMintActive) {
            require(
                pricePublic * _amount <= msg.value,
                "BadSeeds: Not enough ethers sent"
            );
        } else {
            require(presaleMintActive, "BadSeeds: Presale is OFF");
            require(
                _amount <= presaleSpotsAvailable[to],
                "BadSeeds: Not enought presale spots"
            );
            presaleSpotsAvailable[to] -= _amount;

            require(
                pricePresale * _amount <= msg.value,
                "BadSeeds: Not enough ethers sent"
            );
        }

        uint256 current = totalSupply();

        require(
            current + _amount <= maxSupply,
            "BadSeeds: Max supply exceeded"
        );

        for (uint256 i = 0; i < _amount; i++) {
            _mintInternal(to);
        }
    }

    function grantPresaleSpots(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; ++i) {
            presaleSpotsAvailable[_users[i]] = presaleAmountLimit;
        }
    }

    function setPrices(uint256 _pricePresale, uint256 _pricePublic) external onlyOwner {
        pricePresale = _pricePresale;
        pricePublic = _pricePublic;
    }

    function setBaseURI(string memory _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleMintActive = !presaleMintActive;
    }

    function togglePublicSale() public onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function setRoyaltyNFTKey(
        address _nftkey,
        address _recipient,
        uint256 _feeFraction
    ) external onlyOwner {
        INFTKEYMarketplaceRoyalty(_nftkey).setRoyalty(
            address(this),
            _recipient,
            _feeFraction
        );
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function _mintInternal(address to) internal {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function priceFor(address _user) external view returns (uint256) {
        return (!publicMintActive && presaleSpotsAvailable[_user] > 0) ? pricePresale : pricePublic;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }

        return (values, cursor + length);
    }
}