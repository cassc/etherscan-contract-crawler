// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NftCollection is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Max supply of NFTs
    uint256 public constant MAX_NFT_SUPPLY = 10000;
    uint256 public maxNftInSinglePurchase = 5;

    // Base URI
    string private baseURI;

    // Minters
    mapping(uint256 => address) public minters;

    //Tax-Free Users
    mapping(address => uint256) public freeNft;

    // Total supply of NFTs
    uint256 public _totalSupply;

    // Pending Ids
    uint256[10001] private _pendingIds;

    uint256 public price = 0.1 ether;

    bool public enablePurchase;

    // Devs wallet
    address private admin;

    constructor(
        string memory _baseURI,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        admin = msg.sender;
    }

    function contractURI() public view returns (string memory) {
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, "metadata.json"))
        : "";
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
            keccak256(abi.encodePacked((baseURI_))),
            "ERC721Metadata: existed baseURI"
        );
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "ERROR: URI query for nonexistent token" );
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function purchase(uint256 numberOfNfts) external payable {
        require(enablePurchase, "Purchase is not enable");
        require(pendingCount() > 0, "All nft are purchase");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= maxNftInSinglePurchase, "You may not buy more than maxNftInSinglePurchase NFTs at once");
        require(totalSupply() + (numberOfNfts) <= MAX_NFT_SUPPLY,"sale already ended");
        require(_calculatePrice(numberOfNfts) == msg.value, "invalid ether value");
        freeNft[msg.sender] -= numberOfNfts - _calculateNftToBePayed(numberOfNfts);
        mint(msg.sender, numberOfNfts);
        sendAmount(msg.value);
    }

    function pendingCount() public view returns (uint256) {
        return MAX_NFT_SUPPLY - _totalSupply;
    }

    function _calculatePrice(uint256 numberOfNfts) internal view returns (uint256) {
        return getCurrentPrice() *  _calculateNftToBePayed(numberOfNfts);
    }

    function _calculateNftToBePayed(uint256 numberOfNfts) internal view returns (uint256) {
        uint256 payableNfts = 0;
        if (numberOfNfts > freeNft[msg.sender]) {
            payableNfts = numberOfNfts - freeNft[msg.sender];
        }

        return payableNfts;
    }

    /**
     * It return the number of NFTS minted by sender
     */
    function getMintedCounts() public view returns (uint256) {
        uint256 count = 0;
        for (uint i = 1; i <= MAX_NFT_SUPPLY; i++) {
            if (minters[i] == msg.sender) {
                count += 1;
            }
        }
        return count;
    }

    function sendAmount(uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        payable(admin).transfer(amount);
    }

    function mint(address _to, uint256 numberOfNfts) internal {
        for(uint256 i; i < numberOfNfts; i++) {
            _totalSupply += 1;
            _mintToken(_to, _totalSupply);
        }
    }

    function _mintToken(address _to, uint256 _tokenId) internal {
        minters[_tokenId] = _to;
        _mint(_to, _tokenId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function getCurrentPrice() public view returns (uint256) {
        return price;
    }

    function setFreeNft(address user, uint256 value) external onlyOwner{
        freeNft[user] = value;
    }

    function setMaxNFTInPurchase(uint256 _max) external onlyOwner {
        maxNftInSinglePurchase = _max;
    }
    /**
    * Emergency function to withdraw BNB from contract
    */
    function rescueBNB() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setDevWallet(address newWallet) external onlyOwner{
        admin = newWallet;
    }

    function setEnablePurchase(bool _enablePurchase) external onlyOwner {
        enablePurchase = _enablePurchase;
    }

    function setAdminWallet(address _admin) external onlyOwner {
        admin = _admin;
    }
}