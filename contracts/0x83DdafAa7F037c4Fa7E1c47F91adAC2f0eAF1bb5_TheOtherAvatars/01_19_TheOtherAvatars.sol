// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./CustomCounter.sol";
import "./TheOtherAvatarsRoyalties.sol";
import "./ReentrancyGuard.sol";
import "./Signable.sol";

contract TheOtherAvatars is ERC721Enumerable, TheOtherAvatarsRoyalties, CustomCounter, ReentrancyGuard, Signable {
    enum Phase { NONE, PRE_SALE, MAIN_SALE }
    
    Phase private _phase;
    
    // Constants
    uint256 public constant maxSupply = 2523;
    uint256 public constant mintPrice = 0.1 ether;
    uint256 public constant mintPerAccount = 5;
    uint256 public constant artistTokensCount = 87;
    
    bool private _withdrawAddressSet = true;

    address private _withdrawAddress = 0xBfb8cB4Ff7A804a1e476241A4E0CF838C5781575;
    
    // Base URI
    string private _baseTokenURI;
    string private _baseContractURI;

    // Minting by account
    mapping(address => uint256) public mintedPreSale;
    mapping(address => uint256) public mintedMainSale;
    
    modifier phaseRequired(Phase phase_) {
        require(phase_ == phase(), "Mint not available on current phase");
        _;
    }
    
    modifier costs(uint price) {
        require(msg.value >= price, "msg.value should be more or eual than price");
        _;
    }
    
    constructor() ERC721("The Other Avatars by Saatchi Art", "TOA") CustomCounter(artistTokensCount) TheOtherAvatarsRoyalties(_withdrawAddress) {
        string memory baseTokenURI = "https://www.saatchiartnfts.com/token/";
        string memory baseContractURI = "https://www.saatchiartnfts.com/contract-metadata";

        _baseTokenURI = baseTokenURI;
        _baseContractURI = baseContractURI;
    }

    function setWithdrawAddress(address withdrawAddress_) public onlyOwner {
        require(_withdrawAddressSet == false, "Withdraw alaready set");
        _withdrawAddress = withdrawAddress_;
        _defaultAccount = withdrawAddress_;
        _withdrawAddressSet = true;
    }

    function setContractURI(string memory baseContractURI_) public onlyOwner {
        _baseContractURI = baseContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function giveawayMint(address to, uint256 amount) public lock onlyOwner {
        uint256 total = counterCurrent();
        require(total + amount <= maxSupply, "Number of tokens reach the limit");

        for (uint i; i < amount; i++) {
            counterIncrement();
            _safeMint(to, counterCurrent());
        }
    }
    
    function artistMint(address[] memory artists, uint256[] memory tokens) public lock onlyOwner {
        for (uint i; i < artists.length; i++) {
            uint256 tokenId = tokens[i];
            require(tokenId > 0 && tokenId <= artistTokensCount, "tokenId does not belong to artists");
            address artist = artists[i];
            _safeMint(artist, tokenId);
        }
    }
    
    function preSaleMint(uint256 amount, uint256 maxAmount, bytes calldata signature) public payable costs(mintPrice * amount) phaseRequired(Phase.PRE_SALE) lock {
        require(!Address.isContract(msg.sender), "Address is contract");
        
        uint256 total = counterCurrent();
        require(total + amount <= maxSupply, "Number of tokens reach the limit");

        require(_verify(signer(), _hash(msg.sender, maxAmount), signature), "Invalid signature");
        
        require(mintedPreSale[msg.sender] + amount <= maxAmount, "Account already minted tokens");
        mintedPreSale[msg.sender] += amount;
        
        for (uint i; i < amount; i++) {
            counterIncrement();
            _safeMint(msg.sender, counterCurrent());
        }
    }
    
    function mint(uint256 amount) public payable costs(mintPrice * amount) phaseRequired(Phase.MAIN_SALE) lock {
        require(!Address.isContract(msg.sender), "Address is a contract");
        
        uint256 total = counterCurrent();
        require(total + amount <= maxSupply, "Number of tokens reach the limit");
        
        require(mintedMainSale[msg.sender] + amount <= mintPerAccount, "Account already minted tokens");
        mintedMainSale[msg.sender] += amount;
        
        for (uint i; i < amount; i++) {
            counterIncrement();
            _safeMint(msg.sender, counterCurrent());
        }
    }
    
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(_withdrawAddress, balance);
    }
    
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }
    
    function setPhase(Phase phase_) public onlyOwner {
        _phase = phase_;
    }
    
    function phase() public view returns (Phase) {
        return _phase;
    }

    function credit() public pure returns (string memory) {
        return "Tech by Alexander Zimin and Sergey Tsibel for Saatchi Art";
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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