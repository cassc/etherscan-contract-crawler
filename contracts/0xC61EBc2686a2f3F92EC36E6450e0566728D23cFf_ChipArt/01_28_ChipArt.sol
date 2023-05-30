// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@author divergence
 */
contract ChipArt is ERC721Common, FixedPriceSeller, BaseTokenURI, IERC2981 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    constructor()
        ERC721Common("Chip Art", "CHIP")
        BaseTokenURI("")
        FixedPriceSeller(
            0.18 ether,
            Seller.SellerConfig({
                totalInventory: 2750,
                maxPerAddress: 2,
                maxPerTx: 0,
                freeQuota: 25,
                reserveFreeQuota: true,
                lockFreeQuota: false,
                lockTotalInventory: false
            }),
            payable(0x17252D391F6c7C25e8cEC6eCf86b0dC3D6aA9970)
        )
    {}

    /**
    @notice Number of tokens already minted.
     */
    Monotonic.Increaser public totalSupply;

    /**
    @dev Required override for FixedPriceSeller to handle minting upon purchase.
    The boolean flag to indicate free of charge is ignored.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        uint256 tokenId = totalSupply.current() + 1;
        uint256 end = tokenId + n;
        for (; tokenId < end; tokenId++) {
            _safeMint(to, tokenId);
        }
        totalSupply.add(n);
    }

    /**
    @notice Flag indicating that public minting is open.
     */
    bool public publicMinting;

    /**
    @notice Set the `publicMinting` flag.
     */
    function setPublicMinting(bool _publicMinting) external onlyOwner {
        publicMinting = _publicMinting;
    }

    /**
    @notice Mint as a member of the public.
     */
    function mint(address to, uint256 n) external payable {
        require(publicMinting, "Minting closed");
        _purchase(to, n);
    }

    /**
    @dev Addresses allowed to sign for early access.
     */
    EnumerableSet.AddressSet private signers;

    /**
    @notice Add an address from which mintEarly() signatures are accepted.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address previously added with addSigner().
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }

    /**
    @notice Mint with an early-access signature.
    @dev Signatures can be reused and are agnostic to the number of tokens being
    purchased; limits are instead enforced by the Seller contract.
     */
    function mintEarly(
        address to,
        uint256 n,
        bytes calldata sig
    ) external payable {
        signers.requireValidSignature(abi.encodePacked(to), sig);
        _purchase(to, n);
    }

    /**
    @dev Override the OZ _baseURI() function to point to the BaseTokenURI
    contract's implementation.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
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
}