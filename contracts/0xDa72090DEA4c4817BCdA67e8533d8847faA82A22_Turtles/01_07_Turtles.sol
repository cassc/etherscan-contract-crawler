// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
    _______________ _____________ 
    \__    ___/    |   \______   \
      |    |  |    |   /|       _/
      |    |  |    |  / |    |   \
      |____|  |______/  |____|_  /
                               \/ 

    The Turtles All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "./ERC721A.sol";
import "./IWhitelist.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";    

contract Turtles is ERC721A, Ownable, ReentrancyGuard {

    /// @dev Role for changing variables in the contract
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    enum SALE_STAGE {
        CLOSED,
        WHITELIST,
        PUBLIC
    }    

    uint16 constant public COLLECTION_SIZE = 4321;
    uint8 constant public RESERVE_TOKENS_LIMIT = 200;

    uint8 constant public MAX_TOKENS_WHITELIST_SALE = 1;
    uint8 constant public MAX_TOKENS_PUBLIC_SALE = 1;

    uint32 public whitelistSaleStartTime = 1661443200;
    uint32 public publicSaleStartTime = 1661461200;

    /// @dev Ammount of tokens an address has minted during the whitelist sales
    uint16 private _tokensAlreadyReserved = 0;

    IWhitelist private _whitelistContract;
    /// @dev Ammount of tokens an address has minted during the whitelist sales
    mapping (address => uint256) private _numberMintedDuringWhitelistSale;

    mapping (address => bool) private _isManager;

    constructor(IWhitelist whitelistContract, address[] memory managers) ERC721A("The Turtles", "TUR") {
        _whitelistContract = whitelistContract;

        for(uint index = 0; index < managers.length; index++) {
            _isManager[managers[index]] = true;
        }
    }

    /// @notice Mint tokens during the sales
    function saleMint(uint256 quantity)
        external
        nonReentrant
    {
        SALE_STAGE saleStage = getCurrentSaleStage();

        require(totalSupply() + quantity <= COLLECTION_SIZE - RESERVE_TOKENS_LIMIT, "Reached max supply");
        require(quantity <= numberAbleToMint(msg.sender), "Exceeding minting limits for this account during current sale stage");

        if(saleStage == SALE_STAGE.WHITELIST) {
            require(isWhitelistAddress(msg.sender), "An account is not on a whitelist");
            _numberMintedDuringWhitelistSale[msg.sender] += quantity;
        }

        _safeMint(msg.sender, quantity);
    }

    /// @notice Reserve tokens for marketing usage/team to a certain address
    function reserveTokens(address reserveToAddress, uint16 tokensCount)
        external 
    {
        require(_isManager[msg.sender], "You don't have the manager rights");
        require(_tokensAlreadyReserved + tokensCount <= RESERVE_TOKENS_LIMIT, "Reached max supply");
        _tokensAlreadyReserved += tokensCount;
        
        _safeMint(reserveToAddress, tokensCount);
    }
    
    /// @notice Number of tokens an address can mint at the given moment
    function numberAbleToMint(address owner) public view returns (uint256) {
        SALE_STAGE saleStage = getCurrentSaleStage();
        
        if(saleStage == SALE_STAGE.PUBLIC)
            return MAX_TOKENS_PUBLIC_SALE + numberMintedDuringWhitelistSale(owner) - numberMinted(owner);
        
        if(saleStage == SALE_STAGE.WHITELIST)
            return MAX_TOKENS_WHITELIST_SALE - numberMinted(owner);

        return 0;
    }

    /// @notice Check if an address is in a whitelist
    function isWhitelistAddress(address owner) public view returns(bool) {
        return _whitelistContract.isWhitelistAddress(owner);
    }

    /// @notice Number of tokens minted by an address during the whitelist sales
    function numberMintedDuringWhitelistSale(address owner) public view returns(uint256){
        return _numberMintedDuringWhitelistSale[owner];
    }

    /// @notice Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /// @notice Get current sale stage
    function getCurrentSaleStage() public view returns (SALE_STAGE) {
        if(block.timestamp >= publicSaleStartTime)
            return SALE_STAGE.PUBLIC;
        
        if(block.timestamp >= whitelistSaleStartTime)
            return SALE_STAGE.WHITELIST;
        
        return SALE_STAGE.CLOSED;
    }

    /// @notice Change whitelist sales start time in unix time format
    function setWhitelistSaleStartTime(uint32 unixTime) public {
        require(_isManager[msg.sender], "You don't have the manager rights");
        whitelistSaleStartTime = unixTime;
    }

    /// @notice Change public sales start time in unix time format
    function setPublicSaleStartTime(uint32 unixTime) public {
        require(_isManager[msg.sender], "You don't have the manager rights");
        publicSaleStartTime = unixTime;
    }

    /// @dev Starting index for the token IDs
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @dev Token metadata folder/root URI
    string private _baseTokenURI = "https://bafybeifga7zzygklunuk4zcdzcsu5z7icgv3fvubc5bv6sjsykt6exfjji.ipfs.nftstorage.link/metadata/";

    /// @notice Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set base token URI
    function setBaseURI(string calldata baseURI) external {
        require(_isManager[msg.sender], "You don't have the manager rights");
        _baseTokenURI = baseURI;
    }
}