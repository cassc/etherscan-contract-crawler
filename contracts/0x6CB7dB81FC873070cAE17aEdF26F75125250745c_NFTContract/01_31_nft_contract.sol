// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import { Base64 } from 'base64-sol/base64.sol';
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface iNFT {
    function externalMintWithNumber(address _address , uint256 _Number ) external payable ;
    function getMintedAmountByNumber(uint256 _number) external view returns (uint256);
    function baseURI() external view returns(string memory);
    function baseExtension() external view returns(string memory);
}

contract NFTContract is RevokableDefaultOperatorFilterer, ERC2981 ,Ownable, ERC721RestrictApprove ,AccessControl,ReentrancyGuard {

    constructor(
    ) ERC721Psi("HAYABUSA ART GALLERY MINT PASS", "HAGMP") {
        
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE       , msg.sender);
        grantRole(AIRDROP_ROLE      , msg.sender);
        grantRole(ADMIN             , msg.sender);

        setUseSingleMetadata(true);
        setMetadataTitle("HAYABUSA ART GALLERY MINT PASS");
        setMetadataDescription("When you burn this NFT, you can mint Hayabusa Art Gallery. Once the mint expires, this NFT will no longer be transferable.");
        setMetadataAttributes("Mint Pass");
        setImageURI("https://data.hayabusa-nft.com/hayabusa-art-gallery/mintpass/1st-season.png");

        //CAL initialization
        setCALLevel(1);

        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        //_setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy

        _addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);//OpenSea
        _addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);//Rarible

        //initial mint
        _safeMint(msg.sender, 1);
        
        //Royalty
        setDefaultRoyalty(0xe34bcC6A93aADF05826052b1da95D52B68A2aDfd , 1000);
        setWithdrawAddress(0xe34bcC6A93aADF05826052b1da95D52B68A2aDfd);

        setMerkleRoot(0x448cb15b0f1a9285f09667a576d617bfe7a5943e40ca7d7928afed058f5ce77b);

    }




    //
    //hayabusa parmeter and function
    //

    iNFT hayabusaNFT;
    uint256 public externalMintCost = 10000000000000000;
    bool public externalMintPaused = true;
    uint256 public minNumber = 1;
    uint256 public maxNumber = 20;
    uint256 public maxMintAmountPerPicture = 1000;

    function setNFT(address _address) public onlyRole(ADMIN) {
        hayabusaNFT = iNFT(_address);
    }

    function externalMintWithNumber(uint256 _nftNumber , uint256 _mintPassTokenId ) public payable callerIsUser{
        require(!externalMintPaused, "the contract is paused");
        require( minNumber <= _nftNumber , "invalid mint number" );
        require( _nftNumber <= maxNumber , "invalid mint number" );
        require( externalMintCost <= msg.value, "insufficient funds");
        require( msg.sender == ownerOf(_mintPassTokenId) , "You don't have a Mint Pass");
        require( hayabusaNFT.getMintedAmountByNumber(_nftNumber) + 1 <= maxMintAmountPerPicture , "Picture is sold out");
        _burn(_mintPassTokenId);
        hayabusaNFT.externalMintWithNumber( msg.sender , _nftNumber );
    }

    function setMinNumber(uint256 _minNumber) public onlyRole(ADMIN) {
        minNumber = _minNumber;
    }

    function setMaxNumber(uint256 _maxNumber) public onlyRole(ADMIN) {
        maxNumber = _maxNumber;
    }

    function setMaxMintAmountPerPicture(uint256 _maxMintAmountPerPicture) public onlyRole(ADMIN) {
        maxMintAmountPerPicture = _maxMintAmountPerPicture;
    }

    function setExternalMintCost(uint256 _externalMintCost) public onlyRole(ADMIN) {
        externalMintCost = _externalMintCost;
    }
    
    function setExternalMintPaused(bool _state) public onlyRole(ADMIN) {
        externalMintPaused = _state;
    }
    function getMintedAmountByNumber(uint256 _number) public view returns(uint256){
        return hayabusaNFT.getMintedAmountByNumber(_number);
    }
    function getArtBaseExtention() public view returns(string memory){
        return hayabusaNFT.baseExtension();
    }
    function getArtBaseURI() public view returns(string memory){
        return hayabusaNFT.baseURI();
    }



    //
    //withdraw section
    //

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    //
    //mint section
    //

    uint256 public cost = 0;
    uint256 public maxSupply = 1000 -1;
    uint256 public maxMintAmountPerTransaction = 200;
    uint256 public publicSaleMaxMintAmountPerAddress = 50;
    bool public paused = true;

    bool public onlyAllowlisted = true;
    bool public mintCount = true;

    //0 : Merkle Tree
    //1 : Mapping
    uint256 public allowlistType = 0;
    bytes32 public merkleRoot;
    uint256 public saleId = 0;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
    //mint with merkle tree
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof , uint256 /*_burnId*/ ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( (_nextTokenId() -1) + _mintAmount <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        uint256 maxMintAmountPerAddress;
        if(onlyAllowlisted == true) {
            if(allowlistType == 0){
                //Merkle tree
                bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
                require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
                maxMintAmountPerAddress = _maxMintAmount;
            }else if(allowlistType == 1){
                //Mapping
                require( allowlistUserAmount[saleId][msg.sender] != 0 , "user is not allowlisted");
                maxMintAmountPerAddress = allowlistUserAmount[saleId][msg.sender];
            }
        }else{
            maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;
        }

        if(mintCount == true){
            require(_mintAmount <= maxMintAmountPerAddress - userMintedAmount[saleId][msg.sender] , "max NFT per address exceeded");
            userMintedAmount[saleId][msg.sender] += _mintAmount;
        }


        _safeMint(msg.sender, _mintAmount);
    }

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
        require(_airdropAddresses.length == _UserMintAmount.length , "Array lengths are different");
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require( (_nextTokenId() -1) + _mintAmount <= maxSupply , "max NFT limit exceeded");        
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function currentTokenId() public view returns(uint256){
        return _nextTokenId() -1;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN) {
        merkleRoot = _merkleRoot;
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setAllowListType(uint256 _type)public onlyRole(ADMIN){
        require( _type == 0 || _type == 1 , "Allow list type error");
        allowlistType = _type;
    }

    function setAllowlistMapping(uint256 _saleId , address[] memory addresses, uint256[] memory saleSupplies) public onlyRole(ADMIN) {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlistUserAmount[_saleId][addresses[i]] = saleSupplies[i];
        }
    }

    function getAllowlistUserAmount(address _address ) public view returns(uint256){
        return allowlistUserAmount[saleId][_address];
    }

    function getUserMintedAmountBySaleId(uint256 _saleId , address _address ) public view returns(uint256){
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return userMintedAmount[saleId][_address];
    }

    function setSaleId(uint256 _saleId) public onlyRole(ADMIN) {
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN) {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyRole(ADMIN) {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyRole(ADMIN) {
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyRole(ADMIN) {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function setMintCount(bool _state) public onlyRole(ADMIN) {
        mintCount = _state;
    }
 


    //
    //URI section
    //

    string public baseURI;
    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyRole(ADMIN) {
        baseExtension = _newBaseExtension;
    }



    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) public onlyRole(ADMIN) {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) public onlyRole(ADMIN) {
        useInterfaceMetadata = _useInterfaceMetadata;
    }



    //
    //single metadata
    //

    bool public useSingleMetadata = false;
    string public imageURI;
    string public metadataTitle;
    string public metadataDescription;
    string public metadataAttributes;
    bool public useAnimationUrl = false;
    string public animationURI;

    //single image metadata
    function setUseSingleMetadata(bool _useSingleMetadata) public onlyRole(ADMIN) {
        useSingleMetadata = _useSingleMetadata;
    }
    function setMetadataTitle(string memory _metadataTitle) public onlyRole(ADMIN) {
        metadataTitle = _metadataTitle;
    }
    function setMetadataDescription(string memory _metadataDescription) public onlyRole(ADMIN) {
        metadataDescription = _metadataDescription;
    }
    function setMetadataAttributes(string memory _metadataAttributes) public onlyRole(ADMIN) {
        metadataAttributes = _metadataAttributes;
    }
    function setImageURI(string memory _ImageURI) public onlyRole(ADMIN) {
        imageURI = _ImageURI;
    }
    function setUseAnimationUrl(bool _useAnimationUrl) public onlyRole(ADMIN) {
        useAnimationUrl = _useAnimationUrl;
    }
    function setAnimationURI(string memory _animationURI) public onlyRole(ADMIN) {
        animationURI = _animationURI;
    }



    //
    //token URI
    //

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }
        if(useSingleMetadata == true){
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(
                abi.encodePacked(
                    '{',
                        '"name":"' , metadataTitle ,'",' ,
                        '"description":"' , metadataDescription ,  '",' ,
                        '"image": "' , imageURI , '",' ,
                        useAnimationUrl==true ? string(abi.encodePacked('"animation_url": "' , animationURI , '",')) :"" ,
                        '"attributes":[{"trait_type":"type","value":"' , metadataAttributes , '"}]',
                    '}'
                )
            ) ) );
        }
        return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), baseExtension));
    }




    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");

    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( (_nextTokenId() -1) + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }


    //
    //sbt and opensea filter section
    //

    bool public isSBT = false;

    function setIsSBT(bool _state) public onlyRole(ADMIN) {
        isSBT = _state;
    }

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( isSBT == false || from == address(0) || to == address(0)|| to == address(0x000000000000000000000000000000000000dEaD), "transfer is prohibited");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator){
        require( isSBT == false || approved == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override onlyAllowedOperatorApproval(operator){
        require( isSBT == false , "approve is prohibited");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }




    //
    //ERC721PsiAddressData section
    //

    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(_owner != address(0), "ERC721Psi: balance query for the zero address");
        return uint256(_addressData[_owner].balance);   
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        require(quantity < 2 ** 64);
        uint64 _quantity = uint64(quantity);

        if(from != address(0)){
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if(to != address(0)){
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }




    //
    //ERC721AntiScam section
    //

    bytes32 public constant ADMIN = keccak256("ADMIN");

    function setEnebleRestrict(bool _enableRestrict )public onlyRole(ADMIN){
        enableRestrict = _enableRestrict;
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function addLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        override
        view
        returns(address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) public override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }




    //
    //setDefaultRoyalty
    //
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }



    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981,ERC721RestrictApprove, AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId);
    }


    

}