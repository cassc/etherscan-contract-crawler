// SPDX-License-Identifier: MIT

/*
   _  __             _      __                ____         ___  _______     __
  / |/ /__ _    __  | | /| / /__ __  _____   / __/_ ______/ _/ / ___/ /_ __/ / 
 /    / -_) |/|/ /  | |/ |/ / _ `/ |/ / -_) _\ \/ // / __/ _/ / /__/ / // / _ \
/_/|_/\__/|__,__/   |__/|__/\_,_/|___/\__/ /___/\_,_/_/ /_/   \___/_/\_,_/_.__/  

*/

pragma solidity 0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NewWaveSurfClub is Ownable, ERC721A {
    using Strings for uint256;

    uint public maxSupply = 300;
    uint public mintPrice = 0.04 ether;
    uint public walletLimit = 2;
    string public PROVENANCE_HASH;
    string private _metadataURI;
    string private _contractURI;
    string private prerevealURI;
    bool public _revealed = false;
    bool public _isSaleLive = false;
    bool public _isPreSaleLive = false;
    bool private locked;
    bool private PROVENANCE_LOCK = false;
    uint public _reserved;
    uint id = totalSupply();

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        bool isAdmin;
        bool isWhitelist;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(address[] memory teamclaim)
        ERC721A("New Wave Surf Club", "NWSC")
    {
        prerevealURI = "ipfs://QmVgGCpPaTT1qMSmATc7YoWwV1R2S6X1eqUxNoXf7X6yxo";

        accounts[msg.sender] = Account( 0, 0, true, false);

        // ReservedNFTs (30 total)
        accounts[teamclaim[0]] = Account( 30, 0, true, false); // 
        
       // New Wave Surf Club reserves 30 surfers at the initial mint for the team and treasury. Any increase to the RESERVED AMOUNTS beyond that is a function of minting surfers for sale and distribution in line with our Season approach.
        _reserved = 30;
    }

    // Modifiers

    modifier onlyAdmin() {
        require(accounts[msg.sender].isAdmin == true, 'Error: You must be an admin.');
        _;
    }

    modifier noReentrant() {
        require(!locked, 'Error: No re-entrancy.');
        locked = true;
        _;
        locked = false;
    }

    // Overrides

    // Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'Error: URI query for nonexistent token');

        if(_revealed == false){
            return prerevealURI;
        }

        return bytes(_metadataURI).length > 0 ? string(abi.encodePacked(_metadataURI, tokenId.toString(), ".json")) : "";
    }

    // Setters

    function setAdmin(address _addr) external onlyOwner {
        accounts[_addr].isAdmin = !accounts[_addr].isAdmin;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }

    function lockProvenance() external onlyOwner {
        PROVENANCE_LOCK = true;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        _metadataURI = _newURI;
    }

    function setPrerevealURI(string memory _prerevealURI) public onlyOwner {
       prerevealURI = _prerevealURI;
  }

    function reveal() external onlyOwner {
        _revealed = true;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    function activatePreSale() external onlyOwner {
        _isPreSaleLive = true;
    }

    function deactivatePreSale() external onlyOwner {
        _isPreSaleLive = false;
    }

    function activateSale() external onlyOwner {
        _isSaleLive = true;
        _isPreSaleLive = false;
    }

    function deactivateSale() external onlyOwner {
        _isSaleLive = false;
    }

    function setWhitelist(address[] memory _addr) external onlyOwner {
        for(uint i = 0; i < _addr.length; i++) {
            accounts[_addr[i]].isWhitelist = true;
        }
    }

    function removeWhitelist(address _addr) external onlyOwner {
        accounts[_addr].isWhitelist = false;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {        
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        walletLimit = _newLimit;
    }

    // New Wave Surf Club reserves 30 surfers at the initial mint for the team and treasury. Any increase to the RESERVED AMOUNTS beyond that is a function of minting surfers for sale and distribution in line with our Season approach.
    function increaseReserved(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(_reserved + totalSupply() + _increaseReservedBy <= maxSupply, 'Error: This would exceed the max supply.');
        _reserved += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        accounts[_addr].isAdmin = true;
    }

    function decreaseReserved(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(_reserved - _decreaseReservedBy >= 0, 'Error: This would make reserved less than 0.');
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, 'Error: User does not have this many reserved NFTs.');
        _reserved -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
        accounts[_addr].isAdmin = true;
    }
    
    // Getters

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _metadataURI;
    }

    // Functions

    function claimReserved(uint _amount) external onlyAdmin {

        require(_amount > 0, 'Error: Need to have reserved supply.');
        require(accounts[msg.sender].isAdmin == true,'Error: Only an admin can claim.');
        require(accounts[msg.sender].nftsReserved >= _amount, 'Error: You are trying to claim more NFTs than you have reserved.');
        require(totalSupply() + _amount <= maxSupply, 'Error: You would exceed the max supply.');

        accounts[msg.sender].nftsReserved -= _amount;
        _reserved -= _amount;

        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
        
    }

    function airDropNFT(address[] memory _addr) external onlyOwner {

        require(totalSupply() + _addr.length <= (maxSupply - _reserved), 'Error: You would exceed the airdrop limit.');

        for (uint i = 0; i < _addr.length; i++) {
             _safeMint(_addr[i], 1);
             emit Mint(msg.sender, totalSupply());
        }

    }

    function mint(uint _amount) external payable noReentrant {
        require(_isPreSaleLive || _isSaleLive, 'Error: No Sale is active.');
        require(msg.value >= (mintPrice * _amount), 'Error: Not enough ether sent.');
        require(totalSupply() + _amount <= (maxSupply - _reserved), 'Error: Purchase would exceed max supply.');
        require(!isContract(msg.sender), 'Error: Contracts cannot mint.');

        if (_isPreSaleLive) {
            require(accounts[msg.sender].isWhitelist, 'Error: You need to be on Whitelist to mint during Presale.');
            require((_amount) <= 2, 'Error: Presale max mint per transaction exceeded.');
            require((_amount + accounts[msg.sender].mintedNFTs) <= walletLimit, 'Error: You would exceed Presale wallet limit');       
        } else if (_isSaleLive) {
            require((_amount) <= 2, 'Error: Public sale max mint per transaction exceeded.');
        }

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, 'Error: No ETH balance to withdraw');
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

    // CONTRACT CREATION by @tootie_eth //