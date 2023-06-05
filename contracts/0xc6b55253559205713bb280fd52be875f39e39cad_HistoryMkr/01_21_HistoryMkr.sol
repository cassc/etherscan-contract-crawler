// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract HistoryMkr is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, RoyaltiesV2Impl {
    event Mint(address indexed _to, uint256 indexed _tokenId, bytes32 _ipfsHash);
    event NftBought(address _buyer, uint256 _price);
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    mapping(string => uint8) hashes;

    uint256 public _salePrice = 88000000000000000; //0.088 eth
    bytes4 constant private _INTERFACE_ID_ERC2981 = 0x2a55205a; //interface for royalties    
    uint16 private initialId;
    string constant private suffix = ".json";

    string public provenanceHash; 
    uint16 public treasurersTokens;
    string private baseURI;
    bool private mintPaused = true;
    address payable public treasurer;
    uint16 private royaltyPercentageBasePoints = 400; //4%
    uint16 private maxAvailableTokens;
    constructor(string memory name, string memory symbol, string memory _provenanceHash, address payable _treasurer, uint16 _initialId, uint16 _treasurersTokens, uint16 _maxAvailableTokens) ERC721(name, symbol) {
        provenanceHash = _provenanceHash;
        initialId = _initialId;
        treasurer = _treasurer;
        treasurersTokens = _treasurersTokens;
        maxAvailableTokens = _maxAvailableTokens;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyOwner {
        super._burn(tokenId);
    }
    function setRoyaltyPercentageBasePoints(uint16 _percentageBasePoints) public  onlyOwner {
        royaltyPercentageBasePoints = _percentageBasePoints;
    }
    function setRoyalties(uint _tokenId) private {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyPercentageBasePoints;
        _royalties[0].account = treasurer;
        _saveRoyalties(_tokenId, _royalties);
    }
    function royaltyInfo(uint16 _tokenId) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            //currently royalties are based on the default starting price of the NFT and not dynamic with the current price of the NFT
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);

    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    } 

    function contractURI() public view returns (string memory) {
        return "ipfs://QmViH1WNS7tWqVcJCmi2tpEGsjvZr3fvDCS3bgTV7bKarn";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId); 
    }
    function mint(uint256 _mintAmount) public payable whenMintNotPaused() {
        require(_tokenIdTracker.current() + _mintAmount <= maxAvailableTokens, "all tokens have been minted");
        require(!Address.isContract(msg.sender), "address cannot be a contract");
        require( _mintAmount <= 10, "You can mint a maximum of 10");
        require( msg.value == _salePrice * _mintAmount, "Ether sent is not equal to PRICE * num" );
        payable(treasurer).transfer(msg.value);
        transferNFTs(_mintAmount, msg.sender);
    }

    function transferNFTs(uint256 num, address recipient) private {
        for(uint256 i = 0; i < num; i++){
            uint256 newItemId = initialId + _tokenIdTracker.current();
            super._safeMint(recipient, newItemId);
            require(_exists(newItemId), "minting the ID failed");
            setRoyalties(newItemId);
            string memory completeURI;
            completeURI = string(abi.encodePacked(Strings.toString(newItemId), suffix));
            _setTokenURI(newItemId, completeURI);
            _tokenIdTracker.increment();
            emit NftBought(msg.sender, newItemId);
        }
    }
    function claimTokens(uint8 num) public onlyOwner {
        require(num <= 50, "more than allowed max at a time"); //todo change this!!
        require(balanceOf(treasurer) + num <= treasurersTokens, "the contract treasurer cannot claim more");
        require(mintPaused, "this can only be done before minting is open to public");
        
        transferNFTs(num, treasurer);
    }
    function startMintingProcess(uint256 tokenPrice) public onlyOwner {
        require(mintPaused, "mint has already begun"); //check that mintPaused is true otherwise its already started
        require(balanceOf(treasurer) >= treasurersTokens, "cannot mint until all tokens have been claimed");
        _salePrice = tokenPrice;
        mintPaused = false;
    }

    function setTokenBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }
    function setNewTokenPrice(uint256 tokenPrice) public onlyOwner {
        _salePrice = tokenPrice;
    }
    modifier whenMintNotPaused() {
        require(!mintPaused, "minting is paused");
        _;
    }
}