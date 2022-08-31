// SPDX-License-Identifier: MIT

/*
   ___   _  _   _  _    ___    ___          
  |_ _| | \| | | \| |  | __|  | _ \         
   | |  | .` | | .` |  | _|   |   /         
  |___| |_|\_| |_|\_|  |___|  |_|_\         
_|"""""_|"""""_|"""""_|"""""_|"""""|        
"`-0-0-"`-0-0-"`-0-0-"`-0-0-"`-0-0-'        
  _  __   ___    ___    ___    ___    ___   
 | |/ /  |_ _|  |   \  |   \  / _ \  / __|  
 | ' <    | |   | |) | | |) || (_) | \__ \  
 |_|\_\  |___|  |___/  |___/  \___/  |___/  
_|"""""_|"""""_|"""""_|"""""_|"""""_|"""""| 
"`-0-0-"`-0-0-"`-0-0-"`-0-0-"`-0-0-"`-0-0-' 
   ___    _     _   _   ___                 
  / __|  | |   | | | | | _ )                
 | (__   | |__ | |_| | | _ \                
  \___|  |____| \___/  |___/                
_|"""""_|"""""_|"""""_|"""""|               
"`-0-0-"`-0-0-"`-0-0-"`-0-0-'               

NFTs are a unique opportunity to experiment with a new technology, build communities in a brand new way, cultivate creativity, and most importantly - HAVE FUN!

The Inner Kiddos Club is on a mission to help people all over the world rediscover their inner child, explore their curiosity, express their creativity, and actually LIVE again.

These tokens are a symbol of that positive attitude and the key to a community that loves to spread joy and invest in each other. Copyright passes to NFT holder.

Welcome aboard, you’re gonna go far kid(do)!
             
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

// Merkle tree:
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Kiddos is Ownable, ERC721A, PaymentSplitter {

    uint public MAXSUPPLY = 10000;         // Hard-coded in setMaxSupply() also.
    uint public THEMINTPRICE = 0.04 ether; 
    uint public WALLETLIMIT = 50;          
    string public PROVENANCE_HASH;
    string private METADATAURI;
    string private CONTRACTURI;
    bool public PRESALEISLIVE = false;
    bool public SALEISLIVE = false;
    bool private MINTLOCK;
    bool private PROVENANCE_LOCK = false;
    uint public RESERVEDNFTS;
    uint id = totalSupply();
    uint public RANDOMOFFSET;

    // Merkle tree:
    bytes32 public merkleRoot;
    mapping(address => bool) public allowlistClaimed;

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

    // Merkle tree (add bytes32 _merkleRoot)
    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim, bytes32 _merkleRoot)
        ERC721A("INNER KIDDOS CLUB", "IKC")
        PaymentSplitter(distro, distro_shares)
    {
        METADATAURI = "ipfs://QmVPLq3wPzs1K429DLJy8iJuSdRWoVDiTb4TA8JFi7fNGb/"; // prereveal

        accounts[msg.sender] = Account( 0, 0, 0 );

        // Set Team NFTs & Initial Admin Levels:
        accounts[teamclaim[0]] = Account( 50, 0, 1 ); //
        accounts[teamclaim[1]] = Account( 50, 0, 1 ); //
        accounts[teamclaim[2]] = Account( 25, 0, 1 ); //
        accounts[teamclaim[3]] = Account( 25, 0, 1 ); //

        RESERVEDNFTS = 150;  

        _distro = distro;
        _distro_shares = distro_shares;

        // Merkle tree:
        merkleRoot = _merkleRoot;

    }

    // (^_^) Modifiers (^_^) 

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

    // (^_^) Overrides (^_^) 

    // Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

    // (^_^) Setters (^_^) 

    function adminLevelRaise(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin ++; 
    }

    function adminLevelLower(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin --; 
    }

    function provenanceLock() external onlyOwner {
        PROVENANCE_LOCK = true;
    }
    
    function provenanceSet(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
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

    function salePresaleActivate() external minAdmin2 {
        PRESALEISLIVE = true;
    }

    function salePresaleDeactivate() external minAdmin2 {
        PRESALEISLIVE = false;
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
        require(_maxSupply <= 10000, 'Error: New max supply cannot exceed original max.');        
        MAXSUPPLY = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        THEMINTPRICE = _newPrice;
    }

    function setWalletLimit(uint _newLimit) external onlyOwner {
        WALLETLIMIT = _newLimit;
    }

    function setRandomValue(address account, uint lowValue, uint highValue) external onlyOwner returns (uint) {
    	require(RANDOMOFFSET==0, "Error: Random offset has already been set.");
    	require(highValue > lowValue, "Error: Low value has to be lower than High value.");
    	uint mod_operator = highValue + 1 - lowValue;
        uint random_id = lowValue + uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.gaslimit, account)))% mod_operator;
        RANDOMOFFSET = random_id;
        return random_id;
    }    

    
    // (^_^) Getters (^_^)

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

    // -- For the Merkle tree
    function getMerkleRoot() public view returns (bytes32){ 
        return merkleRoot; 
    }

    // -- For the Optional Start Index / Offset
    function getRandomValue() public view returns (uint){
        return RANDOMOFFSET;
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

    // Merkle tree:
    function allowlistMint(bytes32[] calldata _merkleProof, uint _amount) external payable noReentrant {
        require(PRESALEISLIVE, "Error: Allowlist Sale is not active.");
        require(totalSupply() + _amount <= (MAXSUPPLY - RESERVEDNFTS), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= WALLETLIMIT, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");
        require(msg.value >= (THEMINTPRICE * _amount), "Error: Not enough ether sent.");
        require(!allowlistClaimed[msg.sender], "Error: You have already claimed all of your NFTs.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Error: You are not allowlisted.");

        if ( ( _amount + accounts[msg.sender].mintedNFTs ) == WALLETLIMIT ) {
            allowlistClaimed[msg.sender] = true;
        }

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    } 

    function changeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    } 

    // (^_^) THE END. (^_^)
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}