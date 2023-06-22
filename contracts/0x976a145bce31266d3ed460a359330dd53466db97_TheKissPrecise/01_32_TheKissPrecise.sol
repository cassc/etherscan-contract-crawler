// SPDX-License-Identifier: MIT
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./IKissRenderer.sol";
import "./IPublicMintable.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/ArbitraryPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
@notice A pure-Solidity generative-art NFT, The Kiss Precise: www.thekiss.xyz
 */
contract TheKissPrecise is
    ERC721Common,
    ArbitraryPriceSeller,
    IERC2981,
    IPublicMintable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165Checker for address;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    /**
    @notice Address of the PROOF OF {ART}WORK NFT. Hodlers are guaranteed 2x
    Kiss mints.
     */
    IERC721 public immutable poaw;

    /**
    @notice Address of the Brotchain NFT. Hodlers are guaranteed 1x Kiss mint.
     */
    IERC721 public immutable brot;

    constructor(
        address _renderer,
        IERC721 _poaw,
        IERC721 _brotchain
    )
        ERC721Common("The Kiss Precise", "KISS")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: 1024,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 20,
                reserveFreeQuota: true,
                lockFreeQuota: false,
                lockTotalInventory: true
            }),
            payable(0x5D484C0546679aaCe24c330b301CC6baDFA60259)
        )
    {
        poaw = _poaw;
        brot = _brotchain;
        setRenderer(_renderer);
    }

    /**
    @notice Minting price for public minters.
     */
    uint256 public publicPrice = 0.314159 ether;

    /**
    @notice Minting price for hodlers of divergence tokens, PO{A}W or Brotchain.
     */
    uint256 public collectorPrice = 0.256 ether;

    /**
    @notice Updates the prices for the two tiers.
     */
    function setPrice(uint256 public_, uint256 collectors) external onlyOwner {
        publicPrice = public_;
        collectorPrice = collectors;
    }

    /**
    @notice Proxy contract from which public minting requests are allowed.
     */
    address public publicMinter;

    /**
    @notice Toggles the public-minting contract.
     */
    function setPublicMinter(address _publicMinter) external onlyOwner {
        publicMinter = _publicMinter;
    }

    /**
    @notice Mint as a member of the public, but only via minter contract.
    @dev This allows for arbitrary control of minting logic post deployment.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(msg.sender == publicMinter, "Direct public minting");
        _purchase(to, n, publicPrice);
    }

    /**
    @notice Flag reflecting if collector (PO{A}W or Brotchain) minting is open.
     */
    bool public collectorMinting = false;

    /**
    @notice Toggles the collector-minting flag.
     */
    function setCollectorMinting(bool _collectorMinting) external onlyOwner {
        collectorMinting = _collectorMinting;
    }

    /**
    @notice Already-claimed mints from the PROOF OF {ART}WORK and Brotchain guaranteed pools.
     */
    ERC721Redeemer.Claims private poawClaims;
    ERC721Redeemer.Claims private brotClaims;
    uint256 private constant CLAIM_ALLOWANCE = 1;

    /**
    @notice Mint as a holder of PROOF OF {ART}WORK or Brotchain token(s).
    @dev Only one of the two collections can be claimed per call.
    @param poawIds PROOF OF {ART}WORK tokenIds to claim against; each claim
    receives an extra free Kiss.
    @param brotIds Brotchain tokenIds to claim against.
     */
    function claimCollectorMints(
        uint256[] calldata poawIds,
        uint256[] calldata brotIds
    ) external payable {
        require(collectorMinting, "Collector minting closed");

        // To adjust for the free Kiss to PO{A}W holders, we halve the price and
        // double the number redeemed. Because of potential rounding errors, we
        // therefore can't merge with Brotchain redemption. It also isn't safe
        // to call _purchase() twice in a single transaction as msg.value will
        // be double spent.
        if (poawIds.length > 0) {
            _purchase(
                msg.sender,
                2 *
                    poawClaims.redeem(
                        CLAIM_ALLOWANCE,
                        msg.sender,
                        poaw,
                        poawIds
                    ),
                collectorPrice / 2
            );
        } else {
            _purchase(
                msg.sender,
                brotClaims.redeem(CLAIM_ALLOWANCE, msg.sender, brot, brotIds),
                collectorPrice
            );
        }
    }

    /**
    @notice Returns the number of additional claims that can be made, via
    claimCollectorMints(), with the specific PROOF OF {ART}WORK token.
     */
    function poawClaimsRemaining(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return claimsRemaining(poaw, poawClaims, CLAIM_ALLOWANCE, tokenId);
    }

    /**
    @notice Returns the number of additional claims that can be made, via
    claimCollectorMints(), with the specific Brotchain token.
     */
    function brotchainClaimsRemaining(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return claimsRemaining(brot, brotClaims, CLAIM_ALLOWANCE, tokenId);
    }

    function claimsRemaining(
        IERC721 token,
        ERC721Redeemer.Claims storage claims,
        uint256 maxAllowance,
        uint256 tokenId
    ) private view returns (uint256) {
        token.ownerOf(tokenId); // will revert if non-existent
        return claims.unclaimed(maxAllowance, tokenId);
    }

    /**
    @notice Set of addresses from which valid signatures will be accepted to
    provide access to minting.
     */
    EnumerableSet.AddressSet private signers;

    /**
    @notice Add an address allowed to sign minting access.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address from those allowed to sign minting access.
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }

    /**
    @notice Already-redeemed signed-minting messages.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint as a holder of a signature; most likely from the allow list.
     */
    function mintWithSignature(
        uint256 n,
        uint256 price,
        bytes32 nonce,
        bytes calldata signature
    ) external payable {
        signers.requireValidSignature(
            abi.encodePacked(msg.sender, n, price, nonce),
            signature,
            usedMessages
        );
        _purchase(msg.sender, n, price);
    }

    /**
    @notice Partially fulfills the ERC721Enumerable interface.
     */
    Monotonic.Increaser public totalSupply;

    /**
    @notice The per-token seeds used to generate images.
     */
    mapping(uint256 => bytes32) public seeds;

    /**
    @notice Override of the Seller purchasing logic to mint the required number
    of tokens. The freeOfCharge boolean flag is deliberately ignored.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        uint256 nextId = totalSupply.current();
        uint256 end = nextId + n;

        // These are close enough to unpredictable / uncontrollable to be
        // sufficiently random for our purpose. Only a miner could really
        // influence this.
        bytes memory entropyBase = abi.encodePacked(
            address(this),
            block.coinbase,
            block.number,
            to
        );

        for (; nextId < end; ++nextId) {
            _safeMint(to, nextId);
            seeds[nextId] = keccak256(abi.encodePacked(entropyBase, nextId));
        }
        totalSupply.add(n);
    }

    /**
    @notice Flag to disable use of renewSeed().
     */
    bool public seedsLocked = false;

    /**
    @notice Permanently sets the seed-lock flag to true.
     */
    function lockSeeds() external onlyOwner {
        seedsLocked = true;
    }

    /**
    @notice Some seeds would result in execution errors and although this
    behaviour has not been seen recently, renewSeed() recalculates a seed by
    hashing the old one. This is a protective mechanism to guarantee that no
    tokens are invalid. Once all tokens are rendered, the irreversible seed lock
    will be put in place.
    */
    function renewSeed(uint256 tokenId)
        external
        tokenExists(tokenId)
        onlyOwner
    {
        require(!seedsLocked, "Seeds locked");
        seeds[tokenId] = keccak256(abi.encodePacked(seeds[tokenId]));
    }

    /**
    @notice Contract responsible for rendering images and token metadata from
    seeds.
     */
    IKissRenderer public renderer;

    /**
    @notice Flag to disable use of setRenderer().
     */
    bool public rendererLocked = false;

    /**
    @notice Permanently sets the renderer-lock flag to true.
     */
    function lockRenderer() external onlyOwner {
        require(
            address(renderer).supportsInterface(
                type(IKissRenderer).interfaceId
            ),
            "Not IKissRenderer"
        );
        rendererLocked = true;
    }

    /**
    @notice Sets the address of the rendering contract.
    @dev No checks are performed when setting, but lockRenderer() ensures that
    the final address implements the IKissRenderer interface.
     */
    function setRenderer(address _renderer) public onlyOwner {
        require(!rendererLocked, "Renderer locked");
        renderer = IKissRenderer(_renderer);
    }

    /**
    @notice Returns the data-encoded token URI containing full metadata and
    image.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        require(address(renderer) != address(0), "No renderer");
        return renderer.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
    @notice Defines royalty proportion in hundredths of a percent.
     */
    uint256 public royaltyBasisPoints = 1000;
    uint256 private constant BASIS_POINT_DENOMINATOR = 100 * 100;

    /**
    @notice Sets royalty proportion.
    @param basisPoints Measured in hundredths of a percent; 1% = 100; 1.5% =
    150; etc.
     */
    function setRoyalties(uint256 basisPoints) external onlyOwner {
        require(basisPoints <= BASIS_POINT_DENOMINATOR, ">100%");
        royaltyBasisPoints = basisPoints;
    }

    /**
    @notice Implements ERC2981, always returning the sales beneficiary as the
    receiver.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        // Probably safe to assume that salePrice will be less than max(uint256)/10000 ;)
        return (
            Seller.beneficiary,
            (salePrice * royaltyBasisPoints) / BASIS_POINT_DENOMINATOR
        );
    }

    /**
    @notice Adds ERC2981 interface to the set of already-supported interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}