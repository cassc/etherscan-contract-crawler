// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

                      ..                 -=+-         .-=++++=   
                    =++++++=-:.      -==+++*====+. .=+++++++++=  
                   -+++++++++++++=-.=+++++++++*+--++++++++++++*  
                   =++++**+++++++++++++++++++++++*+++++++***+++: 
                   =+++*=--=++++++++++++++++++++++++++++=--+*++- 
                   -++++....:=*++++++++++++++++++++++++:. .-+++- 
                   .+++*:...=*+++++++++++++++++++++*###*-..=+++- 
                    +++++:-*+++++++*%@@@%#+++++++%@+---*%*+*+++: 
                    -+++***+++++++%%=:..:[email protected]#++++#*....   ##++++. 
                     ++++*+++++++##   .:..:##+++%-*#.-+.  %++++  
                     [email protected]  :+%+*@=%+++#[email protected]@@@@-  +.:+:  
       .              =+:   .:=++%   -#@@@@**+-=*=*@@@@-  -  :.  
   .:.....:.::        .-        :+:  :[email protected]@@@=+:  .--=-+-  .    .  
  :-..       ..-:                 -.  .-.+-:.      .           . 
 .=-:.           ::                ..          -+##*+           . 
 =--:.     .      -.                           .=*#+:           .
 =--:..::=:-:.... .-                        ..       ..      ..  
 =-::==+++++++-.-.-:    ....                  ..    .      ..    
 :=++**++++++++--.         .::::...                    ..:.      
  -******+++++++++-:.:-==+++=+=-::::::::.......    ..::.         
   :+********+++++++++++=++++++**++==--------::::::-=            
     :+*********+++++========+++********+==----::::::.           
          :-=+*****++++==========++++**=-::::............          
                ++++++++=========++++::....                      
               :++++++++++=======++++=..                         
               -++++++++++*=====+++++=.                 .        
               +++++++++++*+++++*++++==                 ..       
            .-+++++++++++++*+++#**++++=-               ..        
            ***+++++++++++++::-***++++++             :- .        
            ****++++++++++*+-:-***+++++*.        .:-++           
            +*****++++++++#***+#**++++++=----===++++++-          
            :******+*==-. =****#***+++++*.   ++++++++++.         
             ==--::..-     **+++#+++++==+=    +*+++++++=         
              :.     -     .+...:=::..  ..:    ==--::..:         
               .:   .-      .-    --.    .-     .:     :         
                 ....         ::::. ::::::        ......   


Doge Dash NFTS are 10,000 unique, cute, fun pieces of art, each with a distinct personality
and style. Holders will be able to play as their NFT in the Doge Dash Play-To-Earn Game just 
by holding it in their wallets. A lucky few will also be granted special abilities such as 
extra lives, super jump, and even double rewards.

*/
                                       
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DogeDash is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string private _tokenBaseURI;

    uint256 public giftedSupply = 100;
    uint256 public preSaleSupply = 1000;
    uint256 public publicSupply = 8900;
    uint256 public collectionSupply = giftedSupply + preSaleSupply + publicSupply;
    uint256 public price = 0.07 ether;
    uint256 public maxMint = 20;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public preSaleMaxMint = 3;

    bool public presaleLive;
    bool public saleLive;
    bool public locked;

    address public wallet1 = 0x7eA92fcA35aC6DAe33a693726779fEdAA85Ba96a;
    address public wallet2 = 0xfe5D07eCCB883532206224C72D36A9b9BFC8C89c;

    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;

    constructor() ERC721("DOGE DASH", "DOGEDASH") { }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }
    
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "sale closed");
        require(!presaleLive, "disable presale");
        require(totalSupply() < collectionSupply, "collection sold out");
        require(publicAmountMinted + tokenQuantity <= publicSupply, "exceeded public supply");
        require(tokenQuantity <= maxMint, "exceeded max limit per mint");
        require(price * tokenQuantity <= msg.value, "insufficient eth");
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "presale closed");
        require(presalerList[msg.sender], "address not in presale");
        require(totalSupply() < collectionSupply, "collection sold out");
        require(privateAmountMinted + tokenQuantity <= preSaleSupply, "exceeded presale supply");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= preSaleMaxMint, "exceeded presale mint allocation");
        require(price * tokenQuantity <= msg.value, "insufficient eth");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function gift() external onlyOwner {
        require(totalSupply() + giftedSupply <= collectionSupply, "MAX_MINT");
        
        for (uint256 i = 0; i < giftedSupply; i++) {
            _safeMint(wallet2, totalSupply() + 1);
        }
    } 

    function withdraw() external onlyOwner {
        (bool success1,) = wallet1.call{value : (address(this).balance)*10/100}("");
        (bool success2,) = wallet2.call{value : (address(this).balance)}("");
        require(success1, "Transfer failed.");
        require(success2, "Transfer failed.");
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }
    
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}