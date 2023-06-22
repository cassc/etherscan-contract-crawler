// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CC0Fighters is AccessControl, ERC721Enumerable, IERC721Receiver, ReentrancyGuard, EIP712 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool private mintFlag = false;
    Counters.Counter private _tokenIdCounter;
    string private _URI = "";
    address private signer = address(0x030b7361eBC8889c30dFA82265165d0f00b19666);
    bytes32 private constant FREE_MINT_HASH_TYPE = keccak256("freemint(address wallet)");
    mapping(address => bool) private freeMintLog;

    // max token supply
    uint256 public _maxSupply;
    uint256 public _maxMintSupply;
    uint256 public _devReserved;
    uint256 public _devMintCounter;
    uint256 public _pubMintCounter;
    // base mint price
    uint256 public _preMintAmount;
    uint256 public _pubMintAmount;

    uint256 public _startMintTime;
    uint256 public _freeMintEndTime;
    uint256 public _preMintEndTime;

    constructor() ERC721("CC0Fighters", "cf") EIP712("CC0Fighters", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _maxSupply = 6969;
        _devReserved = 690;
        _maxMintSupply = _maxSupply - _devReserved;
        _devMintCounter = 0;
        _pubMintCounter = 0;

        _preMintAmount = 0.0069 ether;
        _pubMintAmount = 0.012 ether;
    }

    modifier canMint() {
        require(mintFlag == true, "mint not started or already stopped.");
        _;
    }

    function setMintPrice(uint256 pre, uint256 pub) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _preMintAmount = pre;
        _pubMintAmount = pub;
    }

    function startMint(uint256 startTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFlag = true;

        _startMintTime = startTime;
        _freeMintEndTime = _startMintTime + 2 hours;
        _preMintEndTime = _freeMintEndTime + 2 hours;
    }

    function stopMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFlag = false;
    }

    function pubmint(uint256 amount) public payable canMint nonReentrant {
        require(amount > 0 && amount <= 20, "invalid amount");
        require(block.timestamp > _preMintEndTime, "pub mint not start.");
        require(this.balanceOf(msg.sender) + amount <= 20, "too many already minted.");
        require(_pubMintCounter + amount <= _maxMintSupply, "insufficient mint.");
        uint256 weiAmount = msg.value;
        require(weiAmount == _pubMintAmount.mul(amount), "invalid price");

        _pubMintCounter += amount;
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function premint(uint256 amount) public payable canMint nonReentrant {
        require(amount > 0 && amount <= 3, "invalid amount");
        require(block.timestamp >= _freeMintEndTime, "pre mint not started.");
        require(block.timestamp <= _preMintEndTime, "pre mint end.");
        require(this.balanceOf(msg.sender) + amount <= 3, "too many already minted.");
        require(_pubMintCounter + amount <= _maxMintSupply, "insufficient mint.");
        uint256 weiAmount = msg.value;
        require(weiAmount == _preMintAmount.mul(amount), "invalid price");
        
        _pubMintCounter += amount;
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function freemint(uint8 v, bytes32 r, bytes32 s) public payable canMint nonReentrant {
        require(block.timestamp <= _freeMintEndTime, "free mint end.");
        require(!freeMintLog[msg.sender], "already mint");
        require(_pubMintCounter + 1 <= _maxMintSupply, "insufficient mint.");

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(FREE_MINT_HASH_TYPE, msg.sender)));
        require(ECDSA.recover(digest, v, r, s) == signer, "invalid signer");
        
        _pubMintCounter += 1;
        freeMintLog[msg.sender] = true;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function devmint(uint256 amount) public payable canMint nonReentrant onlyRole(MINTER_ROLE) {
        require(_devMintCounter + amount <= _devReserved, "too many already minted.");

        _devMintCounter += amount;
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function withdraw(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(to).transfer(address(this).balance);
    }

    function changeSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    function _baseURI() internal view override returns (string memory) {
        return _URI;
    }
    
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _URI = uri;
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}