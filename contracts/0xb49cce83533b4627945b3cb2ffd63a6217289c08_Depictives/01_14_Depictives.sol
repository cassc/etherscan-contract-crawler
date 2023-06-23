//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Depictives
 * @author artist: expfunction (twitter.com/expfunction)
 * @author dev: maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for Depictives NFT by twitter.com/expfunction
 */
contract Depictives is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name,
        string memory symbol) 
        ERC721(
            name,
            symbol
        ) {
            // Start token IDs at 1
            _tokenIds.increment();
        }

    bool public preSaleActive;
    bool public publicSaleActive;
    bool public isSaleHalted;
    bool private ownerSupplyMinted;

    uint16 private constant MAX_SUPPLY = 2048;
    uint16 private constant OWNER_SUPPLY = 50;
    bytes32 public merkleRoot = 0x77ca49bd64f871f31f6d417d2a20095d696362ae03c345bbe310d8f248b873fe;
    
    uint16 private constant APOSTLE_FREE_MINTS = 10;
    uint16 private constant AUGURY_FREE_MINTS = 1;

    uint256 private constant MAX_MULTI_MINT_AMOUNT = 5;
    uint256 public constant PRICE = 0.15 ether;

    uint256 private preSaleLaunchTime = 1640210400;
    uint256 private publicSaleLaunchTime = 1640296800;

    mapping(address => uint16) private apostleHolderMints;
    mapping(address => uint16) private auguryHolderMints;

    mapping(address => bool) private apostleHolders;
    mapping(address => bool) private auguryHolders; 

    address private constant F_ADDRESS = 0xB32b819c70C54e8aCfe24dF78E70D3D828FBA194;
    address private constant M_ADDRESS = 0x180c5E11d2e4844e9EF8D155A69085200Bb38f0b;

    uint16 private constant F_CUT = 90;
    uint16 private constant M_CUT = 10;

    string public baseTokenURI = "https://arweave.net/TBD/";

    function _genMerkleLeaf(address account, uint256 mints) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, mints));
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

    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) external onlyOwner {
        isSaleHalted = _saleHaltedState;
    }

    function setApostleHolders(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            apostleHolderMints[addresses[i]] = APOSTLE_FREE_MINTS;
            apostleHolders[addresses[i]] = true;
        }
    }

    function setAuguryHolders(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            auguryHolderMints[addresses[i]] = AUGURY_FREE_MINTS;
            auguryHolders[addresses[i]] = true;
        }
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

    function _numberOfFreeMints(address addr) internal view returns (uint16) {
        return apostleHolderMints[addr] + auguryHolderMints[addr];
    }

    /**
     * @notice Allow an Apostle holder to mint their free Depictives
     */
    function freeMint() public nonReentrant {
        require(isPreSaleActive() && !isPublicSaleActive(), "SALE_NOT_ACTIVE");
        require(apostleHolderMints[msg.sender] > 0 || auguryHolderMints[msg.sender] > 0, "NOT_APOSTLE_HOLDER_OR_ALREADY_DONE");

        uint16 numberOfFreeMints = _numberOfFreeMints(msg.sender);
        require(totalSupply() + numberOfFreeMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < numberOfFreeMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }

        apostleHolderMints[msg.sender] = 0;
        auguryHolderMints[msg.sender] = 0;
    }

    function mintOwnerSupply(address addr) public nonReentrant onlyOwner {
        require(!ownerSupplyMinted, "OWNER_MINT_COMPLETED");
        require(totalSupply() + OWNER_SUPPLY <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        for (uint256 i = 0; i < OWNER_SUPPLY; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(addr, tokenId);
            _tokenIds.increment();
        }

        ownerSupplyMinted = true;
    }

    /**
     * @notice Allow public to bulk mint tokens
     */
    function mint(uint256 numberOfMints, bytes memory data) public payable nonReentrant {
        require(
            apostleHolderMints[msg.sender] == 0 && 
            auguryHolderMints[msg.sender] == 0,
            "FREE_CLAIM_AVAILABLE"
        );

        if (isPreSaleActive() && !isPublicSaleActive()) {
            require(data.length != 0, "NOT_PRESALE_ELIGIBLE");
            (address addr, uint256 mintAllocation, bytes32[] memory proof) = abi.decode(data, (address, uint256, bytes32[]));
            require(MerkleProof.verify(proof, merkleRoot, _genMerkleLeaf(msg.sender, mintAllocation)), "INVALID_PROOF");
            require(addr == msg.sender, "INVALID_SENDER");
            require(numberOfMints + balanceOf(msg.sender) <= mintAllocation, "PRESALE_LIMIT_REACHED");
        } else {
            require(isPublicSaleActive(), "SALE_NOT_ACTIVE");
            require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "TOO_LARGE_PER_TX");
        }

        require(totalSupply() + numberOfMints <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");

        require(msg.value >= PRICE * numberOfMints, "INVALID_PRICE");
        
        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }
    }

    function withdrawProceeds() external onlyOwner nonReentrant {
        uint256 value = address(this).balance;
        uint256 fPayout = (value * F_CUT) / 100;
        uint256 mPayout = (value * M_CUT) / 100;

        payable(F_ADDRESS).transfer(fPayout);
        payable(M_ADDRESS).transfer(mPayout);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() - 1;
    }
}