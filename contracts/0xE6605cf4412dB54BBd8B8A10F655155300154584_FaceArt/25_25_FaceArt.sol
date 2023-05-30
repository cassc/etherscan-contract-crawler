// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma abicoder v2;
// Uncomment this line to use console.log

// required to accept structs as function parameters
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract FaceArt is ERC721, ERC721Enumerable, PaymentSplitter, Pausable, ReentrancyGuard, AccessControl, EIP712, IERC2981 {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "FaceArt";
    string private constant SIGNATURE_VERSION = "1";
    string public baseURI;

    enum Level {
        A0,
        B0,
        A1,
        B1,
        C1,
        D1
    }
    uint256 private constant FREEMINT_LOT_SIZE = 3;
    uint256 public mintPrice = 0.001 ether;
    uint256 private maxMintQuantity = 10;
    uint256 private burnVoucherExpiry = 2 hours;
    address public crossmintAddress;
    mapping (address => bool) public blockedMarketplaces;
    mapping(address => mapping(address => bool)) affiliateMapping;
    mapping(address => uint) public affiliateCounter;
    mapping(address => uint) public freeMintCounter;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public minterlist;
    mapping(Level => uint) levelSupply;
    mapping(Level => uint) public levelMintedCounter;
    mapping(uint => Level) public tokenLevel;
    mapping(uint => BurnVoucher) burnVoucher;
    bool private _fusionEnabled;
    Counters.Counter private _tokenIdCounter;
    RoyaltyInfo private _currentRoyaltyInfo;

    address[] private _team = [0x70B66C23F8f7ab6AcACEC011337e58c9314E96cF, 0x99A7130dc775dB71E5252dE59F0f156DF1B96d89];

    uint[] private _shares = [750, 250];

    struct MintVoucher {
        address recipient;
        address referrer;
        bytes signature;
    }

    struct BurnVoucher {
        address recipient;
        uint256 emitTimestamp;
    }

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    event BurnTicket(address _recipient, uint256 _emitTimestamp, uint256 _tokenId);
    event FreeMintTicket(address _recipient, uint256 _emitTimestamp);
    event EnableFusion(address account);
    event DisableFusion(address account);

    constructor(address _minter) ERC721("FaceArt", "F-ART") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) PaymentSplitter(_team, _shares) {
        _pause();
        _setupRole(MINTER_ROLE, _minter);
        _setupRole(OWNER_ROLE, _msgSender());
        crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
        levelSupply[Level.A0] = 3400;
        levelSupply[Level.B0] = 3400;

        levelSupply[Level.A1] = 2000;
        levelSupply[Level.B1] = 800;
        levelSupply[Level.C1] = 400;
        levelSupply[Level.D1] = 200;
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function enableFusion() public onlyRole(OWNER_ROLE) {
        _fusionEnabled = true;
    }

    modifier whenFusionEnabled() {
        require(_fusionEnabled, "Fusion not enabled");
        _;
    }

    function setMintPrice(uint256 newMintPrice) public onlyRole(OWNER_ROLE) {
        mintPrice = newMintPrice;
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyRole(OWNER_ROLE) {
        crossmintAddress = _crossmintAddress;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getFreeMintQuantity(address _account) public view returns (uint256) {
        return freeMintCounter[_account];
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(OWNER_ROLE) {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _levelName(Level _level) internal pure returns (string memory) {
        if (_level == Level.A0) return "A0";
        if (_level == Level.B0) return "B0";
        if (_level == Level.A1) return "A1";
        if (_level == Level.B1) return "B1";
        if (_level == Level.C1) return "C1";
        if (_level == Level.D1) return "D1";
        return "KO";
    }

    function getLevel(uint256 tokenId) public view returns (string memory) {
        _requireMinted(tokenId);
        return _levelName(tokenLevel[tokenId]);
    }

    function gift(uint _quantity, address _to) external onlyRole(OWNER_ROLE) {
        require(_quantity <= maxMintQuantity, "Exceeds max mint quantity per tx");
        require((levelMintedCounter[Level.A0] + levelMintedCounter[Level.B0] + _quantity) <= (levelSupply[Level.A0] + levelSupply[Level.B0]), "Exceeds Level 0 supply");
        for (uint256 i; i < _quantity;) {
            _tokenIdCounter.increment();
            uint256 currentTokenId = _tokenIdCounter.current();
            _safeMint(_to, currentTokenId);
            tokenLevel[currentTokenId] = randomizeLevel0(currentTokenId);

            unchecked {
                levelMintedCounter[tokenLevel[currentTokenId]]++;
                i++;
            }
        }
    }

    function _mint(uint256 quantity, MintVoucher memory voucher) internal {
        require(quantity <= maxMintQuantity, "Exceeds max mint quantity per tx");
        require((levelMintedCounter[Level.A0] + levelMintedCounter[Level.B0] + quantity) <= (levelSupply[Level.A0] + levelSupply[Level.B0]), "Exceeds Level 0 supply");
        if (minterlist[voucher.recipient]) {
            uint256 freeMint = freeMintCounter[voucher.recipient];
            uint256 diffQty = quantity >= freeMint ? quantity - freeMint : 0;

            require( msg.value == mintPrice * diffQty, "Not enough ETH sent");

            if (freeMint != 0) {
                uint256 diffQtyNd = freeMint >= quantity ? freeMint - quantity : 0;
                freeMintCounter[voucher.recipient] = diffQtyNd;
            }
        } else {
            require(msg.value == mintPrice * quantity, "Not enough ETH sent");
        }

        for (uint256 i; i < quantity;) {
            _tokenIdCounter.increment();
            uint256 currentTokenId = _tokenIdCounter.current();
            _safeMint(voucher.recipient, currentTokenId);
            tokenLevel[currentTokenId] = randomizeLevel0(currentTokenId);
            levelMintedCounter[tokenLevel[currentTokenId]]++;

            unchecked {
                i++;
            }
        }

        if (voucher.referrer != address(0)) {
            if (!affiliateMapping[voucher.referrer][voucher.recipient]) {
                affiliateCounter[voucher.referrer]++;
                affiliateMapping[voucher.referrer][voucher.recipient] = true;
                if (affiliateCounter[voucher.referrer] % FREEMINT_LOT_SIZE == 0) {
                    freeMintCounter[voucher.referrer]++;
                    emit FreeMintTicket(voucher.referrer, block.timestamp);
                }
            }
        } else if (!whitelist[voucher.recipient]) {
            whitelist[voucher.recipient] = true;
        }
        if (!minterlist[voucher.recipient]) {
            minterlist[voucher.recipient] = true;
        }
    }

    function mintCrossmint(uint256 quantity, address to, address recipient, address referrer) public payable whenNotPaused {
        require(to == crossmintAddress, "Restricted for crossmint");
        require(_msgSender() == crossmintAddress, "Should be to crossmint");
        require(_msgSender() != referrer, "Referrer can't be crossmint");
        require(recipient != referrer, "Referrer can't be the recipient");

        MintVoucher memory voucher = MintVoucher({recipient: recipient, referrer: referrer, signature: ""});
        _mint(quantity, voucher);
    }

    /// @notice Mint function
    /// @param voucher A signed MintVoucher.
    function mint(uint256 quantity, address to, MintVoucher calldata voucher) public payable whenNotPaused {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        require(to == _msgSender() && (voucher.recipient == _msgSender()), "Voucher is for different caller");
        require(voucher.referrer != _msgSender(), "Referrer can't be the caller");

        _mint(quantity, voucher);
    }

    function randomizeLevel0(uint256 salt) private view returns (Level) {
        if (levelMintedCounter[Level.A0] == levelSupply[Level.A0]) {
            return Level.B0;
        } else if (levelMintedCounter[Level.B0] == levelSupply[Level.B0]) {
            return Level.A0;
        }
        return random(salt, 2) == 0 ? Level.A0 : Level.B0;
    }

    /// @notice Fusion function
    function fusion(uint256 tokenId1, uint256 tokenId2) public whenNotPaused whenFusionEnabled returns (uint256) {
        require(!Address.isContract(_msgSender()), "Cannot be called from contract");
        require(ownerOf(tokenId1) == _msgSender(), "Not owner of NFT");
        require(tokenLevel[tokenId1] < Level.A1, "Invalid level");
        require(ownerOf(tokenId2) == _msgSender(), "Not owner of NFT");
        require(tokenLevel[tokenId2] < Level.A1, "Invalid level");
        require(tokenLevel[tokenId1] != tokenLevel[tokenId2], "Tokens should have different type");

        _burn(tokenId1);
        _burn(tokenId2);
        _tokenIdCounter.increment();
        uint256 currentTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), currentTokenId);
        tokenLevel[currentTokenId] = randomizeLevel1(currentTokenId);
        levelMintedCounter[tokenLevel[currentTokenId]]++;
        if (whitelist[_msgSender()]) {
            burnVoucher[currentTokenId] = BurnVoucher({recipient: _msgSender(), emitTimestamp: block.timestamp});
            emit BurnTicket(_msgSender(), block.timestamp, currentTokenId);
        }
        return currentTokenId;
    }

    function burnWithTicket(uint256 burnTokenId) public whenNotPaused {
        require(!Address.isContract(_msgSender()), "Cannot be called from contract");
        require(ownerOf(burnTokenId) == _msgSender(), "Not owner of NFT");
        require(burnVoucher[burnTokenId].emitTimestamp + burnVoucherExpiry >= block.timestamp, "No valid burn ticket");

        if(levelMintedCounter[tokenLevel[burnTokenId]] > 0) levelMintedCounter[tokenLevel[burnTokenId]]--;
        delete burnVoucher[burnTokenId];
        delete tokenLevel[burnTokenId];
        _burn(burnTokenId);
        _tokenIdCounter.increment();
        uint256 currentTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), currentTokenId);
        tokenLevel[currentTokenId] = randomizeLevel1(currentTokenId);
        levelMintedCounter[tokenLevel[currentTokenId]]++;
    }

    function randomizeLevel1(uint256 salt) private view returns (Level) {
        uint256[4] memory _level1Supply = [levelSupply[Level.A1], levelSupply[Level.B1], levelSupply[Level.C1], levelSupply[Level.D1]];
        if (levelMintedCounter[Level.A1] == levelSupply[Level.A1]) {
            _level1Supply[0] = 0;
        }
        if (levelMintedCounter[Level.B1] == levelSupply[Level.B1]) {
            _level1Supply[1] = 0;
        }
        if (levelMintedCounter[Level.C1] == levelSupply[Level.C1]) {
            _level1Supply[2] = 0;
        }
        if (levelMintedCounter[Level.D1] == levelSupply[Level.D1]) {
            _level1Supply[3] = 0;
        }
        uint256 randomValue = random(salt, _level1Supply[0] + _level1Supply[1] + _level1Supply[2] + _level1Supply[3]);
        if (randomValue < _level1Supply[0]) {
            return Level.A1;
        }
        if ((randomValue >= _level1Supply[0]) && (randomValue < (_level1Supply[0] + _level1Supply[1]))) {
            return Level.B1;
        }
        if ((randomValue >= (_level1Supply[0] + _level1Supply[1])) && (randomValue < (_level1Supply[0] + _level1Supply[1] + _level1Supply[2]))) {
            return Level.C1;
        }
        return Level.D1;
    }

    function random(uint256 salt, uint256 mod) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), salt))) % mod;
    }

    /**
     * @notice Release the gains on every accounts
     */
    function releaseAll() external nonReentrant onlyRole(OWNER_ROLE) {
        for (uint i = 0; i < _team.length; i++) {
            release(payable(payee(i)));
        }
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 , uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _currentRoyaltyInfo;

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyRole(OWNER_ROLE) {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _currentRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function approve(address to, uint256 id) public virtual override(ERC721, IERC721) {
        require(!blockedMarketplaces[to], "Invalid marketplace, not allowed");
        super.approve(to, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        require(!approved || !blockedMarketplaces[operator], "Invalid marketplace, not allowed");
        super.setApprovalForAll(operator, approved);
    }

    function setBlockedMarketplace(address marketplace, bool blocked) public onlyRole(OWNER_ROLE) {
        blockedMarketplaces[marketplace] = blocked;
    }

    //Not allowing receiving ethers outside minting functions
    receive() external payable override {
        revert("Only if you mint");
    }

    /// @notice Returns a hash of the given MintVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An MintVoucher to hash.
    function _hash(MintVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("MintVoucher(address recipient,address referrer)"), voucher.recipient, voucher.referrer)));
    }

    /// @notice Verifies the signature for a given MintVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An MintVoucher describing an unminted NFT.
    function _verify(MintVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}