// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


pragma solidity ^0.8.0;

contract THESAUDISHIBAS is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    string public provenanceHash;

    uint256 public numReservedTokens;

    mapping(address => uint256) public preSaleMintCounts; 
    bytes32 public preSaleListMerkleRoot;

    enum SaleState {
        Inactive,
        PreSale,
        PublicSale
    }

    SaleState public saleState = SaleState.Inactive;

    address public royaltyReceiverAddress;

    bool public revealed = false;

    // ============ CUSTOMIZE VALUES BELOW ============
    uint256 public maxSupply = 5555;

    uint256 public constant MAX_PRE_SALE_MINTS = 10;
    uint256 public preSalePrice = 0.1 ether;

    uint256 public constant MAX_PUBLIC_SALE_MINTS = 10;
    uint256 public publicSalePrice = 0.15 ether;

    uint256 public constant MAX_RESERVE_TOKENS = 55;
    uint256 public constant MAX_TOKENS_PER_WALLET = 10; 
    
    uint256 public constant ROYALTY_PERCENTAGE = 8;
    // ================================================

    constructor(address _royaltyReceiverAddress)
        ERC721("THE SAUDI SHIBAS", "SAUDISHIBA")
    {
	setHiddenMetadataUri("ipfs://QmfWxPAmCbhtRXPtCPSJD1RSwbP5FJ5wVFXpgzPA8nbdXc/hidden.json");    
        royaltyReceiverAddress = _royaltyReceiverAddress;
        assert(MAX_TOKENS_PER_WALLET >= MAX_PRE_SALE_MINTS);
        assert(MAX_TOKENS_PER_WALLET >= MAX_PUBLIC_SALE_MINTS);
    }

    // ============ ACCESS CONTROL MODIFIERS ============
    modifier preSaleActive() {
        require(saleState == SaleState.PreSale, "Pre sale is not open");
        _;
    }

    modifier publicSaleActive() {
        require(saleState == SaleState.PublicSale, "Public sale is not open");
        _;
    }

    modifier maxTokensPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxSupply - MAX_RESERVE_TOKENS + numReservedTokens,
            "Insufficient tokens remaining"
        );
        _;
    }

    modifier canReserveTokens(uint256 numberOfTokens) {
        require(
            numReservedTokens + numberOfTokens <= MAX_RESERVE_TOKENS,
            "Insufficient token reserve"
        );
        require(
            tokenCounter.current() + numberOfTokens <= maxSupply,
            "Insufficient tokens remaining"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidPreSaleAddress(bytes32[] calldata merkleProof) {
        require(
            MerkleProof.verify(
                merkleProof,
                preSaleListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintPublicSale(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        publicSaleActive
        isCorrectPayment(publicSalePrice, numberOfTokens)
        canMint(numberOfTokens)
        maxTokensPerWallet(numberOfTokens)
    {
        require(
            numberOfTokens <= MAX_PUBLIC_SALE_MINTS,
            "Exceeds max number for public mint"
        );
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function mintPreSale(uint8 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        isCorrectPayment(preSalePrice, numberOfTokens)
        canMint(numberOfTokens)
        isValidPreSaleAddress(merkleProof)
    {
        uint256 numAlreadyMinted = preSaleMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_PRE_SALE_MINTS,
            "Exceeds max number for pre sale mint"
        );

        preSaleMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /**
     * @dev reserve tokens for self
     */
    function reserveTokens(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canReserveTokens(numToReserve)
    {
        numReservedTokens += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    /**
     * @dev gift token directly to list of recipients
     */
    function giftTokens(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canReserveTokens(addresses.length)
    {
        uint256 numRecipients = addresses.length;
        numReservedTokens += numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    
    function totalSupply() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ SUPPORTING FUNCTIONS ============
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (
            royaltyReceiverAddress,
            SafeMath.div(SafeMath.mul(salePrice, ROYALTY_PERCENTAGE), 100)
        );
    }

    /**
     * @dev support EIP-2981 interface for royalties
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setPublicSaleActive() external onlyOwner {
        saleState = SaleState.PublicSale;
    }

    function setPreSaleActive() external onlyOwner {
        saleState = SaleState.PreSale;
    }

    function setSaleInactive() external onlyOwner {
        saleState = SaleState.Inactive;
    }

    /**
     * @dev used for allowlisting pre sale addresses
     */
    function setPreSaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preSaleListMerkleRoot = merkleRoot;
    }

    /**
     * @dev used for art reveals
     */

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPresaleCost(uint256 _cost) public onlyOwner {
        preSalePrice = _cost;
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicSalePrice = _cost;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }


    function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    }

    
    function setProvenanceHash(string calldata _hash) public onlyOwner {
        provenanceHash = _hash;
    }

    function setRoyaltyReceiverAddress(address _royaltyReceiverAddress)
        external
        onlyOwner
    {
        royaltyReceiverAddress = _royaltyReceiverAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev enable contract to receive ethers in royalty
     */
    receive() external payable {}
}