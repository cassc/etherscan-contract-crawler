// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract wereWulfz is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    string private baseTokenURI;

    bytes32 internal whitelistMerkleRootTier1;
    bytes32 internal whitelistMerkleRootTier2;

    uint256 public totalMaxSupply = 2222;
    uint256 public price = 0.025 ether;
    uint256 public maxFreeTier1 = 1;
    uint256 public maxMintTier1 = 2; // 1 free 1 paid (optional)
    uint256 public maxFreeTier2 = 2;
    uint256 public maxMintTier2 = 3; // 2 free 1 paid (optional)
    uint256 public maxPerPublicSale = 2;
    uint256 public reservedAmount = 100;

    bool public presaleActive = true;
    bool public publicSaleActive = false;
    bool public burnActive = false;

    mapping (address => uint256) public walletNumberMintedTierSale1;
    mapping (address => uint256) public walletNumberMintedTierSale2;

    constructor() ERC721A("WereWulfz", "WW") {
    }

    //modifiers
    //checks WL eligibility
    modifier isValidMerkleProofTier1(bytes32[] calldata merkleProof) {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRootTier1, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in Tier 1 list");
        _;
    }

    modifier isValidMerkleProofTier2(bytes32[] calldata merkleProof) {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRootTier2, keccak256(abi.encodePacked(msg.sender))), "Address does not exist in Tier 2 list");
        _;
    }

    //main minting functions

    function tier1Mint(bytes32[] calldata _merkleProof, uint256 _count) public nonReentrant isValidMerkleProofTier1(_merkleProof) payable {
        require(presaleActive, "Presale: not active");
        uint256 mintCount = walletNumberMintedTierSale1[msg.sender].add(_count);
        require(_count > 0, "Cannot mint 0");
        require(mintCount <= maxMintTier1, "Purchase would exceed max number of mints allocated");
        require(totalSupply().add(_count) <= totalMaxSupply - reservedAmount, "Mintable: supply exceeded"); 
        if (mintCount > maxFreeTier1) {
            uint256 numEthMint = mintCount - maxFreeTier1;
            require(price.mul(numEthMint) <= msg.value, "Value sent not correct");
        }
        _safeMint(msg.sender, _count);
        walletNumberMintedTierSale1[msg.sender] += _count;
    }

    function tier2Mint(bytes32[] calldata _merkleProof, uint256 _count) public nonReentrant isValidMerkleProofTier2(_merkleProof) payable {
        require(presaleActive, "Presale: not active");
        uint256 mintCount = walletNumberMintedTierSale2[msg.sender].add(_count);
        require(_count > 0, "Cannot mint 0");
        require(mintCount <= maxMintTier2, "Purchase would exceed max number of mints allocated");
        require(totalSupply().add(_count) <= totalMaxSupply - reservedAmount, "Mintable: supply exceeded"); 
        if (mintCount > maxFreeTier2) {
            uint256 numEthMint = mintCount - maxFreeTier2;
            require(price.mul(numEthMint) <= msg.value, "Value sent not correct");
        }
        _safeMint(msg.sender, _count);
        walletNumberMintedTierSale2[msg.sender] += _count;
    }

   function publicMint(uint256 _count) public nonReentrant payable {
        require(publicSaleActive, "Mint: not active");
        require(_count > 0 && _count <= maxPerPublicSale, "Invalid purchase amount");
        require(totalSupply().add(_count) <= totalMaxSupply - reservedAmount, "Mintable: supply exceeded");
        require(price.mul(_count) <= msg.value, "Value sent not correct");
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, _count);
    }

    function mintTeam(uint256 _count) external onlyOwner {
        require(totalSupply().add(_count) <= totalMaxSupply, "Supply exceeded"); 
        require(reservedAmount > 0, "Exceeds team allocation");

        _safeMint(msg.sender, _count);

        reservedAmount -= _count;
    }

    function mintRemaining() external onlyOwner {
        uint256 remainingSupply = totalMaxSupply - reservedAmount; // don't count the amount left to be minted for team
        require(totalSupply().add(remainingSupply) <= totalMaxSupply - reservedAmount, "Supply exceed"); 
        require(remainingSupply > 0, "No more supply");

        _safeMint(msg.sender, remainingSupply); 
    }

    //failsafes
    /* Value to be given in gwei (18 decimals) */
    function adjustPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function adjustSupply(uint256 newSupply) external onlyOwner {
        require(newSupply >= (reservedAmount + totalSupply()), "Invalid new supply");
        totalMaxSupply = newSupply;
    }

    function adjustMaxPerPublicSale(uint256 newCap) external onlyOwner {
        maxPerPublicSale = newCap;
    }

    function adjustMaxMintsTier1(uint256 newCap) external onlyOwner {
        maxMintTier1 = newCap;
    }

    function adjustMaxMintsTier2(uint256 newCap) external onlyOwner {
        maxMintTier2 = newCap;
    }

    function adjustNumFreeTier1(uint256 newCap) external onlyOwner {
        require(newCap <= maxMintTier1, "cannot be more than Max number of Mints for Tier 1");
        maxFreeTier1 = newCap;
    }

    function adjustNumFreeTier2(uint256 newCap) external onlyOwner {
        require(newCap <= maxMintTier2, "cannot be more than Max number of Mints for Tier 2");
        maxFreeTier2 = newCap;
    }

    function adjustAmtReserved(uint256 newAmount) external onlyOwner {
        reservedAmount = newAmount;
    }

    //burn tokens
    function burn(uint256 tokenId) external {
        require(burnActive, "burning not active");
        _burn(tokenId, true);
    }

    //toggling of functions
    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleBurn() public onlyOwner {
        burnActive = !burnActive;
    }

    //metadata functions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    //whitelist merkle root
    function setMerkleRootTier1(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRootTier1 = _merkleRoot;
    }

    function setMerkleRootTier2(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRootTier2 = _merkleRoot;
    }

    // check if user is whitelisted
    function isTier1(address user, bytes32[] calldata merkleProof) external view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRootTier1, keccak256(abi.encodePacked(user)));
    }

    function isTier2(address user, bytes32[] calldata merkleProof) external view returns (bool) {
        return MerkleProof.verify(merkleProof, whitelistMerkleRootTier2, keccak256(abi.encodePacked(user)));
    }

    //withdrawal 
    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}