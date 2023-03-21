// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Keisuke OHNO (kei31.eth)

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


pragma solidity >=0.8.17;

import { Base64 } from 'base64-sol/base64.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract NFTContract1155 is RevokableDefaultOperatorFilterer , ERC1155, ERC2981 , Ownable ,AccessControl{
    using Strings for uint256;    

    string public name;
    string public symbol;
    mapping(uint => string) public tokenURIs;
    bytes32 public constant ADMIN = keccak256("ADMIN");


    constructor() ERC1155("") {
        name = "Umuco's ART";
        symbol = "UAT";

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE        , msg.sender);
        grantRole(AIRDROP_ROLE       , msg.sender);
        grantRole(ADMIN              , msg.sender);

        //CAL initialization
        setCALLevel(1);

        setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        //setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy

        addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);//OpenSea
        addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);//Rarible

        //Royalty
        setDefaultRoyalty(0xe72301c175e589eE2F94e77c40A2E37096a771D0 , 1000);
        setWithdrawAddress(0xe72301c175e589eE2F94e77c40A2E37096a771D0);

        setPhaseId(0);
        setUseOnChainMetadataWithImageURI(true);

        setOnChainMetadataWithImageURI(
            0 , 
            "elements" , 
            "elements -Super Pop- Umuco's ART",
            "Super Pop",
            "https://arweave.net/zsAwF4x-0FPhWxCzSTGJxFkkqQ2hPh08E7h0AqQQhEg",
            false,
            " "
        );

        setOnChainMetadataWithImageURI(
            1 , 
            "KATAWARE" , 
            "KATAWARE -Alchemy- Umuco's ART",
            "Alchemy ",
            "https://arweave.net/zfthzuzfYWPQDBQ6vqEmyX87pDwfaFrRv-bMMz7hcDk",
            false,
            " "
        );
        setOnChainMetadataWithImageURI(
            2 , 
            "TSUKIUMI" , 
            "TSUKIUMI -Yaoyorozu- Umuco's ART",
            "Yaoyorozu",
            "https://arweave.net/o_9X8m1MufhR0rXhKXDH4J4I-ergbWFayZQM_VZDpaw",
            false,
            " "
        );

    }


    //
    //withdraw section
    //

    address public withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    bool public paused = true;
    bool public onlyAllowlisted = true;
    bool public mintCount = true;
    uint256 public publicSaleMaxMintAmountPerAddress = 50;
   
    uint256 public phaseId = 1;
    mapping(uint256 => phaseStrct) public phaseData;

    struct phaseStrct {
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 cost;
        uint256 maxMintAmountPerTransaction;
        bytes32 merkleRoot;
        mapping(address => uint256) userMintedAmount;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof , uint256 /*_burnId*/ )  external payable callerIsUser{
        require( !paused, "the contract is paused");
        require( 0 < _mintAmount , "need to mint at least 1 NFT");
        require( _mintAmount <= phaseData[phaseId].maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require( phaseData[phaseId].totalSupply + _mintAmount <= phaseData[phaseId].maxSupply, "max NFT limit exceeded");
        require( phaseData[phaseId].cost * _mintAmount <=  msg.value , "insufficient funds");

        uint256 maxMintAmountPerAddress;
        if(onlyAllowlisted == true) {
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
            require(MerkleProof.verify(_merkleProof, phaseData[phaseId].merkleRoot, leaf), "user is not allowlisted");
            maxMintAmountPerAddress = _maxMintAmount;
        }else{
            maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;//atode kangaeru
        }

        if(mintCount == true){
            require(_mintAmount <= maxMintAmountPerAddress - phaseData[phaseId].userMintedAmount[msg.sender] , "max NFT per address exceeded");
            phaseData[phaseId].userMintedAmount[msg.sender] += _mintAmount;
        }

        phaseData[phaseId].totalSupply += _mintAmount;
        _mint(msg.sender, phaseId , _mintAmount, "");
    }

    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public {
        require(hasRole(AIRDROP_ROLE, msg.sender), "Caller is not a air dropper");
        require(_airdropAddresses.length == _UserMintAmount.length , "Array lengths are different");
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require( 0 < _mintAmount , "need to mint at least 1 NFT" );
        require( phaseData[phaseId].totalSupply + _mintAmount <= phaseData[phaseId].maxSupply, "max NFT limit exceeded");
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            phaseData[phaseId].totalSupply += _UserMintAmount[i];
            _mint(_airdropAddresses[i], phaseId , _UserMintAmount[i] , "" );
        }
    }

    function adminMint(address _address , uint256 _mintAmount ) public onlyRole(ADMIN) {
        phaseData[phaseId].totalSupply += _mintAmount;
        _mint(_address, phaseId , _mintAmount, "");
    }

    function setPhaseData( 
        uint256 _id , 
        uint256 _maxSupply , 
        uint256 _cost , 
        uint256 _maxMintAmountPerTransaction ,
        bytes32 _merkleRoot
    ) external onlyRole(ADMIN) {
        phaseData[_id].maxSupply = _maxSupply;
        phaseData[_id].cost = _cost;
        phaseData[_id].maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
        phaseData[_id].merkleRoot = _merkleRoot;
    }

    function setPhaseId(uint256 _id) public onlyRole(ADMIN) {
        phaseId = _id;
    }

    function setMintCount(bool _state) public onlyRole(ADMIN) {
        mintCount = _state;
    }

    function setPause(bool _state) public onlyRole(ADMIN) {
        paused = _state;
    }

    function setCost(uint256 _newCost) public onlyRole(ADMIN) {
        phaseData[phaseId].cost = _newCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ADMIN) {
        phaseData[phaseId].maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyRole(ADMIN) {
        phaseData[phaseId].maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN) {
        phaseData[phaseId].merkleRoot = _merkleRoot;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyRole(ADMIN) {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setOnlyAllowlisted(bool _state) public onlyRole(ADMIN) {
        onlyAllowlisted = _state;
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
    //URI section
    //

    bool public useOnChainMetadata = false;

    function setUseOnChainMetadata(bool _useOnChainMetadata) public onlyRole(ADMIN) {
        useOnChainMetadata = _useOnChainMetadata;
    }

    mapping (uint256 => string)  public metadataTitle;
    mapping (uint256 => string)  public metadataDescription;
    mapping (uint256 => string)  public metadataAttributes;
    mapping (uint256 => string)  public imageData;

    bool public useOnChainMetadataWithImageURI = false;

    function setUseOnChainMetadataWithImageURI(bool _useOnChainMetadataWithImageURI) public onlyRole(ADMIN) {
        useOnChainMetadataWithImageURI = _useOnChainMetadataWithImageURI;
    }

    mapping (uint256 => string)  public imageURI;
    mapping (uint256 => bool)    public useAnimationURI;
    mapping (uint256 => string)  public animationURI;




    //single image metadata
    function setMetadataTitle(uint256 _id , string memory _metadataTitle) public onlyRole(ADMIN) {
        metadataTitle[_id] = _metadataTitle;
    }
    function setMetadataDescription(uint256 _id , string memory _metadataDescription) public onlyRole(ADMIN) {
        metadataDescription[_id] = _metadataDescription;
    }
    function setMetadataAttributes(uint256 _id , string memory _metadataAttributes) public onlyRole(ADMIN) {
        metadataAttributes[_id] = _metadataAttributes;
    }
    function setImageData(uint256 _id , string memory _imageData) public onlyRole(ADMIN) {
        imageData[_id] = _imageData;
    }


    function setImageURI(uint256 _id , string memory _imageURI) public onlyRole(ADMIN) {
        imageURI[_id] = _imageURI;
    }
    function setUseAnimationURI(uint256 _id , bool _useAnimationURI) public onlyRole(ADMIN) {
        useAnimationURI[_id] = _useAnimationURI;
    }
    function setAnimationURI(uint256 _id , string memory _animationURI) public onlyRole(ADMIN) {
        animationURI[_id] = _animationURI;
    }



    function setOnChainMetadata(
        uint256 _id , 
        string memory _metadataTitle, 
        string memory _metadataDescription,
        string memory _metadataAttributes,
        string memory _imageData
         )public onlyRole(ADMIN){
        setMetadataTitle( _id , _metadataTitle);
        setMetadataDescription( _id , _metadataDescription);
        setMetadataAttributes( _id , _metadataAttributes);
        setImageData( _id , _imageData);
    }

    function setOnChainMetadataWithImageURI(
        uint256 _id , 
        string memory _metadataTitle, 
        string memory _metadataDescription,
        string memory _metadataAttributes,
        string memory _imageURI,
        bool _useAnimationURI,
        string memory _animationURI
         )public onlyRole(ADMIN){
        setMetadataTitle( _id , _metadataTitle);
        setMetadataDescription( _id , _metadataDescription);
        setMetadataAttributes( _id , _metadataAttributes);
        setImageURI( _id , _imageURI);
        setUseAnimationURI( _id , _useAnimationURI);
        setAnimationURI( _id , _animationURI);
    }


    bool public useBaseURI = false;
    string public baseURI;
    string public baseExtension = ".json";

    function setUseBaseURI(bool _useBaseURI) public onlyRole(ADMIN) {
        useBaseURI = _useBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyRole(ADMIN) {
        baseExtension = _newBaseExtension;
    }



    function uri(uint256 _id) public override view returns (string memory) {
        if( useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(_id);
        }
        if( useOnChainMetadata == true ){
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(
                abi.encodePacked(
                    '{'
                        '"name":"' , metadataTitle[_id] ,'",' ,
                        '"description":"' , metadataDescription[_id] ,  '",' ,
                        '"image": "data:image/svg+xml;base64,' , imageData[_id] , '",' ,
                        '"attributes":[{"trait_type":"type","value":"' , metadataAttributes[_id] , '"}]',
                    '}'
                )
            ) ) );
        }
        if(useOnChainMetadataWithImageURI == true){
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(
                abi.encodePacked(
                    '{',
                        '"name":"' , metadataTitle[_id] ,'",' ,
                        '"description":"' , metadataDescription[_id] ,  '",' ,
                        '"image": "' , imageURI[_id] , '",' ,
                        useAnimationURI[_id]==true ? string(abi.encodePacked('"animation_url": "' , animationURI[_id] , '",')) :"" ,
                        '"attributes":[{"trait_type":"type","value":"' , metadataAttributes[_id] , '"}]',
                    '}'
                )
            ) ) );
        }
        if( useBaseURI == true) {
            return string(abi.encodePacked( baseURI, _id.toString(), baseExtension));
        }        
        return tokenURIs[_id];
    }

    function setURI(uint _id, string memory _uri) external onlyRole(ADMIN) {
        tokenURIs[_id] = _uri;
        emit URI(_uri, _id);
    }



    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");

    function externalMint(address _address , uint256 _amount ) external payable onlyRole(MINTER_ROLE){
        phaseData[phaseId].totalSupply += _amount;
        _mint(_address, phaseId, _amount, "");
    }

    function externalMintWithPhaseId(address _address , uint256 _amount , uint256 _phaseId ) external payable onlyRole(MINTER_ROLE){
        phaseData[_phaseId].totalSupply += _amount;
        _mint(_address, _phaseId, _amount, "");
    }



    //
    //1155 owner mint section iranai kamo
    //

    function ownermint(address _to, uint _id, uint _amount) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint _id, uint _amount) external {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }



    //
    //return phase data
    //

    function merkleRoot() external view returns(bytes32) {
        return phaseData[phaseId].merkleRoot;
    }

    function maxSupply() external view returns(uint256){
        return phaseData[phaseId].maxSupply;
    }

    function totalSupply() external view returns(uint256){
        return phaseData[phaseId].totalSupply;
    }

    function maxMintAmountPerTransaction() external view returns(uint256){
        return phaseData[phaseId].maxMintAmountPerTransaction;
    }

    function cost() external view returns(uint256){
        return phaseData[phaseId].cost;
    }

    function getAllowlistUserAmount(address /*_address*/ ) public pure returns(uint256){
        return 0;
    }

    function allowlistType() public pure returns(uint256){
        return 0;
    }    

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return phaseData[phaseId].userMintedAmount[_address];
    }



    //
    //sbt and opensea filter section
    //

    bool public isSBT = false;

    function setIsSBT(bool _state) public onlyRole(ADMIN) {
        isSBT = _state;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        require( isSBT == false || approved == false , "setApprovalForAll is prohibited");
        require(
            _isAllowed(operator) || approved == false,
            "RestrictApprove: Can not approve locked token"
        );
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override{
        require( isSBT == false ||
            from == address(0) || 
            to == address(0)|| 
            to == address(0x000000000000000000000000000000000000dEaD), 
            "transfer is prohibited");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }


    //
    //setDefaultRoyalty
    //
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }




    // ==================================================================
    // Ristrict Approve
    // ==================================================================

    using EnumerableSet for EnumerableSet.AddressSet;

    IContractAllowListProxy public cal;
    EnumerableSet.AddressSet localAllowedAddresses;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;

    function setEnebleRestrict(bool _enableRestrict )public onlyRole(ADMIN){
        enableRestrict = _enableRestrict;
    }


    function addLocalContractAllowList(address transferer)
        public
        onlyRole(ADMIN)
    {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        localAllowedAddresses.remove(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return localAllowedAddresses.values();
    }

    function _isLocalAllowed(address transferer)
        internal
        view
        virtual
        returns (bool)
    {
        return localAllowedAddresses.contains(transferer);
    }

    function _isAllowed(address transferer)
        internal
        view
        virtual
        returns (bool)
    {
        if(enableRestrict == false) {
            return true;
        }

        return
            _isLocalAllowed(transferer) || cal.isAllowed(transferer, calLevel);
    }

    function setCAL(address value) public onlyRole(ADMIN) {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) public onlyRole(ADMIN) {
        calLevel = value;
    }






    //
    //support interface override
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981,ERC1155,AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ;
    }

}