// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
// import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
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
    string public contractURI;
    string public baseURI;

    // You have made it here. Thank you.
    // This is the original contract for Kemushi the blockchain butterfly
    // Together, we will grow, develop and earn

    uint256 public maxSupply = 5555;

    // it is a WL free mint only
    bool public whitelistStatus = true;

    // this turns true to allow public sale
    bool public publicStatus = false;

    mapping(address => uint256) public onWhitelist;

    //there is a public sale and a private sale, private is for WL and is free. public is at 0.01

    //free minting for WL wallets
    uint256 private price = 0.0 ether;

    //minting price for public
    uint256 private pricePublic = 0.01 ether;

    //free mint per wallet
    uint256 public maxMint = 1;

    //Otosan
    address[] private addressList = [
        0xcBc7df01a96Df8E73DD9BfF50c7e9Dc332D80193
    ]; //Sa7labeesi
    uint256[] private shareList = [100];
    address public royaltyOwner = 0xcBc7df01a96Df8E73DD9BfF50c7e9Dc332D80193;

    Counters.Counter private _tokenIds;

    //token
    constructor(uint96 _royaltyFeesBips, string memory _contractURI)
        ERC721("KEMUSHI", "KSI")
    {
        royaltyFeesBips = _royaltyFeesBips;
        contractURI = _contractURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    //read metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintPublic(uint256 _tokenAmount) public payable {
        uint256 s = totalSupply();
        require(publicStatus, "Public mint is not enabled!");
        require(_tokenAmount > 0, "You cannot mint 0 NFT!");
        require(_tokenAmount <= maxMint, "You must mint less!");
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= pricePublic * _tokenAmount, "Wrong ETH input!");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }

    // whitelist minting
    function mintPrivate(uint256 _tokenAmount) public payable {
        uint256 s = totalSupply();
        uint256 wl = onWhitelist[msg.sender];

        require(whitelistStatus, "Private mint is not enabled!");
        require(_tokenAmount > 0, "You cannot mint 0 NFT!");
        require(_tokenAmount <= maxMint, "You must mint less!");
        require(s + _tokenAmount <= maxSupply, "You must mint less!");
        require(msg.value >= price * _tokenAmount, "Wrong ETH input!");
        require(wl > 0);
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

    // authorised personnel only :)
    function SetWhiteList(address[] calldata _addresses) public onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            onWhitelist[_addresses[i]] = maxMint;
        }
    }

    //price update
    function setPrice(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    //price update
    function setPricePrivate(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    // write metadata
    function setContractURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //onoff switch
    function setWhiteList(bool _wlstatus) public onlyOwner {
        whitelistStatus = _wlstatus;
    }

    function setPublicSale(bool _pstatus) public onlyOwner {
        publicStatus = _pstatus;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

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

    function updateURI(uint256 tokenid, string memory newURI) public onlyOwner {
        _setTokenURI(tokenid, newURI);
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