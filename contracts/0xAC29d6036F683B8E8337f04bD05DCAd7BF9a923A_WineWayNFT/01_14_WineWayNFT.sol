// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

contract WineWayNFT is ReentrancyGuard, Ownable, ERC721A, PaymentSplitter {
    using ECDSA for bytes32;

    // The token name and symbol.
    string public constant TOKEN_NAME = "WineWayNFT";
    string public constant TOKEN_SYMBOL = "WINEWAYNFT";

    // The maximum amount of NFTs one can mint in a single mint call (mainly during public mint).
    uint8 public constant BATCH_MINT_MAX = 3;

    // The maximum amount of NFTs a wallet can mint during whitelist mint.
    uint8 public constant TOTAL_MINT_MAX_WHITELIST = 2;

    // The maximum amount of NFTs a wallet can mint during public mint.
    uint8 public constant TOTAL_MINT_MAX_PUBLIC = 3;

    // The total supply of NFTs.
    uint16 public constant TOTAL_SUPPLY = 1995;

    // The price of a single NFT during whitelist mint.
    uint256 public constant MINT_PRICE_WHITELIST = 0.079 ether;

    // The price of a single NFT during public mint.
    uint256 public constant MINT_PRICE_PUBLIC = 0.089 ether;

    // If the NFTs have been revealed.
    bool public isRevealed = false;

    // Base URIs for NFT metadata.
    string private baseURI;
    string private preRevealBaseURI;

    // Controls minting.
    bool public isWhitelistMinting = false;
    bool public isPublicMinting = false;

    // Minting control for whitelist & public minting.
    mapping(address => MintingControl) private mintingControl;
    bytes32 private whitelistMerkleRoot;

    // Free minting. Key is hash of coupon.
    mapping(bytes32 => bool) private freeMintClaimed;
    address private freeMintAddress;

    // A struct containing all per-user minting data.
    struct MintingControl {
        uint8 whitelistMinted;
        uint8 publicMinted;
    }

    // A signed coupon for free minting.
    struct SignedCoupon {
        bytes32 couponHash;
        address sender;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Payment split.
    address[] private payeesList = [
        address(0x4BC15535beb2128E6DEbb7B60DBd65BcBA73943A),
        address(0x8f505b39a533cE343321341e8CA7102E6b9571e3),
        address(0x729f98a80dc90b063635F96b88b6DAc2E94e958D)
    ];
    uint256[] private sharesList = [uint256(76), uint256(15), uint256(9)];

    constructor()
        ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
        PaymentSplitter(payeesList, sharesList)
    {}

    /*
    Reveal control
    */

    // Set the post-reveal base uri. This base uri is used when the collection has
    // been revealed. The default base uri is empty, so this has to be set before revealing.
    // Only callable by owner.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // Set the pre-reveal base uri. This base uri is used when the collection has
    // not been revealed yet. The default base uri is empty, so this has to be set before minting.
    // Only callable by owner.
    function setPreRevealBaseURI(string memory newBaseURI) external onlyOwner {
        preRevealBaseURI = newBaseURI;
    }

    // Get the currently set pre-reveal base uri. This base uri is used when the
    // collection has not been revealed yet.
    // Only callable by owner.
    function getBaseURI() external view onlyOwner returns (string memory) {
        return baseURI;
    }

    // Get the currently set pre-reveal base uri. This base uri is used when the
    // collection has not been revealed yet.
    // Only callable by owner.
    function getPreRevealBaseURI()
        external
        view
        onlyOwner
        returns (string memory)
    {
        return preRevealBaseURI;
    }

    // Set wether the collection should be revealed or not. Function _baseURI() returns
    // different base uris for the two different states. The smart contracts defaults
    // the collection not being revealed. Be sure to set the post reveal base uri using setBaseURI().
    // Only callable by owner.
    function setRevealed(bool state) external onlyOwner {
        isRevealed = state;
    }

    /*
    Minting control
    */

    // Enable whitelist minting. Only callable by owner.
    function setWhitelistMinting(bool state) external onlyOwner {
        isWhitelistMinting = state;
    }

    // Enable public minting. Only callable by owner.
    function setPublicMinting(bool state) external onlyOwner {
        isPublicMinting = state;
    }

    /*
    Whitelist control
    */

    // Set the merkle tree root for the whitelisted mint list. Only callable by owner.
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // Get the merkle tree root for the whitelisted mint list. Only callable by owner.
    function getWhitelistMerkleRoot()
        external
        view
        onlyOwner
        returns (bytes32)
    {
        return whitelistMerkleRoot;
    }

    // Wether a whitelist mint spot has been claimed yet or not.
    function hasWhitelistClaimed() external view returns (bool) {
        // Does not check if sender is eligible to whitelist mint.
        return
            mintingControl[msg.sender].whitelistMinted >=
            TOTAL_MINT_MAX_WHITELIST;
    }

    /*
    Free minting control
    */

    // Set the merkle tree root for the free mint list. Only callable by owner.
    function setFreeMintAddress(address addr) external onlyOwner {
        freeMintAddress = addr;
    }

    // Get the merkle tree root for the free mint list. Only callable by owner.
    function getFreeMintAddress() external view onlyOwner returns (address) {
        return freeMintAddress;
    }

    // Wether a free mint coupon has been claimed yet or not.
    function isFreeMintClaimed(bytes32 coupon) external view returns (bool) {
        return freeMintClaimed[coupon];
    }

    /*
    Minting
    */

    // Modifier that reverts when whitelist minting is not enabled.
    modifier whitelistMintEnabled() {
        require(isWhitelistMinting == true, "whitelist minting not enabled");
        _;
    }

    // Modifier that reverts when public minting is not enabled.
    modifier publicMintEnabled() {
        require(isPublicMinting == true, "public minting not enabled");
        _;
    }

    function mintHandleWhitelist(
        uint256 quantity,
        bytes32[] calldata whitelistProof
    ) private {
        require(
            mintingControl[msg.sender].whitelistMinted + quantity <=
                TOTAL_MINT_MAX_WHITELIST,
            "not enough whitelist spots left"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(whitelistProof, whitelistMerkleRoot, leaf),
            "sender not on whitelist"
        );

        // Casting is safe becuase quantity will never be bigger than uint8 as
        // long as TOTAL_MINT_MAX_WHITELIST is of type uint8.
        mintingControl[msg.sender].whitelistMinted += uint8(quantity);
    }

    function mintHandlePublic(uint256 quantity) private {
        require(
            mintingControl[msg.sender].publicMinted + quantity <=
                TOTAL_MINT_MAX_PUBLIC,
            "not enough wallet spots left"
        );

        // Casting is safe because quantity will never be bigger than uint8 as
        // long as TOTAL_MINT_MAX_PUBLIC is of type uint8.
        mintingControl[msg.sender].publicMinted += uint8(quantity);
    }

    function mintHandleCoupon(SignedCoupon calldata signedCoupon) private {
        require(
            freeMintClaimed[signedCoupon.couponHash] == false,
            "coupon already claimed"
        );
        require(signedCoupon.sender == msg.sender, "invalid signed coupon");

        bytes32 msgHash = keccak256(
            abi.encode(signedCoupon.couponHash, signedCoupon.sender)
        );
        address signer = ECDSA.recover(
            msgHash,
            signedCoupon.v,
            signedCoupon.r,
            signedCoupon.s
        );

        // Check if the coupon has been signed by the correct private key.
        require(signer == freeMintAddress, "invalid signed coupon");

        freeMintClaimed[signedCoupon.couponHash] = true;
    }

    // Whitelist mint

    function mintWhitelist(uint256 quantity, bytes32[] calldata whitelistProof)
        external
        payable
        whitelistMintEnabled
    {
        mintHandleWhitelist(quantity, whitelistProof);
        doMint(quantity, MINT_PRICE_WHITELIST);
    }

    function mintWhitelistCoupon(
        uint256 quantity,
        bytes32[] calldata whitelistProof,
        SignedCoupon calldata signedCoupon
    ) external payable whitelistMintEnabled {
        mintHandleWhitelist(quantity, whitelistProof);
        mintHandleCoupon(signedCoupon);
        doMint(quantity, 0);
    }

    // Public mint

    function mint(uint256 quantity) external payable publicMintEnabled {
        mintHandlePublic(quantity);
        doMint(quantity, MINT_PRICE_PUBLIC);
    }

    function mintCoupon(uint256 quantity, SignedCoupon calldata signedCoupon)
        external
        payable
        publicMintEnabled
    {
        mintHandlePublic(quantity);
        mintHandleCoupon(signedCoupon);
        doMint(quantity, 0);
    }

    // Owner mint

    function mintOwner(uint256 quantity) external onlyOwner {
        // Always allow, even if minting is disabled.
        doMint(quantity, 0);
    }

    // Mint function all methods above call

    function doMint(uint256 quantity, uint256 mintPrice) private {
        require(quantity > 0, "cannot mint 0 tokens");
        require(
            (msg.sender == owner() && quantity <= 30) ||
                quantity <= BATCH_MINT_MAX,
            "too many tokens in one batch"
        );

        uint256 nextTokenId = _nextTokenId();

        require(nextTokenId < TOTAL_SUPPLY, "sold out");
        require(
            nextTokenId + (quantity - 1) < TOTAL_SUPPLY,
            "not enough tokens left for mint"
        );

        require(
            mintPrice == 0 || msg.value >= mintPrice * quantity,
            "not enough eth to mint"
        );

        _mint(msg.sender, quantity);
    }

    /*
    ERC721A Overrides
    */

    // Returns either the public or pre-reveal base uri for the token metadata.
    function _baseURI() internal view virtual override returns (string memory) {
        if (isRevealed) {
            return baseURI;
        }
        return preRevealBaseURI;
    }
}