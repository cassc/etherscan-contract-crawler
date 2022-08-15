// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice ERC721A is an improved implementation of the IERC721 standard that supports minting multiple tokens for close to the cost of one
/// @notice More info could be found here: https://www.azuki.com/erc721a
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Official Worlds Of Trains NFT Smart Contract
/// @author Mechanist
/// @notice This Smart Contract allows managing Public Sales and mint NFTs to the Community Members and Owner
/// @notice It optimized to reduce gas fees. It allows to mint several tokens with a close to one cost
contract WorldsOfTrains is ERC721A, Ownable, ReentrancyGuard {
    /// @dev Public Sale Configuration
    /// @dev Is Public Sale active or not
    bool private publicSale = false;
    /// @dev How many NFTs are provided for this Public Sale
    uint256 private publicSupply = 0;
    /// @dev Index of maximum Public Sale token
    uint256 private maxPublicSupply = 0;
    /// @dev How many NFTs are allowed to mint per wallet 
    uint256 private mintPerWallet = 0;
    /// @dev Minting price per one token during Public Sale (excluding GAS fee)
    uint256 private pricePerToken = 0;    
    /// @dev Contains number of minted tokens per wallet
    mapping(address => uint256) private totalPublicMint;

    /// @dev Base token URI used as a prefix by tokenURI() to map metadata
    string private baseTokenURI = "ipfs://QmU6YV3TnRBqdSHexNz5LqVMxvGco5TjKcVjsgUAQV18Dx/";

    /// @dev Size of NFT Collection
    uint256 private constant TOTAL_SUPPLY = 11;//11_111;

    /// @dev Smart Contract  constructor which initializes basic identifiers of a collection
    constructor() ERC721A("Worlds Of Trains", "WOFT") { }

    // =============================================================
    //                            MINTING                                 
    // =============================================================

    /// @dev Mints several NFTs to the Owner
    /// @param _quantity The quantity of NFTs to mint
    /// @custom:owner Could be called only by Smart Contract Owner     
    function mintMass(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= TOTAL_SUPPLY, "Max supply reached");
        _mint(msg.sender, _quantity);
    }

    /// @dev Mints several NFTs to the recipient specified by Owner
    /// @param _recipient Wallet address of tokens recipient    
    /// @param _quantity The quantity of NFTs to mint
    /// @custom:owner Could be called only by Smart Contract Owner     
    function mintTo(address _recipient, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= TOTAL_SUPPLY, "Max supply reached");
        _mint(_recipient, _quantity);
    }

    // =============================================================
    //                          PUBLIC SALE                         
    // =============================================================

    /// @dev Check if the caller is a User and not other Smart Contract 
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Public Sale - Cannot be called by a contract");
        _;
    }    

    /// @notice When the Public Sale is activated this method allows to mint several NFTs and 
    /// @notice Minted NFTs will be assigned to the wallet address which calls this method
    /// @param _quantity The quantity of NFTs to mint
    function publicSaleMint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Public Sale - Not Yet Active!");
        require(0 < _quantity, "Public Sale - minimum 1 to mint!");
        require(_quantity <= mintPerWallet, "Public Sale - Beyond Mint Per Wallet Supply!");
        require((totalSupply() + _quantity) <= maxPublicSupply, "Public Sale - Beyond Max Supply!");
        require((pricePerToken * _quantity) <= msg.value, "Public Sale - Below Price!"); 
        require((totalPublicMint[msg.sender] + _quantity) <= mintPerWallet, "Public Sale - Max mint amount per wallet exceeded!");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);

        // If all tokens minted - close Public Sale:
        if(maxPublicSupply <= totalSupply())
            _setPublicSale(false);
    }    

    /// @dev Activates Public Sale
    /// @param _supply Quantity of NFTs which will be sold during this Public Sale    
    /// @param _mintPerWallet How many NFTs are allowed to mint per wallet
    /// @param _pricePerToken Minting price per one token during Public Sale    
    /// @custom:owner Could be called only by Smart Contract Owner     
    function publicSaleStart(uint256 _supply, uint256 _mintPerWallet, uint256 _pricePerToken) external onlyOwner {
        maxPublicSupply = totalSupply() + _supply;
        maxPublicSupply = maxPublicSupply <= TOTAL_SUPPLY ? maxPublicSupply : TOTAL_SUPPLY;
        publicSupply = maxPublicSupply - totalSupply();
        mintPerWallet = _mintPerWallet;
        pricePerToken = _pricePerToken;
        _setPublicSale(true);
    }

    /// @dev Deactivates Public Sale
    /// @custom:owner Could be called only by Smart Contract Owner    
    function publicSaleStop() external onlyOwner {
        _setPublicSale(false);
    }

    /// @notice Checks if Public Sale is active or not
    /// @return True if Public Sale is activated and False in other case 
    function publicSaleIsActive() external view returns (bool) {
        return publicSale;
    }  

    /// @notice Checks quantity of NFTs which are supplied for this Public Sale
    /// @return Quantity of NFTs which are supplied for this Public Sale
    function publicSaleTotalSupply() external view returns (uint256) {
        return publicSale ? publicSupply : 0;
    }  

    /// @notice Checks the quantity of NFTs which are remains for this Public Sale
    /// @return Quantity of NFTs which are remains for this Public Sale
    function publicSaleRemainingSupply() external view returns (uint256) {
        return publicSale ? maxPublicSupply - totalSupply() : 0;
    }    

    /// @notice Checks minting price per one token during Public Sale (excluding GAS fee)
    /// @return Minting price per one token during Public Sale
    function publicSalePricePerToken() external view returns (uint256) {
        return publicSale ? pricePerToken : 0;
    }     

    /// @notice Checks allowed (maximum) number of tokens which could be minted per unique wallet
    /// @return Number of tokens which could be minted per unique wallet during Public Sale    
    function publicSaleMintPerWallet() external view returns (uint256) {
        return publicSale ? mintPerWallet : 0;
    }         

    /// @dev Used for Public Sale activation or deactivation
    /// @custom:owner Could be called only by Smart Contract Owner     
    function _setPublicSale(bool _state) private {
        publicSale = _state;
    }     

    // =============================================================
    //                           TOKEN URI                         
    // =============================================================

    /// @dev Sets the base token URI prefix
    /// @custom:owner Could be called only by Smart Contract Owner     
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }   

    /// @notice This method is used to return Uniform Resource Identifier (URI) for `tokenId` token
    /// @param tokenId Identifier of the token
    /// @return Uniform Resource Identifier (URI) for `tokenId` token
    /// @inheritdoc ERC721A
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    /// @dev This method returns base URI for computing {tokenURI}
    /// @return URI for a given token ID
    /// @inheritdoc ERC721A
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev This method returns ID of the starting token 
    /// @return Returns the starting token ID
    /// @inheritdoc ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                           WITHDRAW                         
    // =============================================================

    /// @dev Withdraws balance accumulated by the Smart Contract according to the profits share agreement
    /// @custom:owner Could be called only by Smart Contract Owner     
    function withdraw() external onlyOwner nonReentrant {
        // Calculate 25% of withdraw balance:
        uint256 withdrawAmount_25 = address(this).balance * 25 / 100;
        // Calculate 15% of withdraw balance:
        uint256 withdrawAmount_15 = address(this).balance * 15 / 100;
        // Calculate 10% of withdraw balance:
        uint256 withdrawAmount_10 = address(this).balance * 10 / 100;
        // Calculate 5% of withdraw balance:
        uint256 withdrawAmount_5  = address(this).balance * 5  / 100;

        // 25% to Artists wallet (utility):
        uint256 artWithdrawAmmount  = withdrawAmount_25;
        // 25% to Developers wallet (utility):
        uint256 devsWithdrawAmmount = withdrawAmount_25;
        // 15% to Marketing wallet:
        uint256 marketingWithdrawAmmount  = withdrawAmount_15;
        // 10% to Community wallet (to have fun;):
        uint256 communityWithdrawAmmount  = withdrawAmount_10;
        // 5% to Books Authors wallet (utility):
        uint256 booksWithdrawAmmount      = withdrawAmount_5;
        // 5% to Board Games Development wallet (utility):
        uint256 boardGamesWithdrawAmmount = withdrawAmount_5;
        // 5% to Toys Development wallet (utility):
        uint256 toysWithdrawAmmount       = withdrawAmount_5;
        // 5% to Lore Development wallet (utility):
        uint256 loreWithdrawAmmount       = withdrawAmount_5;

        // Withdraw shared profits:
        payable(0xd887173b5cdC2e56F610Ab4913389563655931c2).transfer(artWithdrawAmmount);
        payable(0x33ce5DD835023A3b6A9D502A767be30e7F690927).transfer(devsWithdrawAmmount);
        payable(0xBd2e63025caf16bEe323DCA52eef74e8c52CB7Ce).transfer(marketingWithdrawAmmount);
        payable(0x6F91e6C50ffda64ed4Bc34Dfdf466B62C990bC07).transfer(communityWithdrawAmmount);   
        payable(0x66D6d0612E85901082436905C649A0CE3a37f5d8).transfer(booksWithdrawAmmount);                 
        payable(0x2599CB0C76237Ac7336a022F98E21BA9eb025474).transfer(boardGamesWithdrawAmmount);   
        payable(0xD1d579b7b95141305AAc158E0bD95A65fB9157B0).transfer(toysWithdrawAmmount); 
        payable(0xCaf6FF321feEDF6cDE97130285FBb5ab960c0B32).transfer(loreWithdrawAmmount);         

        // Investors get remaining 5%:
        payable(msg.sender).transfer(address(this).balance);
    }    

    /// @dev This method returns amount of Ether which could be withdrawn 
    /// @return Returns amount of ether which could be withdrawn 
    /// @custom:owner Could be called only by Smart Contract Owner     
    function withdrawBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }    
}