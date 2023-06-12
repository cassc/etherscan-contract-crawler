// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_eth                 *
 * @team:   The Golden X              *
 ****************************************
                ██▓                     
                ▓███▒                   
                ▓█████                  
                ███████                 
               ▓████████                
               ██████████               
              ▒██████████▓              
               ███████████              
              ▓███████████              
            ▒█████████████              
           ▒██████████████▓▒            
           ██████████████████           
          ▒███████████████████          
          ▓███████████████████▒         
          ▓███▓▓█████████▓▓███▒         
           ██    ███████▒   ▓█          
         ▓██  ██  █████▒ ██▓ ██▒        
        ███▓ ████ ▓████ ▓███ ▒███       
       ████▓ ████ █████ ▒███  ████      
       █████  ██  █████▒ ██  █████      
       ██████    ▓██████    ▒█████      
       ███████▒▒█████████▓▒██████▓      
     ▓█████████████████████████████▓    
    █████████████████████████████████   
   ▒███████████   ▒▒▒▒▒   ▓██████████▒  
   ████████████▓         ▓████████████  
   ██████████████▒     ▒██████████████  
   ███████████████████████████████████  
   ██████████ THE GOLDEN X ██████████▒  
   ▒█████████████████████████████████   
    ▓██████████████████████████████▒    
      ▓███▒      ▒▓▓███████████▓▒       
*****************************************/

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
//import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
//import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract GiraffesAtTheBar is ERC721Enumerable, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Strings for uint256;

    string public GATB_PROVENANCE  = '';
    string public LICENSE_TEXT     = '';
    uint256 public MAX_SUPPLY      = 10000;
    uint256 public RESERVED_SUPPLY = 80;

    bool public paused             = true;
    uint public price              = 0.055 ether;

    uint public presale_mint_max   = 10;
    uint public presale_start      = 1640415600;
    uint public presale_supply     = 200 + 500;
    uint public presale_wallet_max = 10000;

    uint public sale_mint_max      = 20;
    uint public sale_start         = 1640415600;
    uint public sale_wallet_max    = 10000;

    string private _baseTokenURI = 'http://giraffesatthebar.com/metadata.php?tokenID=';
    bool private _licenseLocked = false;

    mapping(address => uint) private _presale;

    event LicenseLocked(string _licenseText);

    // Withdrawal addresses
    address t1 = 0x7F4ECce5310a5d33D2e9FCaFedCdE430249D1Bc3;
    address t2 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;
    address[] addressList = [t1, t2];
    uint256[] shareList   = [90, 10];

    constructor()
    ERC721("Giraffes At The Bar", "GATB")
    PaymentSplitter(addressList, shareList)  {
      //send reserves
      //gift( RESERVED_SUPPLY, owner() );
    }

    function mint(uint256 quantity) public payable {
        require( !paused, "Sale paused" );
        require( msg.value >= price * quantity, "Ether sent is not correct" );

        //regular sale
        uint256 balance = totalSupply();
        if( block.timestamp >= sale_start ){
            require( quantity           <= sale_mint_max, "Order too big" );
            require( balance + quantity <= MAX_SUPPLY,    "Exceeds supply" );
            require( balanceOf( msg.sender ) + quantity <= sale_wallet_max, "Don't be greedy" );
        }
        //presale
        else if( block.timestamp >= presale_start ){
            require( quantity           <= presale_mint_max, "Order too big" );
            require( balance + quantity <= presale_supply,   "Exceeds supply" );
            require( _presale[ msg.sender ] == 1,            "Wallet is not whitelisted" );
            require( balanceOf( msg.sender ) + quantity <= presale_wallet_max, "Don't be greedy" );
        }
        else{
            require( false, "Sale has not started yet" );
        }

        for( uint256 i; i < quantity; ++i ){
            _safeMint( msg.sender, balance + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIDs;
    }

    //owner
    function gift(uint256 quantity, address recipient) public onlyOwner {
        uint256 balance = totalSupply();
        require( balance + quantity <= MAX_SUPPLY, "Exceeds supply" );

        for(uint256 i; i < quantity; ++i ){
            _safeMint( recipient, balance + i );
        }
    }

    //owner setters
    function changeLicense(string memory _license) public onlyOwner {
        require(_licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function flipSaleState() public onlyOwner {
        paused = !paused;
    }

    function lockLicense() public onlyOwner {
        _licenseLocked =  true;
        emit LicenseLocked(LICENSE_TEXT);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMaxSupply(uint maxSupply) public onlyOwner {
        require(maxSupply > totalSupply(), "Specified supply is lower than current balance" );
        MAX_SUPPLY = maxSupply;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        GATB_PROVENANCE = provenanceHash;
    }

    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }

    function addPresaleAddresses( address[] memory wallets ) public onlyOwner {
        for( uint i; i < wallets.length; ++i ){
            _presale[ wallets[i] ] = 1;
        }
    }

    function setPresaleOptions( uint mint_max, uint start, uint wallet_max, uint supply ) public onlyOwner {
        require( supply >= totalSupply(),  "Specified supply is lower than current balance" );
        require( supply <= MAX_SUPPLY,     "Specified supply is greater than max supply" );

        if( presale_mint_max != mint_max )
            presale_mint_max = mint_max;

        if( presale_start != start )
            presale_start = start;

        if( presale_mint_max != wallet_max )
            presale_wallet_max = wallet_max;

        if( presale_supply != supply )
            presale_supply = supply;
    }

    function setSaleOptions(uint mint_max, uint start, uint wallet_max ) public onlyOwner {
        if( sale_mint_max != mint_max )
            sale_mint_max = mint_max;

        if( sale_start != start )
            sale_start = start;

        if( sale_wallet_max != wallet_max )
            sale_wallet_max = wallet_max;
    }

    //internal
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")) : "";
    }
}