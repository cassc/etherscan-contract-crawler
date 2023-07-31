//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
* Mint Phases:
* Phase1: OG and WL1
* Phase2: WL2
* Phase3: Public
*
* Minters:
* OG; 0.015
* WL1; 0.016
* WL2; 0.019
* Public; 0.022
* 
* Team Mint - Mint for team only
* Multi-Airdrop
*/
contract FailGuys is ERC721A, Ownable, Pausable, ReentrancyGuard, DefaultOperatorFilterer {

    uint256 public maxSupply = 6666;
    mapping(uint8 => uint8) public maxMintPerWallet;

    //minter types configuration
    struct MintersInfo {
        uint8 maxMintPerTransaction;
        uint256 mintCost;
        bytes32 root; //Merkle root
    }

    mapping(string => MintersInfo) minters; //map of minter types

    enum Phases { N, Phase1, Phase2, Public } //mint phases, N = mint not live

    Phases public currentPhase;

    mapping(address => uint256) minted; 
    
    mapping(uint8 => mapping(address => uint8)) public mintedPerPhase;
    mapping(address => uint256) totalCostOfMinted; //total eth spent of minters

    address[] public teamAddresses; //array of addresses that the tean uses
    address[] public mintersAddresses; //addresses of minters

    mapping(address => uint256) public mintCostPerAddress;
    
    
    string private baseURI;
    bool isRevealed;

    //events
    event Minted(address indexed to, uint8 numberOfTokens, uint256 amount);
    event TeamMinted(address indexed to, uint8 numberOfTokens);
    event Airdropped(address indexed to, uint8 numberOfTokens);
    event PhaseChanged(address indexed to, uint256 indexed eventId, uint8 indexed phaseId);
    event WithdrawalSuccessful(address indexed to, uint256 amount);
    event CollectionRevealed(address indexed to);
    event MintDetailsChanged(address indexed to, string description);

    //errors
    error WithdrawalFailed();

    constructor() ERC721A("Fail Guys NFT", "FGNFT") {
        _pause();
        currentPhase = Phases.N;

        maxMintPerWallet[uint8(Phases.Phase1)] = 3;
        maxMintPerWallet[uint8(Phases.Phase2)] = 3;
        maxMintPerWallet[uint8(Phases.Public)] = 5;

        addMintersInfo("OG", 3, 0.015 ether, 0xbe2582dccf06784e51457010e0a666478ae48d6a41f60854a0d8e3028d616e5e);
        addMintersInfo("WL1", 3, 0.016 ether, 0xbe2582dccf06784e51457010e0a666478ae48d6a41f60854a0d8e3028d616e5e);
        addMintersInfo("WL2", 3, 0.019 ether, 0xbe2582dccf06784e51457010e0a666478ae48d6a41f60854a0d8e3028d616e5e);
        addMintersInfo("PUBLIC", 5, 0.022 ether, 0xbe2582dccf06784e51457010e0a666478ae48d6a41f60854a0d8e3028d616e5e);
        
        teamAddresses.push(0xbf44A37fb76AD878834590f0de5D1840B8f75c4d); //Add team wallet here

        baseURI = "ipfs://bafkreiakjrn5dtlli3kyefldp54w6p4ans4x3drs3257xo4pmfuweyut64"; //IPFS address of prereveal artwork
    }
 
    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Modifiers
    * ******** ******** ******** ******** ******** ******** ********
    */

    /*
    * @dev onlyTeam modifier - checks if the address that is sending the transaction belongs to Team
    */

    modifier onlyTeam() {
        bool _isTeamMember = false;
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            if (teamAddresses[i] == msg.sender) {
                _isTeamMember = true;
                break;
            }
        }
        require(_isTeamMember, "ERROR: Only team members are allowed to interact with this function.");
        _;
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public - onlyOwner (dev) functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    /*
    * @dev onlyOwner modifier - checks if the address that is sending the transaction is the Owner
    */
    
    function phase1Mint(uint8 numberOfTokens, bytes32[] calldata proof) external payable nonReentrant whenNotPaused {

        require(currentPhase == Phases.Phase1, "ERROR: Phase 1 mint is not yet active.");
       
        bool _isAddressAllowed = true;
        uint256 _totalCost;

        //verify whitelist
        MintersInfo memory _activeMinter;

        if (_isWhitelisted(msg.sender, proof, minters["OG"].root)) {
            //check if address is OG
            _activeMinter = minters["OG"];
        } else if (_isWhitelisted(msg.sender, proof, minters["WL1"].root)) {
            //check if address is WL1
            _activeMinter = minters["WL1"];
        } else {
            _isAddressAllowed = false;
        }
        require(_isAddressAllowed, "ERROR: You are not allowed to mint on this phase.");
        require(numberOfTokens <= _activeMinter.maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        
        
        _totalCost = _activeMinter.mintCost * numberOfTokens;
        _phaseMint(numberOfTokens, _totalCost);
    }

    function phase2Mint(uint8 numberOfTokens, bytes32[] calldata proof) external payable nonReentrant whenNotPaused {

        require(currentPhase == Phases.Phase2, "ERROR: Phase 2 mint is not yet active.");
        require(numberOfTokens <= minters["WL2"].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");

        bool _isAddressAllowed = true;
        uint256 _totalCost;

        //verify whitelist
        MintersInfo memory _activeMinter;

        if (_isWhitelisted(msg.sender, proof, minters["WL2"].root)) {
            //check if address is WL2
            _activeMinter = minters["WL2"];
        } else {
            _isAddressAllowed = false;
        }

        require(_isAddressAllowed, "ERROR: You are not allowed to mint on this phase.");
         
        _totalCost = _activeMinter.mintCost * numberOfTokens;
        _phaseMint(numberOfTokens, _totalCost);   
    }

    function publicMint(uint8 numberOfTokens) external payable nonReentrant whenNotPaused {
        require(currentPhase == Phases.Public, "ERROR: Public mint is not yet active.");
        require(numberOfTokens <= minters["PUBLIC"].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        uint256 _totalCost;
        
        _totalCost = minters["PUBLIC"].mintCost * numberOfTokens;
        _phaseMint(numberOfTokens, _totalCost);   
    }

    function setMintPhase(uint8 _phase) public onlyOwner {
        currentPhase = Phases(_phase);
        emit PhaseChanged(msg.sender, block.timestamp, uint8(currentPhase));
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerPhase(uint8 _mintPhaseId, uint8 _maxMintPerWallet) public onlyOwner {
        maxMintPerWallet[_mintPhaseId] = _maxMintPerWallet;
    }

    //Function to add MintersInfo to minters
    function addMintersInfo(
        string memory _minterName,
        uint8 _maxMintPerTransaction,
        uint256 _mintCost,
        bytes32 _root
    ) public onlyOwner {
        MintersInfo memory newMintersInfo = MintersInfo(
            _maxMintPerTransaction,
            _mintCost,
            _root
        );
        minters[_minterName] = newMintersInfo;
    }

    //Function to modify MintersInfo of an item in minters
    function modifyMintersInfo(
        string memory _minterName,
        uint8 _newMaxMintPerTransaction,
        uint256 _newMintCost,
        bytes32 _newRoot
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        MintersInfo memory updatedMintersInfo = MintersInfo(
            _newMaxMintPerTransaction,
            _newMintCost,
            _newRoot
        );

        minters[_minterName] = updatedMintersInfo;
    }

    function modifyMintersMintCost(
        string memory _minterName,
        uint256 _newMintCost
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].mintCost = _newMintCost;
    }

    function modifyMintersMaxMintPerTransaction(
        string memory _minterName,
        uint8 _newMaxMintPerTransaction
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].maxMintPerTransaction = _newMaxMintPerTransaction;
    }
/*
    //Function to remove a MintersInfo in minters
    function removeMintersInfo(string memory _minterName) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        delete minters[_minterName];
    }*/

    //Function to get the MintersInfo for a specific minter
    function getMintersInfo(string memory _minterName) public view returns (uint8, uint256) {
        return (minters[_minterName].maxMintPerTransaction, minters[_minterName].mintCost);
    }

    //Function to modify the root of an existing MintersInfo
    function modifyMintersRoot(string memory _minterName, bytes32 _newRoot) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "ERROR: MintersInfo not found."); //change
        minters[_minterName].root = _newRoot;
    }

    function revealCollection (string memory _baseURI, bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
        baseURI = _baseURI;

        if (isRevealed)
            emit CollectionRevealed(msg.sender);
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public - onlyTeam functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    function internalMint(uint8 numberOfTokens) public onlyTeam {
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: Not enough tokens");
        _safeMint(msg.sender, numberOfTokens);
        emit Minted(msg.sender, numberOfTokens, 0);
    }

    function airdrop(uint8 numberOfTokens, address recipient) public onlyTeam whenNotPaused {
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: Not enough tokens left");
        _safeMint(recipient, numberOfTokens);
        emit Airdropped(recipient, numberOfTokens);
    }

    function multipleAirdrop(uint8 numberOfTokens, address[] memory recipients) public onlyTeam whenNotPaused {
        for (uint256 i = 0; i < recipients.length; i++) {
            airdrop(numberOfTokens, recipients[i]);
        }
    }

    function withdraw() public onlyTeam {

        require(address(this).balance > 0, "ERROR: No balance to withdraw.");
        uint256 amount = address(this).balance;
        //sends fund to team wallet
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

        if (!success) {
            revert WithdrawalFailed();
        } 

        emit WithdrawalSuccessful(msg.sender, amount);
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public - functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    function verifyWhitelist(string memory _minterType, address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        require(minters[_minterType].root != bytes32(0), "ERROR: Minter Type not found.");
        if (_isWhitelisted(_address, _merkleProof, minters[_minterType].root))
            return true;
        return false;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (isRevealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        }

        return baseURI;
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Internal - functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    function _phaseMint(uint8 _numberOfTokens, uint256 _totalCost) internal {
        
        require((_totalMinted() + _numberOfTokens) <= maxSupply, "ERROR: No tokens left to mint");
        require(_numberOfTokens > 0, "ERROR: Number of tokens should be greater than zero");
        require((mintedPerPhase[uint8(currentPhase)][msg.sender] + _numberOfTokens) <= maxMintPerWallet[uint8(currentPhase)], "ERROR: Your maximum NFT mint per wallet on this phase has exceeded.");
        require(msg.value >= _totalCost, "ERROR: Insufficient funds");

        _safeMint(msg.sender, _numberOfTokens);
        mintedPerPhase[uint8(currentPhase)][msg.sender] += _numberOfTokens;
        mintersAddresses.push(msg.sender);

        emit Minted(msg.sender, _numberOfTokens, _totalCost);
        
        if (_totalMinted() >= maxSupply) {
            _pause();
        }    
    } 

     function _isWhitelisted  (
        address _minterLeaf,
        bytes32[] calldata _merkleProof, 
        bytes32 _minterRoot
    ) public pure returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_minterLeaf));
        return MerkleProof.verify(_merkleProof, _minterRoot, _leaf);
    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * OpenSea - Operator Filterer Overrides
    * ******** ******** ******** ******** ******** ******** ********
    */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}