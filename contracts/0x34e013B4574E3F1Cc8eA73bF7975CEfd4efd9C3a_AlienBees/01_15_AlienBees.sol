//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";    
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RandomlyAssigned.sol";

contract AlienBees is ERC721, Ownable, ReentrancyGuard, RandomlyAssigned{
    uint256 public constant _totalSupply = 7777;
    uint256 public constant mintPrice = 30000000000000000;//0.003 ETH
    uint256 public reservedNFTLimit = 100;
    uint256 public publicLimit = 5;
    uint256 public HPLimit = 7;
    uint256 public WhiteListedLimit = 7;

    uint256 public reservedTokensMinted;

    string public baseURI;
    string public constant provenanceHash = "cca31106a60c4e9d9a3b690dfadf880ea66571f2f2374d634c52ef5645d2c7c7";
    string public placeholderURI = "https://ipfs.io/ipfs/QmVhPw9nvZq2xhHS9GHQstbGgLKMKF4VbAjtdg3CFXe7aC";

    bool public publicSale;
    bool public HPSale;
    bool public whiteListSale;
    bool internal isRevealed;
    
    address public constant HPContractAddress = 0x3606b0B69a36d7B46Db004A58dea74Ea2b885F0b;
    address public constant reservedWalletAddress = 0xE6546AD0CEfc3f57CF3b4Bba7cB55c53B78A4261;
    
    mapping(address => bool) public whiteListedWallets;
    mapping(address => uint256) public mintedTokensByAddress;

    constructor() ERC721("Alien Bees Club", "ABC") RandomlyAssigned(_totalSupply, 1){ }

    function setHivePalsSale(bool flag) external onlyOwner{
        HPSale = flag;
    }

    function setWhiteListedSale(bool flag) external onlyOwner{
        whiteListSale = flag;
    }

    function setPublicSale(bool flag) external onlyOwner{
        publicSale = flag;
    }

    function addNewWalletsForWhiteList(address[] memory WhiteListAddress) external onlyOwner{  
        for(uint32 i =0; i < WhiteListAddress.length; i++){
            whiteListedWallets[WhiteListAddress[i]] = true;
        }
    }

    function hpUserBalanceCheck() public view returns(uint256) {
        uint256 balance = (IERC721(HPContractAddress).balanceOf(msg.sender)); 
        return balance;
    }

    function mintBee(uint256 quantity) public payable nonReentrant {
        require((HPSale == true || whiteListSale == true || publicSale == true), "Minting is not live.");
        require((quantity + tokenCount() + reservedNFTLimit - reservedTokensMinted) <= totalSupply(), "Mint Completed"); 
        require(msg.value >= (mintPrice * quantity), "Insufficient funds passed to mint requested quantity.");
        uint256 balance = (IERC721(HPContractAddress).balanceOf(msg.sender)); 
        require(publicSale == true || (HPSale == true && balance > 0) || (whiteListSale == true && whiteListedWallets[msg.sender] == true)
            , "Minting is not live.");
        uint256 tokensMintedByUser = mintedTokensByAddress[msg.sender];
        uint256 totalMintLimit = 0;
        
        totalMintLimit += (balance > 0 && HPSale == true) ?  HPLimit: 0;
        totalMintLimit += (whiteListedWallets[msg.sender] == true && whiteListSale == true) ? WhiteListedLimit : 0;
        totalMintLimit += (publicSale == true) ? publicLimit : 0;

        require((tokensMintedByUser + quantity) <= totalMintLimit, "Your mint limit has been met.");
        for (uint256 i = 1; i <= quantity; i++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
        }
        mintedTokensByAddress[msg.sender] += quantity;
        if(msg.value > (mintPrice * quantity)){
            payable(msg.sender).transfer(msg.value - (mintPrice * quantity));
        }
    }

    function mintReserved(uint256 quantity) public {
        require(reservedWalletAddress == msg.sender, "Permission Denied.");
        require((quantity + tokenCount()) <= totalSupply(), "All NFTs are already minted");
        require( (reservedTokensMinted + quantity) <= reservedNFTLimit, "You cannot mint more reserved NFTs.");

        for (uint256 i = 1; i <= quantity; i++) {
            uint256 id = nextToken();
            _safeMint(msg.sender, id);
        }
        reservedTokensMinted += quantity;
        mintedTokensByAddress[msg.sender] += quantity;
    }

    function freeMint(address[] memory walletAddresses) public onlyOwner {
        require((tokenCount() + walletAddresses.length + reservedNFTLimit - reservedTokensMinted) <= totalSupply(), "You cannot mint more thann total supply.");

        for (uint256 i = 0; i < walletAddresses.length; i++) {
            uint256 id = nextToken();
            _safeMint(walletAddresses[i], id);
        }
    }

    function freeMintBatch(address[] memory walletAddresses, uint8[] memory quantities) public onlyOwner {
        require(walletAddresses.length == quantities.length, "Input data length mismatched. Check input length.");
        uint256 totalQuantityToMint = 0;

        for (uint256 i = 0; i < quantities.length; i++) {
            totalQuantityToMint += quantities[i];
        }
        require((totalQuantityToMint + tokenCount() + reservedNFTLimit - reservedTokensMinted) <= totalSupply(), "Mint Completed");

        for (uint256 i = 0; i < walletAddresses.length; i++) {
            for (uint256 j = 0; j < quantities[i]; j++) {
                uint256 id = nextToken();
                _safeMint(walletAddresses[i], id);
            }
        }
    }

    function updateBaseURI(string memory _baseuri) public onlyOwner{
        require(bytes(_baseuri).length > 0, "Base URI cannot be empty.");
        baseURI   =   _baseuri;
    }

    function updateRevealStatus(bool _isRevealed) external onlyOwner{
        isRevealed = _isRevealed;
    }

    function updatePlaceholderURI(string memory _placeholderURI) external onlyOwner {
        require(bytes(_placeholderURI).length > 0, "Placeholder URI cannot be empty.");
        placeholderURI = _placeholderURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        return (isRevealed == true) ? string(abi.encodePacked(baseURI, Strings.toString(tokenId),".json")) : placeholderURI ;
    }

    function updateMintLimit(uint256 saleType, uint256 newLimit) public onlyOwner{
        require(newLimit > 0, "Limit should be greater than 0.");
        require(saleType == 1 || saleType == 2 || saleType == 3, "Invalid sale type.");
        if(saleType == 1){
            publicLimit  = newLimit;
        }else if(saleType == 2 ){
            HPLimit = newLimit;
        }else if(saleType == 3){
            WhiteListedLimit = newLimit;
        }
    }

    function withdraw() public payable onlyOwner{  
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
    fallback() external payable {}
}