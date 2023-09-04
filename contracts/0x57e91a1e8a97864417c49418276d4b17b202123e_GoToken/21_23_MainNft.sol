pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MainNft is Ownable, ERC721, IERC2981{
    string public baseURI;
    address public sellerManager;
    uint256 public royaltyPercent = 100;
    address private SYS_ADDRESS;

    event NftMint(address user, uint256 tokenId);
    event NftBurn(address user, uint256 tokenId);

    constructor(string memory name_, string memory symbol_, address feeAddress) public ERC721(name_, symbol_){
        SYS_ADDRESS = feeAddress;
        sellerManager = msg.sender;
    }

    function mint(address user, uint256 currentIndex) public payable onlySellManager returns (uint256) {
        require(!exists(currentIndex), 'nft has minted err');
        _safeMint(user, currentIndex);
        emit NftMint(user, currentIndex);
        return currentIndex;
    }

    function setTypeRoyalty(uint256 value) public onlyOwner{
        require((value >= 0 && value < 10000), "value range error");
        royaltyPercent = value;
    }

    function setFeeAddress(address value) public onlyOwner{
        SYS_ADDRESS = value;
    }


    function exists(uint256 tokenId) public view returns (bool){
        return _exists(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUrl(string memory url_) public onlyOwner{
        baseURI = url_;
    }

    modifier onlySellManager() {
        require(msg.sender == sellerManager, 'not sellerManager');
        _;
    }

    function setSellManager(address value) public onlyOwner{
        sellerManager = value;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }


    // Implementing the ERC-2981 royaltyInfo() function
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (SYS_ADDRESS, salePrice * royaltyPercent / 10000);
    }
}