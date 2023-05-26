// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721CommonAutoIncrement.sol";
import "@divergencetech/ethier/contracts/sales/ArbitraryPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract PREMINTCollector is
    ERC721CommonAutoIncrement,
    BaseTokenURI,
    ArbitraryPriceSeller,
    SignerManager,
    ERC2981
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    constructor(address payable beneficiary, address royaltyReceiver)
        ERC721CommonAutoIncrement("PREMINT Collector", "PREMINTCOLL")
        BaseTokenURI("")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: 10000,
                lockTotalInventory: false,
                maxPerAddress: 10,
                maxPerTx: 0,
                freeQuota: 930,
                lockFreeQuota: false,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 750);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMintN(to, n);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint as an address on one of the early-access lists.
     */
    function mint(
        address to,
        uint256 price,
        bytes32 nonce,
        bytes calldata sig
    ) external payable {
        signers.requireValidSignature(
            signaturePayload(to, price, nonce),
            sig,
            usedMessages
        );
        _purchase(to, 1, price);
    }

    /**
    @notice Returns whether the address has minted at the specified price with
    the particular nonce. If true, future calls to mint() with the same
    parameters will fail.
     */
    function alreadyMinted(
        address to,
        uint256 price,
        bytes32 nonce
    ) external view returns (bool) {
        return
            usedMessages[
                SignatureChecker.generateMessage(
                    signaturePayload(to, price, nonce)
                )
            ];
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting signature.
     */
    function signaturePayload(
        address to,
        uint256 price,
        bytes32 nonce
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(to, price, nonce);
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
    @notice Price to mint for the general public.
     */
    uint256 public publicPrice = 0.25 ether;

    /**
    @notice Update the public-minting price.
     */
    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    /**
    @notice Mint as a member of the public.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(publicMinting, "Minting closed");
        _purchase(to, n, publicPrice);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
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
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}