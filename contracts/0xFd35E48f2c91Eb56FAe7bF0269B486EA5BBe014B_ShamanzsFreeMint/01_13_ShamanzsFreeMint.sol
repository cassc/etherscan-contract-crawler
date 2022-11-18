// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 < 0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ShamanzsFreeMint is Ownable, ReentrancyGuard {

    using Strings for uint256;
    using MerkleProof for bytes32[];

    bool public PAUSED = true;
    bool public HOLDERS_PHASE = true;
    bool public LEFTOVER_PHASE = false;
    bool public SHAMAPASS_PHASE = false;
    bool public WHITELIST_PHASE = false;
    bool public PREMINT_PHASE = false;
    bool public PUBLIC_PHASE = false;

    address public SHAMANZSV2_ADDRESS = 0xd4e53E3597a2ED999D37E974F1f36B15eB879Bad;
    address public SHAMAPASS_ADDRESS = 0x11Bb15a3C2aA265f83333ad606cA3359C405D83d;
    uint256 public COUNTER = 1;
    uint256 public MAX_SUPPLY = 500;

    mapping(address => uint256) public HOLDER_MINTED;
    mapping(address => bool) public SHAMAPASS_HOLDER_MINTED;
    mapping(address => bool) public PUBLIC_MINTED;
    mapping(address => bool) public WHITELIST_MINTED;
    mapping(address => bool) public PREMINT_MINTED;

    bytes32 public HOLDERS_MERKLE_ROOT;
    bytes32 public TIER1_MERKLE_ROOT;
    bytes32 public TIER2_MERKLE_ROOT;
    bytes32 public TIER3_MERKLE_ROOT;
    bytes32 public TIER4_MERKLE_ROOT;
    bytes32 public TIER5_MERKLE_ROOT;
    bytes32 public WHITELIST_MERKLE_ROOT;
    bytes32 public PREMINT_MERKLE_ROOT;

    uint256 public TIER1_MINT= 1;
    uint256 public TIER2_MINT= 2;
    uint256 public TIER3_MINT= 3;
    uint256 public TIER4_MINT= 4;
    uint256 public TIER5_MINT= 5;

    uint256 public SHAMAPASS_NEEDED = 2;

    uint256 public SHAMAPASS_MAX_MINT_AMOUNT = 1;
    uint256 public LEFTOVERS_MAX_MINT_AMOUNT = 2;
    uint256 public PUBLIC_MAX_MINT_AMOUNT = 1;

    event shamanzsMinted(address _to, uint256 _qty);

    constructor () {}

    function holdersFreeMint(bytes32[] calldata _merkleProof, uint256 _mintAmount, uint256 _tier) external nonReentrant {
        require(!PAUSED, "Contract paused");
        require(HOLDERS_PHASE, "Incorrect phase");
        require(_mintAmount > 0, "No mint amount set");
        require(COUNTER + _mintAmount <= MAX_SUPPLY, "Supply depleted");
        uint256 mintAmount = 0;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (_tier == 1) {
            require(MerkleProof.verify(_merkleProof, TIER1_MERKLE_ROOT, leaf), "Not in tier");
            mintAmount = TIER1_MINT;
        }

        if (_tier == 2) {
            require(MerkleProof.verify(_merkleProof, TIER2_MERKLE_ROOT, leaf), "Not in tier");
            mintAmount = TIER2_MINT;
        }

        if (_tier == 3) {
            require(MerkleProof.verify(_merkleProof, TIER3_MERKLE_ROOT, leaf), "Not in tier");
            mintAmount = TIER3_MINT;
        }

        if (_tier == 4) {
            require(MerkleProof.verify(_merkleProof, TIER4_MERKLE_ROOT, leaf), "Not in tier");
            mintAmount = TIER4_MINT;
        }

        if (_tier == 5) {
            require(MerkleProof.verify(_merkleProof, TIER5_MERKLE_ROOT, leaf), "Not in tier");
            mintAmount = TIER5_MINT;
        }

        require(HOLDER_MINTED[msg.sender] + _mintAmount <= mintAmount, "You can`t mint more than that available in your tier");
        for (uint256 i = 0; i < _mintAmount; i++) {
            require(ERC721(SHAMANZSV2_ADDRESS).ownerOf(COUNTER) == owner(), "Owner doesnt own this shamanz" );
            ERC721(SHAMANZSV2_ADDRESS).transferFrom(owner(), msg.sender, COUNTER);
            COUNTER++;
        }
        HOLDER_MINTED[msg.sender] += _mintAmount;
        emit shamanzsMinted(msg.sender, _mintAmount);
    }

    function leftOversFreeMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external nonReentrant {
        require(!PAUSED, "Contract paused");
        require(MerkleProof.verify(_merkleProof, HOLDERS_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), "Not in Whitelist");
        require(LEFTOVER_PHASE, "Incorrect phase");
        require(_mintAmount > 0, "No mint amount set");
        require(_mintAmount <= LEFTOVERS_MAX_MINT_AMOUNT, "No more than maxMintAmount per transaction");
        require (COUNTER + _mintAmount <= MAX_SUPPLY, "Supply depleted");
        for (uint256 i = 0; i < _mintAmount; i++) {
            require(ERC721(SHAMANZSV2_ADDRESS).ownerOf(COUNTER) == owner(), "Owner doesnt own this shamanz" );
            ERC721(SHAMANZSV2_ADDRESS).transferFrom(owner(), msg.sender, COUNTER);
            COUNTER++;
        }
        emit shamanzsMinted(msg.sender, _mintAmount);
    }

    function ShamaPassFreeMint() external nonReentrant {
        require(!PAUSED, "Contract paused");
        require(SHAMAPASS_PHASE, "Incorrect phase");
        require (COUNTER + SHAMAPASS_MAX_MINT_AMOUNT <= MAX_SUPPLY, "Supply depleted");
        require(!SHAMAPASS_HOLDER_MINTED[msg.sender], "You can mint only once");
        require(ERC721(SHAMAPASS_ADDRESS).balanceOf(msg.sender) >= SHAMAPASS_NEEDED, "You dont own enough ShamaPasses");
        for (uint256 i = 0; i < SHAMAPASS_MAX_MINT_AMOUNT; i++) {
            require(ERC721(SHAMANZSV2_ADDRESS).ownerOf(COUNTER) == owner(), "Owner doesnt own this shamanz" );
            ERC721(SHAMANZSV2_ADDRESS).transferFrom(owner(), msg.sender, COUNTER);
            COUNTER++;
        }
        SHAMAPASS_HOLDER_MINTED[msg.sender] = true;
        emit shamanzsMinted(msg.sender, SHAMAPASS_MAX_MINT_AMOUNT);
    }

    function freeMint(bytes32[] calldata _merkleProof) external nonReentrant {
        require(!PAUSED, "Contract paused");
        require (COUNTER + PUBLIC_MAX_MINT_AMOUNT <= MAX_SUPPLY, "Supply depleted");
        require(PUBLIC_PHASE || WHITELIST_PHASE || PREMINT_PHASE, "Incorrect phase");

        if (PUBLIC_PHASE) require(!PUBLIC_MINTED[msg.sender], "Already minted in public phase");

        if (WHITELIST_PHASE) {
            require(!WHITELIST_MINTED[msg.sender], "Already minted in whitelist phase");
            require(MerkleProof.verify(_merkleProof, WHITELIST_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), "Not in Whitelist");
        }

        if (PREMINT_PHASE) {
            require(!PREMINT_MINTED[msg.sender], "Already minted in premint phase");
            require(MerkleProof.verify(_merkleProof, PREMINT_MERKLE_ROOT, keccak256(abi.encodePacked(msg.sender))), "Not in Premint");
        }

        for (uint256 i = 0; i < PUBLIC_MAX_MINT_AMOUNT; i++) {
            require(ERC721(SHAMANZSV2_ADDRESS).ownerOf(COUNTER) == owner(), "Owner doesnt own this shamanz" );
            ERC721(SHAMANZSV2_ADDRESS).transferFrom(owner(), msg.sender, COUNTER);
            COUNTER++;
        }

        if (PUBLIC_PHASE) PUBLIC_MINTED[msg.sender] = true;
        if (WHITELIST_PHASE) WHITELIST_MINTED[msg.sender] = true;
        if (PREMINT_PHASE) PREMINT_MINTED[msg.sender] = true;
        
        emit shamanzsMinted(msg.sender, PUBLIC_MAX_MINT_AMOUNT);
    }

    //UTILS
    function setShamanzsAddress(address _shamanzsAddress) public onlyOwner {
        SHAMANZSV2_ADDRESS = _shamanzsAddress;
    }

    function setShamaPassAddress(address _shamaPassAddress) public onlyOwner {
        SHAMAPASS_ADDRESS = _shamaPassAddress;
    }

    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    function activateHoldersPhase() public onlyOwner {
        HOLDERS_PHASE = true;
        if(LEFTOVER_PHASE) LEFTOVER_PHASE = false;
        if(SHAMAPASS_PHASE) SHAMAPASS_PHASE = false;
        if(WHITELIST_PHASE) WHITELIST_PHASE = false;
        if(PREMINT_PHASE) PREMINT_PHASE = false;
        if(PUBLIC_PHASE) PUBLIC_PHASE = false;
    }

    function activateLeftOversPhase() public onlyOwner {
        LEFTOVER_PHASE = true;
        if(SHAMAPASS_PHASE) SHAMAPASS_PHASE = false;
        if(WHITELIST_PHASE) WHITELIST_PHASE = false;
        if(PREMINT_PHASE) PREMINT_PHASE = false;
        if(PUBLIC_PHASE) PUBLIC_PHASE = false;
        if(HOLDERS_PHASE) HOLDERS_PHASE = false;
    }

    function activateWhitelistPhase() public onlyOwner {
        WHITELIST_PHASE = true;
        if(LEFTOVER_PHASE) LEFTOVER_PHASE = false;
        if(SHAMAPASS_PHASE) SHAMAPASS_PHASE = false;
        if(PREMINT_PHASE) PREMINT_PHASE = false;
        if(PUBLIC_PHASE) PUBLIC_PHASE = false;
        if(HOLDERS_PHASE) HOLDERS_PHASE = false;
    }

    function activatePremintPhase() public onlyOwner {
        PREMINT_PHASE = true;
        if(SHAMAPASS_PHASE) SHAMAPASS_PHASE = false;
        if(WHITELIST_PHASE) WHITELIST_PHASE = false;
        if(LEFTOVER_PHASE) LEFTOVER_PHASE = false;
        if(PUBLIC_PHASE) PUBLIC_PHASE = false;
        if(HOLDERS_PHASE) HOLDERS_PHASE = false;
    }

    function  activatePublicPhase() public onlyOwner {
        PUBLIC_PHASE = true;
        if(SHAMAPASS_PHASE) SHAMAPASS_PHASE = false;
        if(WHITELIST_PHASE) WHITELIST_PHASE = false;
        if(LEFTOVER_PHASE) LEFTOVER_PHASE = false;
        if(PREMINT_PHASE) PREMINT_PHASE = false;
        if(HOLDERS_PHASE) HOLDERS_PHASE = false;
    }

    function activateShamaPassPhase() public onlyOwner {
        SHAMAPASS_PHASE = true;
        if(PUBLIC_PHASE) PUBLIC_PHASE = false;
        if(WHITELIST_PHASE) WHITELIST_PHASE = false;
        if(LEFTOVER_PHASE) LEFTOVER_PHASE = false;
        if(PREMINT_PHASE) PREMINT_PHASE = false;
        if(HOLDERS_PHASE) HOLDERS_PHASE = false;
    }

    function setCounter(uint256 _newCounter) public onlyOwner {
        COUNTER = _newCounter;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setLeftOversMaxMintAmount(uint256 _mintAmount) public onlyOwner {
        LEFTOVERS_MAX_MINT_AMOUNT = _mintAmount;
    }

    function setShamaPassMaxMintAmount(uint256 _mintAmount) public onlyOwner {
        SHAMAPASS_MAX_MINT_AMOUNT = _mintAmount;
    }

    function setPublicMaxMintAmount(uint256 _mintAmount) public onlyOwner {
        PUBLIC_MAX_MINT_AMOUNT = _mintAmount;
    }

    function setShamaPassNeeded(uint256 _newAmount) public onlyOwner {
        SHAMAPASS_NEEDED = _newAmount;
    }

    function changeMerkleRoot(bytes32 _root, uint256 _tier) public onlyOwner {
        if (_tier == 1) TIER1_MERKLE_ROOT = _root;
        if (_tier == 2) TIER2_MERKLE_ROOT = _root;
        if (_tier == 3) TIER3_MERKLE_ROOT = _root;
        if (_tier == 4) TIER4_MERKLE_ROOT = _root;
        if (_tier == 5) TIER5_MERKLE_ROOT = _root;
        if (_tier == 10) HOLDERS_MERKLE_ROOT = _root;
        if (_tier == 11) WHITELIST_MERKLE_ROOT = _root;
        if (_tier == 12) PREMINT_MERKLE_ROOT = _root;
    }

    function changeTierMintAmount(uint256 _tier, uint256 _mintAmount) public onlyOwner {
        if (_tier == 1) TIER1_MINT = _mintAmount;
        if (_tier == 2) TIER2_MINT = _mintAmount;
        if (_tier == 3) TIER3_MINT = _mintAmount;
        if (_tier == 4) TIER4_MINT = _mintAmount;
        if (_tier == 5) TIER5_MINT = _mintAmount;
    }


    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}