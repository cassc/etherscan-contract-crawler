// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./ERC721A.sol";

error InvalidSignature();
error NotMeetWhiteListMint();
error NotMeetPublicMint();

contract TheWars is Ownable, ERC721A, ReentrancyGuard {
    struct WhiteListItem {
        uint64 whitePriceWei;
        uint64 whitelistStartTime;
        uint64 whitelistEndTime;
        uint256 total;
        address checkAddress;
    }
    struct PublicItem {
        uint64 publicPriceWei;
        uint64 publicStartTime;
        uint64 total;
    }
    PublicItem public publicConfig;
    WhiteListItem public whiteListConfig;

    string _baseTokenURI;
    uint256 public constant MAX_TOTAL_SUPPLY = 600;
    
    constructor() ERC721A("TheWars", "TW", 100) {}

    // limit total
    modifier maxTotal(uint256 total){
        require(
            (total != 0) && (totalSupply() + total <= MAX_TOTAL_SUPPLY),
            "Error: Exceed max total nor zero"
        );
        _;
    }

    function setWhiteListConfig(WhiteListItem calldata configData) external onlyOwner maxTotal(configData.total) {
        require(!isWhiteListSaleOn(),"Error: activity has started");
        whiteListConfig = configData;
    }

    function setPublicConfig(PublicItem calldata configData) external onlyOwner maxTotal(configData.total) {
        require(!isPublicSaleOn(),"Error: activity has started");
        publicConfig = configData;
    }

    function adminMint(address[] calldata tos, uint256[] calldata nums) external onlyOwner {
        uint256 length = tos.length;
        require(length == nums.length,"Parameter length error");        
        uint256 total = totalSupply();
        for(uint256 t=0; t<length; t++){
            total += nums[t];
        }
        require(total <= MAX_TOTAL_SUPPLY,"Not enough for mint");

        for (uint256 i = 0; i < length; i++) {
            _safeMint(tos[i], nums[i], 0);
        }
    }
    
    function isWhiteListSaleOn() public view returns (bool) {
        return
            whiteListConfig.total > 0 &&
            whiteListConfig.whitePriceWei > 0 &&
            whiteListConfig.whitelistStartTime <= uint64(block.timestamp) &&
            whiteListConfig.whitelistEndTime > uint64(block.timestamp);
    }

    //WhiteList Mint
    function whitelistMint(uint256 salt, bytes calldata signature) public payable {
        if (!isWhiteListSaleOn()) {
            revert NotMeetWhiteListMint();
        }

        WhiteListItem memory config = whiteListConfig;
        require(config.total >= 1, "Not enough for mint");
        require(msg.value >= uint256(config.whitePriceWei), "Need to send more ETH.");

        checkSigna(salt,signature,config.checkAddress);
        _safeMint(msg.sender, 1 , 0);
        config.total -= 1;

        whiteListConfig.total = config.total;
    }

    //check Public
    function isPublicSaleOn() public view returns (bool) {
        return
            publicConfig.total > 0 &&
            publicConfig.publicPriceWei > 0 &&
            publicConfig.publicStartTime <= uint64(block.timestamp);
    }
    //publi Mint
    function PublicMint(uint256 quantity) public payable {
        if (!isPublicSaleOn()) {
            revert NotMeetPublicMint();
        }

        PublicItem memory config = publicConfig;
        require(config.total >= quantity, "Not enough for mint");
        require(msg.value >= (uint256(config.publicPriceWei) * quantity), "Need to send more ETH.");

        _safeMint(msg.sender, quantity, 0);
        config.total -= uint64(quantity);

        publicConfig.total = config.total;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function checkSigna(uint256 salt, bytes calldata signature,address checkAddr) private view{
        bytes32 HashData = keccak256(abi.encodePacked(msg.sender, salt));
        if (
            !SignatureChecker.isValidSignatureNow(
                checkAddr,
                HashData,
                signature
            )
        ) {
            revert InvalidSignature();
        }
    }
}