// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

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

pragma solidity >=0.7.0 <0.9.0;

import { Base64 } from 'base64-sol/base64.sol';
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract MahjongHayabusaClubYakuman is Ownable, ERC721AntiScam ,AccessControl {

    constructor(
    ) ERC721A("Mahjong Hayabusa Club Yakuman", "MHCY") {
        
        //Role initialization
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE       , msg.sender);
        _setupRole(AIRDROP_ROLE      , msg.sender);
        _setupRole(ADMIN             , msg.sender);


        //URI initialization
        setBaseURI("https://data.hayabusa-nft.com/hmcy/metadata/");


        //CAL initialization
        //setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
        //setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy
        setCAL(0x0000000000000000000000000000000000000000);//no use
        setCALLevel(1);
        setEnebleRestrict(false);

        //first airdrop
        _safeMint(0x24417F9C016cBe08e5045BF1C048f9ef98D4164e, 30);

    }


    //
    //withdraw section
    //

    address public constant withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    uint256 public cost = 0;
    uint256 public maxSupply = 680;
    uint256 public maxMintAmountPerTransaction = 14;
    uint256 public publicSaleMaxMintAmountPerAddress = 300;
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bool public mintCount = true;
    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public publicSaleMintedAmount;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }
 
 /*
    //mint with merkle tree
    bytes32 public merkleRoot;
    function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        if(onlyWhitelisted == true) {
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
            if(mintCount == true){
                require(_mintAmount <= _maxMintAmount - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }else{
            if(mintCount == true){
                require(_mintAmount <= publicSaleMaxMintAmountPerAddress - publicSaleMintedAmount[msg.sender] , "max NFT per address exceeded");
                publicSaleMintedAmount[msg.sender] += _mintAmount;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
*/


    //mint with mapping
    mapping(address => uint256) public whitelistUserAmount;
    function mint(uint256 _mintAmount ) public payable callerIsUser{
        require(!paused, "the contract is paused");
        require(0 < _mintAmount, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        if(onlyWhitelisted == true) {
            require( whitelistUserAmount[msg.sender] != 0 , "user is not whitelisted");
            if(mintCount == true){
                require(_mintAmount <= whitelistUserAmount[msg.sender] - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
                whitelistMintedAmount[msg.sender] += _mintAmount;
            }
        }else{
            if(mintCount == true){
                require(_mintAmount <= publicSaleMaxMintAmountPerAddress - publicSaleMintedAmount[msg.sender] , "max NFT per address exceeded");
                publicSaleMintedAmount[msg.sender] += _mintAmount;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistUserAmount[addresses[i]] = saleSupplies[i];
        }
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


    function setMaxSupply(uint256 _maxSupply) public onlyOwner() {
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyOwner() {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyOwner {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }
  
    function pause(bool _state) public onlyOwner {
        paused = _state;
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
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }



    //
    //burnin' section
    //

    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");    
    function externalMint(address _address , uint256 _amount ) external payable {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require( _nextTokenId() -1 + _amount <= maxSupply , "max NFT limit exceeded");
        _safeMint( _address, _amount );
    }




    //
    //viewer section
    //

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }



    //
    //sbt section
    //

    bool public isSBT = false;

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
    //ERC721AntiScam section
    //

    bytes32 public constant ADMIN = keccak256("ADMIN");

    function setEnebleRestrict(bool _enableRestrict )public onlyRole(ADMIN){
        enableRestrict = _enableRestrict;
    }

    /*///////////////////////////////////////////////////////////////
                        OVERRIDES ERC721Lockable
    //////////////////////////////////////////////////////////////*/
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)
        public
        override
    {
        //for (uint256 i = 0; i < tokenIds.length; i++) {
        //    require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        //}
        //_setTokenLock(tokenIds, lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus)
        public
        override
    {
        //require(to == msg.sender, "not yourself.");
        //_setWalletLock(to, lockStatus);
    }

    function setContractLock(LockStatus lockStatus)
        public
        override
        onlyOwner
    {
        _setContractLock(lockStatus);
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721RestrictApprove
    //////////////////////////////////////////////////////////////*/
    function addLocalContractAllowList(address transferer)
        public
        override
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        public
        override
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function setCALLevel(uint256 level) public override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) public override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES ERC721AntiScam
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AntiScam, AccessControl)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId);
    }





}