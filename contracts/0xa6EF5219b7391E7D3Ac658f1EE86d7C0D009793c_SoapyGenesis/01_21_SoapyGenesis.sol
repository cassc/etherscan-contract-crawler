//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
pragma solidity ^0.8.0;

/*                                                                                                                                                                                      
                                                   
 .M"""bgd                                          
,MI    "Y                                          
`MMb.      ,pW"Wq.   ,6"Yb. `7MMpdMAo.`7M'   `MF'  
  `YMMNq. 6W'   `Wb 8)   MM   MM   `Wb  VA   ,V    
.     `MM 8M     M8  ,pm9MM   MM    M8   VA ,V     
Mb     dM YA.   ,A9 8M   MM   MM   ,AP    VVV      
P"Ybmmd"   `Ybmd9'  `Moo9^Yo. MMbmmd'     ,V       
                              MM         ,V        
                            .JMML.    OOb"         
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoapyGenesis is ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private nftCounter;

    string private baseURI;
    address private openSeaProxyRegAddr;
    bool private isOpenSeaProxyActive = true;

    uint256 public maxPerAddrLmt  = 10000;
    uint256 public constant maxSupply = 10000;
    uint256 public maxMintLmt = 10;

    uint256 public nftSalePrice = 0.1 ether;
    bool public isSaleActive = true;
    
    uint256 public maxWhitelisteds = 3000;
    uint256 public numClaimed = 0;
    uint256 public claimExpireAt = 1643673600;
    bytes32 public whitelistedMKRoot;
    bool public isClaimActive = true;

    uint256 public maxGifts = 500;
    uint256 public numGifts = 0;    
    
    mapping(address => bool) public claimed;

    constructor(
        address _openSeaProxyRegAddr,        
        string memory _baseURI,
        bytes32  _whitelistedMKRoot
    ) ERC721("Soapy Genesis", "SG") {
        openSeaProxyRegAddr = _openSeaProxyRegAddr;        
        baseURI = _baseURI;
        setMerkleRoot(_whitelistedMKRoot);        
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier saleActive() {
        require(isSaleActive, "Public sale is not open");
        _;
    }

    modifier whitelistActive() {
        require(isClaimActive, "whitelist claim is not open");
        _;
    }

    modifier maxNFTsPerWallet(uint256 num) {
        require(balanceOf(msg.sender) + num <= maxPerAddrLmt, "Exceeding Max NFTs to hold");
        _;
    }

    modifier canMint(uint256 num) {
        require(num <= maxMintLmt, "Exceeding mint amount limit each time");
        
        require(
            totalSupply() + num <=
                maxSupply - maxGifts - maxWhitelisteds,
            "Not enough NFTs remaining to mint"
        );
        _;
    }

    modifier canClaim(uint256 num) {        
        require(
            numClaimed + num <= maxWhitelisteds,
            "Not enough NFTs remaining to claim or expire for claim"
        );
        
        require(
            totalSupply() + num <= maxSupply,
            "Not enough NFTs remaining to mint"
        );
        _;
    }

    modifier canGiftNFTs(uint256 num) {
        require(
            numGifts + num <= maxGifts,
            "Not enough NFTs remaining to gift"
        );
        require(
            totalSupply() + num <= maxSupply,
            "Not enough NFTs remaining to gift mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 num) {
        if (msg.sender != owner()) {
            require(
                price * num == msg.value,
                "Incorrect ETH value sent"
            );
        }
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata mkProof, address _address) {
        require(
            MerkleProof.verify(
                mkProof,
                whitelistedMKRoot,
                keccak256(abi.encodePacked(_address))
            ),
            "Address does not exist in list"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 num)
        external
        payable
        nonReentrant
        isCorrectPayment(nftSalePrice, num)
        saleActive
        canMint(num)
        maxNFTsPerWallet(num)
    {
        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function claim(bytes32[] calldata mkProof, address _address)
        external
        payable
        nonReentrant
        whitelistActive
        canClaim(1)        
        isValidMerkleProof(mkProof, _address)
    {
        
        require(!claimed[_address], "NFT already claimed by this wallet");

        claimed[_address] = true;
        numClaimed += 1;

        _safeMint(_address, nextTokenId());
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function isWhitelisted(bytes32[]  calldata mkProof, address _user) public view returns (bool){      
                        
        return MerkleProof.verify(
                mkProof,
                whitelistedMKRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMaxMintLmt(uint256 _limit) public onlyOwner() {
        maxMintLmt = _limit;
    }

    function setMaxPerAddrLmt(uint256 _limit) public onlyOwner() {
        maxPerAddrLmt = _limit;
    }

    function setClaimExpireAt(uint256 _limit) public onlyOwner() {
        claimExpireAt = _limit;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsSaleActive(bool _active)
        external
        onlyOwner
    {
        isSaleActive = _active;
    }

    function setIsWhitelistedActive(bool _active)
        external
        onlyOwner
    {
        isClaimActive = _active;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        whitelistedMKRoot =_root;
    }

    function reserveForGifting(uint256 _num)
        external
        nonReentrant
        onlyOwner
        canGiftNFTs(_num)
    {
        numGifts += _num;

        for (uint256 i = 0; i < _num; i++) {
            _mint(msg.sender, nextTokenId());
        }
    }

    function giftNFTs(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftNFTs(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGifts += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
             // use mint rather than _safeMint here to reduce gas costs
            // and prevent this from failing in case of grief attempts
            _mint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function releaseUnClaimedWhitelisted()
        external
        nonReentrant        
        onlyOwner
    {
        require(block.timestamp>=claimExpireAt, "unable to release due to not expired");
        maxWhitelisteds = numClaimed;
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        nftCounter.increment();
        return nftCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegAddr
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non existent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}