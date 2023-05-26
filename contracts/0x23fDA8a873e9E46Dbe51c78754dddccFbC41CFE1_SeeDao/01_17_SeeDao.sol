// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract SeeDao is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    
    IERC721 public v3Token;
    IERC721 public sdToken;
    IERC20 public rally;
    IERC20 public bank;
    IERC20 public fwb;
    IERC20 public ff;
    

    string public baseTokenURI;

    uint256 public singlePrice;
    uint256 public migrateLimit = 72;
    uint256 public limit = 150;
    uint256 public supply = 150;
    uint256 public totalLimit = 10000;

    uint256 public bankBalance = 2000000000000000000000;
    uint256 public rallyBalance = 400000000000000000000;
    uint256 public fwbBalance = 2000000000000000000;
    uint256 public ffBalance = 50000000000000000000;
    uint256 public payGas = 20000000000000000;
    
    bool public onSale;
    bool public ogMint;
    bool public onClaim;
    bool public onMigrate;

    mapping (uint256 => bool) public claimed;
    mapping (address => bool) public daoClaimed;
    mapping (uint256 => bytes32) public roots;
    mapping (uint256 => mapping(address => bool)) public minted;
    mapping (uint256 => bool) public migrated;
    mapping (address => uint256) public approvedAmount;
    mapping (address => bool) public approvedContract;

    constructor(address token, address sdAddr, address rallyAddr, address bankAddr, address fwbAddr, address ffAddr) ERC721("SeeDao", "SEED") {
        v3Token = IERC721(token);
        sdToken = IERC721(sdAddr);
        rally = IERC20(rallyAddr);
        bank = IERC20(bankAddr);
        fwb = IERC20(fwbAddr);
        ff = IERC20(ffAddr);
    }

    /** mint */
    function _mintSeed(uint256 num, address to) internal {
        require(totalSupply() + num <= totalLimit, "exceed limit");
        for(uint256 i = 0; i < num; i++) {
            uint256 tokenIndex = totalSupply();
            _safeMint(to, tokenIndex);
        }
    }
    
    // mint for sale
    function mint(uint256 num) external payable nonReentrant {
        require(!msg.sender.isContract(), "contract not allowed");
        require(onSale, "not on sale");
        uint256 totalPrice = num.mul(singlePrice);
        require(msg.value >= totalPrice, "wrong ether value");
        _mintSeed(num, msg.sender);
    }

    // claim for OG
    function claim(uint256 tokenId) public nonReentrant {
        require(!msg.sender.isContract(), "contract not allowed");
        require(ogMint, "not on claim");
        require(v3Token.ownerOf(tokenId) == msg.sender, "not owner");
        require(!claimed[tokenId], "already claimed");
        _mintSeed(1, msg.sender);
        claimed[tokenId] = true;
    }

    // claim for dao holder
    function claimDAO() public nonReentrant {
        require(!msg.sender.isContract(), "contract not allowed");
        require(onClaim, "not on claim");
        require(
            rally.balanceOf(msg.sender) >= rallyBalance || 
            bank.balanceOf(msg.sender) >= bankBalance ||
            fwb.balanceOf(msg.sender) >= fwbBalance ||
            ff.balanceOf(msg.sender) >= ffBalance,
            "low balance"
        );
        require(!daoClaimed[msg.sender], "already claimed");
        require(limit > 0, "out of supply");
        limit = limit.sub(1);
        daoClaimed[msg.sender] = true;
        _mintSeed(1, msg.sender);
    }

    // mint for whitelist
    function mintWhiteList(uint256 id, bytes32[] calldata proof) external nonReentrant {
        require(!minted[id][msg.sender], "already minted");
        require(supply > 0, "out of supply");
        require(
            MerkleProof.verify(
                proof, roots[id], keccak256(abi.encodePacked(msg.sender))
            ), 
            "invalid proof");
        supply = supply.sub(1);
        minted[id][msg.sender] = true;
        _mintSeed(1, msg.sender);
    }

    function migrate(uint256 id, uint256 vId) external nonReentrant {
        require(id < migrateLimit, "out of range");
        require(onMigrate, "not on migrate");
        require(!msg.sender.isContract(), "contract not allowed");
        require(sdToken.ownerOf(id) == msg.sender && v3Token.ownerOf(vId) == msg.sender, "not owner");
        require(!migrated[id] && !claimed[vId], "already migrated or claimed");
        _mintSeed(1, msg.sender);
        migrated[id] = true;
        claimed[vId] = true;
        (bool success, ) = msg.sender.call{value: payGas}("");
        require(success, "refund failed");
    }

    function verifyWhiteList(uint256 id, address user, bytes32[] calldata proof) external view returns (bool) {
        return MerkleProof.verify(proof, roots[id], keccak256(abi.encodePacked(user)));
    }

    function approvedMint(address to, uint256 num) external nonReentrant {
        require(approvedContract[msg.sender], "not approved");
        require(num <= approvedAmount[msg.sender], "out of amount");
        approvedAmount[msg.sender] = approvedAmount[msg.sender].sub(num);
        _mintSeed(num, to);
    }

    /** admin method */
    function addContract(address plat, uint256 n) external onlyOwner {
        require(plat.isContract(), "not contract");
        require(!approvedContract[plat], "already approved");
        approvedContract[plat] = true;
        approvedAmount[plat] = n;
    }

    function removeApproved(address plat) external onlyOwner {
        require(approvedContract[plat], "not approved");
        approvedContract[plat] = false;
    }

    function getApprovedAmount(address plat) external view returns (uint256) {
        return approvedAmount[plat];
    }

    function giveAway(address to, uint256 num) public onlyOwner {
        _mintSeed(num, to);
    }

    /** setter */
    function setPrice(uint256 price) public onlyOwner {
        singlePrice = price;
    }

    function setRoot(uint256 id, bytes32 root) public onlyOwner {
        roots[id] = root;
    }

    /** flips */
    function pauseOG() public onlyOwner {
        require(ogMint, "already paused");
        ogMint = false;
    }

    function unpauseOG() public onlyOwner {
        require(!ogMint, "already unpaused");
        ogMint = true;
    }

    function pauseSale() public onlyOwner {
        require(onSale, "already paused");
        onSale = false;
    }

    function unpauseSale() public onlyOwner {
        require(!onSale, "already unpaused");
        onSale = true;
    }

    function pauseClaim() public onlyOwner {
        require(onClaim, "already paused");
        onClaim = false;
    }

    function unpauseClaim() public onlyOwner {
        require(!onClaim, "already unpaused");
        onClaim = true;
    }

    function pauseMigrate() public onlyOwner {
        require(onMigrate, "already paused");
        onMigrate = false;
    }

    function unpauseMigrate() public onlyOwner {
        require(!onMigrate, "already unpaused");
        onMigrate = true;
    }

    /** URI */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    receive() external payable {}
    
    function withdraw() public onlyOwner {
        uint256 val = address(this).balance;
        payable(owner()).transfer(val);
    }
}