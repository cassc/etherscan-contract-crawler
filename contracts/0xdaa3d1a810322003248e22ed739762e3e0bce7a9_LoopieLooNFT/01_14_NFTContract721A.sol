// SPDX-License-Identifier: MIT

/*
    _                            _             
 \_|_)                 o      \_|_)            
   |     __   __    _      _    |     __   __  
  _|    /  \_/  \_|/ \_|  |/   _|    /  \_/  \_
 (/\___/\__/ \__/ |__/ |_/|__/(/\___/\__/ \__/ 
                 /|                            
                 \|                            

LoopieLooNFTs are 9,663 (phone code for WOOF) dog portraits living their best lives out on the fringes of the Ethereum blockchain. These feral NFTs can't be controlled with any so-called "roadmap," restrained with any "utility," or confined within some boring web2 "website." A Twitter account occasionally reporting their whereabouts is about all they will abide. LoopieLooNFTs are basically a giant pack of badass cattle dogs roamin' the chain, herdin' all the straggler 1/1 varmints they find along the way, just for sport. Each trippy doggo's digital frame adds a touch of class to these wild beasts; they'll stand out as fine, presentable, attractive modern-art additions to degen ETH wallets worldwide. Noble as the pups are, each one of course features not one, not two, but *three* Shakespearean quotes related to dogs. And defiantly setting them apart from anything else in the canine metaverse, each LoopieLooNFT bears a unique name generated from more than 1,000 possible words. (LoopieLooNFTs will reveal after mint out, but you will be able to see your NFT's unique name prior to reveal!) As for rarity, surely some underutilized bot will swing by and sort out the pack hierarchy, as there are definitely some alpha dogs here. And hey, if you mint or acquire one, please howl at the ol "wen moon" by tweeting out your doggo's name, tagging @LoopieLooNFT.

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

contract LoopieLooNFT is Ownable, ERC721A, PaymentSplitter {

    uint public MAXSUPPLY = 9663;  // Hard-coded in setMaxSupply() also.
    uint public THEMINTPRICE = 0.0 ether;
    uint public WALLETLIMIT = 5; 
    string public PROVENANCE_HASH;
    string private METADATAURI;
    string private CONTRACTURI;
    bool public SALEISLIVE = false;
    bool private MINTLOCK;
    uint public RESERVEDNFTS;
    uint id = totalSupply();

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        uint isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim)
        ERC721A("LOOPIE-LOO", "LDOGS")
        PaymentSplitter(distro, distro_shares)
    {
        METADATAURI = "ipfs://QmcFXhZQzr7JJNuF5kEJXXuJ6N8qFpx7tWf5B2qrZhH1TD/"; // prereveal

        accounts[msg.sender] = Account( 0, 0, 0 );

        // Owner keeping some for gifts / prizes / whatver
        accounts[teamclaim[0]] = Account( 200, 0, 2); 
        RESERVEDNFTS = 200;

        _distro = distro;
        _distro_shares = distro_shares;

    }

    // (^_^) Modifierrrrrrs (^_^) 

    modifier minAdmin1() {
        require(accounts[msg.sender].isAdmin > 0 , "Error: Level 1(+) admin clearance required.");
        _;
    }

    modifier minAdmin2() {
        require(accounts[msg.sender].isAdmin > 1, "Error: Level 2(+) admin clearance required.");
        _;
    }

    modifier noReentrant() {
        require(!MINTLOCK, "Error: No re-entrancy.");
        MINTLOCK = true;
        _;
        MINTLOCK = false;
    } 

    // (^_^) Overrrrrrrides (^_^) 

    // Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

    // (^_^) Setterrrrrrs (^_^) 

    function adminLevelRaise(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin ++; 
    }

    function adminLevelLower(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin --; 
    }
    
    function provenanceSet(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }  

    function reservesDecrease(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(RESERVEDNFTS - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        RESERVEDNFTS -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
    }

    function reservesIncrease(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(RESERVEDNFTS + totalSupply() + _increaseReservedBy <= MAXSUPPLY, "Error: This would exceed the max supply.");
        RESERVEDNFTS += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        if ( accounts[_addr].isAdmin == 0 ) { accounts[_addr].isAdmin ++; }
    }

    function salePublicActivate() external minAdmin2 {
        SALEISLIVE = true;
    }

    function salePublicDeactivate() external minAdmin2 {
        SALEISLIVE = false;
    } 

    function setBaseURI(string memory _newURI) external minAdmin2 {
        METADATAURI = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        CONTRACTURI = _newURI;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply <= 9663, 'Error: New max supply cannot exceed original max.');        
        MAXSUPPLY = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        THEMINTPRICE = _newPrice;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        WALLETLIMIT = _newLimit;
    }
    
    // (^_^) Getterrrrrrs (^_^)

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return CONTRACTURI;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return METADATAURI;
    }

    // -- For Convenience
    function getMintPrice() public view returns (uint){ 
        return THEMINTPRICE; 
    }

    // (^_^) Functions (^_^) 

    function airDropNFT(address[] memory _addr) external minAdmin2 {

        require(totalSupply() + _addr.length <= (MAXSUPPLY - RESERVEDNFTS), "Error: You would exceed the airdrop limit.");

        for (uint i = 0; i < _addr.length; i++) {
             _safeMint(_addr[i], 1);
             emit Mint(msg.sender, totalSupply());
        }

    }

    function claimReserved(uint _amount) external minAdmin1 {

        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= MAXSUPPLY, "Error: You would exceed the max supply limit.");

        accounts[msg.sender].nftsReserved -= _amount;
        RESERVEDNFTS -= _amount;

        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
        
    }

    function mint(uint _amount) external payable noReentrant {

        require(SALEISLIVE, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (MAXSUPPLY - RESERVEDNFTS), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= WALLETLIMIT, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");
        require(msg.value >= (THEMINTPRICE * _amount), "Error: Not enough ether sent.");

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    }

    function burn(uint _id) external returns (bool, uint) {

        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);

    }

    function distributeShares() external minAdmin2 {

        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }

    }

    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    

    // (^_^) THE END. (^_^)
    // .--.-. ... .-- .. --. --. .- .--- ..- .. -.-. .

}