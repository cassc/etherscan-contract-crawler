// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Gaku-BRSLIFE

pragma solidity >=0.7.0 <0.9.0;

import { Base64 } from 'base64-sol/base64.sol';
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract CNPi_2023VT_SBT is Ownable, ERC721A ,AccessControl {

    constructor(
    ) ERC721A("CNPinfant_2023Valentine_SBT", "CI23VS") {
        
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE       , msg.sender);
        _setupRole(AIRDROP_ROLE      , msg.sender);

        //use single metadata
        // setUseSingleMetadata(true);
        // setMetadataTitle("CNPinfant 2023 SBT");
        // setMetadataDescription("CNPinfant Links : https://lit.link/cnpinfant ");
        // setMetadataAttributes("2023SBT");
        // setImageURI("ipfs://QmbF9GCfi5fsmEC2mNoeCZ64k7Qj9Bpag38yThHPHDgZXc/");

        //use multi metadata
        setUseMultiMetadata(true);
        setInterval(18000);
        setPicChgCnt(2);
        setPicGrpCnt(3);
        setMetadataTitle("CNPinfant 2023 Valentine's Day SBT");
        setMetadataDescription("CNPinfant Links : https://lit.link/cnpinfant ");
        setMetadataAttributes("2023 Valentine's Day SBT");
        metadataTeamName = ["Orochi/Luna", "Narukami/Yama", "Leelee/Mitama"];

    }

    //
    //withdraw section
    //
    address public constant withdrawAddress = 0xB65e9b81Bc515756dD823A94Ad79e34e3c44A20D;
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    //
    //mint section
    //
    uint256 public cost = 3000000000000000;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTransaction = 100;
    uint256 public publicSaleMaxMintAmountPerAddress = 1000;
    bool public paused = true;

    bool public onlyAllowlisted = false;
    bool public mintCount = false;
    bool public burnAndMintMode = false;

    //0 : Merkle Tree
    //1 : Mapping
    uint256 public allowlistType = 0;
    bytes32 public merkleRoot;
    uint256 public saleId = 0;
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;

    // multiImage
    mapping(uint256 => uint256) public picGrpNo;// 画像グループ番号

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
    //mint with merkle tree
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof , uint256 _burnId , uint256[] memory _gpNos , address _giftAddress) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( _nextTokenId() -1 + _mintAmount <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");

        uint256 maxMintAmountPerAddress;
        address sendToAddress;
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

        if(burnAndMintMode == true ){
            require(_mintAmount == 1, "");
            require(msg.sender == ownerOf(_burnId) , "Owner is different");
            _burn(_burnId);
        }

        if(useMultiMetadata == true){
            require(_mintAmount == _gpNos.length, "mint amount and gpNo length is different");
            for (uint256 i = 0; i < _gpNos.length; i++) {
                picGrpNo[i + _nextTokenId()] = _gpNos[i];
            }
        }

        if(_giftAddress == address(0)) {
            sendToAddress = msg.sender;
        } else {
            sendToAddress = _giftAddress;
        }

        _safeMint(sendToAddress, _mintAmount);
    }

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }
    function setBurnAndMintMode(bool _burnAndMintMode) public onlyOwner {
        burnAndMintMode = _burnAndMintMode;
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
    string public baseURI = "ipfs://QmZs8ty46F1RjjeqFxBD4GyCpcma97GT2Ysr8cPdw4j36s/";
    string public baseExtension = ".jpg";
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
    //single metadata
    //
    bool public useSingleMetadata = false;
    string public imageURI;
    string public metadataTitle;
    string public metadataDescription;
    string public metadataAttributes;

    //single image metadata
    function setUseSingleMetadata(bool _useSingleMetadata) public onlyOwner() {
        useSingleMetadata = _useSingleMetadata;
    }
    function setMetadataTitle(string memory _metadataTitle) public onlyOwner {
        metadataTitle = _metadataTitle;
    }
    function setMetadataDescription(string memory _metadataDescription) public onlyOwner {
        metadataDescription = _metadataDescription;
    }
    function setMetadataAttributes(string memory _metadataAttributes) public onlyOwner {
        metadataAttributes = _metadataAttributes;
    }
    function setImageURI(string memory _newImageURI) public onlyOwner {
        imageURI = _newImageURI;
    }

    // 
    //multi image metadata
    // 
    bool public useMultiMetadata = false;
    uint public interval; //画像切り替え間隔
    uint public picChgCnt; //変わる画像数
    uint public picGrpCnt; //画像グループ数
    string[] public metadataTeamName;//Teamプロパティ

    function setUseMultiMetadata(bool _useMultiMetadata) public onlyOwner() {
        useMultiMetadata = _useMultiMetadata;
    }
    function setInterval(uint _interval) public onlyOwner() {
        interval = _interval;
    }
    function setPicChgCnt(uint _picChgCnt) public onlyOwner() {
        picChgCnt = _picChgCnt;
    }
    function setPicGrpCnt(uint _picGrpCnt) public onlyOwner() {
        picGrpCnt = _picGrpCnt;
    }
    function setMetadataTeamName(string[] memory _metadataTeamName) public onlyOwner() {
        metadataTeamName = _metadataTeamName;
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
                    '{'
                        '"name":"' , metadataTitle ,'",' ,
                        '"description":"' , metadataDescription ,  '",' ,
                        '"image": "' , imageURI , '",' ,
                        '"attributes":[{"trait_type":"type","value":"' , metadataAttributes , '"}]',
                    '}'
                )
            ) ) );
        }
        if(useMultiMetadata == true){
            // 時間による画像番号
            uint picNo = uint((block.timestamp / interval) % picChgCnt) + 1;
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(
                    abi.encodePacked(
                        abi.encodePacked(
                            '{' ,
                                '"name":"' , metadataTitle , ' #' , _toString(tokenId), '",' ,
                                '"description":"' , metadataDescription ,  '",' ,
                                '"image": "' , baseURI , _toString(picGrpNo[tokenId] + 1) , '-' , _toString(picNo) , baseExtension , '",') ,
                        abi.encodePacked(
                                '"attributes":[' ,
                                '{"trait_type":"type","value":"' , metadataAttributes , '"},' ,
                                '{"trait_type":"team","value":"' , metadataTeamName[picGrpNo[tokenId]] , '"}]' ,
                            '}')
                    )
                ) ) );
            }

        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //
    //burnin' section
    //
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE  = keccak256("BURNER_ROLE");
    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _nextTokenId() -1 + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }

    function externalBurn(uint256[] memory _burnTokenIds) external {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(msg.sender == ownerOf(tokenId) , "Owner is different");
            _burn(tokenId);
        }        
    }

    //
    //sbt section
    //
    bool public isSBT = true;
    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( isSBT == false || from == address(0) || to == address(0x000000000000000000000000000000000000dEaD), "transfer is prohibited");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( isSBT == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require( isSBT == false , "approve is prohibited");
        super.approve(to, tokenId);
    }

    //
    // override section
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

}