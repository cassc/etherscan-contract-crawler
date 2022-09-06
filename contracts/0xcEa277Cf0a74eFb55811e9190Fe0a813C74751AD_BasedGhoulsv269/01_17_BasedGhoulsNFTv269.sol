//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./interfaces/IBatchReveal.sol";

// ghouls rebased by @0xhanvalen

contract BasedGhoulsv269 is ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable {
    using StringsUpgradeable for uint256;

    mapping (address => bool) public EXPANSIONPAKRedemption;
    mapping (address => bool) public REBASERedemption;

    struct GhoulData {
    bool isMintable;
    uint16 totalSupply;
    uint16 maxGhouls;
    uint16 summonedGhouls;
    uint16 rebasedGhouls;
    uint16 maxRebasedGhouls;
    uint16 lastTokenRevealed;
    uint16 TOKEN_LIMIT;
    uint16 REVEAL_BATCH_SIZE;
    string baseURI;
    string unrevealedURI;

    bytes32 EXPANSION_PAK;
    bytes32 SUMMONER_LIST;

    address shufflerAddress;

    bool isHordeReleased;
    }

    GhoulData ghouldata;

    function initialize() initializer public {
        __ERC721_init("Based Ghouls", "GHLS");
        ghouldata.maxGhouls = 6666;
        ghouldata.maxRebasedGhouls = 2529;
        ghouldata.baseURI = "https://ghlsprod.s3.amazonaws.com/json/";
        ghouldata.unrevealedURI = "https://ghlsprereveal.s3.amazonaws.com/json/Shallow_Grave.json";
        ghouldata.EXPANSION_PAK = 0x45b023b371a3c483c2f511b6647ab965a580f4f2eaa3f9240a74c50bd9af779f;
        ghouldata.SUMMONER_LIST = 0x0b2bcd41b8945cfd9ffe48a11ad38426bb2146bc95f2f2d35087037166f8cfec;
        ghouldata.lastTokenRevealed = 1;
        ghouldata.TOKEN_LIMIT = 6666;
        ghouldata.REVEAL_BATCH_SIZE = 66;
        ghouldata.isMintable = false;
        ghouldata.totalSupply = 0;
        _setDefaultRoyalty(0x475dcAA08A69fA462790F42DB4D3bbA1563cb474, 690);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, 0x98CCf605c43A0bF9D6795C3cf3b5fEd836330511);
    }

    function getGhoulData() view public returns (GhoulData memory) {
        return ghouldata;
    }

    function updateBaseURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.baseURI = _newURI;
    }

    function updateUnrevealedURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.unrevealedURI = _newURI;
    }
 
    function setMintability(bool _mintability) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.isMintable = _mintability;
    }

    function setShufflerAddress(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.shufflerAddress = _address;
    }

    function setBatchSeed(uint _randomness) private {
        IBatchReveal(ghouldata.shufflerAddress).setBatchSeed(_randomness);
    }

    function setLastTokenRevealed(uint16 _index) private {
        IBatchReveal(ghouldata.shufflerAddress).setLastTokenRevealed(_index);
    }

    function getShuffledTokenId(uint _startId) view private returns (uint) {
        return IBatchReveal(ghouldata.shufflerAddress).getShuffledTokenId(_startId);
    }

    function insertExpansionPack(bytes32 _newMerkle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.EXPANSION_PAK = _newMerkle;   
    }

    function releaseTheHorde(bool _isHordeReleased) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.isHordeReleased = _isHordeReleased;
    }

    function insertRebasePack(bytes32 _newMerkle, uint16 _maxRebasedGhouls) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.SUMMONER_LIST = _newMerkle;   
        ghouldata.maxRebasedGhouls = _maxRebasedGhouls;
    }

    // u gotta... GOTTA... send the merkleproof in w the mint request. 
    function summon(bytes32[] calldata _merkleProof, bool _isRebase) public {
        require(ghouldata.isMintable, "NYM");
        require(ghouldata.totalSupply <= ghouldata.maxGhouls, "OOG");
        address minter = msg.sender;
        require(tx.origin == msg.sender, "NSCM");
        if (_isRebase) {
            require(!REBASERedemption2[minter], "TMG");
            require(ghouldata.rebasedGhouls + 3 <= ghouldata.maxRebasedGhouls, "NEG");
            bytes32 leaf = keccak256(abi.encodePacked(minter));
            bool isLeaf = MerkleProofUpgradeable.verify(_merkleProof, ghouldata.SUMMONER_LIST, leaf);
            require(isLeaf, "NBG");
            REBASERedemption2[minter] = true;
            EXPANSIONPAKRedemption2[minter] = true;
            ghouldata.totalSupply = ghouldata.totalSupply + 3;
            ghouldata.rebasedGhouls += 3;
            _mint(minter, ghouldata.totalSupply - 3);
            _mint(minter, ghouldata.totalSupply - 2);
            _mint(minter, ghouldata.totalSupply - 1);
        }
        if (!ghouldata.isHordeReleased && !_isRebase) {
                require(!EXPANSIONPAKRedemption2[minter], "TMG");
                require(ghouldata.summonedGhouls + 1 + ghouldata.maxRebasedGhouls <= ghouldata.maxGhouls, "NEG");
                bytes32 leaf = keccak256(abi.encodePacked(minter));
                bool isLeaf = MerkleProofUpgradeable.verify(_merkleProof, ghouldata.EXPANSION_PAK, leaf);
                require(isLeaf, "NBG");
                EXPANSIONPAKRedemption2[minter] = true;
                ghouldata.totalSupply = ghouldata.totalSupply + 1;
                ghouldata.summonedGhouls += 1;
                _mint(minter, ghouldata.totalSupply - 1);
        }
        if (ghouldata.isHordeReleased) {
            require(ghouldata.summonedGhouls + 1 + ghouldata.maxRebasedGhouls <= ghouldata.maxGhouls, "NEG");
            ghouldata.summonedGhouls += 1;
            ghouldata.totalSupply = ghouldata.totalSupply + 1;
            _mint(minter, ghouldata.totalSupply - 1);
        }
        if(ghouldata.totalSupply >= (ghouldata.lastTokenRevealed + ghouldata.REVEAL_BATCH_SIZE)) {
            ghouldata.lastTokenRevealed = ghouldata.totalSupply;
            setLastTokenRevealed(ghouldata.totalSupply);
            uint256 seed;
            unchecked {
                seed = uint256(blockhash(block.number - 69)) * uint256(block.timestamp % 69);
            }
            setBatchSeed(seed);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if(id >= ghouldata.lastTokenRevealed){
            return ghouldata.unrevealedURI;
        } else {
             return string(abi.encodePacked(ghouldata.baseURI, getShuffledTokenId(id).toString(), ".json"));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    mapping (address => bool) public EXPANSIONPAKRedemption2;
    mapping (address => bool) public REBASERedemption2;

    function setGDLastTokenRevealed(uint16 newToken) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ghouldata.lastTokenRevealed = newToken;
    }
}