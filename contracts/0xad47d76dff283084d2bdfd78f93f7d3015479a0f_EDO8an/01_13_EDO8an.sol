// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract EDO8an is Ownable, ERC721A, DefaultOperatorFilterer, ERC2981 {

    constructor(
    ) ERC721A("EDO8an", "EDO") {

        setBaseURI("https://edo-1.com/data/edo8an/json/");
        _safeMint(msg.sender, 1);
        _setDefaultRoyalty(0x33d1aaBb4D0a8D84f55a196517523D83CFEbB714, 1000);
        setMerkleRoot(0xe3160c2082cc63e3fb887418788dd272c3304993f78e21e0f648f06e9fb0a684);

    }



    //
    //withdraw section
    //

    address public constant WITHDRAW_ADDRESS = 0x33d1aaBb4D0a8D84f55a196517523D83CFEbB714;

    function withdraw() external onlyOwner {    
    require( WITHDRAW_ADDRESS != address(0), "The address shouldn't be 0" );
    (bool os, ) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
    require(os);
    }



    //
    //mint section
    //

    uint256 public cost = 0;
    uint256 public maxSupply = 7000;
    uint256 public maxMintAmountPerTransaction = 20;
    uint256 public publicSaleMaxMintAmountPerAddress = 300;
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
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( _nextTokenId() -1 + _mintAmount <= maxSupply , "max NFT limit exceeded");
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

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setAllowListType(uint256 _type)public onlyOwner{
        require( _type == 0 || _type == 1 , "Allow list type error");
        allowlistType = _type;
    }

    function setAllowlistMapping(uint256 _saleId , address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
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

    function setSaleId(uint256 _saleId) public onlyOwner {
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyOwner() {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyOwner {
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyOwner {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function setMintCount(bool _state) public onlyOwner {
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }



    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) public onlyOwner() {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) public onlyOwner() {
        useInterfaceMetadata = _useInterfaceMetadata;
    }



    //
    //token URI
    //

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        }
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }



    //
    // override section
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
            
    }



    ///////////////////////////////////////////////////////////////////////////
    // Transfer functions
    ///////////////////////////////////////////////////////////////////////////
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    ///////////////////////////////////////////////////////////////////////////
    // Approve functions
    ///////////////////////////////////////////////////////////////////////////
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        payable
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    //Royalty setting
    function setDefaultRoyalty( address receiver, uint96 feeNumerator ) external onlyOwner { _setDefaultRoyalty( receiver, feeNumerator ); }
    function deleteDefaultRoyalty() external onlyOwner { _deleteDefaultRoyalty(); }
    function setTokenRoyalty( uint256 tokenId, address receiver, uint96 feeNumerator ) external onlyOwner { _setTokenRoyalty( tokenId, receiver, feeNumerator ); }
    function resetTokenRoyalty( uint256 tokenId ) external onlyOwner { _resetTokenRoyalty( tokenId ); }
   
}