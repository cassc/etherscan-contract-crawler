// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
   .           ....                                                                                          
  @88>     .xH888888Hx.                                                                                      
  %8P    .H8888888888888:       .u    .                             ..    .     :                  .u    .   
   .     888*"""?""*88888X    .d88B :@8c       .u          u      .888: x888  x888.       .u     .d88B :@8c  
 [email protected]  'f     d8x.   ^%88k  ="8888f8888r   ud8888.     us888u.  ~`8888~'888X`?888f`   ud8888.  ="8888f8888r 
''888E` '>    <88888X   '?8    4888>'88"  :888'8888. [email protected] "8888"   X888  888X '888>  :888'8888.   4888>'88"  
  888E   `:..:`888888>    8>   4888> '    d888 '88%" 9888  9888    X888  888X '888>  d888 '88%"   4888> '    
  888E          `"*88     X    4888>      8888.+"    9888  9888    X888  888X '888>  8888.+"      4888>      
  888E     .xHHhx.."      !   .d888L .+   8888L      9888  9888    X888  888X '888>  8888L       .d888L .+   
  888&    X88888888hx. ..!    ^"8888*"    '8888c. .+ 9888  9888   "*88%""*88" '888!` '8888c. .+  ^"8888*"    
  R888"  !   "*888888888"        "Y"       "88888%   "888*""888"    `~    "    `"`    "88888%       "Y"      
   ""           ^"***"`                      "YP'     ^Y"   ^Y'                         "YP'                 

*/

contract IDreamer is ERC721, Ownable {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 8;
    uint256 public maxPresaleMintsPerWallet = 4;
    uint256 public maxReserveMintsPerWallet = 10;

    uint256 public mintPrice = 0.08 ether;
    uint256 public reserveMintPrice = 0.12 ether;
    uint256 public evolvePrice = 0.015 ether;

    bool public presaleMintingIsActive = false;
    bool public mintingIsActive = false;
    bool public reserveMintingIsActive = false;
    bool public freeMintingIsActive = false;
    bool public evolutionIsActive = false;

    bool public isLocked = false;
    string public baseURI;
    string public provenance;

    // Used to validate authorized mint addresses
    address public signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    address[5] private _shareholders;
    uint[5] private _shares;

    mapping (address => uint256) public presaleMints;
    mapping (address => uint256) public reserveMints;
    mapping (address => bool) public freeMints;

    event ReserveMinted(uint256 tokenId, string id);
    event Evolved(uint256 tokenId, string id);
    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxSupply) ERC721(name, symbol) {
        maxTokenSupply = maxSupply;

        _shareholders[0] = 0xFb728a85e05b74EA63243E8108080aA9bbc595E8; // Glassface
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x7f73422854dD9727858bE39E86C1AD8B6bCA89d4; // Wolfbear
        _shareholders[3] = 0xaf6c9fA6a10DCcBCC636F15E365c8A0aD7fcaB99; // Dedz
        _shareholders[4] = 0x93a0AA2CEd962A4BBBC8FA37b0b8d8885c595417; // Gowens

        _shares[0] = 4850;
        _shares[1] = 2500;
        _shares[2] = 2000;
        _shares[3] = 500;
        _shares[4] = 150;
    }

    function setMaxTokenSupply(uint256 maxSupply) external onlyOwner {
        require(!isLocked, "Locked");
        maxTokenSupply = maxSupply;
    }

    function setMaxMintsPerWallet(uint256 newPresaleLimit, uint256 newReserveLimit) external onlyOwner {
        maxPresaleMintsPerWallet = newPresaleLimit;
        maxReserveMintsPerWallet = newReserveLimit;
    }

    function setPrices(uint256 newPrice, uint256 newReservePrice, uint256 newEvolvePrice) external onlyOwner {
        mintPrice = newPrice;
        reserveMintPrice = newReservePrice;
        evolvePrice = newEvolvePrice;
    }

    function setMintingStates(bool newMintingIsActive, bool newPresaleMintingIsActive, bool newReserveMintingIsActive, bool newFreeMintingIsActive) external onlyOwner {
        mintingIsActive = newMintingIsActive;
        presaleMintingIsActive = newPresaleMintingIsActive;
        reserveMintingIsActive = newReserveMintingIsActive;
        freeMintingIsActive = newFreeMintingIsActive;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        signerAddress = newSignerAddress;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) external onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    function hashMintApproval(address mintAddress, uint256 mintAllowance) public pure returns (bytes32) {
        return keccak256(abi.encode(
            mintAddress,
            mintAllowance
        ));
    }

    /*
    * Mint NFTs for giveaways, devs, etc.
    */
    function ownerMint(uint256 reservedAmount, address mintAddress) external onlyOwner {        
        _mintMultiple(reservedAmount, mintAddress);
    }

    /*
    * Pause evolution if active, make active if paused.
    */
    function flipEvolutionState() external onlyOwner {
        evolutionIsActive = !evolutionIsActive;
    }

    /*
    * Lock provenance, supply and base URI.
    */
    function lockProvenance() external onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function reserveMint(string memory id) external payable {
        require(reserveMintingIsActive, "Reserve minting not live");
        require(_tokenIdCounter.current() < maxTokenSupply, "Exceeds max supply");
        require(reserveMints[msg.sender] < maxReserveMintsPerWallet, "Exceeds max per wallet");
        require(reserveMintPrice <= msg.value, "Incorrect ether value");

        reserveMints[msg.sender] += 1;

        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        emit ReserveMinted(_tokenIdCounter.current(), id);
    }

    function publicMint(uint256 numTokens) external payable {
        require(mintingIsActive, "Sale not live");
        require(numTokens <= MAX_MINTS_PER_TXN, "Exceeds max per txn");
        require(mintPrice * numTokens <= msg.value, "Incorrect ether value");

        _mintMultiple(numTokens, msg.sender);
    }

    function presaleMint(uint256 numTokens) external payable {
        require(presaleMintingIsActive, "Presale not live");
        require(presaleMints[msg.sender] + numTokens <= maxPresaleMintsPerWallet, "Exceeds max per wallet");
        require(mintPrice * numTokens <= msg.value, "Incorrect ether value");

        presaleMints[msg.sender] += numTokens;

        _mintMultiple(numTokens, msg.sender);
    }

    function freeMint(uint256 mintAllowance, bytes memory signature) external {
        require(freeMintingIsActive, "Free mints not live");
        require(!freeMints[msg.sender], "Already claimed");
        require(signerAddress == hashMintApproval(msg.sender, mintAllowance).toEthSignedMessageHash().recover(signature), "Invalid signature");

        freeMints[msg.sender] = true;

        _mintMultiple(mintAllowance, msg.sender);
    }

    function _mintMultiple(uint256 numTokens, address mintAddress) internal {
        require(_tokenIdCounter.current() + numTokens <= maxTokenSupply, "Exceeds max supply");

        for (uint256 i = 0; i < numTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    function evolve(uint256 tokenId, string memory id) external payable {
        require(evolutionIsActive, "Evolution not live");
        require(evolvePrice <= msg.value, "Incorrect ether value");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller not owner nor approved");

        emit Evolved(tokenId, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!isLocked, "Locked");
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!isLocked, "Locked");
        provenance = provenanceHash;
    }
}