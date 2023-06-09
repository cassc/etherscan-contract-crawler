//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/INOwnerResolver.sol";
import "./interfaces/IGmDaoRarible.sol";
import "./interfaces/IGmDao.sol";


/**
  ██████╗░░█████╗░████████╗██╗███████╗███╗░░██╗░█████╗░███████╗
  ██╔══██╗██╔══██╗╚══██╔══╝██║██╔════╝████╗░██║██╔══██╗██╔════╝
  ██████╔╝███████║░░░██║░░░██║█████╗░░██╔██╗██║██║░░╚═╝█████╗░░
  ██╔═══╝░██╔══██║░░░██║░░░██║██╔══╝░░██║╚████║██║░░██╗██╔══╝░░
  ██║░░░░░██║░░██║░░░██║░░░██║███████╗██║░╚███║╚█████╔╝███████╗
  ╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚═╝╚══════╝╚═╝░░╚══╝░╚════╝░╚══════╝
 * @title Patience
 * @notice This contract provides minting for the Patience NFT by twitter.com/giorgiobalbi
 * @notice Dev: https://twitter.com/maximonee_
 */
contract Patience is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol,
        address nOwnerResolver_,
        address gmDaoRarible_,
        address gmDao_
        ) 
        ERC721A(
            name,
            symbol
        ) {
            nOwnerResolver = INOwnerResolver(nOwnerResolver_);
            gmDaoRarible = IGmDaoRarible(gmDaoRarible_);
            gmDao = IGmDao(gmDao_);
        }

    enum PreSaleType {
        N,
        GM,
        AL,
        None
    }

    bool public preSaleActive;
    bool public publicSaleActive;
    bool public isSaleHalted;

    uint16 public constant MAX_SUPPLY = 1000;
    uint16 private constant PSVC_SUPPLY = 500;
    uint16 private constant MAX_PRESALE_MINTS = 2;
    uint16 private constant BASIS_POINTS = 1000;

    uint256 private constant PRESALE_GROUPS_ALLOCATION = 100;
    uint256 private constant PRESALE_AL_ALLOCATION = 300;

    bytes32 public merkleRoot = 0x62abf22a86b3fb6933d6c7663f60611a573f6f04f8323beeab582c4ca59e00fa;

    uint256 public constant MINT_PRICE = 0.15 ether;

    uint256 private maxMintPerTx = 3;
    uint256 private maxMintPerWallet = 3;
    uint256 private gmDaoTokenId = 706480;

    uint256 private preSaleLaunchTime = 1652637600;
    uint256 private publicSaleLaunchTime = 1652724000;
    uint256 public psvcMints;

    mapping (address => uint256) private mintsTracker;
    mapping (address => uint256) private freeMintsTracker;
    mapping (PreSaleType => uint256) public presaleLimits;

    address[] private payouts = [
        0xF882c6f07A0Cf48CFb181e23fD1780299d13b633, // D
        0x97631BE4AC73Ef6042494FfdEbA4Bb1d70a23404 // A
    ];

    uint16[] private cuts = [
        250,
        750
    ];

    INOwnerResolver public immutable nOwnerResolver;
    IGmDaoRarible public immutable gmDaoRarible;
    IGmDao public immutable gmDao;

    string public baseTokenURI = "https://arweave.net/TBD/";

    function _genMerkleLeaf(address account, uint256 preSaleMints, uint256 freeMints) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, preSaleMints, freeMints));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPreSaleState(bool _preSaleActiveState) external onlyOwner {
        preSaleActive = _preSaleActiveState;
    }

    function setPublicSaleState(bool _publicSaleActiveState) external onlyOwner {
        publicSaleActive = _publicSaleActiveState;
    }

    function setPreSaleTime(uint32 _time) external onlyOwner {
        preSaleLaunchTime = _time;
    }

    function setPublicSaleTime(uint32 _time) external onlyOwner {
        publicSaleLaunchTime = _time;
    }

    function setMaxMintPerWallet(uint256 _amount) external onlyOwner {
        maxMintPerWallet = _amount;
    }

    function setMaxMintPerTx(uint256 _amount) external onlyOwner {
        maxMintPerTx = _amount;
    }

    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) external onlyOwner {
        isSaleHalted = _saleHaltedState;
    }

    function isPreSaleActive() public view returns (bool) {
        return ((block.timestamp >= preSaleLaunchTime || preSaleActive) && !isSaleHalted);
    }

    function isPublicSaleActive() public view returns (bool) {
        return ((block.timestamp >= publicSaleLaunchTime || publicSaleActive) && !isSaleHalted);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _canMintPresale(address wallet, uint256 amount, bytes memory data) internal view returns (bool, PreSaleType) {
        if (isPublicSaleActive()) {
            return (false, PreSaleType.None);
        }

        require(isPreSaleActive(), "SALE_NOT_ACTIVE");

        if (data.length > 0) {
            (address addr, uint256 preSaleMints, uint256 freeMints, bytes32[] memory proof) = abi.decode(data, (address, uint256, uint256, bytes32[]));
            require(MerkleProof.verify(proof, merkleRoot, _genMerkleLeaf(msg.sender, preSaleMints, freeMints)), "INVALID_PROOF");
            require(addr == wallet, "INVALID_SENDER");
            require(amount + mintsTracker[wallet] <= preSaleMints, "PRESALE_LIMIT_REACHED");

            if (preSaleMints > 0 && (mintsTracker[wallet] + amount <= preSaleMints)) {
                require(presaleLimits[PreSaleType.AL] + amount <= PRESALE_AL_ALLOCATION, "PRESALE_CATEGORY_REACHED");
                return (true, PreSaleType.AL);
            }
        }

        if (nOwnerResolver.balanceOf(wallet) > 0) {
            require(presaleLimits[PreSaleType.N] + amount <= PRESALE_GROUPS_ALLOCATION, "PRESALE_CATEGORY_REACHED");
            return (true, PreSaleType.N);
        }

        if (gmDaoRarible.balanceOf(wallet, gmDaoTokenId) > 0 || gmDao.balanceOf(wallet) > 0) {
            require(presaleLimits[PreSaleType.GM] + amount <= PRESALE_GROUPS_ALLOCATION, "PRESALE_CATEGORY_REACHED");
            return (true, PreSaleType.GM);
        }

        return (false, PreSaleType.None);
    }

    /**
    Free mint for psvc holders
     */
    function freeMint(bytes memory data) public nonReentrant {
        require(isPreSaleActive() && !isPublicSaleActive(), "SALE_NOT_ACTIVE");
        require(data.length != 0, "NOT_FREE_MINT_ELIGIBLE");

        (address addr, uint256 preSaleMints, uint256 freeMints, bytes32[] memory proof) = abi.decode(data, (address, uint256, uint256, bytes32[]));
        require(MerkleProof.verify(proof, merkleRoot, _genMerkleLeaf(msg.sender, preSaleMints, freeMints)), "INVALID_PROOF");
        require(addr == msg.sender, "INVALID_SENDER");

        require(freeMints + psvcMints <= PSVC_SUPPLY, "PSVC_MINT_CAPACITY");
        require(totalSupply() + freeMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        require(freeMints + freeMintsTracker[msg.sender] <= freeMints, "PRESALE_LIMIT_REACHED");

        _safeMint(msg.sender, freeMints);
        freeMintsTracker[msg.sender] += freeMints;
        psvcMints += freeMints;
    }

    function mint(uint256 numberOfMints, bytes memory data) public payable nonReentrant {
        (bool preSaleEligible, PreSaleType presaleType) = _canMintPresale(msg.sender, numberOfMints, data);
        if (isPreSaleActive() && !isPublicSaleActive()) {
            require(preSaleEligible, "NOT_PRESALE_ELIGIBLE");
            require(numberOfMints + mintsTracker[msg.sender] <= MAX_PRESALE_MINTS, "PRESALE_LIMIT_REACHED");
        } else {
            require(isPublicSaleActive(), "SALE_NOT_ACTIVE");
            require(numberOfMints <= maxMintPerTx, "TOO_LARGE_PER_TX");
            require(numberOfMints + mintsTracker[msg.sender] <= maxMintPerWallet, "TOO_LARGE_PER_WALLET");
        }

        require(msg.sender == tx.origin, "NO_CONTRACTS");
        require(totalSupply() + numberOfMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        require(numberOfMints * MINT_PRICE == msg.value, "INVALID_PRICE");

        _safeMint(msg.sender, numberOfMints);
        mintsTracker[msg.sender] += numberOfMints;

        if (preSaleEligible && (isPreSaleActive() && !isPublicSaleActive())) {
            presaleLimits[presaleType] += numberOfMints;
        }
    }

    function withdrawProceeds() external onlyOwner nonReentrant {
        uint256 value = address(this).balance;
        for (uint256 i = 0; i < payouts.length; i++) {
            uint256 payout = (value * cuts[i]) / BASIS_POINTS;
            payable(payouts[i]).transfer(payout);
        }
    }
}