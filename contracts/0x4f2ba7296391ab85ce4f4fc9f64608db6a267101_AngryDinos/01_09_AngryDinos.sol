pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AngryDinos is ERC721AQueryable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum SaleState {
        NOT_LIVE,
        WHITELIST_SALE,
        PUBLIC_SALE
    }

    struct Slot {
        uint8 maxPerWallet;
        uint16 maxSupply;
        uint112 price;
    }

    SaleState public saleState;
    Slot public tokenInfo;
    
    address public signer = 0x9E6376d88d7cb9bfC8a3A87Bf12853017460E544;

    string private _baseTokenURI;

    mapping(bytes => bool) public claimedSig;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    constructor(uint8 maxPerWallet, uint16 maxSupply, uint112 price, address royaltyAddress, uint256 royaltyPercentage, string memory baseURI) ERC721A("AngryDinos", "AD") {
        tokenInfo = Slot(maxPerWallet, maxSupply, price);
        _royaltyAddress = royaltyAddress;
        _royaltyPercentage = royaltyPercentage;
        _baseTokenURI = baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(saleState == SaleState.PUBLIC_SALE, "NOT_LIVE");
        Slot memory token = tokenInfo;
        require(totalSupply() + quantity <= token.maxSupply, "MAX_SUPPLY");
        require(quantity <= token.maxPerWallet, "MAX_PER_WALLET");
        uint256 cost = token.price * quantity;
        require(msg.value >= cost, "INSUFFICENT_ETH");
        _mint(msg.sender, quantity);
    }

    function whitelistMint(bytes calldata signature) external {
        require(saleState == SaleState.WHITELIST_SALE, "NOT_LIVE");
        Slot memory token = tokenInfo;
        require(totalSupply() + 1 <= token.maxSupply, "MAX_SUPPLY");
        require(!claimedSig[signature], "ALREADY_CLAIMED");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender))
        )).recover(signature) == signer);
        claimedSig[signature] = true;
        _mint(msg.sender, 1);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance }("");
        require(sent, "FAILED");
    }


    function editPrice(uint112 newPrice) external onlyOwner {
        tokenInfo.price = newPrice;
    }

    function editSupply(uint16 newSupply) external onlyOwner {
        tokenInfo.maxSupply = newSupply;
    }

    function editState(SaleState newState) external onlyOwner {
        saleState = newState;
    }

    function editURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}