// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            ""
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            ""
        );

        _burnBatch(account, ids, values);
    }
}


contract RookieSeason is ERC1155Burnable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  struct Infonft {
    string name;
    string URI;
    uint cost;
    uint whitelistCost;
    uint supply;
    uint reserve; 
    uint maxsupply;
    uint burned;
    bool tokenIdExist; 
    bytes32 serialN;
  }

  bytes32 private merkleRoot; 
  mapping(uint => bytes32) private serial;

  Infonft[] private _infoNft; 
  mapping (uint => string) private nameDesign; 
  mapping (uint => string) private URIs; 
  mapping (uint => uint) private price; 
  mapping (uint => uint) private whitelistPrice;
  mapping (uint => uint) private supply;
  mapping (uint => uint) private reserve; 
  mapping (uint => uint) private maxsupply; 
  mapping (uint => uint) private burnCounter;
  mapping (uint => bool) private validOfTokenId; 
  
  string public name = "Rookie Season";
  string public symbol = "RS";

  address private dev ;  
  address private own ; 
  address public crossmintaddress;
  
  mapping(string => bool) public serialNumberUsed;
  mapping(string => address) public serialNumberUsers;
  mapping(address => mapping(uint => bool)) public whitelistClaimed; 
  mapping(address => mapping(uint => bool)) public listOfAddressMinted;
  mapping(address => mapping(uint => bool)) public listOfAddressBurned; 
  mapping(address => mapping(uint => bool)) public listOfAddressMintedFree; 
  mapping(address => mapping(uint => uint)) public burnCounterAddress;

  uint public maxChange = 5; 
  uint public maxTokenId = 30;
  uint public TotalTokenId = 0 ; 
  uint public maxAmountPerTx = 3; 
  uint public maxAmountPerTxFree = 1;

  bool public whitelistSale = false; // Period whitelist sale
  bool public paused = true; 
  bool public readyToFree = false; // Period for the free mint
  bool public timeToBurn = false; // Period for burn
  bool public activeListSerialNumber = false; 


  constructor(address _dev, address _own) ERC1155("") {
     Infonft memory newinfoNft = Infonft({
        name :  "No",
        URI : "ipfs://",
        cost : 0,
        whitelistCost : 0,
        supply : 0,
        reserve : 0,
        burned : 0,
        maxsupply: 0,
        tokenIdExist: false,
        serialN: ""
      });
      
      dev = _dev;
      own = _own;
      _infoNft.push(newinfoNft); 
  }
 
// mint

  function mint(uint tokenId, uint quantity) payable external returns(bool) {
        require(balanceOf(msg.sender, tokenId) + quantity <= maxAmountPerTx, "You are more than 3 copies of this design");
        require(quantity > 0);
        require(quantity <= maxAmountPerTx, "You can't mint more than 3 copies of this design");
        require(msg.value >= price[tokenId]*quantity,"You don't have the good price for pay this design");
        require(validOfTokenId[tokenId] == true, "Design not exist");
        require(whitelistSale == false, "Whitelist sale is open, not the public sale");
        require(!paused, "Paused");
        require((supply[tokenId] + quantity) <= (maxsupply[tokenId] - reserve[tokenId]), "You have execeed the maximum supply of this design");
        
        _mint(msg.sender, tokenId, quantity,"");
        supply[tokenId] += quantity;
        listOfAddressMinted[msg.sender][tokenId] = true;
        Infonft storage thisInfonft = _infoNft[tokenId];
        thisInfonft.supply += quantity;

        return true; 
}

  function whitelistMint(uint tokenId, uint quantity, bytes32[] calldata _merkleProof) payable external returns(bool) {
        require(balanceOf(msg.sender, tokenId) + quantity <= maxAmountPerTx, "You are allowed to have only 3 copies per design in your wallet");
        require(quantity > 0);
        require(quantity <= maxAmountPerTx, "You can't mint more than 3 copies of this design");
        require(msg.value >= whitelistPrice[tokenId]*quantity,"You don't have the good price for pay this design");
        require(validOfTokenId[tokenId] == true, "Design not exist");
        require(whitelistSale == true, "Whitelist not open");
        require(!paused, "Paused");
        require((supply[tokenId] + quantity) <= (maxsupply[tokenId] - reserve[tokenId]), "You have execeed the maximum supply of this design");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not on the whitelist");
        
        _mint(msg.sender, tokenId, quantity,"");
        supply[tokenId] += quantity;
        whitelistClaimed[msg.sender][tokenId] = true;
        listOfAddressMinted[msg.sender][tokenId] = true;
        Infonft storage thisInfonft = _infoNft[tokenId];
        thisInfonft.supply += quantity;

        return true; 
}


  function mintwithcard(address to, uint tokenId, uint quantity) payable public returns(bool) {
    
    require(validOfTokenId[tokenId] == true, "NFT not exist");
    require(quantity > 0);
    require(quantity <= maxAmountPerTx, "You can't mint more than 3 copies of this design");
    require(!paused, "Paused");
    require(whitelistSale == false);
    require(msg.sender == crossmintaddress, "CR");
    
    require(msg.value >= price[tokenId]*quantity, "You don't have the good price for pay this design");
    require((supply[tokenId] + quantity) <= (maxsupply[tokenId] - reserve[tokenId]), "You have execeed the maximum supply of this design");
    require(balanceOf(to, tokenId) + quantity <= maxAmountPerTx, "You have exceeded the maximum number of copies to mint");

    _mint(to, tokenId, quantity,"");
    supply[tokenId] += quantity;
    Infonft storage thisInfonft = _infoNft[tokenId];
    thisInfonft.supply += quantity;

    return true; 
}


  function freeMint(uint tokenId, uint quantity, string memory _serialnumber, bytes32[] calldata _serialProof) external returns(bool){
        require(readyToFree == true, "It's not time for the free mint");
        require(whitelistSale == false, "Whitelist sale is open");
        require(validOfTokenId[tokenId] == true, "NFT not exist");        
        require(quantity > 0);
        require(quantity <= maxAmountPerTxFree, "You have exceeded the maximum quota of copies to mint in a single transaction");
        require(balanceOf(msg.sender, tokenId) + quantity <= maxAmountPerTx, "You have exceeded the maximum number of copies to mint");

        require(activeListSerialNumber == true, "Active SN");        
        bytes32 leaf = keccak256(abi.encodePacked(_serialnumber));
        require(MerkleProof.verify(_serialProof, serial[tokenId], leaf), "Serial number not exist");
        require(serialNumberUsed[_serialnumber] == false, "Serial number already used");

        
        if (quantity == quantity && listOfAddressBurned[msg.sender][tokenId] == true){
            _mint(msg.sender, tokenId, 1,"");
            supply[tokenId] += quantity;
            Infonft storage thisInfonft = _infoNft[tokenId];
            thisInfonft.supply += quantity;
            thisInfonft.burned -= quantity;
            burnCounter[tokenId] -= quantity;
            burnCounterAddress[msg.sender][tokenId] -= quantity; 
            listOfAddressMintedFree[msg.sender][tokenId] = true;
            serialNumberUsers[_serialnumber] = msg.sender;
            serialNumberUsed[_serialnumber] = true;

            if(burnCounterAddress[msg.sender][tokenId] == 0){
              listOfAddressBurned[msg.sender][tokenId] = false;
            }

        }
      
         else{
                _mint(msg.sender, tokenId, quantity,"");
                supply[tokenId] += quantity;
                Infonft storage thisInfonft = _infoNft[tokenId];
                thisInfonft.supply += quantity;
                serialNumberUsers[_serialnumber] = msg.sender;
                serialNumberUsed[_serialnumber] = true;
                listOfAddressMintedFree[msg.sender][tokenId] = true;
            }
        
        return true; 

}



  
// ownership
   function changeOwn(address _own) external {
     uint number = 0;
     require(msg.sender == own || msg.sender == dev);
     require(number <= maxChange, "");
     own = _own;
     number++; 
   }   


   function changeDev (address _dev) external {
     require(msg.sender == own || msg.sender == dev);
     dev = _dev;
   }

   function changeAddressCrossmint (address _newcrossmintaddress) external returns (bool) {
     require(msg.sender == own || msg.sender == dev);
     crossmintaddress = _newcrossmintaddress; 
     return true;
   }


// NFT Element

  function totalSupply(uint _tokenId) public view returns (uint) {
    return supply[_tokenId]; 
  }

  function totalPrice(uint _tokenId) public view returns (uint) {
    return price[_tokenId]; 
  }

   function totalWhitelistPrice(uint _tokenId) public view returns (uint) {
    return whitelistPrice[_tokenId]; 
  }

  function totalMaxSupply(uint _tokenId) public view returns (uint) {
    return maxsupply[_tokenId] - reserve[_tokenId]; 
  } 
  
  function totalBurned(uint _tokenId) public view returns (uint){
    return burnCounter[_tokenId];
  }

  function totalURI(uint _tokenId) public view returns (string memory) {
    return URIs[_tokenId]; 
  }

  function totalName(uint _tokenId) public view returns (string memory) {
    return nameDesign[_tokenId]; 
  }

  function totalValidation(uint _tokenId) public view returns (bool) {
    return validOfTokenId[_tokenId]; 
  }


  function reserveDeleo(uint _tokenId) public view returns (uint){
      return reserve[_tokenId];
  }

  function BurnedperAddress(address newaddress, uint _tokenId) public view returns (uint){
      return burnCounterAddress[newaddress][_tokenId];
  }

// SN

  function changeSerialroot(bytes32 _serial, uint tokenId) external {
      require(msg.sender == own || msg.sender == dev);
      serial[tokenId] = _serial;
      Infonft storage thisInfonft = _infoNft[tokenId];
      thisInfonft.serialN = _serial;
    
    }

  function changemanySerialroot(bytes32[] memory _serial, uint[] memory tokenId) external {
      require(msg.sender == own || msg.sender == dev);
      for(uint i = 0; i < tokenId.length; i++ ){      
      serial[tokenId[i]] = _serial[i];
      Infonft storage thisInfonft = _infoNft[tokenId[i]];
      thisInfonft.serialN = _serial[i];
      }
  }

  
  function acitveSN (bool activate) external returns (bool){
      require(msg.sender == own || msg.sender == dev);
      activeListSerialNumber = activate;
      return true; 
  }
 

// MD
 
    function uri(uint256 tokenId) public view virtual override returns (string memory){
          return URIs[tokenId];  
    }



     function setUris(uint[] memory tokenId, string[] memory _uri) public {
        require(msg.sender == own || msg.sender == dev);
        for(uint i = 0; i < tokenId.length; i++ ){
           URIs[tokenId[i]] = _uri[i];
           Infonft storage thisInfonft = _infoNft[tokenId[i]];
           thisInfonft.URI = _uri[i];
        }
    }



    // State 

    function toPause (bool _state) external {
         require(msg.sender == own || msg.sender == dev);
         paused = _state;
    }

    function freeMintStep(bool _state) external {
         require(msg.sender == own || msg.sender == dev);
         readyToFree = _state;
    }

   function activeWhitelistSale(bool _active) external {
         require(msg.sender == own || msg.sender == dev);
         whitelistSale = _active; 
   }

   function activeTimeToBurn(bool _active) external {
         require(msg.sender == own || msg.sender == dev);
         timeToBurn = _active; 
   }


// Other

    function changeName (string memory _name) external {
     require(msg.sender == own || msg.sender == dev);
     name =_name;
    }

    function changeSymbol (string memory _symbol) external {
     require(msg.sender == own || msg.sender == dev);
     symbol =_symbol;
    }

    function setMaxSupply(uint[] memory tokenId, uint[] memory _maxAmount) external returns(bool) {
        require(msg.sender == own || msg.sender == dev);
        for(uint i = 0; i < tokenId.length; i++ ){
           maxsupply[tokenId[i]] = _maxAmount[i];  
           Infonft storage thisInfonft = _infoNft[tokenId[i]];
          thisInfonft.maxsupply = _maxAmount[i];      
        }
        return true; 
    }

    function nameOfDesign(string[] memory design, uint[] memory tokenId) external returns(bool) {
      require(msg.sender == own || msg.sender == dev);
        
        for(uint i = 0; i < tokenId.length; i++ ){
            
            nameDesign[tokenId[i]] = design[i];
            Infonft storage thisInfonft = _infoNft[tokenId[i]];
            thisInfonft.name = design[i];

        }
        return true;

    }

     function changeReserve(uint[] memory tokenId, uint[] memory number) public returns(bool){
      require(msg.sender == own || msg.sender == dev);
            for(uint i = 0; i < tokenId.length; i++ ){
              reserve[tokenId[i]] -= number[i];
            }
            return true;
     }

    function setReserve(uint[] memory tokenId, uint[] memory number) public returns(bool){
      require(msg.sender == own || msg.sender == dev);
            for(uint i = 0; i < tokenId.length; i++ ){
              reserve[tokenId[i]] = number[i];
            }
            return true;
     }

    function changeValidationOfTokenId(uint[] memory tokenId, bool _state ) public returns(bool) {
      require(msg.sender == own || msg.sender == dev);
        
        for(uint i = 0; i < tokenId.length; i++ ){
            validOfTokenId[tokenId[i]] = _state;
        }
        return true;

    }

    function changeMaxTokenId(uint _maxTokenId) public {
      require(msg.sender == own || msg.sender == dev);
      maxTokenId = _maxTokenId;
    }

    function changeMaxAmountPerTx(uint _maxAmountPerTx) public {
      require(msg.sender == own || msg.sender == dev);
      maxAmountPerTx = _maxAmountPerTx;
    }

    function changeMaxAmountPerTxFree(uint _maxAmountPerTxFree) public {
      require(msg.sender == own || msg.sender == dev);
      maxAmountPerTxFree = _maxAmountPerTxFree;
    }

    function changeMerkleroot(bytes32 _merkleRoot) public {
      require(msg.sender == own || msg.sender == dev);
      merkleRoot = _merkleRoot;
    }


// Create 
     function createToken(uint tokenId, string memory design, uint _maxsupply, string memory _uri, uint _price, uint _whitelistPrice, uint _reserve) external returns(bool){

      require(msg.sender == own || msg.sender == dev);
      require(validOfTokenId[tokenId] == false, "NFT already exists.");
      require(TotalTokenId <= maxTokenId, "You reached the maximum NFT to create.");
      require(_maxsupply >= _reserve);

      Infonft memory newinfoNft = Infonft({
        name : nameDesign[tokenId] = design,
        URI : URIs[tokenId] = _uri,
        cost : price[tokenId]= _price,
        whitelistCost : whitelistPrice[tokenId] = _whitelistPrice, 
        supply : supply[tokenId] = 0,
        burned : burnCounter[tokenId] = 0,
        reserve : reserve[tokenId] = _reserve,
        maxsupply: maxsupply[tokenId] = _maxsupply,
        tokenIdExist: validOfTokenId[tokenId] = true,
        serialN : serial[tokenId] = ""

      });
      
    
      _infoNft.push(newinfoNft); 
      TotalTokenId++;   
      return true;  

    }

    function manycreateToken(uint[] memory tokenId, string[] memory design, uint[] memory _maxsupply, string[] memory _uri, uint[] memory _price, uint[] memory _reserve, uint[] memory _whitelistPrice) external returns(bool){
      require(msg.sender == own || msg.sender == dev);
     
      for(uint i = 0; i < tokenId.length; i++ ){
          require(validOfTokenId[tokenId[i]] == false, "This NFT already exists.");
          require(TotalTokenId <= maxTokenId, "You reached the maximum NFT to create.");
          require(_maxsupply[i] >= _reserve[i]);
          Infonft memory newinfoNft = Infonft({
              name : nameDesign[tokenId[i]] = design[i],
              URI : URIs[tokenId[i]] = _uri[i],
              cost : price[tokenId[i]]= _price[i],
              whitelistCost : whitelistPrice[tokenId[i]] = _whitelistPrice[i], 
              supply : supply[tokenId[i]] = 0,
              reserve : reserve[tokenId[i]] = _reserve[i],
              burned : burnCounter[tokenId[i]] = 0,
              maxsupply: maxsupply[tokenId[i]] = _maxsupply[i],
              tokenIdExist : validOfTokenId[tokenId[i]] = true,
              serialN : serial[tokenId[i]] = ""

      });
       
       _infoNft.push(newinfoNft);   
       TotalTokenId++;   
    }       
       return true;  

   }


// Price 
 
    function setPrice(uint tokenId, uint eth) external returns(bool){
        require(msg.sender == own || msg.sender == dev);
        price[tokenId] = eth;         
        Infonft storage thisInfonft = _infoNft[tokenId];
        thisInfonft.cost = eth;
        return true; 
    }

    function bigSetPrice(uint[] memory tokenId, uint[] memory eth) external returns(bool){
 
        for (uint256 i = 0; i < tokenId.length; i++) {
        require(msg.sender == own || msg.sender == dev);
        price[tokenId[i]] = eth[i];
        Infonft storage thisInfonft = _infoNft[tokenId[i]];
        thisInfonft.cost = eth[i];
     }
        return true; 
    }

    function setPriceWhitelist(uint tokenId, uint eth) external returns(bool){
        require(msg.sender == own || msg.sender == dev);
        whitelistPrice[tokenId] = eth;         
        Infonft storage thisInfonft = _infoNft[tokenId];
        thisInfonft.whitelistCost = eth;
        return true; 
    }

   
 // Airdrop



    function airdrop(address[] calldata addresses, uint tokenId) public returns(bool)   {
           require(msg.sender == own || msg.sender == dev);
            require(addresses.length > 0);
            for (uint256 i = 0; i < addresses.length; i++) {
              _mint(addresses[i], tokenId, 1, "");
            }
              return true;
        }

    function bigairdrop(address[] calldata addresses, uint[] memory tokenId, uint[] memory amount ) public returns(bool) {
            require(msg.sender == own || msg.sender == dev);
            require(addresses.length > 0);
            for (uint256 i = 0; i < addresses.length; i++) {
              _mint(addresses[i], tokenId[i], amount[i],"");
            }
              return true;
     }
  

    // Transfer & Burn NFT
    
    function transfer(address[] calldata addresses, uint tokenId, uint[] memory quantity) public returns(bool)  {
              require(addresses.length > 0);
              for (uint256 i = 0; i < addresses.length; i++) {        
                safeTransferFrom(msg.sender, addresses[i], tokenId, quantity[i], "");
              }

              return true;
      }

    function burned(uint id, uint amount) public returns(bool)  {
            
            require(timeToBurn == true, "It's not time to burn your design");
            require(msg.sender == _msgSender(), "not the sender");
            uint newsupply = balanceOf(msg.sender, id);
            require(1 <= newsupply, "You do to have minimum 1 copy of this design in your wallet");
            require(newsupply >= amount, "You doesn't have this number of copy of this design in your wallet");
            
            
            _burn(msg.sender, id, amount);
            newsupply -= amount;

            Infonft storage thisInfonft = _infoNft[id];
            thisInfonft.supply -= amount;
            thisInfonft.burned += amount; 

            supply[id] -= amount;
            burnCounter[id] += amount;
            burnCounterAddress[msg.sender][id] += amount; 
            listOfAddressBurned[msg.sender][id] = true;
            
            if(newsupply == 0){
              listOfAddressMinted[msg.sender][id] = false; // Delete every owner doesn't have a NFT of this collection. 
            }                
            return true;
    }

       // ETH
    function withdraw(address payable receiver) external nonReentrant {
        require(msg.sender == own || msg.sender == dev);
        receiver.transfer(address(this).balance);
    }

    function deposit() payable external {}
    
}