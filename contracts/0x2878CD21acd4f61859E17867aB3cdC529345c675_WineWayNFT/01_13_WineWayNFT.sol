// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

contract WineWayNFT is ReentrancyGuard, Ownable, ERC721A, PaymentSplitter {
    using ECDSA for bytes32;

    // The token name and symbol.
    string public constant TOKEN_NAME = "WineWay: Genesis";
    string public constant TOKEN_SYMBOL = "WWG";

    // The maximum amount of NFTs one can mint in a single mint call (mainly during public mint).
    uint8 public constant BATCH_MINT_MAX = 30;

    // The total supply of NFTs.
    uint16 public constant TOTAL_SUPPLY = 1995;

    // The price of a single NFT during public mint.
    uint256 public constant MINT_PRICE_PUBLIC = 0.033 ether;

    // If the NFTs have been revealed.
    bool public isRevealed = false;

    // Base URIs for NFT metadata.
    string private baseURI;
    string private preRevealBaseURI;

    // Controls minting.
    bool public isPublicMinting = false;

    // Free minting. Key is hash of coupon.
    mapping(bytes32 => bool) private freeMintClaimed;
    address private freeMintAddress;

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
        address(0x729f98a80dc90b063635F96b88b6DAc2E94e958D)
    ];
    uint256[] private sharesList = [uint256(90), uint256(10)];

    constructor()
        ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
        PaymentSplitter(payeesList, sharesList)
    {
        initialOwnerMints();
        airdropMints();
    }

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

    // Enable public minting. Only callable by owner.
    function setPublicMinting(bool state) external onlyOwner {
        isPublicMinting = state;
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

    // Modifier that reverts when public minting is not enabled.
    modifier publicMintEnabled() {
        require(isPublicMinting == true, "public minting not enabled");
        _;
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

    // Public mint

    function mint(uint256 quantity) external payable publicMintEnabled {
        doMint(quantity, MINT_PRICE_PUBLIC);
    }

    function mintCoupon(uint256 quantity, SignedCoupon calldata signedCoupon)
        external
        payable
        publicMintEnabled
    {
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
    Constructor mints.
    */

    function initialOwnerMints() private {
        _mintERC2309(msg.sender, 11);
    }

    function airdropMints() private {
        _mintERC2309(address(0xdEb74295385486AF495149FDd209C4f11BccA530), 7);
        _mintERC2309(address(0xcaefB6AF0295540e1fD62C877b770bA5E6dC4088), 3);
        _mintERC2309(address(0xCdb21dF1551d3fa3c8119eDde8A09F0A234Fa81D), 7);
        _mintERC2309(address(0x85a7C4A49Be079B9e56280741A637Db0CcA9f0CD), 7);
        _mintERC2309(address(0x2653c1a358C945ff1a41DCD6BA5D4f20dD984e6e), 7);
        _mintERC2309(address(0x5eAa9BbAdEc92Ba712A1C8127f613Ec792B50657), 7);
        _mintERC2309(address(0x94e8b6295be681a2C4DdAD11F501E0fE9AbB758A), 7);
        _mintERC2309(address(0xB11B504349A6C145cc64d29194D05AC4AC73eE12), 7);
        _mintERC2309(address(0xFC390a8865D6c056f1aBe6CbE378c2767D1D1b04), 3);
        _mintERC2309(address(0x3BC3a258fc6Dd9F6D3021a47b44706c656Faa6Da), 7);
        _mintERC2309(address(0x85e41D90D865101bf78567446E2e24ecd9389349), 7);
        _mintERC2309(address(0x5AF4a30C39f329097D4873705E9D5cecE987D03D), 3);
        _mintERC2309(address(0x778418a7c23fC411caa09C2d173a3a9efbAa997a), 7);
        _mintERC2309(address(0x223ED8e5b169575a47a35C5A527aBC379DbB2391), 3);
        _mintERC2309(address(0x11254490b714401716d1BA7f89EdF9D57EFB6393), 3);
        _mintERC2309(address(0x86854904e954FB0a278C809a20f3fFc91C67eB2b), 3);
        _mintERC2309(address(0x94F87D292267A1cc3AcD25174769ba8CD551A762), 3);
        _mintERC2309(address(0x711c0eE5ae52491f8B043Df2DE00771115F9a1Eb), 3);
        _mintERC2309(address(0x0c867eBc064D124eBFDe75D0a56a672f6277dea5), 3);
        _mintERC2309(address(0x66B62DF3ba32c8281A96E47249f43e20aD7D08Bb), 3);
        _mintERC2309(address(0xB6fC5228d6e0eFA7000e926710475b4E0d256405), 7);
        _mintERC2309(address(0xD0b391E98e9f6C1EBA629C693FF1fafd34BF437b), 3);
        _mintERC2309(address(0x67E3f3aAb8A6A44d93e2ac55811695585Ad4cAa3), 7);
        _mintERC2309(address(0xD0ea19063156F1Dd0FD0af10aa4573124fc6E777), 3);
        _mintERC2309(address(0x88d41BF32B54a811419fad119BC05BD86353dead), 3);
        _mintERC2309(address(0x744D9Db6F6354bB40eBbC2f0FC2E10B38eF2e173), 3);
        _mintERC2309(address(0x6fD1c5608027FC6759777a147594595411137FcF), 7);
        _mintERC2309(address(0xf5AA806CC154E6fc2e3aA65d384c482733309615), 3);
        _mintERC2309(address(0x1B1c218d0D6e6854485B6B4b7A2Bb733d1FdF433), 3);
        _mintERC2309(address(0x1Cf6437111A85CB37603650f278B80655A1c43E9), 7);
        _mintERC2309(address(0x7D945321043BF04e9F1bCC86eb02319E83206c62), 3);
        _mintERC2309(address(0x3274f50e233Eee15b5418f2722Fa499D2e25281d), 7);
        _mintERC2309(address(0xeDfF408Aac2da8ECdC698E80e6dF84155bA4D250), 7);
        _mintERC2309(address(0x458F5ae3bf6536B2FB97e2629faEEbaDcDeDF21B), 3);
        _mintERC2309(address(0x2a582d8a62414abec897E2012BED9c54Bb5e6bD9), 7);
        _mintERC2309(address(0x04c95C6F8EA7Ff7c3F7a2F148Fae75650c5A875E), 3);
        _mintERC2309(address(0x7915e43086Cd78Be341Df73726C0947B6334b978), 7);
        _mintERC2309(address(0x4EF12497d9A1370a3fC6DE20689548734e292851), 3);
        _mintERC2309(address(0xA8644D3d37e5B9bA50038F652eebeE3b7108d554), 3);
        _mintERC2309(address(0x1D16aBc9d250224cC7C577432eDcDBeab573C0Eb), 3);
        _mintERC2309(address(0xe2892767aFF5a0D42C7A25c981cFb0C432f8F338), 3);
        _mintERC2309(address(0x060c2879e12f8fbf2D96a5610f0981C132312731), 10);
        _mintERC2309(address(0x1c3738E5654Fd2A56b4f6D625660d448bbe7a683), 7);
        _mintERC2309(address(0x07587c046d4d4BD97C2d64EDBfAB1c1fE28A10E5), 3);
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