// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ==========================================================================================
// ==========================================================================================
// [email protected]@@@@@@@@@+=======================
// =====================================================%%%%%%%%%%%%%%%#=====================
// ================================*********************@@@%%%%%%%%%%@@%**+==================
// [email protected]@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%@@*==================
// ==========================*@@@@@%%%%%%%%%%%%%%%%%%%%%@@@%%%%%%%%%%%%%@@*==================
// ========================#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@%%%%%%%%@@*==================
// =====================+**%@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@%%%%%%%%@@%**================
// =====================#@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@%%%%%@@%=============
// =====================#@@%%%%%@@@++++++++++++++++++#@@%%%%%%%%%%%%%@@@%%@@@*++=============
// ===================::[email protected]@%%%@@#**==================+**@@@%%%%%%%%%%%@@@@@@@##*=============
// ==================-  =%%%%%@@*[email protected]@@%%%%%%%%%%%%%@@@%%%%#=============
// ==================-  =%%%%%@@*[email protected]@@%%@@@%%%%%%%%@@@@@+===============
// =============:    :@@@%%@@@@@%####*==========######%%@@@@@@@@@@%%%%%%@@*==================
// =============:    :@@@%%@@@%%%%%%%*==========%%%%%%%%%%%@@%%%@@@%%%%%@@*==================
// =============:    :@@@%%@@#[email protected]@%%%@@@%%%%%@@*==================
// ================. :@@@%%@@@@@@@@@@#[email protected]@@@@@@@@@%%%@@@%%%%%@@*==================
// ================. :@@@%%@@#--#@%---=============--*@%[email protected]@%%%@@@%%%%%@@*==================
// =============:       =%%@@%=======================+*[email protected]@%%%@@@%%%%%@@*==================
// =============:    :@@%%%@@%=======================+++=====%@@==*%%%%%@@*==================
// =============---  .**%@@%%#=======================+++=====#%%**#%%@@%**+==================
// ================:.:+++**++=:::::::=************+===++===++#####%%%%%#=====================
// ===================+*-            [email protected]@@@@@@@@@@@%=======+#######%@@+=======================
// ========================%@@##+=======================#######%@@#==========================
// ========================++#@@#**=====********=====+**##%@@@@%+++==========================
// ==========================+##%%%+++++########+++++###%%%#####=============================
// =============================#%%%%%%%%%%%%%%%%%%%%%%%%@#==================================
// [email protected]@@@@@@@@@@@@@@@@@@@@=====================================
// ================================+++++++++++++++++++++=====================================
// ==========================================================================================
// ==========================================================================================
// ░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░░▒▒▒▒░░▒▒▒▒▒░░░░▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒░░▒▒▒▒▒░░▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒░░░░░░░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░▒▒▒▒▒░░▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░░░░░░░░▒▒▒▒▒░░░░▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract YakuzziNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private _maxMint = 1;

    uint256 private constant TEAM_RESERVED = 89;
    uint256 private constant SAKE_RESERVED = 693;
    uint256 public constant TOTAL_SUPPLY = 893;

    bytes32 public whitelistMerkleRoot;

    string private _baseTokenUri;

    uint256 private _whitelistMintDuration = 90 minutes;
    uint256 private _openGateWL;
    uint256 private _openGatePublic;

    mapping(address => bool) private _teamWallet;

    mapping(address => uint256) private _totalMinted;

    constructor(uint256 _gateOpenAt) ERC721("Yakuzzi", "YKZ") {
        _openGateWL = _gateOpenAt;
        _openGatePublic = _gateOpenAt + _whitelistMintDuration;
    }

    /////////////////////////////
    //    PUBLIC FUNCTIONS    //
    ////////////////////////////
    function joinJacuzzi() external onMintCheck {
        require(block.timestamp >= _openGatePublic, "YKZ!: Gate is not yet open for you!");
        require(totalSupply() < TOTAL_SUPPLY, "YKZ!: No more yakuzzi available!");

        _totalMinted[msg.sender] += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function sakeListMint(bytes32[] calldata _merkleProof) external onMintCheck {
        require(block.timestamp >= _openGateWL, "YKZ!: Gate is not yet open!");
        require(block.timestamp <= _openGatePublic, "YKZ!: Gate is closed!");
        require(totalSupply() >= TEAM_RESERVED, "YKZ!: Gate is not yet open!");
        require(totalSupply() < TEAM_RESERVED + SAKE_RESERVED, "YKZ!: Sorry no more sake available!");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, sender), "YKZ!: You are not whitelisted!");

        _totalMinted[msg.sender] += 1;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function gateOpen() public view returns (uint256) {
        return _openGateWL;
    }

    function publicGateOpen() public view returns (uint256){
        return _openGatePublic;
    }

    function isTeamAddress(address addr) public view returns(bool){
        return _teamWallet[addr];
    }

    function isWhitelisted(bytes32[] calldata _merkleProof) public view returns(bool){
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool checkWhitelist = MerkleProof.verify(_merkleProof, whitelistMerkleRoot, sender);
        return checkWhitelist;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_baseTokenUri).length > 0 ? string(abi.encodePacked(_baseTokenUri, tokenId.toString(), ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //////////////
    //  ADMIN   //
    //////////////
    function teamMint(uint256 qty) external onlyTeam() {
        require(totalSupply() + qty <= TEAM_RESERVED, "YKZ!: Cannot Mint More Than reserved token!");
       
        for (uint256 i = 0; i < qty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function addTeamWallet(address _addr) external onlyOwner(){
        _teamWallet[_addr] = true;
    }

    function removeTeamWallet(address _addr) external onlyOwner(){
        require(_teamWallet[_addr], "YKZ!: Sorry teamwallet not found");
        delete _teamWallet[_addr];
    }

    function withdraw() external onlyOwner(){
        require(msg.sender != address(0), "YKZ!: Can't withdraw to 0 address");
        uint256 balance = address(this).balance;
        require(balance > 0, "YKZ!: No balance to withdraw!");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTokenUri(string memory __baseTokenUri) external onlyOwner() {
        _baseTokenUri = __baseTokenUri;
    }

    function setGate(uint256 _newDate) external onlyOwner() {
        _openGateWL = _newDate;
        _openGatePublic = _newDate + _whitelistMintDuration;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner() {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //////////////////
    //   PRIVATE   //
    /////////////////
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    /////////////////////
    //     MODIFIER    //
    /////////////////////
    modifier onMintCheck() {
        require(_totalMinted[msg.sender] < _maxMint, "YKZ!: You only able to drink 1 sake!");
        _;
    }

    modifier onlyTeam(){
        require(_teamWallet[msg.sender], "YKZ!: only team wallet able to mint");
        _;
    }
}