// SPDX-License-Identifier: GPL-3.0
// You have made it here. Thank you.
// This is the original contract for KEMUSHI the blockchain butterfly
// Together, we will grow, develop and earn

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KEMUSHI is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint96 royaltyFeesBips;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    uint256 public maxSupply = 5555;
    bool public paused = false;
    bool public revealed = false;
    bool public public_sale = false;
    mapping(address => uint256) public onWhitelist;
    uint256 private price = 0.0 ether;
    uint256 private pricePublic = 0.1 ether;

    //free mint per wallet
    uint256 public maxMint = 1;
    //this applies to minting only. buying on secondary is open
    uint256 public maxInWallet = 2;

    //Otosan
    address[] private addressList = [
        0x0bc854245B825C83ddF477151f4b1bCC70D86Bb2
    ];

    //this wallet will be used to try and protect our investors by holding the floor price
    address private FloorProtect = 0x73D385C854438C86ca7d3B9bfe6e2BF168169EEa;

    uint256[] private shareList = [100];
    address public royaltyOwner = 0x0bc854245B825C83ddF477151f4b1bCC70D86Bb2;
    uint96 public royaltyBips = 1000;

    Counters.Counter private _tokenIds;

    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        setRoyaltyInfo(royaltyOwner, royaltyBips);
        whiteListOne(FloorProtect);
    }

    //+++++++++++++++++++++++++++++++++++++++++ *********** +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ *********** +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ *********** +++++++++++++++++++++++++++++++++++++++++

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage) onlyOwner
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ONLY OWNER +++++++++++++++++++++++++++++++++++++++++

    function reveal() public onlyOwner {
        revealed = true;
    }

    function updateURI(uint256 tokenid, string memory newURI) public onlyOwner {
        _setTokenURI(tokenid, newURI);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whiteListOne(address _addressToWhitelist) public onlyOwner {
        onWhitelist[_addressToWhitelist] = maxMint;
    }

    function whiteListMany(address[] calldata _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            onWhitelist[_addresses[i]] = maxMint;
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setPricePrivate(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPublicSale(bool _truefalse) public onlyOwner {
        public_sale = _truefalse;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
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

    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ PUBLIC READ +++++++++++++++++++++++++++++++++++++++++

    function mintPublic(uint256 _tokenAmount) public payable {
        uint256 s = totalSupply();

        require(public_sale == true, "Public mint is not enabled!");
        require(_tokenAmount > 0, "You cannot mint 0 NFT!");
        require(_tokenAmount <= maxMint, "You must mint less!");
        require(balanceOf(msg.sender) < maxInWallet, "Max tokens per wallet reached!");
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= pricePublic * _tokenAmount, "Wrong ETH input!");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // whitelist minting
    function mintPrivate() public payable {
        uint256 _tokenAmount = 1;
        uint256 s = totalSupply();
        uint256 wl = onWhitelist[msg.sender];

        require(public_sale == false, "Private mint is not enabled!");
        require(wl > 0);
        require(balanceOf(msg.sender) < maxMint, "Max private mint per wallet reached!");
        require(msg.value >= price * _tokenAmount, "Wrong ETH input!");
        delete wl;

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    function gift(uint256[] calldata gifts, address[] calldata recipient)
        external
        onlyOwner
    {
        require(gifts.length == recipient.length);
        uint256 g = 0;
        uint256 s = totalSupply();
        for (uint256 i = 0; i < gifts.length; ++i) {
            g += gifts[i];
        }
        require(s + g <= maxSupply, "Exceeded max allowed!");
        delete g;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < gifts[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

    //+++++++++++++++++++++++++++++++++++++++++ ROYALTIES +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ROYALTIES +++++++++++++++++++++++++++++++++++++++++
    //+++++++++++++++++++++++++++++++++++++++++ ROYALTIES +++++++++++++++++++++++++++++++++++++++++

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesBips;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesBips)
        public
        onlyOwner
    {
        royaltyOwner = _receiver;
        royaltyFeesBips = _royaltyFeesBips;
    }

    function royaltyInfo(uint256 _salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount //uint256 _tokenId,
        )
    {
        return (royaltyOwner, calculateRoyalty(_salePrice));
    }
}