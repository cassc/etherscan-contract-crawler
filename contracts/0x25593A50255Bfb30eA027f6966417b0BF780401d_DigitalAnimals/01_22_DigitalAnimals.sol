// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Creators.sol";
import "./Signable.sol";

contract DigitalAnimals is ERC721Enumerable, VRFConsumerBase, Ownable, Signable, ReentrancyGuard, Creators {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    enum Phase { NONE, PRE_SALE, MAIN_SALE }
    
    // Constants
    uint256 public constant maxSupply = 8888;
    uint256 public constant mintPrice = 0.1 ether;
    uint256 public constant mainSaleMintPerAccount = 2;

    // Phase
    Phase private _phase;
    
    // Base URI
    string private _baseTokenURI;
    string private _baseContractURI;
    
    // Minting by account on different phases
    mapping(address => uint256) public mintedAllSales;

    // Original minter
    mapping(uint256 => address) public originalMinter;
    
    // Counter
    Counters.Counter private _tokenCount;

    // Flag
    bool private gotGiftMints = false;

    // Random
    bool public randomRevealed = false;
    uint256 public randomValue = 0;

    // VRF Credentials
    address private VRFCoodinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address private LINKToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 internal fee = 2 ether;
    
    modifier onlyCreators {
        require(msg.sender == owner() || isCreator(msg.sender));
        _;
    }
    
    modifier phaseRequired(Phase phase_) {
        require(phase_ == phase(), "Mint not available on current phase");
        _;
    }
    
    modifier costs(uint price) {
        if (isCreator(msg.sender) == false) {
            require(msg.value >= price, "msg.value should be more or eual than price");   
        }
        _;
    }
    
    constructor() 
        ERC721("Digitals Aniamls", "DALS")
        VRFConsumerBase(VRFCoodinator, LINKToken)
    {
        string memory baseTokenURI = "https://digitalanimals.club/animal/";
        string memory baseContractURI = "https://digitalanimals.club/files/metadata.json";

        _baseTokenURI = baseTokenURI;
        _baseContractURI = baseContractURI;
    }

    receive() external payable { }

    fallback() external payable { }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }
    
    function setContractURI(string memory baseContractURI_) public onlyOwner {
        _baseContractURI = baseContractURI_;
    }

    function mintForGifts() public onlyOwner lock { 
        require(gotGiftMints == false, "Already minted");
        uint256 amount = 22;

        uint256 total = totalToken();
        require(total + amount <= maxSupply, "Max limit");

        for (uint i; i < amount; i++) {
            _tokenCount.increment();
            _safeMint(msg.sender, totalToken());
            originalMinter[totalToken()] = msg.sender;
        }

        gotGiftMints = true;
    }
    
    function mintMainSale(uint256 amount, bytes calldata signature) public payable costs(mintPrice * amount) phaseRequired(Phase.MAIN_SALE) {
        _mint(amount, mainSaleMintPerAccount, signature, Phase.MAIN_SALE);
    }
    
    function mintPreSale(uint256 amount, uint256 maxAmount, bytes calldata signature) public payable costs(mintPrice * amount) phaseRequired(Phase.PRE_SALE) {
        _mint(amount, maxAmount, signature, Phase.PRE_SALE);
    }
    
    function setPhase(Phase phase_) public onlyOwner {
        _phase = phase_;
    }

    function reveal() public onlyOwner lock returns (bytes32 requestId) {
        require(!randomRevealed, "Chainlink VRF already requested");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        randomRevealed = true;
        return requestRandomness(keyHash, fee);
    }
    
    function withdrawAll() public onlyCreators {
        uint256 balance = address(this).balance;
        require(balance > 0);
        
        _widthdraw(creator1, balance.mul(3).div(100));
        _widthdraw(creator2, balance.mul(3).div(100));
        _widthdraw(creator3, balance.mul(3).div(100));
        _widthdraw(creator4, balance.mul(2).div(100));
        _widthdraw(creator5, balance.mul(6).div(100));
        _widthdraw(creator6, balance.mul(20).div(100));
        _widthdraw(creator7, balance.mul(20).div(100));
        _widthdraw(creator8, balance.mul(20).div(100));
        _widthdraw(creator9, balance.mul(20).div(100));
        _widthdraw(creator10, address(this).balance);
    }
    
    function phase() public view returns (Phase) {
        return _phase;
    }
    
    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId > 0 && tokenId <= totalSupply(), "Token not exist.");
        return string(abi.encodePacked(_baseURI(), metadataOf(tokenId), ".json"));
    }
    
    function totalToken() public view returns (uint256) {
        return _tokenCount.current();
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomValue == 0, "Random already defined");
        
        if (randomness == 0) {
            randomValue = 1;
        } else {
            randomValue = randomness;
        }
    }

    function _mint(uint256 amount, uint256 maxAmount, bytes calldata signature, Phase phase_) private lock {
        require(!Address.isContract(msg.sender), "Address is contract");

        uint256 total = totalToken();
        require(total + amount <= maxSupply, "Max limit");

        require(maxAmount <= 3, "You can't mint more than 3 tokens");
        require(_verify(signer(), _hash(msg.sender, maxAmount), signature), "Invalid signature");

        if (phase_ == Phase.PRE_SALE) {
            uint256 minted = mintedAllSales[msg.sender];
            require(minted + amount <= maxAmount, "Already minted maximum on pre-sale");
            mintedAllSales[msg.sender] = minted + amount;
        } else {
            uint256 minted = mintedAllSales[msg.sender];
            require(minted + amount <= maxAmount, "Already minted maximum on main-sale");
            mintedAllSales[msg.sender] = minted + amount;
        }
        
        for (uint i; i < amount; i++) {
            _tokenCount.increment();
            _safeMint(msg.sender, totalToken());
            originalMinter[totalToken()] = msg.sender;
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function metadataOf(uint256 tokenId) private view returns (string memory) {
        if (randomValue == 0) {
            return "hidden";
        }

        uint256 shift = randomValue % maxSupply;
        uint256 newId = tokenId + shift;
        if (newId > maxSupply) {
            newId = newId - maxSupply;
        }

        return Strings.toString(newId);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Widthdraw failed");
    }
    
    function _verify(address signer, bytes32 hash, bytes memory signature) private pure returns (bool) {
        return signer == ECDSA.recover(hash, signature);
    }
    
    function _hash(address account, uint256 amount) private pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account, amount)));
    }
}