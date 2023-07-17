// SPDX-License-Identifier: MIT
// ndgtlft etm.

pragma solidity ^0.8.17;

import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract MyCoolHEROES is ERC721PsiBurnable, ERC2981, Ownable, AccessControl, ReentrancyGuard, DefaultOperatorFilterer{
    constructor() ERC721Psi("My Cool HEROES", "MCH"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(withdrawAddress, 1000); //royalty param setting（1000/10000 = 10%）
    }

    //param
    bytes32 public constant ENGINEER = keccak256("ENGINEER");
    bytes32 public constant EXTERNAL = keccak256("EXTERNAL");
    bytes32 public merkleRoot;
    address public withdrawAddress = 0xB951eD229FDa8c997dE975e6BfE1Fd83d9DAd288;
    
    uint256 public maxSupply = 1160;
    uint256 public cost = 2000000000000000; //0.002 ether
    uint256 public maxMintAmountPerTx = 10;
    uint256 public publicSaleMaxMintAmountPerAddress = 10;
    uint256 public saleId = 0;   
    
    string public baseURI = "https://mchjson.ndgtlft.net/";
    string public baseExtension = ".json";
    
    bool public paused = true;
    bool public burnMintPaused = true;
    bool public onlyAllowlisted = true;        
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;

    //mint
    function mint(uint256 _mintAmount, uint256 _maxMintAmount, bytes32[] calldata _merkleProof, uint256 _burnId) public payable nonReentrant{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTx, "max mint amount per session exceeded");
        require(totalSupply() + _mintAmount <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "cost is insufficient");
        require(tx.origin == msg.sender, "not externally owned account");

        uint256 maxMintAmountPerAddress;
        if(onlyAllowlisted) {
            bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not allowlisted");
            maxMintAmountPerAddress = _maxMintAmount;
        }else{
            maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;
        }
        require(_mintAmount <= maxMintAmountPerAddress - userMintedAmount[saleId][msg.sender] , "max NFT per address exceeded");
        userMintedAmount[saleId][msg.sender] += _mintAmount;
        if(!burnMintPaused){
            require(_mintAmount == 1, "mint amount is only 1 please");
            require(msg.sender == ownerOf(_burnId) , "Owner is different");
            _burn(_burnId);
        }
        _safeMint(msg.sender, _mintAmount);
    }

    //onlyOwner
    function withdraw() public payable onlyOwner{
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setWithdrawAddress(address _newAddress) public onlyOwner{
        withdrawAddress = _newAddress;
    }

    function setRoyalty(uint96 _newRoyalty) external onlyOwner{
        _setDefaultRoyalty(withdrawAddress, _newRoyalty);
        }

    //onlyENGINEER
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyRole(ENGINEER){
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

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ENGINEER){
        merkleRoot = _merkleRoot;
    }

    function setPaused(bool _state) public onlyRole(ENGINEER){
        paused = _state;
    }

    function setSaleId(uint256 _saleId) public onlyRole(ENGINEER){
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyRole(ENGINEER){
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyRole(ENGINEER){
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyRole(ENGINEER){
        cost = _newCost;
    }

    function setOnlyAllowlisted(bool _state) public onlyRole(ENGINEER){
        onlyAllowlisted = _state;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyRole(ENGINEER){
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(ENGINEER){
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyRole(ENGINEER){
        baseExtension = _newBaseExtension;
    }

    function setBurnMintPaused(bool _burnMintPaused) public onlyRole(ENGINEER){
        burnMintPaused = _burnMintPaused;
    }

    //view
    function getUserMintedAmountBySaleId(uint256 _saleId , address _address ) public view returns(uint256){
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return userMintedAmount[saleId][_address];
    }

    //onlyExternal
    function externalMint(address _to, uint256 _mintAmount) external onlyRole(EXTERNAL){
        _safeMint(_to, _mintAmount);
    }

    function externalBurn(uint256 _burnId) external onlyRole(EXTERNAL){
        _burn(_burnId);
    }

    //override
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory){
        return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns(string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721Psi, ERC2981) returns(bool){
        return AccessControl.supportsInterface(interfaceId) || ERC721Psi.supportsInterface(interfaceId);
    }

    //operator filter override
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator){
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator){
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ERC721PsiAddressData block
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

    // @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view virtual override returns (uint){
        require(owner != address(0), "ERC721Psi: balance query for the zero address");
        return uint256(_addressData[owner].balance);   
    }

    // @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes minting.
    // startTokenId - the first token id to be transferred
    // quantity - the amount to be transferred
    // Calling conditions:
    // - when `from` and `to` are both non-zero.
    // - `from` and `to` are never both zero.
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override virtual{
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
}