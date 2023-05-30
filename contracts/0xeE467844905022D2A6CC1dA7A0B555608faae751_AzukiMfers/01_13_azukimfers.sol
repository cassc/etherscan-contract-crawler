pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract AzukiMfers is ERC721A, Ownable {
    uint256 public constant maxSupply = 10000;
    uint256 public constant reservedAmount = 300;
    uint256 private constant maxBatchSize = 10;

    constructor() ERC721A("Azuki Mfer", "AZUKIMFER") {}

    uint256 public mintPrice = 0.042 ether;
    uint256 public maxAmountPerMint = 10;
    uint256 public maxMintPerWallet = 30;

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxAmountPerMint(uint256 newMaxAmountPerMint) external onlyOwner {
        maxAmountPerMint = newMaxAmountPerMint;
    }

    function setMaxMintPerWallet(uint256 newMaxMintPerWallet) external onlyOwner {
        maxMintPerWallet = newMaxMintPerWallet;
    }

    /**
     * metadata URI
     */
    string private _baseURIExtended = "https://media.azukimfers.art/metadata/unrevealed/";

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * withdraw proceeds
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    /**
     * pre-mint for team
     */
    function devMint(uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= reservedAmount, "too many already minted before dev mint");
        require(amount % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        
        uint256 numChunks = amount / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    /**
     * Public minting
     * _publicSaleCode & publicSaleStartTime will be set to non-zero to enable minting. This helps to slow down bot.
     * allowedMintSupply will be used to enable multi-phases minting. Default is equal to maxSupply.
     */
    uint private _publicSaleCode = 0;

    uint32 public publicSaleStartTime = 0;
    uint256 public allowedMintSupply = maxSupply;

    mapping(address => uint256) public minted;

    function setPublicSaleCode(uint newCode) public onlyOwner {
        _publicSaleCode = newCode;
    }

    function setPublicSaleStartTime(uint32 newTime) public onlyOwner {
        publicSaleStartTime = newTime;
    }

    function setAllowedMintSupply(uint newLimit) public onlyOwner {
        allowedMintSupply = newLimit;
    }

    function publicMint(uint amount, uint code) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(code != 0 && code == _publicSaleCode, "code is mismatched");
        require(publicSaleStartTime != 0 && publicSaleStartTime <= block.timestamp, "sales is not started");
        require(minted[msg.sender] + amount <= maxMintPerWallet, "limit per wallet reached");
        require(totalSupply() + amount <= allowedMintSupply, "current phase minting was ended");

        uint256 mintableAmount = amount;
        require(mintableAmount <= maxAmountPerMint, "Exceeded max token purchase");

        // check to ensure amount is not exceeded MAX_SUPPLY
        uint256 availableSupply = maxSupply - totalSupply();
        require(availableSupply > 0, "No more item to mint!"); 
        mintableAmount = Math.min(mintableAmount, availableSupply);

        uint256 totalMintCost = mintableAmount * mintPrice;
        require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

        minted[msg.sender] += mintableAmount;

        _safeMint(msg.sender, mintableAmount);

        // Refund unused fund
        uint256 changes = msg.value - totalMintCost;
        if (changes != 0) {
            Address.sendValue(payable(msg.sender), changes);
        }
    }
}