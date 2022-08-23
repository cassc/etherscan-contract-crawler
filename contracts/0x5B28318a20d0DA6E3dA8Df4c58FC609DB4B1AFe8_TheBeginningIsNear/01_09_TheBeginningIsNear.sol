// SPDX-License-Identifier: MIT
/*                                             
                         [email protected]@GL08C.                         
                       8i;;;;;;;;;;;[email protected]                         
                     [email protected];;;;;;;;;;;;;;;@;                       
                    tL;;;;;;;iii;;;;;;;0:                      
                   0i;;;;[email protected]@@@@@@@L;;;;;CG.                    
                 [email protected];;;;;[email protected]@@@@@@@@@@;;;;;;00,                  
               t8t;;;;;[email protected]@@@@@@@@@@@@1;;;;;;G0,                
              8t;;;;;[email protected]@@@@@@@@@@@@@@@G;;;;;;[email protected]               
            ,81;;;;[email protected]@@@@@@@@@@@@@@@@@0;;;;;;;@:              
            [email protected];;;;;[email protected]@@@@@@@@@@@@@@@@@@@;;;;;;;@:              
            [email protected];;;;;[email protected]@@@@@@@@@@@@@@@@@@8;;;;;;;G               
             0L;;;;;[email protected]@@@@@@@@@@@@@@@@C;;;;;;i0                
          .18800fi;;;;;[email protected]@@@@@@@@Gt;;;;[email protected]            
        [email protected];;;;;;[email protected];;;[email protected]@@@81;;[email protected];;;;;;;;;;G0           
      [email protected];;;;;;;;;;;;;;[email protected];[email protected]@L;f0f;;;;;;;;;;;;;;;;[email protected]:         
     [email protected];;;;;;;;;10;;;;;;;18iitf8i;;;;;;;;;;;;;;;;;;;LC         
     8;;;;;;;;;;;@1;;;;1;;;8L8L;;;;f8;;;;;;;G;;;;;;;;@.        
    fC;;;;;;[email protected];;;1t;;;;@;;;;@@;;;;GC;;;L;;;;C;;;;;;;;CC        
   .0t;;;;;;f8;;;tC;;;;Ci;;;@i;;;[email protected];;;i8;;;;L8;;;;;;;f8.       
   ;@;;;;;;;fL;;;G1;;;;;0;;;0;;;;01;;;[email protected];;;;L8;;;;;;;;@:       
   81;;;;;;;ft;;;@1;;;;;8i;;0;;;;8i;;;i8;;;;L8;;;;;;;;0f       
   @i;;;;;;;f8;;;@1;;;;;8i;;0i;;tG;;;;;0;;;;Lt;;;;;;;;10       
  tG;;;;;;;;;8t;;@1;;;;;@1;;0f;;GG;;;;;Gi;18f;;;;;;;;;10       
  LG;;;;;;;;;;C0;@1;;;;;@1;;LC;;GG;;;;;[email protected]@@@@80Gi;;;;;81       
  .0;;;;;;[email protected]@[email protected]@@@@88i;;fL;;;[email protected]@i;;;;;;;;;;;;;;;;@:       
   :@;;;;1;;;;;;;;;;;;;;;[email protected];;;;;;;;;;;;;;;;;;;;8t        
     0t;;;;;;;;;;;;;;;;;;;;1;;C;;ti;;;;;;;;;;;;;;;;[email protected],         
       [email protected];;;;;;;;;;;;;;;i8;;Cf;tL;;;;;;;;;;;;;tCGi           
           ;[email protected];;;;;;;Ci;;L8;;LC;;;;;;;[email protected]              
            1i;;;[email protected]@Gt;;CG;;;L8;;;LC;C88Li;;@i                
            1i;;;;0;;;[email protected];;;;CL;;;[email protected];;18;;;@i                
            ii;;;;0t;;;;[email protected];;@;i88G;;;;i8;;;@:                
            it;;;;0C;;;;iL;;[email protected]@81;;0;;;;;01;;8                 
            i0;;;;0C;;;;iL;;;@f;;;;ft;;;;0C;18                 
            i8;;;;0t;;;;1f;;;@f;;;;ft;;;;0C;18                 
            i8;;;;0;;;;;ft;;;@f;;;;G;;;;;0C;i8                 
            i0;;;[email protected];;;;;@t;;;@f;;;;@;;;;;0C;;8                 
            iL;;;01;;;;;@t;;;@f;;;;G;;;;;0C;;@;                
            ii;;t0;;;;;;@1;;;@f;;;0C;;;;;tC;;@i                
            Li;;G;;;;;;f0;;;;@f;;i8;;;;;;iC;;Li                
            @i;iG;;;;;;C1;;;;@f;;;;;;;;;;CC;;i0                
            C;;@f;;;;;;8;;;;;@f;;;;;;;;;;0f;;[email protected]                
           GC;;8;;;;;;@t;;;;;@t;;;;;;;;;18;;;;C1               
          .0;;L8;;;;;L8;;;;;;@;;;t1;;;;i8i;;;;1G               
          :L;;L8;;;;tG;;;;;;[email protected];;;@i;;;i81;;;;;;8:              
          @1;;L8;;;[email protected];;;;;;;[email protected];;LG;;;;0t;;;;;;;[email protected]              
         L0;;;;@t;;;;;;;;;;;8;;i8;;;;L8;;;;;;;;;0L             
        ,8;;;;;;8;;;;;;;;;;iC;;0t;;;;@;;;;;;;;;;;8.            
       i8;;;;;;;C0;;;;;;;;;81;f8;;;;LL;;;;;;;;1;;i8,           
      ;0;;;;;;;;;01;;;;;;;tC;;Ct;;;;@f;;;;;;[email protected];;;;0           
     [email protected];;C1;;;;;;[email protected];;;;;;;@i;;8;;;;[email protected];;;;;;;Gi;;;;;f8          
    t0;;;C0;;;;;;;0L;;;;;GG;;;@;;;;[email protected];;;;;;iC;;;;;;;tG         
   ;@;;;;;0;;;;;;;0G;;;;;G;;;;@;;;;[email protected];;;;;;8f;;;;;;;;LG        
   0;;;;;;8i;;;;;;1G;;;;[email protected];;;;G;;;;f8;;;;;[email protected];;;;;;;;;;18       
  CG;;;;;;8i;;;;;;;G;;;;[email protected];;;;;;;;;[email protected];;;;;iG;;;;;;;;;;;CC      
  LG;;;;;;L;;;;;;;iG;;;;;C0i;;;;;;;;;;;;;;;;;;;;;;;;;;;iG.     
   [email protected]@[email protected]@@Gti;;;;;;;;[email protected]@0tti;;;[email protected]       
              ;tttffff1             ,ttt:                                                                                          
*/
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheBeginningIsNear is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public MAX_FREE = 2;
    uint256 public MAX_PER_WALLET = 6;
    uint256 public MAX_SUPPLY = 6666;
    uint256 public PRICE = 0.005 ether;
    bool public revealed = false;
    bool public initialize = false;
    string public baseURI = "";

    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("The Beginning Is Near", "TBIN") {}

    function freeMint(uint256 quantity) external
    {
        uint256 cost = PRICE;
        bool free = (qtyFreeMinted[msg.sender] + quantity <= MAX_FREE);
        if (free) {
            cost = 0;
            qtyFreeMinted[msg.sender] += quantity;
            require(quantity < MAX_FREE + 1, "Max free reached.");
        }

        require(initialize, "The tale has not begun.");
        require(_numberMinted(msg.sender) + quantity <= MAX_FREE, "You may mint more for a price.");
        require(totalSupply() + quantity < MAX_SUPPLY + 1, "None left. The tale unfolds in the metadata.");

        _safeMint(msg.sender, quantity);
    }

    function mintMore(uint256 quantity) external payable
    {
        require(initialize, "The tale has not begun.");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "You have already minted. Watch the tale unfold.");
        require(msg.value >= quantity * PRICE, "Please send the exact amount.");
        require(totalSupply() + quantity < MAX_SUPPLY + 1, "None left. The tale unfolds in the metadata.");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory baseURI_ = _baseURI();

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        } else {
            return string(abi.encodePacked(baseURI_, ""));
        }
    }
    
    function withdraw() external onlyOwner nonReentrant
    {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function setInitialize(bool _initialize) external onlyOwner
    {
        initialize = _initialize;
    }

    function setPrice(uint256 _price) external onlyOwner
    {
        PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner
    {
        MAX_PER_WALLET = _limit;
    }

    function setLimitFreeMintPerWallet(uint256 _limit) external onlyOwner
    {
        MAX_FREE = _limit;
    }

}