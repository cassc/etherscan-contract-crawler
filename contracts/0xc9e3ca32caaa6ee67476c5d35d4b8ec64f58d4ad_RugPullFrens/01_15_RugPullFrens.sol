// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//           @@@@@@@@                                                     @@@@@@                                     
//           @@@@@@@@@@@@*                                             [email protected]@@@@@@@@                          
//           @@@@@   @@@@@@@@                                      %@@@@@@@@@@@@                         
//             @@@@@@    @@@@@@@@@@                              ,@@@@@@@@@@@@@@@                         
//               @@@@@       @@@@@@@@@@.                       @@@@@@@  @@@@@@@@.                         
//                  @@@@@@        @@@@@@@@/                  @@@@@@/   @@@@@@@@.                          
//                     @@@@@@@@@,    &((#%  ______        #@@@@@&     @@@@@@@.                           
//                       [email protected]@(                   .(     [email protected]@@@@     #@@@@@@@@                             
//                     (.                             ( @@@@@      @@@@@@@@                               
//                  ,(                                  (@@     ,@@@@@@@@.                                
//                 .                                       (  @@@@@@@@@                                   
//               .                                            *@@@@,                                     
//               (   _,[email protected]@                                         (                                        
//              (   (   %%@                                         .                                      
//              .  /  %%%%%       &@@@@@@                           ,                                     
//             (  /  %%$%%       @@  ,%%%% ,                        ,                                     
//             (  \  %%%&       @@  %%%%%%%@                         *                                    
//             |  *  %%,        @  /%%%$%%(@                         (                                    
//           ,,    """         @@  %%%%%%%#*                         (                                    
//         @@                  @. .%%%%%% @                          (                                    
//         ##                   @   %%% @@                           (                                     
//          *                    ""...#,                             (                                     
//          (                                                      .((                                    
//           (                                                      ((.                                   
//           (                                                       (((__                                  
//           \                                                           ((___                               
//           (                                                                (/ ___                        
//           (                          C                                          (/__                   
//             \                         &                                               (__               
//             *                         \                                                  (             
//             (                         \                                                   ,            
//             (                         ,                                                     ,          
//             .                          |                                                     .          
//              *                         (                                                    (         
//              $         |                ,                                                     (        
//              .         \                 .                                                    *        
//              /         ,                                                                       *       
//              (          (                                                                       (       
//              (          (                                                                        }      
//              *           \                                                                       ,      
//              /          (                                                                             
//             (                                                                           Artist_Raimochi @2021

//    ______   _    _   ______     ______   _    _   _        _          ______  ______   ______  ______   ______  
//   | |  | \ | |  | | | | ____   | |  | \ | |  | | | |      | |        | |     | |  | \         | |  \ \ / |
//   | |__| | | |  | | | |  | |   | |__|_/ | |  | | | |   _  | |   _    | |---- | |__| |  ΞΞΞΞΞΞ | |  | | '------. 
//   |_|  \_\ \_|__|_| |_|__|_|   |_|      \_|__|_| |_|__|_| |_|__|_|   |_|     |_|  \_\  ______ |_|  |_|  ____|_/ 




contract RugPullFrens is ERC721Enumerable, Ownable, EIP712 {
    using Strings for uint256;

    // Sales variables
    // ------------------------------------------------------------------------
    uint256 public MAX_FRENS = 10000;
    uint256 public MINTED_RESERVED_FRENS = 0;
    uint256 public constant RESERVED_FRENS = 250;

    uint256 public MAX_MINT_PER_TX = 20; // Max number of token can be minted per tx
    uint256 public FREN_PRICE = 0.05 ether; //price for minting on Presale and Sale period

    uint256 private publicSaleTimestamp = 1635958800; // Public Sale start time in epoch format
    
    
    // Treasury addresses
    // ------------------------------------------------------------------------
    address private _treasury = 0xbA53C6831B496c8a40c02A3c2d1366DfC6503F4e; // address where ether Withdraw to

    
    // State variables
    // Using toggles to open/close sale
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false; 
    bool public isPublicSaleActive = false;
    bool public isBurnEnabled = false;


    // Sale arrays
    // ------------------------------------------------------------------------
    mapping(address => uint256) public presaleClaimed;  // current claimed number of a address on presale


    // URI variables
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _baseTokenURI;


    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event URIChanged(string contractURI, string tokenURI);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event priceChanged(uint256 newTokenPrice);
    event supplyChanged(uint256 totalSupply, uint256 maxMintLimitPerTX);
    event FRENSMinted(address owner, uint256 numMint, uint256 totalSupply);


    // Constructor
    // ------------------------------------------------------------------------
    constructor() 
    ERC721("RugPullFrens", "RPF")
    EIP712("RugPullFrens", "1.0.0")
    {}


    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPresale() {
        require(isPresaleActive, "PRESALE_NOT_ACTIVE");
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        require(block.timestamp >= publicSaleTimestamp, "PUBLIC_SALE_NOT_STARTED");
        _;
    }

    modifier onlySaleNotActive() {
        require(!isPublicSaleActive, "PUBLIC_SALE_IS_ACTIVE");
        require(!isPresaleActive, "PUBLIC_SALE_IS_ACTIVE");
        _;
    }
    
    // Block smart contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "CALLER_IS_CONTRACT");
        _;
    }


    // sale functions
    // ------------------------------------------------------------------------
    function setSupply(uint256 _MAX_FRENS, uint256 _MAX_MINT_PER_TX) external onlySaleNotActive onlyOwner {
        require(_MAX_FRENS >= RESERVED_FRENS, "MAX_FRENS_MUST_GREATER_THAN_RESERVED_FRENS");
        MAX_FRENS = _MAX_FRENS;
        MAX_MINT_PER_TX = _MAX_MINT_PER_TX;
        emit supplyChanged(_MAX_FRENS, _MAX_MINT_PER_TX);
    }
    
    function setPrice(uint256 _FREN_PRICE) external onlyOwner {
        FREN_PRICE = _FREN_PRICE;
        emit priceChanged(_FREN_PRICE);
    }
    
    function isPresaleEligible(uint256 _MAX_CLAIM_FRENS_ON_PRESALE, uint256 _START_PRESALE_MINT_TIMESTAMP, bytes memory _SIGNATURE) public view returns (bool){
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address addressForPresaleClaim,uint256 maxClaimNumOnPresale,uint256 startTimestampForPresale)"),
            _msgSender(),
            _MAX_CLAIM_FRENS_ON_PRESALE,
            _START_PRESALE_MINT_TIMESTAMP
        ))), _SIGNATURE);
        
        return owner() == recoveredAddr;
    }

    function setPresaleStatus(bool _isPreSaleActive) external onlyOwner {
        require(isPresaleActive != _isPreSaleActive,"SETTING_TO_CURRENT_STATE");
        isPresaleActive = _isPreSaleActive;
    }

    function setPublicSale(bool _isPublicSaleActive, uint256 _publicSaleStartTimestamp) external onlyOwner {
        require(isPublicSaleActive != _isPublicSaleActive || publicSaleTimestamp!=_publicSaleStartTimestamp, "PUBLIC_SALE_CONFIG_IS_THE_SAME");
        isPublicSaleActive = _isPublicSaleActive;
        publicSaleTimestamp = _publicSaleStartTimestamp;
    }

    function setMintedReservedFrens(uint256 _MINTED_RESERVED_FRENS) external onlyOwner {
        MINTED_RESERVED_FRENS = _MINTED_RESERVED_FRENS;
    }

    // Mint functions
    // ------------------------------------------------------------------------
    
    function claimReservedFrens(uint256 quantity, address addr) external onlyOwner {
        require(MINTED_RESERVED_FRENS + quantity <= RESERVED_FRENS, "EXCEEDS_SUPPLY_FOR_RESERVED_FRENS");
        
        for (uint256 i = 0; i < quantity; i++) {
            MINTED_RESERVED_FRENS += 1;
            _safeMint(addr, MINTED_RESERVED_FRENS);
        }
        
        emit FRENSMinted(addr, quantity, totalSupply());
    }
    
    function mintPresaleFrens(
        uint256 quantity, 
        uint256 _MAX_CLAIM_FRENS_ON_PRESALE, 
        uint256 _START_PRESALE_MINT_TIMESTAMP, 
        bytes memory _SIGNATURE
    )
        external
        payable
        onlyPresale
        callerIsUser
    {
        require(isPresaleEligible(_MAX_CLAIM_FRENS_ON_PRESALE, _START_PRESALE_MINT_TIMESTAMP, _SIGNATURE), "NOT_ELIGIBLE_FOR_PRESALE");
        require(block.timestamp >= _START_PRESALE_MINT_TIMESTAMP, "YOUR_PRESALE_MINTING_TIME_NOT_STARTED");
        require(quantity > 0 && presaleClaimed[msg.sender] + quantity <= _MAX_CLAIM_FRENS_ON_PRESALE, "EXCEEDS_MAX_CLAIMED_NUM_ON_ADDR_OR_BELOW_ONE");
        require(FREN_PRICE * quantity == msg.value, "SENDING_INVALID_ETHERS");
        require(totalSupply() + quantity <= MAX_FRENS - RESERVED_FRENS + MINTED_RESERVED_FRENS, "EXCEEDS_MAX_SUPPLY");


        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply() - MINTED_RESERVED_FRENS + RESERVED_FRENS + 1);
        }
        presaleClaimed[msg.sender] += quantity;
        
        emit FRENSMinted(msg.sender, quantity, totalSupply());
    }

    function mintFrens(uint256 quantity) 
        external
        payable
        onlyPublicSale
        callerIsUser
    {
        require(quantity > 0 && quantity <= MAX_MINT_PER_TX, "EXCEEDS_MAX_MINT_PER_TX_OR_BELOW_ONE");
        require(totalSupply() + quantity <= MAX_FRENS - RESERVED_FRENS + MINTED_RESERVED_FRENS, "EXCEEDS_MAX_SUPPLY");
        require(FREN_PRICE * quantity == msg.value, "SENDING_INVALID_ETHERS");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply() - MINTED_RESERVED_FRENS + RESERVED_FRENS + 1);
        }
        
        emit FRENSMinted(msg.sender, quantity, totalSupply());
    }
    
    function ownerClaimFrens(uint256 quantity, address addr) external onlyOwner {
        require(totalSupply() + quantity <= MAX_FRENS - RESERVED_FRENS + MINTED_RESERVED_FRENS, "EXCEEDS_MAX_SUPPLY");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addr, totalSupply() - MINTED_RESERVED_FRENS + RESERVED_FRENS + 1);
        }
        
        emit FRENSMinted(addr, quantity, totalSupply());
    }

    function ownerClaimFrensId(uint256[] memory id, address addr) external onlyOwner {
        for(uint256 i = 0 ; i < id.length; i++) {
            _safeMint(addr, id[i]);
        }
        
    }

    // Burn Functions
    // ------------------------------------------------------------------------
    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit IsBurnEnabledChanged(_isBurnEnabled);
    }
    
    // only token owner approved spender can burn when the state of isBurnEnabled is true
    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "BURN_DISABLED");
        require(_isApprovedOrOwner(msg.sender, tokenId), "NOT_AUTHORIZED_TO_BURN");
        _burn(tokenId);
    }

    // Base URI Functions
    // ------------------------------------------------------------------------
    function setURI(string calldata __contractURI, string calldata __tokenURI) external onlyOwner {
        _contractURI = __contractURI;
        _baseTokenURI = __tokenURI;
        emit URIChanged(__contractURI, __tokenURI);
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "TOKEN_NOT_EXISTS");
        
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Withdrawal functions
    // ------------------------------------------------------------------------
    function setTreasury(address treasury) external onlyOwner {
        require(treasury != address(0), "SETTING_ZERO_ADDRESS");
        _treasury = treasury;
    }
    
    function withdraw() external onlyOwner {
        payable(_treasury).transfer(address(this).balance);
    }

}