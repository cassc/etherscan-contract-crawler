//SPDX-License-Identifier: MIT

//Author: @hodl_pcc << twitter

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./registration-rules.sol";
import "./interfaces/IERC2981.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IRegister.sol";
import "./interfaces/IENSAdmin.sol";
import "./interfaces/IReverseResolver.sol";
import "./interfaces/ICCIPResolver.sol";
import "./metadata-provider.sol";
import "./ENSEnumerable.sol";
import "./EnsTldWrapper.sol";

pragma solidity ^0.8.13;


struct EnsInfo {
    uint256 id;
    string domain;
    uint256 royalty;
    address owner;
    bool locked;
    uint256 price;
    string image;
    bytes32 domainHash;
    address currentLocation;
    uint256 expiry;

}

contract SubdomainFactory is  IManager, IERC721Receiver, Ownable, ERC165, ERC721, IERC2981, ENSEnumerable {

    using SafeMath for uint256;
    using Strings for uint256;

    event DepositEns(address indexed _from, uint256 indexed _id, string _domainLabel);
    event TransferEnsOwnership(address indexed _from, address indexed _to, uint256 indexed _id);
    event WithdrawEns(address indexed _to, uint256 indexed _id);
    event WithdrawFunds(address indexed _addr, uint256 _funds);
    event UpdateDomainDefaultImage(address indexed _addr, uint256 indexed _id, string _image);
    event UpdateDomainDefaultMintPrice(address indexed _addr, uint256 indexed _id, uint256 _defaultPriceInWei);
    event UpdateDomainRoyaltyPercentage(address indexed _addr, uint256 indexed _id, uint256 _percentage);
    event UpdateDomainRegistrationRules(address indexed _addr, uint256 indexed _id, address indexed _registrationStrategy);
    event LockEnsDomain(address indexed _addr, uint256 indexed _id);
    event SubdomainRegistered(address indexed _addr, uint256 indexed _id, uint256 indexed _subdomainId, string _subDomain);
    event AddrChanged(bytes32 indexed node, address a);

    address constant ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant PUBLIC_RESOLVER_ADDRESS = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
    address constant REVERSE_RESOLVER_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
    address constant ENS_TOKEN_ADDRESS = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;

    IReverseResolver public ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
    IENSAdmin public PublicResolver = IENSAdmin(PUBLIC_RESOLVER_ADDRESS);
    IENSToken public EnsToken = IENSToken(ENS_TOKEN_ADDRESS);
    ENS private ens = ENS(ENS_ADDRESS); 

    EnsTldWrapper public EnsWrapper;
    IRegister public DefaultRegister;
    ICCIPResolver public CCIPResolver;
    bool public CCIPResolverLocked;   
    IMetadata public MetaData;
    uint256 private currentId; 
    uint256 public ContractOwnerPrimaryRoyalties = 2;
    uint256 public MinDomainExpiry = 90 days;
    mapping(uint256 => address) public TokenOwnerMap;
    mapping(uint256 => bool) public TokenLocked;
    mapping(bytes32 => uint256) public HashToIdMap;
    mapping(uint256 => bytes32) public IdToHashMap;
    mapping(uint256 => uint256) public IdToOwnerId;
    mapping(uint256 => string) public IdToLabelMap;
    mapping(uint256 => IRegister) public IdToRegisterMap;
    mapping(uint256 => bool) public IdToUseCCIPMap;
    mapping(address => mapping(uint256 => address)) public RedirectAddress;
    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(uint256 => string) public IdToDomain;
    mapping(uint256 => uint256) public IdRoyaltyMap;
    mapping(uint256 => string) public IdImageMap;
    mapping(uint256 => uint256) public DefaultMintPrice;
    mapping(address => uint256) public OwnerFunds;

    uint256 public ContractOwnerFunds;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    uint256 public DepositCost = 0.1 ether;

    constructor() ERC721("ENS sub-domains", "ESF"){
         MetaData = new MetadataProviderV1(this);
         DefaultRegister = new RegistrationRulesV1(this);
         EnsWrapper = new EnsTldWrapper(this);
         EnsWrapper.transferOwnership(msg.sender); //just so can update metadata link
    }

    function onERC721Received(
        address operator,
        address from,   
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        require(address(this) == operator, "only transfer from contract address");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    fallback() payable external {
        ContractOwnerFunds += msg.value;
    }

    receive() payable external {
        ContractOwnerFunds += msg.value;
    }

    function withdrawEns(uint256 _id) external tokenOwner(_id) {

        require(!TokenLocked[_id], "token is locked");
        EnsToken.safeTransferFrom(address(this), msg.sender, _id);
        EnsWrapper.burn(_id);
        _beforeTLDTransfer(msg.sender, address(0), _id);

        emit WithdrawEns(msg.sender, _id);
    }


function depositEns(string calldata _label, uint256 _royalty, uint256 _mintPrice, string calldata _defaultImageUri) payable external {
    depositEns(_label, _royalty, _mintPrice, _defaultImageUri, DefaultRegister, false);
}

    //only pay for the first deposit of a token.
    function getDepositCost(uint256 _id) public view returns(uint256) {
        return TokenOwnerMap[_id] == address(0) ? DepositCost : 0;
    }

    function getSubdomainCost(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns (uint256){
        require(EnsToken.ownerOf(_tokenId) == address(this), "token not in contract");
        return IdToRegisterMap[_tokenId].mintPrice(_tokenId, _label, _addr, _proofs);
    }
    ///Deposit the ENS token and register it for sub-domain creation
    ///This costs the fixed amount that is set by the contract owner
    ///@param _label label of the .eth domain that is being deposited
    // the id is worked out from the text
    ///@param _royalty Royalty % should be integer 0 - 10
    ///@param _mintPrice should be more than 0.01 ether
    function depositEns(string calldata _label, uint256 _royalty, uint256 _mintPrice, string calldata _defaultImageUri, IRegister _registrationStrategy, bool _useCCIP) payable public {
        uint256 id = getIdFromLabel(_label);
        require(msg.value == getDepositCost(id), "incorrect ether");             
        require(EnsToken.nameExpires(id) > (block.timestamp.add(MinDomainExpiry)), "domain expires too early");

        EnsToken.reclaim(id, address(this));
        bytes32 domainHash = getDomainHash(_label);

        if (ens.resolver(domainHash) != address(PublicResolver) 
            && (!_useCCIP || address(CCIPResolver) == address(0))){

                ens.setResolver(domainHash, address(PublicResolver));
        }

        //if resolver is already set to public and _useCCIP is false then do nothing

        if (_useCCIP && address(CCIPResolver) != address(0)){
            ens.setResolver(domainHash, address(this));
            IdToUseCCIPMap[id] = true;
        }

        EnsToken.safeTransferFrom(msg.sender, address(this), id);
        TokenOwnerMap[id] = msg.sender;
        IdToDomain[id] = _label;

        IdToRegisterMap[id] = _registrationStrategy;

        ContractOwnerFunds = ContractOwnerFunds.add(msg.value);

        if(_royalty > 0){
            setRoyaltyPercent(id, _royalty);            
        }

        if(_mintPrice > 0){
            setMintPrice(id, _mintPrice);                      
        }

        if(bytes(_defaultImageUri).length > 0){
            setSubdomainImageUri(id, _defaultImageUri);           
        }

        IdToRegisterMap[id] = _registrationStrategy;

        emit UpdateDomainRegistrationRules(msg.sender, id, address(_registrationStrategy));
        emit DepositEns(msg.sender, id, _label);

        //if the token has expired then it may be redeposited
        if(EnsWrapper.exists(id)){
            EnsWrapper.burn(id);
            TokenLocked[id] = false;
            _beforeTLDTransfer(msg.sender, address(0), id);
        }

            EnsWrapper.mint(msg.sender, id);
            _beforeTLDTransfer(address(0), msg.sender, id);                 
    }

    ///helper method for getting ens id from the domain label
    function getIdFromLabel(string calldata _label) public pure returns(uint256 id) {
        bytes32 labelHash = keccak256(abi.encodePacked(_label));
        id = uint256(labelHash);
    }

    ///function to register sub-domain
    ///@param _id token id of the parent ens domain
    ///@param _label label for the subdomain, should be lower-case, numeric not uppercase
    function registerSubdomain(uint256 _id, string calldata _label, bytes32[] calldata _proofs) payable public {
        address owner = TokenOwnerMap[_id];
        //owner can always mint sub-domains of their TLD
        if (msg.sender != owner){
            //use ID specific registration strategy    
            //can be used for whitelist minting / payment strategy / label exclusion etc        
            require(IdToRegisterMap[_id].canRegister(_id, _label, msg.sender, msg.value, _proofs));
        }

        uint256 ownerCut;

        if (msg.value > 0){
            //owner primary cut is maximum 5% (set at 2% for contract deployment, unlikely to change)
            ownerCut = (msg.value / 100) * ContractOwnerPrimaryRoyalties;
            ContractOwnerFunds = ContractOwnerFunds.add(ownerCut);
            OwnerFunds[owner] = OwnerFunds[owner].add(msg.value - ownerCut);
        }

        register(_id, _label, msg.sender);       
    }

    function register(uint256 _tokenId, string memory _label, address _addr) private {
        bytes32 encoded_label = keccak256(abi.encodePacked(_label));
        bytes32 domainHash = getDomainHash(IdToDomain[_tokenId]);
        bytes32 hashed = keccak256(abi.encodePacked(domainHash, encoded_label));

        //we only check this contract for minted sub-domains. If you wish to protect sub-domains
        //registered externally then these will require specifying in some custom registration rules
        require(HashToIdMap[hashed] == 0, "sub-domain already exists");
        require(!ens.recordExists(hashed), "sub-domain already exists outside of esf.eth");

        //start from ID 1, this is because of the above check ^^
        uint256 id = ++currentId;

        IdToHashMap[id] = hashed;
        HashToIdMap[hashed] = id;
        _safeMint(_addr, id);
        IdToOwnerId[id] = _tokenId; //_tokenId is the parent ens id
        IdToLabelMap[id] = _label;
        ens.setSubnodeRecord(domainHash, encoded_label, address(this), address(this), 0);

        emit SubdomainRegistered(_addr, _tokenId, id, name(hashed));
    }


    ///@param node nodes representaion of the full domain
    ///@param key key of the key:value pair to return
    ///@return value of the key. avatar is default but it can be overridden
    function rawText(bytes32 node, string calldata key) public view returns (string memory) {
        string memory value = texts[node][key];
        
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar") && bytes(value).length == 0){
            uint256 id = HashToIdMap[node];
            uint256 owner = IdToOwnerId[id];
            value = IdImageMap[owner];
        }

        return value;
    }


    ///interface method
    ///@param node nodes representaion of the full domain
    ///@param key key of the key:value pair to return
    ///@return value of the key. avatar is default but it can be overridden
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 id = HashToIdMap[node];
        //added ccip proxy resolver to "future proof"
        if (shouldUseCcipResolver(IdToOwnerId[id])) {
            return CCIPResolver.text(node, key);
        }
        else {
            return rawText(node, key);
        }
    }

    //standard interface method
    function addr(bytes32 nodeID) public view returns (address) {
        uint256 id = HashToIdMap[nodeID];

        //added in ccip resolver to "future proof"
        if (shouldUseCcipResolver(IdToOwnerId[id])) {
            return CCIPResolver.addr(nodeID);
        }
        else {
            address owner = ownerOf(id);
            address redirect = RedirectAddress[owner][id];
            return (redirect == address(0)) ? owner : redirect;
        }
    }

    function shouldUseCcipResolver(uint256 _id) private view returns(bool){
        //0 for wildcard entries.. will need to add extra logic inside of registration
        //rules to stop off-chain sub-domains being reregistered
        return (IdToUseCCIPMap[_id] || _id == 0) 
                && address(CCIPResolver) != address(0);
    }


    function name(bytes32 node) view public returns (string memory){
        uint256 id = HashToIdMap[node];
        uint256 owner = IdToOwnerId[id];

        //added in ccip resolver to "future proof"
        if (shouldUseCcipResolver(owner)) {
            return CCIPResolver.name(node);
        }
        else {

            string memory domain = IdToDomain[owner];
            string memory label = IdToLabelMap[id];
            return string(abi.encodePacked(label,".",domain,".eth"));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC165, ERC721) returns(bool){
        return super.supportsInterface(interfaceId) 
        || interfaceId == 0x3b3b57de //addr
        || interfaceId == 0x59d1d43c //text
        || interfaceId == 0x691f3431 //name
        || interfaceId == 0x2a55205a //royalties
        || interfaceId == 0x01ffc9a7; //supportsInterface << [inception];
    }
    ///this is the correct method for creating a 2 level ENS namehash
    function getDomainHash(string memory _domain) public pure returns (bytes32 namehash) {
            namehash = 0x0;
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(_domain))));
    }

    function tokenURI(uint256 tokenId) public view  override(ERC721) returns(string memory){
        require(_exists(tokenId), "token does not exist");

        return MetaData.tokenURI(tokenId);
    }

    //user can set an address redirect for any delegated address. The redirect is only active
    //whilst the NFT is in the wallet that set it. Set to `0x0000000000000000000000000000000000000000`
    //to remove redirect
    function setRedirect(uint256 _id, address _to) external {
        //token checked if it exists in _isApprovedOrOwner method
        require(_isApprovedOrOwner(msg.sender, _id), "not approved");
        address owner = ownerOf(_id);
        RedirectAddress[owner][_id] = _to;
        emit AddrChanged(IdToHashMap[_id], _to == address(0) ? owner : _to);
    }

        function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        emit AddrChanged(IdToHashMap[tokenId], RedirectAddress[to][tokenId] == address(0) ? to : RedirectAddress[to][tokenId]);
    }

    function setText(bytes32 node, string calldata key, string calldata value) external {
        uint256 token_id = HashToIdMap[node];
        require(_exists(token_id), "token does not exist");
        require(_isApprovedOrOwner(msg.sender, token_id), "not approved");
        
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

///token owner functions

    ///This is the royalty percentage for secondary sales. It's set per sub-domain
    ///owner of the TLD can set this 0-10%, this works on all marketplaces that support 
    ///on-chain royalties :-)
    function setRoyaltyPercent(uint256 _id, uint256 _percent) public tokenOwner(_id) {
        require(_percent <= 10, "max 10 percent");

        IdRoyaltyMap[_id] = _percent;
        emit UpdateDomainRoyaltyPercentage(msg.sender, _id, _percent);
    }

    ///token owner can set mint price. 0 mint price means that it is not for minting by
    ///anyone apart from the token owner. Additional logic for mint price can be applied 
    ///in custom registration-rules that can be applied to any ENS domain. eg. you want to charge
    ///more for shorter labels / give certain wallets reduced price, many other ideas
    function setMintPrice(uint256 _id, uint256 _price) public tokenOwner(_id) {

        require(_price >= 0.01 ether || _price == 0, "min 0.01 ether");
        DefaultMintPrice[_id] = _price;
        emit UpdateDomainDefaultMintPrice(msg.sender, _id, _price); 
    }

    ///this is the default image that will display when users mint a sub-domain. This can be overridden
    ///by the user setting a value for the 'avatar' key in their text mappings
    function setSubdomainImageUri(uint256 _id, string calldata _uri) tokenOwner(_id) public {
        
        IdImageMap[_id] = _uri;
        emit UpdateDomainDefaultImage(msg.sender, _id, _uri);
    }

    ///proxy method so that the TLD owner can still manage various public resolver
    ///functions for their token despite it being contained in this contract
    function setTldAddr(uint256 _id, uint256 coinType, bytes  memory a) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setAddr(node, coinType, a);
    }

    function setTldAddr(uint256 _id, address a) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setAddr(node, a);
    }

    function setTldDNSRecords(uint256 _id, bytes memory data) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setDNSRecords(node, data);
    }

    function setTldText(uint256 _id, string memory key, string memory value) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setText(node, key, value);
    }


    ///use this method to update the registration stategy for any ENS domains. Can only be called by the 
    ///account that owns the tokens. Can update multiple at the same time.
    function updateRegistrationStrategy(uint256[] calldata _ids, IRegister _registrationStrategy) public {
        for(uint256 i; i < _ids.length;){
            require(TokenOwnerMap[_ids[i]] == msg.sender, "not owner");

            IdToRegisterMap[_ids[i]] = _registrationStrategy;

            emit UpdateDomainRegistrationRules(msg.sender, _ids[i], address(_registrationStrategy));

            //we do this because it's the most gas efficient way of doing the loop          
            unchecked { ++i; }
        }
    }

    ///I don't really like ccip, but need to make sure we provide a way of updating this in the future if it
    ///matures to a usable state.
    function updateUseCCIPResolver(uint256[] calldata _ids, bool _shouldUse) public {
        require(address(CCIPResolver) != address(0), "ccip resolver not set");
        for(uint256 i; i < _ids.length;){
            require(TokenOwnerMap[_ids[i]] == msg.sender, "not owner");

            IdToUseCCIPMap[_ids[i]] = _shouldUse;
            
            ens.setResolver(getDomainHash(IdToDomain[_ids[i]])
                            , _shouldUse ? address(this) : address(PublicResolver)
                            );

            //we do this because it's the most gas efficient way of doing the loop
            unchecked { ++i; }
        }        
    }

    ///this action cannot be undone. locked domain will remain permenantly locked in the contract unless
    ///it expires (remember that anyone can renew a domain, so it is our intention that project funds could be 
    ///redirected to fund renewals for popular domains)
    function lockDomain(uint256 _id) tokenOwner(_id) public {
        require(EnsToken.ownerOf(_id) == address(this), "token not in contract");
        require(!TokenLocked[_id], "token already locked");
        TokenLocked[_id] = true;

        emit LockEnsDomain(msg.sender, _id);
    }

///end token owner functions
//
// ------------------------------------

    ///if the "wrapped" ens domain is transferred then this method is called which will change the ownership
    ///of the domain for admin and payout purposes. We can't just link to the owner of this token because
    ///it is burned when the ENS is withdrawn.
    function transferDomainOwnership(uint256 _id, address _newOwner) external {       
        require(address(EnsWrapper) == msg.sender, "only through EnsWrapper transfer");
        address currentOwner = TokenOwnerMap[_id];
        TokenOwnerMap[_id] = _newOwner;
       
        _beforeTLDTransfer(currentOwner, _newOwner, _id);
        emit TransferEnsOwnership(currentOwner, _newOwner, _id);
    }

    ///this is for the ENS owners to withdraw primary sales. It's collected by wallet not by ID
    ///so that only 1 withdrawal is required and if a domain is sold then previous sales can still be
    ///claimed by the original owner.
    function withdrawPrimarySalesFunds() external  {        
        require(OwnerFunds[msg.sender] > 0, "no funds to claim");
        
        //we do this like this to prevent re-entrency
        uint256 balance = OwnerFunds[msg.sender];
        OwnerFunds[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit WithdrawFunds(msg.sender, balance);
    }

///contract owner functions

    ///contract owner to set default registration strategy. This will not alter any exsting domains that 
    ///are using the current default strategy only future registered ones. currently the default
    ///registration strategy is quite basic so there is lots of room to be able to improve this in the future
    function updateDefaultRegister(IRegister _registrationStrategy) external onlyOwner {
        DefaultRegister = _registrationStrategy;
    }

    ///contract owner withdraw for any primary sale commission / 
    function contractOwnerWithdrawFunds() external onlyOwner {        
        require(ContractOwnerFunds > 0, "no funds to claim");
        
        //we do this like this to prevent re-entrency
        uint256 balance = ContractOwnerFunds;
        ContractOwnerFunds = 0;
        payable(msg.sender).transfer(balance);
    }

    function setCCIPResolver(ICCIPResolver _ccip) onlyOwner external {
        require(!CCIPResolverLocked, "resolver already locked");
        CCIPResolver = _ccip;
    }

    function setCCIPLocked() onlyOwner external {
        require(!CCIPResolverLocked, "resolver already locked");
        CCIPResolverLocked = true;
    }

    function setMetadataContract(IMetadata _metadata) onlyOwner external {
        MetaData = _metadata;
    }

    function setDepositCost(uint256 _priceInWei) onlyOwner external {
        DepositCost = _priceInWei;
    }

    ///contract owner percentage for primary sales. this cannot be set to higher than 5%
    ///probably set to 2% when the contract is initially deployed
    function setContractOwnerPrimaryRoyalty(uint256 _percent) onlyOwner external {
        require(_percent <= 5, "max 5 percent");
        ContractOwnerPrimaryRoyalties = _percent;
    }

    //set the minimum requirement for a deposited domain to expire. 30 days seems low, default is 90 days
    function setMinDomainExpiryForDeposit(uint256 _minNumberOfDays) onlyOwner external {
        MinDomainExpiry = (_minNumberOfDays * 1 days);
        require(MinDomainExpiry >= 30 days, "must be minimum of 30 days");
    }

    ///underutilised ENS functionality. Naming a contract using the reverse registrar
    function setContractName(string calldata _name) onlyOwner external {
        ReverseResolver.setName(_name);
    }

/// <end> contract owner functions
//
// ------------------------------------

    ///IERC2981 interface method for on-chain royalty. This is so we can charge different royalty %
    ///per ENS domain and also pay out to the contract owner. This standard is only supported by good reputable
    ///ethereum marketplaces
    function royaltyInfo( 
    uint256 _tokenId,
    uint256 _salePrice
        ) external view returns (
            address receiver,
            uint256 royaltyAmount
        ){
            uint256 parentId = IdToOwnerId[_tokenId];
            address owner = TokenOwnerMap[parentId];
            uint256 percent = IdRoyaltyMap[parentId];
            uint256 royalty = _salePrice.div(100).mul(percent);

            return (owner, royalty);
        }

   ///read method to get some information for the UI
    function getTokenInfo(uint256[] calldata _ids) external view returns(EnsInfo[] memory){
        EnsInfo[] memory infos = new EnsInfo[](_ids.length);

        for(uint256 i; i < _ids.length;){
            infos[i] = getInfo(_ids[i]);
            unchecked { ++i; }
        }

        return infos;
    }

    function getInfo(uint256 _id) private view returns(EnsInfo memory){
        EnsInfo memory info;

        info.id = _id;
        info.domain = IdToDomain[_id];
        info.royalty = IdRoyaltyMap[_id];
        info.owner = TokenOwnerMap[_id];
        info.locked = TokenLocked[_id];
        info.price = DefaultMintPrice[_id];
        info.image = IdImageMap[_id];
        info.domainHash = getDomainHash(info.domain);
        info.currentLocation = EnsToken.ownerOf(_id);
        info.expiry = EnsToken.nameExpires(_id);
    
        return info;
    }

        function tldBalanceOf(address _addr) public view returns(uint256){
            return TLDBalances[_addr];
        }

        function totalSupply() public view returns(uint256){
            return currentId;
        }

   modifier tokenOwner(uint256 _id) {
        require(TokenOwnerMap[_id] == msg.sender, "is not owner");
      _;
   }
}