// SPDX-License-Identifier: CC0
/* REKTPIXELS by CoolNftArt */

pragma solidity ^0.8.17;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract RektPixels is ERC721A, Ownable, ERC2981 {
    bool public saleEnabled;
    uint256 public price;
    uint256 public priceFree;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public maxMintsPerTX;
    uint256 public maxFreeMintsPerTX;
    uint256 public freeMintSupply;
    uint256 public freeMintCount;

    uint256 public maxSupply;

    uint96 public defaultRoyaltyPercent;
    address public defaultRoyaltyWallet;

    constructor() ERC721A("REKTPIXEL", "REKTPXL") {
        saleEnabled = false;

        maxSupply = 4096;
        maxMintsPerTX = 100;
        
        freeMintCount = 0;
        freeMintSupply = 500;
        maxFreeMintsPerTX = 1;

        price = 0.002 ether;
        priceFree = 0.00042 ether;

        // erc2981 royalty - set to defaultRoyaltyPercent
        defaultRoyaltyPercent = 500; 
        defaultRoyaltyWallet = msg.sender;
        _setDefaultRoyalty(defaultRoyaltyWallet, defaultRoyaltyPercent);
    }

    function supportsInterface(bytes4 interfaceId) 
        public view virtual override (ERC721A, ERC2981)
        returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setFreeMintSupply(uint256 _freeMintSupply) external onlyOwner {
        freeMintSupply = _freeMintSupply;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxMintsPerTX(uint256 _maxMintsPerTX) external onlyOwner {
        maxMintsPerTX = _maxMintsPerTX;
    }

    function setMaxFreeMintsPerTX(uint256 _maxFreeMintsPerTX) external onlyOwner {
        maxFreeMintsPerTX = _maxFreeMintsPerTX;
    }

    function updateMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function updateFreeMintPrice(uint256 _price) external onlyOwner {
        priceFree = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function checkFreeMint(address walletAddress) external view returns (uint256) {
        return _getAux(walletAddress);
    }

    function mint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(totalSupply() + numOfTokens <= (maxSupply), "Exceed MAX supply");
        require(numOfTokens <= maxMintsPerTX, "Exceed mints per transaction");
        require(
            (price * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, numOfTokens);
        
    }

    function freeMint(uint256 numOfTokens) external payable {
        require(saleEnabled, "Sale must be active.");

        require(numOfTokens > 0, "Must mint at least 1 token");
        require(totalSupply() + numOfTokens <= maxSupply, "Exceed MAX supply");
        require(freeMintCount + numOfTokens <= freeMintSupply, "No Free Mints available");

        require(numOfTokens <= maxFreeMintsPerTX, "Exceed MAX Free Mints per transaction");
        require(
            (priceFree * numOfTokens) <= msg.value,
            "Insufficient funds to claim."
        );
        require(_getAux(msg.sender) == 0, 'Free Mints Already Claimed');

        _safeMint(msg.sender, numOfTokens);
        _setAux(msg.sender, 1);
        freeMintCount = freeMintCount + numOfTokens;

    }
    
}