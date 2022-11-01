// SPDX-License-Identifier: MIT
import "./libs.sol";

pragma solidity ^0.8.4;

contract DDNS is ERC721A, IERC2981, Ownable, ReentrancyGuard {

    /*

	██████╗ ██████╗ ███╗   ██╗███████╗
	██╔══██╗██╔══██╗████╗  ██║██╔════╝
	██║  ██║██║  ██║██╔██╗ ██║███████╗
	██║  ██║██║  ██║██║╚██╗██║╚════██║
	██████╔╝██████╔╝██║ ╚████║███████║
	╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

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

    string private BASE_URI = "https://metadata.ddns.dweb/";
    string private domain = ".dweb";

    uint256 public cost = 10000000000000000;
    uint256 public whitelist_price = 10000000000000000;

    bytes32 public merkleRoot;
    bool public IS_SALE_ACTIVE = false;
    bool public IS_ALLOWLIST_ACTIVE = false;
    using Strings for uint256;

    uint256 public ref = 5;
    uint256 public ref_owner = 10;
    uint256 public ref_discount = 10;
    uint256 public subdomains_fee = 1;
    uint256 private maxCharSize = 1024;
    bytes _disallowChars = hex"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2e2f3a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f607b7c7d7e7f";
    bool public domainsuffix = true;

    constructor() ERC721A("DDNS", "DDNS") {
        tokenIDandAddress[_currentIndex]="ddns";
        tokenAddressandID["ddns"]=_currentIndex;
        resolveAddress["ddns"]=msg.sender;
        _safeMint(msg.sender,1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setAddress(string calldata ddns_name, address newresolve) external {
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        if (Ownership.addr != msg.sender) revert("Error");
        bytes memory result = bytes(primaryAddress[resolveAddress[ddns_name]]);
        if (keccak256(result) == keccak256(bytes(ddns_name))) {
            primaryAddress[resolveAddress[ddns_name]]="";
        }
        resolveAddress[ddns_name]=newresolve;
    }

    function setPrimaryAddress(string calldata ddns_name) external {
        require(resolveAddress[ddns_name]==msg.sender, "Error");
        primaryAddress[msg.sender]=ddns_name;
    }

    function setDataAddress(string calldata ddns_name,string calldata setArea, string  memory newDatas) external {
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        if (Ownership.addr != msg.sender) revert("Error");
        dataAddress[ddns_name][setArea]=newDatas;
    }

    function getDataAddress(string memory ddns_name, string calldata Area) public view returns(string memory) {
        return dataAddress[ddns_name][Area];
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }
    
    function setDomain(string memory customDomain_) external onlyOwner {
        domain = customDomain_;
    }

    function setMaxCharSize(uint256 maxCharSize_) external onlyOwner {
        maxCharSize = maxCharSize_;
    }

    function setDisallowChars(bytes memory disallchr) external onlyOwner {
        _disallowChars = disallchr;
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

    function setDomainSuffixActive(bool DomainSuffixIsActive) external onlyOwner {
        domainsuffix = DomainSuffixIsActive;
    }

    function setSubdomainSaleActive(bool saleIsActive, uint256 customPrice, string calldata ddns_name) public {
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        require(Ownership.addr == msg.sender, "Invalid");
        subDomains_cost[ddns_name] = customPrice;
        subDomains_publicSale[ddns_name] = saleIsActive;
    }

    function register(address ref_address, string memory ddns_name)
        public
        payable
    {
        uint256 price = cost;
        bool is_ref=false;
        uint256 ref_cost=0;
        require(bytes(ddns_name).length<=maxCharSize,"Long name");
        require(bytes(ddns_name).length>0,"Write a name");
        require(_checkName(ddns_name),"Invalid name");
        if (ref_address == 0x0000000000000000000000000000000000000000) {
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
        require(tokenAddressandID[ddns_name] == 0, "This is already taken"); 
        require(IS_SALE_ACTIVE, "Sale is not active");
        require(msg.value >= price, "Insufficient funds");
        tokenIDandAddress[_currentIndex]=ddns_name;
        tokenAddressandID[ddns_name]=_currentIndex;
        resolveAddress[ddns_name]=msg.sender;
        if (is_ref) {
        payable(ref_address).transfer(ref_cost);
        }
        _safeMint(msg.sender,1);
    }

    function bulkregister(address ref_address, string[] memory ddns_name)
        public
        payable
    {
        for ( uint i = 0; i < ddns_name.length; ++i ) {
        uint256 price = cost*ddns_name.length;
        uint256 priceref = cost;        
        bool is_ref=false;
        uint256 ref_cost=0;
        require(bytes(ddns_name[i]).length<=maxCharSize, string.concat(ddns_name[i]," is a long name"));
        require(bytes(ddns_name[i]).length>0,"Write a name");
        require(_checkName(ddns_name[i]), string.concat(ddns_name[i]," is an invalid name"));
        if (ref_address == 0x0000000000000000000000000000000000000000) {
        price = cost*ddns_name.length;
        } else {
        if (bytes(primaryAddress[ref_address]).length>0){
        ref_cost = priceref*ref_owner/100;
        } else {
        ref_cost = priceref*ref/100;
        }
        price = cost*ddns_name.length*(100-ref_discount)/100;
        is_ref=true;
        }
        require(tokenAddressandID[ddns_name[i]] == 0, string.concat(ddns_name[i]," is already taken"));
        require(IS_SALE_ACTIVE, "Sale is not active");
        require(msg.value >= price, "Insufficient funds");
        tokenIDandAddress[_currentIndex]=ddns_name[i];
        tokenAddressandID[ddns_name[i]]=_currentIndex;
        resolveAddress[ddns_name[i]]=msg.sender;
        if (is_ref) {
        payable(ref_address).transfer(ref_cost);
        }
        _safeMint(msg.sender,1);
        }
    }

    function allowList(string memory ddns_name, bytes32[] calldata _merkleProof)
        public
        payable
    {
            require(IS_ALLOWLIST_ACTIVE, "Allowlist sale is not active");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof");
            require(bytes(ddns_name).length<=maxCharSize,"Long name");
            require(bytes(ddns_name).length>0,"Write a name");
            require(_checkName(ddns_name), "Invalid name");
            require(allowlistAddresses[msg.sender] < 10, "You have reached maximum allowlist mints");
            require(tokenAddressandID[ddns_name] == 0 , "This is already taken");
            require(msg.value >= whitelist_price, "Insufficient funds");
            allowlistAddresses[msg.sender] += 1;
            tokenIDandAddress[_currentIndex]=ddns_name;
            tokenAddressandID[ddns_name]=_currentIndex;
            resolveAddress[ddns_name]=msg.sender;
            _safeMint(msg.sender,1);
    }

    function checkAllowlist(bytes32[] calldata _proof) public view returns(bool) {
        bool allowed = MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
        return allowed;
    }

    function registerSubdomain(string memory ddns_name, string memory subdomain_name)
        public
        payable
    {
        require(IS_SALE_ACTIVE, "Sale is not active");
        string memory new_domain=string.concat(subdomain_name,'.',ddns_name);
        require(bytes(subdomain_name).length<=maxCharSize,"Long name");
        require(bytes(subdomain_name).length>0,"Write a name");
        require(_checkName(subdomain_name), "Invalid name");
        require(tokenAddressandID[new_domain] == 0, "This is already taken");  
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        if (Ownership.addr == msg.sender)
        {
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender;
        _safeMint(msg.sender,1);
        } else {
        require(subDomains_publicSale[ddns_name]==true, "Only owner can register");
        require(msg.value >= subDomains_cost[ddns_name], "Insufficient funds");
        payable(Ownership.addr).transfer(msg.value*(100-subdomains_fee)/100);
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender;
        _safeMint(msg.sender,1);
        }
    }

    function bulkregisterSubdomain(string memory ddns_name, string[] memory subdomain_name)
        public
        payable
    {
        for ( uint i = 0; i < subdomain_name.length; ++i ) {
        require(IS_SALE_ACTIVE, "Sale is not active");
        string memory new_domain=string.concat(subdomain_name[i],'.',ddns_name);
        require(bytes(subdomain_name[i]).length<=maxCharSize, string.concat(new_domain," is a long name"));
        require(bytes(subdomain_name[i]).length>0,"Write a name");
        require(_checkName(subdomain_name[i]), string.concat(new_domain," is an invalid name"));
        require(tokenAddressandID[new_domain] == 0, string.concat(new_domain," is already taken"));
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        if (Ownership.addr == msg.sender)
        {
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender;
        _safeMint(msg.sender,1);
        } else {
        require(subDomains_publicSale[ddns_name]==true, "Only owner can register");
        require(msg.value >= subDomains_cost[ddns_name]*subdomain_name.length, "Insufficient funds");
        payable(Ownership.addr).transfer(subDomains_cost[ddns_name]*(100-subdomains_fee)/100);
        tokenIDandAddress[_currentIndex]=new_domain;
        tokenAddressandID[new_domain]=_currentIndex;
        resolveAddress[new_domain]=msg.sender;
        _safeMint(msg.sender,1);
        }
        }
    }

    function allowListSubdomain(string memory ddns_name, string memory subdomain_name, bytes32[] calldata _merkleProof)
        public
        payable
    {
            string memory new_domain=string.concat(subdomain_name,'.',ddns_name);
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, subDomains_allowList[ddns_name], leaf),"Invalid proof");
            require(msg.value >= subDomains_allowList_cost[ddns_name], "Insufficient funds");
            require(bytes(subdomain_name).length<=maxCharSize,"Long name");
            require(bytes(subdomain_name).length>0,"Write a name");
            require(_checkName(subdomain_name), "Invalid name");
            require(subDomains_allowlistAddresses[ddns_name][msg.sender]!=true, "Claimed");
            require(tokenAddressandID[new_domain] == 0 , "This is already taken"); 
            TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
            payable(Ownership.addr).transfer(msg.value*(100-subdomains_fee)/100);
            subDomains_allowlistAddresses[ddns_name][msg.sender] = true;
            tokenIDandAddress[_currentIndex]=new_domain;
            tokenAddressandID[new_domain]=_currentIndex;
            resolveAddress[new_domain]=msg.sender;
            _safeMint(msg.sender,1);
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
		  if ( domainsuffix == true ) {
		  ownedTokenIds[ownedTokenIndex] = string.concat(tokenIDandAddress[currentTokenId],domain);
		  } else {
		  ownedTokenIds[ownedTokenIndex] = string.concat(domain,tokenIDandAddress[currentTokenId]);  
		  }
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
        if ( domainsuffix == true ) {
        lastAddr[ownedTokenIndex] = string.concat(tokenIDandAddress[total],domain);
        } else {
        lastAddr[ownedTokenIndex] = string.concat(domain,tokenIDandAddress[total]);  
        }        
        ownedTokenIndex++;
      total--;
    }
    return lastAddr;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setMerkleRootSubdomain(bytes32 _newMerkleRoot, string memory ddns_name, uint256 _cost) external {
        TokenOwnership memory Ownership = _ownershipOf(tokenAddressandID[ddns_name]);
        if (Ownership.addr != msg.sender) revert("Error");
        subDomains_allowList[ddns_name] = _newMerkleRoot;
        subDomains_allowList_cost[ddns_name] = _cost;
    }

    function _checkName(string memory _name) public view returns(bool){
        bytes memory b = bytes(_name);
        bytes memory disallowed = _disallowChars;
        for(uint i; i<b.length; i++){
        for(uint j; j<disallowed.length; j++){
        if(b[i] == disallowed[j])
        return false;
        }
        }
        return true;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(0x888888542DA9E684078a68708fD56f86D43699ae),balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external pure returns (address, uint256 royaltyAmount) {
    _tokenId;
    royaltyAmount = (_salePrice / 100) * 1;
    return (0x888888542DA9E684078a68708fD56f86D43699ae, royaltyAmount);
    }

}