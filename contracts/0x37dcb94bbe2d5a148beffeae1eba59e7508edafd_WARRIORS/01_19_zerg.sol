// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WARRIORS is ERC721A, Ownable, AccessControl {
    bool public open = false;
    bool public allowlistActive = true;
    uint public constant PRICE = 0.1 ether;
    uint public constant MAX_SUPPLY = 10000;
    uint public constant MAX_MINT = 500;
    uint public constant MAX_BATCH = 100;
    uint public reservedFreeMints = 250;
    address public rootSigner;
    address public vault;
    string public baseURI;

    // Allow list Ids:
    uint public seedIdFreeMint;
    uint public seedIdHalfMint;
    uint public seedIdAllowMint;
    uint public seedIdPostMint;

    // Mint counters
    mapping(uint => uint) public mintListFreeMint;
    mapping(uint => uint) public mintListHalfMint;
    mapping(uint => uint) public mintListPostMint;
    mapping(address => uint) public mintTotals;

    mapping(address => bool) public blockList;

    constructor(
    ) ERC721A("WARRIORS BY ZERG", "WARRIOR", MAX_BATCH, 10150) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0xE338F87E46e8a9D9D38144743c1Ff7311f641AF9);
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
        seedIdFreeMint = 0x5f30feede5deaaed58c5ce6038b57143;
        seedIdHalfMint = 0xcbf563b440f6aeb0049cc048aaeed8a0;
        seedIdAllowMint = 0x10af80d34235cc4ff8b5c4515d06b891;
        seedIdPostMint = 4;
        baseURI = 'https://warriors-zerg.s3.amazonaws.com/warriors/metadata/warriors/';
        rootSigner = 0xD2973834CA2D087cB18DBdbcECbAeF12CF3dA572;
        vault = 0xc050A0e9c1c347364e53961420a2b54BE8B3B117;
        
        _safeMint(0xE338F87E46e8a9D9D38144743c1Ff7311f641AF9, 1);
    }

    struct SignatureData {
        uint awrdId;
        uint nMints;
        uint nCounts;
        uint seedId;
        address minter;
        bytes signature;
    }

    modifier onlyIfOpen() {
        require(isOpen(), "Mint is not open");
        _;
    }

    function setSeedIdFreeMint(uint _seedId) public onlyRole(DEFAULT_ADMIN_ROLE){
        seedIdFreeMint = _seedId;
    }
    
    function setSeedIdHalfMint(uint _seedId) public onlyRole(DEFAULT_ADMIN_ROLE){
        seedIdHalfMint = _seedId;
    }
    
    function setSeedIdAllowMint(uint _seedId) public onlyRole(DEFAULT_ADMIN_ROLE){
        seedIdAllowMint = _seedId;
    }

    function setSeedIdPostMint(uint _seedId) public onlyRole(DEFAULT_ADMIN_ROLE){
        seedIdPostMint = _seedId;
    }

    function setReservedFreeMint(uint _reservedFreeMints) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(totalSupply() + _reservedFreeMints <= MAX_SUPPLY, "Exceeds maximum supply.");
        reservedFreeMints = _reservedFreeMints;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE){
        baseURI = _newBaseURI;
    }

    function setVault(address _vault) public onlyRole(DEFAULT_ADMIN_ROLE){
        vault = _vault;
    }

    function setSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE){
        rootSigner = _signer;
    }

    function setAllowMint() public onlyRole(DEFAULT_ADMIN_ROLE){
        allowlistActive = !allowlistActive;
    }

    function addToBlockList(address[] memory _addresses) public onlyRole(DEFAULT_ADMIN_ROLE){
        for (uint i = 0; i < _addresses.length; i++){
            blockList[_addresses[i]] = true;
        }
    }

    function removeFromBlockList(address[] memory _addresses) public onlyRole(DEFAULT_ADMIN_ROLE){
        for (uint i = 0; i < _addresses.length; i++){
            blockList[_addresses[i]] = false;
        }
    }

    function startMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!open, "Mint has already started");
        open = true;
    }

    function emergencyStopMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        open = false;
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = vault.call{value: address(this).balance}("");
        require(success, "Failed to transfer payment.");
    }

    function isOpen() public view returns (bool) {
        return open;
    }
    
    function isEnded() public view returns (bool) {
        return !open && totalSupply() > 0;
    }

    function isAllowList() public view returns (bool){
        return allowlistActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint qty) public payable onlyIfOpen {
        require(!blockList[to], "You are in the block list");
        require(totalSupply() + qty + reservedFreeMints <= MAX_SUPPLY, "Exceeds maximum supply.");
        require(!isAllowList(), "Allowlist mint is currently active.");
        require(msg.value == PRICE * qty, "Wrong price.");
        require(qty <= MAX_BATCH, "Exceeds maximum batch amount.");
        require(mintTotals[to] + qty <= MAX_MINT, "Exceeds maximum mint amount per user.");

        (bool success, ) = vault.call{value: msg.value}("");
        require(success, "Failed to transfer payment.");

        mintTotals[to] += qty;
        _safeMint(to, qty);
    }

    /// @notice This function allows users to claim across multiple claim lists in one go. Retaining multi-faceted Awardable badge integration at the cost of less efficient minting (use single use claim for an individual claim)
    /// @dev This function handles a series of arrays for minting out claims. This allows a frontend interface to collect a sequence of signatures from AWRD and handle the mint in one transaction, vs making the user generate signatures 1 at a time
    function multiClaim(
        uint awrdId,
        address minter, 
        SignatureData[] memory _signatures
    ) public payable onlyIfOpen {
        require(_signatures.length > 0, "Empty signature array.");
        
        uint totalCost = 0;
        uint totalMints = 0;
        for (uint i = 0; i < _signatures.length; i++){

            bytes32 dataHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(awrdId, _signatures[i].nCounts, minter, _signatures[i].seedId))
                )
            );
            require(
                SignatureChecker.isValidSignatureNow(
                    rootSigner, 
                    dataHash, 
                    _signatures[i].signature
                    ), "Invalid signature."
            );

            if (_signatures[i].seedId == seedIdFreeMint){
                require(_signatures[i].nMints <= reservedFreeMints, "All reserved Free Mint are gone!");
                require(_signatures[i].nMints <= _signatures[i].nCounts - mintListFreeMint[awrdId], "No remaining Free Mint.");
                mintListFreeMint[awrdId] += _signatures[i].nMints;
                totalMints += _signatures[i].nMints;
                reservedFreeMints -= _signatures[i].nMints;
            }
            else if( _signatures[i].seedId == seedIdHalfMint){
                require(_signatures[i].nMints <= _signatures[i].nCounts - mintListHalfMint[awrdId], "No remaining Half Price Mint.");
                totalCost += (PRICE / 2) * _signatures[i].nMints;
                mintListHalfMint[awrdId] += _signatures[i].nMints;
                totalMints += _signatures[i].nMints;
            } else if (_signatures[i].seedId == seedIdAllowMint){
                require(_signatures[i].nCounts > 0, "Not allowed.");
                totalCost += PRICE * _signatures[i].nMints;
                totalMints += _signatures[i].nMints;
            }
            else {
                revert("Invalid seedId");
            }
        }
             
        require(totalMints <= MAX_BATCH, "Exceeds maximum batch amount."); 
        require(mintTotals[minter] + totalMints <= MAX_MINT, "Exceeds maximum mint amount per user."); 
        require(totalSupply() + totalMints + reservedFreeMints <= MAX_SUPPLY, "Exceeds maximum supply.");
        require(msg.value == totalCost, "Wrong total price");
            
        (bool success, ) = vault.call{value: msg.value}("");
        require(success, "Failed to transfer payment.");

        mintTotals[minter] += totalMints;
        _safeMint(minter, totalMints);
    }

    function claimPostMint(
        SignatureData memory _signature
    ) public payable {
        require(isEnded(), "Mint ongoing.");
        require(_signature.nMints <= MAX_BATCH, "Exceeds maximum batch amount.");
        require(mintTotals[_signature.minter] + _signature.nMints <= MAX_MINT, "Exceeds maximum mint amount per user.");
        require(_signature.seedId == seedIdPostMint, "Invalid list seed input.");

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_signature.awrdId, _signature.nCounts, _signature.minter, _signature.seedId))
            )
        );
        require(
            SignatureChecker.isValidSignatureNow(
                rootSigner,
                dataHash,
                _signature.signature
            ),
            "Invalid signature."
        );

        require(_signature.nMints <= _signature.nCounts - mintListPostMint[_signature.awrdId], "No remaining claims.");
        mintListPostMint[_signature.awrdId] += _signature.nMints;
        mintTotals[_signature.minter] += _signature.nMints;
        _safeMint(_signature.minter, _signature.nMints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}