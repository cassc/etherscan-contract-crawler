// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./IERC2981.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721A.sol";
import "./ERC2981.sol";
import "./IERC165.sol";
import "./OperatorFilterer.sol";


contract UnboundPhantomCollection is Ownable, OperatorFilterer, ERC721A, ReentrancyGuard, ERC2981  {
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxSupply = 2025;
    uint256 public publicMax = 5;
    uint256 public maxTotalMintPerWallet = 9;

    uint256 public maxFreeMintEach = 5;
     uint256 public maxMintAmount = 9;
    mapping(address => uint256) private _publicMintCounter;

    bool public operatorFilteringEnabled = true;

    bool public _isPublicMintEnabled = false;
    bool public _isClaimMintEnabled = false;
    bool public _isMinterMintEnabled = false;

    mapping(address => uint8) public _claimMintCounter;
    mapping(address => uint8) public _minterMintCounter;


    bool public isRevealed = false;
    string preRevealedURI= "https://cloudflare-ipfs.com/ipfs/bafkreifqaxc5cmudrbvbvj4clkzi2uebnetw52e4oi2xs2a6chbyjqycla";
    string baseURI="";
    // merkle root
    bytes32 public claimMerkleRoot;
    bytes32 public minterMerkleRoot;
    address public UnboundWallet = 0xb0CA168BeAb12821bb59E4339F4e8430B47fe084;
    address public royaltyReceiver;
    uint256 public royaltyPercentage = 777;
    string private _baseTokenURI;
    


    constructor(string memory name, string memory symbol, address _royaltyReceiver) ERC721A(name, symbol) {
        royaltyReceiver = _royaltyReceiver;
        _setRoyaltyReceiver(_royaltyReceiver);
        _publicMintCounter[msg.sender] = 0;
        _claimMintCounter[msg.sender] = 0;
        _minterMintCounter[msg.sender] = 0;
        _registerForOperatorFiltering();
        _setDefaultRoyalty(UnboundWallet, 777);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setPublicMintEnabled(bool enabled) external onlyOwner {
        _isPublicMintEnabled = enabled;
    }


    function setisClaimMintEnabled(bool isClaimMintEnabled) external onlyOwner {
        _isClaimMintEnabled = isClaimMintEnabled;
    }
    function setisMinterMintEnabled(bool isMinterMintEnabled) external onlyOwner {
        _isMinterMintEnabled = isMinterMintEnabled;
    }

    function setClaimMerkle(bytes32 _merkleRoot) external onlyOwner {
        claimMerkleRoot = _merkleRoot;
    }

    function setMinterMerkle(bytes32 _merkleRoot) external onlyOwner {
        minterMerkleRoot = _merkleRoot;
    }

    
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply > 0 && newMaxSupply >= totalSupply(), "Invalid new maximum supply");
        maxSupply = newMaxSupply;
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function teamMint() external onlyOwner{
 
        _safeMint(msg.sender, 60);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        isRevealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed) {
            return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId_), ".json"));
        }
        else {
            return preRevealedURI;
        }
    }


    function setPreRevealedURI(string memory _preRevealedURI) external onlyOwner {
        preRevealedURI = _preRevealedURI;
    }


// Presale

    function minterClaim(uint8 quantity, bytes32[] calldata _merkleProof) external nonReentrant {
        require(_isMinterMintEnabled, "Whitelist minting is not enabled");
        require(_minterMintCounter[msg.sender] == 0, "You have already minted a token");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, minterMerkleRoot, leaf), "Sorry, not whitelisted");
        require(totalSupply() + quantity <= maxSupply, "Sold out!");

        // Ensure quantity is equal to 3
        require(quantity == 3, "Quantity must be equal to 3");

        _safeMint(msg.sender, quantity);
        _minterMintCounter[msg.sender] += 1;
    }





    function freeClaim(uint8 quantity, bytes32[] calldata _merkleProof) external nonReentrant {
        require(_isClaimMintEnabled, "Free claim is not enabled");
        require(_claimMintCounter[msg.sender] == 0, "You have already claimed a free token");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, claimMerkleRoot, leaf), "Sorry, not whitelisted");
        require(totalSupply() + quantity <= maxSupply, "Sold out!");

        // Ensure quantity is equal to 1
        require(quantity == 1, "Quantity must be equal to 1");

        _safeMint(msg.sender, quantity);
        _claimMintCounter[msg.sender] += quantity;
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }



    modifier SupplyCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= publicMax, "You can only mint 5 for public!!");
        require(totalSupply() + _mintAmount <= maxSupply, "Sold out!");
        require(
        _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
        "You have reached the max mint limit!"
        );
        _;
    }

    modifier SupplyPriceCompliance(uint256 _mintAmount) {
        uint256 realCost = 0;
        
        if (numberMinted(msg.sender) < maxFreeMintEach) {
            uint256 freeMintsLeft = maxFreeMintEach - numberMinted(msg.sender);
            realCost = mintPrice * freeMintsLeft;
        }
   
        require(msg.value >= mintPrice * _mintAmount - realCost, "Insufficient/incorrect funds.");
        _;
    }

function mint(uint256 _mintAmount) public payable SupplyCompliance(_mintAmount) SupplyPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }





  
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 1000, "Invalid royalty percentage");
        royaltyPercentage = _royaltyPercentage;
    }   


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function royaltyInfo(uint256, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * royaltyPercentage) / 10000;
        receiver = royaltyReceiver;
    }


    function _setRoyaltyReceiver(address _royaltyReceiver) internal {
        royaltyReceiver = _royaltyReceiver;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) public onlyOwner {
        _setRoyaltyReceiver(_royaltyReceiver);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(ERC2981).interfaceId
            || super.supportsInterface(interfaceId);
        }   
    }