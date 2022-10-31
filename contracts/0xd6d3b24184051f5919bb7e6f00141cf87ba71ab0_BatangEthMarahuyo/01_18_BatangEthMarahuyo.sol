// SPDX-License-Identifier: MIT
//*********************************************************************//
//*********************************************************************//
//
//  ________  ________  _________  ________  ________   ________          _______  _________  ___  ___     
// |\   __  \|\   __  \|\___   ___\\   __  \|\   ___  \|\   ____\        |\  ___ \|\___   ___\\  \|\  \    
// \ \  \|\ /\ \  \|\  \|___ \  \_\ \  \|\  \ \  \\ \  \ \  \___|        \ \   __/\|___ \  \_\ \  \\\  \   
//  \ \   __  \ \   __  \   \ \  \ \ \   __  \ \  \\ \  \ \  \  ___       \ \  \_|/__  \ \  \ \ \   __  \  
//   \ \  \|\  \ \  \ \  \   \ \  \ \ \  \ \  \ \  \\ \  \ \  \|\  \       \ \  \_|\ \  \ \  \ \ \  \ \  \ 
//    \ \_______\ \__\ \__\   \ \__\ \ \__\ \__\ \__\\ \__\ \_______\       \ \_______\  \ \__\ \ \__\ \__\
//     \|_______|\|__|\|__|    \|__|  \|__|\|__|\|__| \|__|\|_______|        \|_______|   \|__|  \|__|\|__|
//                                                                                                         
//                                                                                                         
//                                                                                                         
//
//*********************************************************************//
//*********************************************************************//
// dev: [email protected] (@CrioxIO)
// git: https://github.com/criox-io
//    _   _   _   _   _   _   _   _  
//   / \ / \ / \ / \ / \ / \ / \ / \ 
//  ( c | r | i | o | x | . | i | o )
//   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ 
pragma solidity ^0.8.17;

import "./ERC721A/ERC721A.sol";
import "./ContractWithdrawable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract BETHMarahuyoAbstract is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    ContractWithdrawable
{
    IERC721 Gen1Collection;
    IERC20 mintingToken;

    uint256 _batchSize = 0;
    uint256 _collectionSize = 0;
    uint256 public unitPriceBarya = 500 ether; // 500 $BARYA
    uint256 public unitPriceEth = 10000000000000000; // 0.010 ether
    uint256 public unitPriceEthPublic = 15000000000000000; // 0.015 ether
    // allocations
    uint256 public allocationEthMint; // 1300
    uint256 public allocationBryMint; // 800
    uint256 public allocationAdminMint; // 122
    uint256 public prePublicMintGap = 3600; // 1 hour
    uint256 public startOfPublicMintingTime;
    uint256 public preRevealImageGap = 172800;
    uint256 public startOfRevealedTime;

    bytes32 public _merkleRoot;
    address public purgatory;
    mapping(address => bool) allowedAdminMinters;
    mapping(address => bool) prePublicMinted;
    mapping(address => bool) publicMinted;

    bool public isEthMintingEnabled = false;
    bool public isPaused = true;
    string _baseTokenURI = "";
    string _hiddenMetadataUri = "";

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory hiddenMetadataUri,
        uint256 collectionSize,
        uint256 batchSize,
        uint256 _allocationEthMint,
        uint256 _allocationBryMint,
        uint256 _allocationAdminMint,
        uint256 _prePublicMintGap,
        bytes32 merkleRoot
    ) ERC721A(name, symbol, batchSize, collectionSize) {
        _baseTokenURI = baseTokenURI;
        _hiddenMetadataUri = hiddenMetadataUri;
        _collectionSize = collectionSize;
        allocationEthMint = _allocationEthMint;
        allocationBryMint = _allocationBryMint;
        allocationAdminMint = _allocationAdminMint;
        prePublicMintGap = _prePublicMintGap;
        _merkleRoot = merkleRoot;

        require(
            _collectionSize ==
                allocationAdminMint + allocationBryMint + allocationEthMint,
            "Allocation size mismatch"
        );
        allowedAdminMinters[msg.sender] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseUri(string memory baseUri) public onlyOwner {
        _baseTokenURI = baseUri;
    }

    function setErc20(IERC20 token) public onlyOwner {
        mintingToken = token;
    }

    function setGen1(IERC721 collection) public onlyOwner {
        Gen1Collection = collection;
    }

    function setBaryaPrice(uint256 baryaPrice) public onlyOwner {
        unitPriceBarya = baryaPrice;
    }

    function setEthPrice(uint256 ethPrice) public onlyOwner {
        unitPriceEth = ethPrice;
    }

    function setEthPricePublic(uint256 ethPrice) public onlyOwner {
        unitPriceEthPublic = ethPrice;
    }

    function setPaused(bool isPausedFlag) public onlyOwner {
        isPaused = isPausedFlag;
    }

    function startEthMinting() public onlyOwner {
        isPaused = false;
        isEthMintingEnabled = true;
        startOfPublicMintingTime = block.timestamp + prePublicMintGap;
        startOfRevealedTime = block.timestamp + preRevealImageGap;
    }

    function setMerkleRoot(bytes32 merkleRoot) public onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setAdminMinter(address wallet, bool isAllowed) public onlyOwner {
        allowedAdminMinters[wallet] = isAllowed;
    }

    function setPurgatory(address _purgatory) public onlyOwner {
        purgatory = _purgatory;
    }

    function setStartOfPublicMintingTime(uint256 _startPublicMintTime) public onlyOwner {
        startOfPublicMintingTime = _startPublicMintTime;
    }

    function setStartOfRevealTime(uint256 _startRevealTime) public onlyOwner {
        startOfRevealedTime = _startRevealTime;
    }

    modifier mintPreChecks(uint256 mintAmount) {
        require(!isPaused, "Minting is paused");
        require(
            _totalMinted() + mintAmount <= collectionSize,
            "Not enough supply"
        );
        _;
    }

    modifier onlyAllowedAdminMinters() {
        require(allowedAdminMinters[msg.sender], "e-101");
        _;
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function verifyProof(bytes32[] calldata merkleProof, address wallet)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(merkleProof, _merkleRoot, toBytes32(wallet));
    }

    // mint:eth:WL
    function mintWhitelist(bytes32[] calldata merkleProof, uint256 amount)
        public
        payable
        nonReentrant
    {
        require(amount > 0, "e-102");
        require(amount < 6, "e-103");
        require(
            block.timestamp < startOfPublicMintingTime,
            "e-104"
        );
        require(!prePublicMinted[msg.sender], "e-105");
        require(
            MerkleProof.verify(
                merkleProof,
                _merkleRoot,
                toBytes32(msg.sender)
            ) == true,
            "e-106"
        );
        _mintMultipleWithEth(amount, unitPriceEth);
        prePublicMinted[msg.sender] = true;
    }

    // mint:eth:gen1
    function mintGen1Holder(uint256 amount) public payable nonReentrant {
        require(amount > 0, "e-102");
        require(amount < 6, "e-103");
        require(
            block.timestamp < startOfPublicMintingTime,
            "e-104"
        );
        require(!prePublicMinted[msg.sender], "e-105");
        require(
            Gen1Collection.balanceOf(msg.sender) > 0,
            "e-107"
        );
        _mintMultipleWithEth(amount, unitPriceEth);
        prePublicMinted[msg.sender] = true;
    }

    // mint:eth:public
    function mintPublic(uint256 amount) public payable nonReentrant {
        require(amount > 0, "e-102");
        require(amount < 6, "e-103");
        require(
            block.timestamp > startOfPublicMintingTime,
            "e-108"
        );
        require(!publicMinted[msg.sender], "e-109");

        _mintMultipleWithEth(amount, unitPriceEthPublic);
        publicMinted[msg.sender] = true;
    }

    function _mintMultipleWithEth(uint256 amount, uint256 unitPrice)
        private
        mintPreChecks(amount)
    {
        require(isEthMintingEnabled, "e-110");
        require(allocationEthMint >= amount, "e-111");
        require(
            msg.value >= unitPrice * amount,
            "e-112"
        );
        _safeMint(msg.sender, amount, false);
        allocationEthMint -= amount;
    }

    function mintMultipleWithBarya(uint256 amount)
        public
        mintPreChecks(amount)
        nonReentrant
    {
        require(amount > 0, "e-102");
        require(
            block.timestamp > startOfPublicMintingTime,
            "e-108"
        );
        require(allocationBryMint >= amount, "e-113");
        require(
            mintingToken.balanceOf(msg.sender) >= unitPriceBarya * amount,
            "e-114"
        );
        require(
            mintingToken.allowance(msg.sender, address(this)) >=
                unitPriceBarya * amount,
            "mintMultipleWithBarya: Not enough allowance"
        );

        SafeERC20.safeTransferFrom(
            mintingToken,
            msg.sender,
            address(this),
            unitPriceBarya * amount
        );

        _safeMint(msg.sender, amount, false);
        allocationBryMint -= amount;
    }

    function mintAdmin(uint256 amount)
        public
        onlyAllowedAdminMinters
        nonReentrant
    {
        require(amount > 0, "e-102");
        require(allocationAdminMint >= amount, "e-116");
        _safeMint(msg.sender, amount, false);
        allocationAdminMint -= amount;
    }

    function mintAdminTo(uint256 amount, address wallet)
        public
        onlyAllowedAdminMinters
        nonReentrant
    {
        require(allocationAdminMint >= amount, "Not enough allocation:ADMIN");
        _safeMint(wallet, amount, false);
        allocationAdminMint -= amount;
    }

    function allocateETH2BRY(uint256 amount) public onlyOwner {
        require(allocationEthMint >= amount, "e-117");
        allocationEthMint -= amount;
        allocationBryMint += amount;
    }

    function allocateBRY2ETH(uint256 amount) public onlyOwner {
        require(allocationBryMint >= amount, "e-118");
        allocationBryMint -= amount;
        allocationEthMint += amount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (block.timestamp < startOfRevealedTime) {
            return _hiddenMetadataUri;
        } else {
            return ERC721A.tokenURI(tokenId);
        }
    }

    function burn(uint256 tokenId) public {
        require(purgatory != address(0), "Purgatory not set");
        transferFrom(msg.sender, purgatory, tokenId);
    }
}

contract BatangEthMarahuyo is BETHMarahuyoAbstract {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory hiddenMetadataUri,
        uint256 collectionSize,
        uint256 batchSize,
        uint256 allocationEthMint,
        uint256 allocationBryMint,
        uint256 allocationAdminMint,
        uint256 prePublicMintGap,
        bytes32 merkleRoot
    )
        BETHMarahuyoAbstract(
            name,
            symbol,
            baseTokenURI,
            hiddenMetadataUri,
            collectionSize,
            batchSize,
            allocationEthMint,
            allocationBryMint,
            allocationAdminMint,
            prePublicMintGap,
            merkleRoot
        )
    {}
}