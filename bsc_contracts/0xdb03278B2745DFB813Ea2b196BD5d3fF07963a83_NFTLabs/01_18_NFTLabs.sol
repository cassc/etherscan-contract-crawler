pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTLabs is Ownable, ERC721, ERC721Enumerable, ERC721URIStorage {
    using Strings for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct StakingInfo {
        uint256 period;
        uint256 weight;
    }

    struct NFTForSale {
        uint256 tokenId;
        uint256 price;
    }

    uint256 public constant FEE_DECIMALS = 100000;

    Counters.Counter private _tokenIdCounter;
    address public paymentToken; // default MMPRO
    string public baseUri;

    uint256 public NFTPrice;
    uint256 public resaleFee;
    uint256 public tokenPool;
    NFTForSale[] public nftsForSale;


    constructor(string memory name, string memory symbol, string memory uri, address _paymentToken, uint256 price, uint256 _resalesFee) ERC721(name, symbol) {
        setBaseURI(uri);
        paymentToken = _paymentToken;
        NFTPrice = price;
        resaleFee = _resalesFee;
    }

    function mint() public {

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

    }

    function PutUpForSales(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");

        uint256 salePrice = getTokenPriceWithFee(price);

        NFTForSale memory currentNftForSale = NFTForSale(tokenId, salePrice);
        nftsForSale.push(currentNftForSale);

    }

    function getAllTokensForSales() view public returns (NFTForSale[] memory) {
        return nftsForSale;
    }

    function takeFromSales(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        require(index < nftsForSale.length, "Token not for sale");
        _removeNftForSale(index);
    }

    function buyNft(uint256 tokenId) public {
        uint256 index = _getIndexInNftForSaleByToken(tokenId);
        require(index < nftsForSale.length, "Token not for sale");
        _transfer(ownerOf(tokenId), _msgSender(), tokenId);
        _removeNftForSale(index);
    }

    function getTokenPriceWithFee(uint256 userPrice) view public returns (uint256) {

        return userPrice + ((userPrice * resaleFee) / FEE_DECIMALS);
    }

    function setResaleFee(uint256 newFee) external onlyOwner {
        resaleFee = newFee;
    }

    function _getIndexInNftForSaleByToken(uint256 tokenId) private returns (uint256){
        for (uint256 i = 0; i < nftsForSale.length; i++) {
            if (nftsForSale[i].tokenId == tokenId) {
                return i;
            }
        }
        return nftsForSale.length + 99;
        // index greater then length of array means that no token found;
    }

    function _putNftForSale(uint256 tokenId, uint256 price) private {
        NFTForSale memory currentNftForSale = NFTForSale(tokenId, price);
        nftsForSale.push(currentNftForSale);
    }

    function _removeNftForSale(uint256 ind) private {
        nftsForSale[ind] = nftsForSale[nftsForSale.length - 1];
        nftsForSale.pop();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(_getIndexInNftForSaleByToken(tokenId) > nftsForSale.length, "Token is already on sale");
        super.transferFrom(from, to, tokenId);
    }

    function setPaymentToken(address newPaymentToken) external onlyOwner {
        paymentToken = newPaymentToken;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function getURI(uint256 tokenId) pure private returns (string memory) {
        return string(abi.encodePacked(tokenId.toString(), ".json"));
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawExtraTokens(
        address token,
        uint256 amount,
        address withdrawTo
    ) external onlyOwner {
        IERC20(token).safeTransfer(withdrawTo, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}