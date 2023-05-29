//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./ITokenDataProvider.sol";

contract ScuffedFemboys is ERC721Enumerable, Ownable, ReentrancyGuard, ERC2981  {

    address public tokenDataProvider;
    uint256 public tokenIdStartFrom = 1;

    // Mint params
    bool public mintStatus = false;

    address public saleReceiver; // sale receiver is also the royalty receiver
    uint256 public buyPrice = 0.04 ether;
    uint256 public maxScuffies4Sale;
    uint256 public scuffiesSold = 0;

    uint256 public maxScuffies4Claim;
    uint256 public scuffiesClaimed = 0;
    uint256 public scuffiesClaimCount = 2;
    bytes32 public claimRoot;
    mapping(address => bool) public claimedAddresses;

    constructor(string memory name_, string memory symbol_, uint256 maxSupplySale, uint256 maxSupplyClaim, address saleReceiver_, address tokenDataProvider_) Ownable() ERC721(name_, symbol_) {
        maxScuffies4Sale = maxSupplySale;
        maxScuffies4Claim = maxSupplyClaim;
        saleReceiver = saleReceiver_;
        _setDefaultRoyalty(saleReceiver, 400); // 4%
        tokenDataProvider = tokenDataProvider_;
    }

    modifier mintStarted() {
        require(mintStatus == true, "Mint has not started");
        _;
    }
    
    function setMintingStatus(bool mintStatus_) public onlyOwner {
        mintStatus = mintStatus_;
    }
    
    function setDefaultRoyalty(address saleReceiver_, uint96 feeNumerator) public onlyOwner {
        saleReceiver = saleReceiver_;
        _setDefaultRoyalty(saleReceiver, feeNumerator);
    }

    function setTokenDataProvider(address tokenDataProvider_) public onlyOwner {
        tokenDataProvider = tokenDataProvider_;
    }

    // Overwrite
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return ITokenDataProvider(tokenDataProvider).tokenURI(tokenId);
    }
    
    function setClaimRoot(bytes32 newClaimRoot) public onlyOwner {
        claimRoot = newClaimRoot;
    }

    function maxSupply() public view virtual returns (uint256) {
        return maxScuffies4Sale + maxScuffies4Claim;
    }
    
    function alreadyClaimed(address claimer) public view virtual returns (bool) {
        return claimedAddresses[claimer];
    }

    // Claim free pair
    function claim(bytes32[] calldata _merkleProof) external nonReentrant mintStarted {
        require(alreadyClaimed(msg.sender) == false, "Claimed already");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, claimRoot, leaf), "Incorrect proof");
        require(scuffiesClaimed + scuffiesClaimCount <= maxScuffies4Claim, "Not enough left to claim");

        scuffiesClaimed += scuffiesClaimCount;
        claimedAddresses[msg.sender] = true;

        uint supply = totalSupply();
        for (uint256 i = 0; i < scuffiesClaimCount; i++) {
            _safeMint(msg.sender, tokenIdStartFrom + supply + i);
        }
    }

    // Buy 1-100
    function buy(uint256 count) external nonReentrant mintStarted payable  {
        require(count > 0, "Cannot mint 0");
        require(count <= 100, "What are you doing");
        require(scuffiesSold + count <= maxScuffies4Sale, "Not enough left for sale");
        require(msg.value == count * buyPrice, "Wrong ETH sum sent");
        
        scuffiesSold += count;

        uint supply = totalSupply();
        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, tokenIdStartFrom + supply + i);
        }
    }

    function withdrawETH() external /* onlyOwner */ {
        payable(saleReceiver).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}