// SPDX-License-Identifier: MIT
import "./libs.sol";

pragma solidity ^0.8.4;

contract ensCOM is ERC721A, Ownable, ReentrancyGuard {
    /*
      ___           ___           ___           ___           ___           ___
     /  /\         /__/\         /  /\         /  /\         /  /\         /__/\    
    /  /:/_        \  \:\       /  /:/_       /  /:/        /  /::\       |  |::\   
   /  /:/ /\        \  \:\     /  /:/ /\     /  /:/        /  /:/\:\      |  |:|:\  
  /  /:/ /:/_   _____\__\:\   /  /:/ /::\   /  /:/  ___   /  /:/  \:\   __|__|:|\:\ 
 /__/:/ /:/ /\ /__/::::::::\ /__/:/ /:/\:\ /__/:/  /  /\ /__/:/ \__\:\ /__/::::| \:\
 \  \:\/:/ /:/ \  \:\~~\~~\/ \  \:\/:/~/:/ \  \:\ /  /:/ \  \:\ /  /:/ \  \:\~~\__\/
  \  \::/ /:/   \  \:\  ~~~   \  \::/ /:/   \  \:\  /:/   \  \:\  /:/   \  \:\      
   \  \:\/:/     \  \:\        \__\/ /:/     \  \:\/:/     \  \:\/:/     \  \:\     
    \  \::/       \  \:\         /__/:/       \  \::/       \  \::/       \  \:\    
     \__\/         \__\/         \__\/         \__\/         \__\/         \__\/    

    ensCOM .com Name Service for Ethereum (https://enscom.domains)
    */

    mapping(address => uint64) public allowlistAddresses;
    mapping(string => mapping(address => bool)) public subDomains_allowlistAddresses;
    mapping(string => address) public resolveAddress;
    mapping(address => string) public primaryAddress;
    mapping(string => bool) public subDomains_publicSale;
    mapping(string => uint) public subDomains_cost;
    mapping(string => bytes32) public subDomains_allowList;
    mapping(string => uint) public subDomains_allowList_cost;
    mapping(string => mapping(string => string)) public dataAddress;

    string private BASE_URI = 'https://enscom.domains/api/';
    string private domain = '.com';

    uint256 public cost = 7000000000000000;
    uint256 public whitelist_price = 5000000000000000;
   
    bytes32 public merkleRoot;
    bool public IS_SALE_ACTIVE = false;
    bool public IS_ALLOWLIST_ACTIVE = false;
    using Strings for uint256;
    
    uint256 public ref = 20;
    uint256 public ref_owner = 25;
    uint256 public ref_discount = 25;
    uint256 public subdomains_fee = 10;
    uint256 private maxCharSize=20;
    bytes _allowChars = "0123456789-_abcdefghijklmnopqrstuvwxyz";

    constructor() ERC721A(".com Name Service (ensCOM)", ".com") {
        tokenIDandAddress[_currentIndex]="com";
        tokenAddressandID["com"]=_currentIndex;
        resolveAddress["com"]=msg.sender;
        _safeMint(msg.sender,1);
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setAddress(string calldata ether_name, address newresolve) external {
         TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);
        if (Ownership.addr != msg.sender) revert("Error");

    bytes memory result = bytes(primaryAddress[resolveAddress[ether_name]]);
        if (keccak256(result) == keccak256(bytes(ether_name))) {
            primaryAddress[resolveAddress[ether_name]]="";
        }
        resolveAddress[ether_name]=newresolve;
    }

    function setPrimaryAddress(string calldata ether_name) external {
        require(resolveAddress[ether_name]==msg.sender, "Error");
        primaryAddress[msg.sender]=ether_name;
    }


    function setDataAddress(string calldata ether_name,string calldata setArea, string  memory newDatas) external {
         TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);

        if (Ownership.addr != msg.sender) revert("Error");
        dataAddress[ether_name][setArea]=newDatas;
    }

    function getDataAddress(string memory ether_name, string calldata Area) public view returns(string memory) {
        return dataAddress[ether_name][Area];
    }


    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setMaxCharSize(uint256 maxCharSize_) external onlyOwner {
        maxCharSize = maxCharSize_;
    }
    
     function setAllowChars(bytes memory allwchr) external onlyOwner {
        _allowChars = allwchr;
    }

    function setPrice(uint256 customPrice) external onlyOwner {
        cost = customPrice;
    }

    function setWhitelistPrice(uint256 customPrice) external onlyOwner {
        whitelist_price = customPrice;
    }

    function setRefSettings(uint ref_,uint ref_owner_,uint ref_discount_,uint subdomains_fee_) external onlyOwner {
        ref = ref_;
        ref_owner = ref_owner_;
        ref_discount = ref_discount_;
        subdomains_fee = subdomains_fee_;

    }


    function setSaleActive(bool saleIsActive) external onlyOwner {
        IS_SALE_ACTIVE = saleIsActive;
    }

     function setAllowListSaleActive(bool WhitesaleIsActive) external onlyOwner {
        IS_ALLOWLIST_ACTIVE = WhitesaleIsActive;
    }

    function setSubdomainSaleActive(bool saleIsActive, uint256 customPrice, string calldata ether_name) public {
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);
        require(Ownership.addr == msg.sender, "Invalid");
        subDomains_cost[ether_name] = customPrice;
        subDomains_publicSale[ether_name] = saleIsActive;
    }

    function register(address ref_address, string memory ether_name)
        public
        payable
    {   
        uint256 price = cost;
        bool is_ref=false;
        uint256 ref_cost=0;
        require(bytes(ether_name).length<=maxCharSize,"Long name");
        require(bytes(ether_name).length>0,"Write a name");
        require(_checkName(ether_name), "Invalid name");
        if (ref_address== 0x0000000000000000000000000000000000000000) {
        price=cost;
        } else {
        if (bytes(primaryAddress[ref_address]).length>0){
        ref_cost=price*ref_owner/100;
        } else {
        ref_cost=price*ref/100;
        }
        price = price*(100-ref_discount)/100;
        is_ref=true;
        }
        require (tokenAddressandID[ether_name] == 0 , "This is already taken"); 
        require(IS_SALE_ACTIVE, "Sale is not active!");
        require(msg.value >= price, "Insufficient funds!");
        tokenIDandAddress[_currentIndex]=ether_name;
        tokenAddressandID[ether_name]=_currentIndex;
        resolveAddress[ether_name]=msg.sender;
         if (is_ref) {
        payable(ref_address).transfer(ref_cost);
        }
        _safeMint(msg.sender,1);
    }

     function allowList(string memory ether_name, bytes32[] calldata _merkleProof)
        public
        payable
    {
            require(IS_ALLOWLIST_ACTIVE, "Allow List sale is not active!");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");
            require(bytes(ether_name).length<=maxCharSize,"Long name");
            require(bytes(ether_name).length>0,"Write a name");
            require(_checkName(ether_name), "Invalid name");
            require(allowlistAddresses[msg.sender] < 3, "You have reached maximum allowlist mints");
            require (tokenAddressandID[ether_name] == 0 , "This is already taken");
            require(msg.value >= whitelist_price, "Insufficient funds!");
            allowlistAddresses[msg.sender] += 1;
            tokenIDandAddress[_currentIndex]=ether_name;
            tokenAddressandID[ether_name]=_currentIndex;
            resolveAddress[ether_name]=msg.sender;
            _safeMint(msg.sender,1);
    }

    function checkAllowlist(bytes32[] calldata _proof) public view returns(bool) {
        bool allowed = MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        return allowed;
    }


    function registerSubdomain(string memory ether_name, string memory subdomain_name)
        public
        payable
    {   
        require(IS_SALE_ACTIVE, "Sale is not active!");
        string memory new_domain=string.concat(subdomain_name,'.',ether_name);
        require(bytes(subdomain_name).length<=maxCharSize,"Long name");
        require(bytes(subdomain_name).length>0,"Write a name");
        require(_checkName(ether_name), "Invalid name");
        require(_checkName(subdomain_name), "Invalid name");
        require (tokenAddressandID[new_domain] == 0 , "This is already taken"); 
  
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);
        if (Ownership.addr == msg.sender)
        {
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender; 
        _safeMint(msg.sender,1);   
        } else {
        require(subDomains_publicSale[ether_name]==true, "Only Owner can register");
        require(msg.value >= subDomains_cost[ether_name], "Insufficient funds!");
        payable(Ownership.addr).transfer(msg.value*(100-subdomains_fee)/100);
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender;
        _safeMint(msg.sender,1);       
        }
    }


    function allowListSubdomain(string memory ether_name,  string memory subdomain_name, bytes32[] calldata _merkleProof)
        public
        payable
    {      
            string memory new_domain=string.concat(subdomain_name,'.',ether_name);
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, subDomains_allowList[ether_name], leaf),"Invalid proof!");
            require(msg.value >= subDomains_allowList_cost[ether_name], "Insufficient funds!");


            require(bytes(subdomain_name).length<=maxCharSize,"Long name");
            require(bytes(subdomain_name).length>0,"Write a name");
            require(_checkName(ether_name), "Invalid name");
            require(_checkName(subdomain_name), "Invalid name");
            require(subDomains_allowlistAddresses[ether_name][msg.sender]!=true, "Claimed!");
            require (tokenAddressandID[new_domain] == 0 , "This is already taken"); 
            TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);
            payable(Ownership.addr).transfer(msg.value*(100-subdomains_fee)/100);
            subDomains_allowlistAddresses[ether_name][msg.sender] = true;
            tokenIDandAddress[_currentIndex]=new_domain;
            tokenAddressandID[new_domain]=_currentIndex;
            resolveAddress[new_domain]=msg.sender;
            _safeMint(msg.sender,1);
    }

    
    function namediff(uint256 tokenId , string calldata new_ether_name) external onlyOwner {
        tokenIDandAddress[tokenId]=new_ether_name;
        tokenAddressandID[new_ether_name]=tokenId;
    }


function walletOfOwnerName(address _owner)
    public
    view
    returns (string[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    string[] memory ownedTokenIds = new string[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = string.concat(tokenIDandAddress[currentTokenId],domain);

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }


function lastAddresses(uint256 count)
    public
    view
    returns (string[] memory)
  {
    uint256 total = totalSupply();
    string[] memory lastAddr = new string[](count);
    uint256 currentId = total - count;
    uint256 ownedTokenIndex = 0;
    require(currentId>=0,"Invalid");
    while (total > currentId) {
        lastAddr[ownedTokenIndex] = string.concat(tokenIDandAddress[total],domain);
        ownedTokenIndex++;
      total--;
    }

    return lastAddr;
  }


function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

function setMerkleRootSubdomain(bytes32 _newMerkleRoot, string memory ether_name, uint256 _cost) external {
      TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ether_name]);
        if (Ownership.addr != msg.sender) revert("Error");

        subDomains_allowList[ether_name] = _newMerkleRoot;
        subDomains_allowList_cost[ether_name] = _cost;
    }
    


 function _checkName(string memory _name) public view returns(bool){
        uint allowedChars =0;
        bytes memory byteString = bytes(_name);
        bytes memory allowed = bytes(_allowChars);  
        for(uint i=0; i < byteString.length ; i++){
           for(uint j=0; j<allowed.length; j++){
              if(byteString[i]==allowed[j] )
              allowedChars++;         
           }
        }
        if (allowedChars==byteString.length) { return true; } else { return false; }
       
    }

        /** PAYOUT **/

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(0x0524989feeB3284B24649C5DfC699Dd9D8edF7D9),balance);
        }

}