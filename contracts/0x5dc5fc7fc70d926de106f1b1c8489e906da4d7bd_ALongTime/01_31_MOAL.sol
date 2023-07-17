// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) MOAL. All rights reserved. */

pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/ArbitraryPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IPublicMintable {
    function mintPublic(address to, uint256 n) external payable;
}

contract ALongTimePublicSale is Ownable {
    using Address for address payable;

    IPublicMintable immutable parent;

    constructor(IPublicMintable _parent) {
        parent = _parent;
    }
    
    event RefundReceived(uint256 value);
    event RefundForwarded(address to, uint256 value);

    receive() external payable {
        emit RefundReceived(msg.value);
    }

    function publicMint(uint256 n) external payable {
        
        parent.mintPublic{value: msg.value}(msg.sender, n);

        // ethier Seller contract will refund here so we need to propagate it
        // and always have a zero balance at the end. This will only happen if
        // there's a race condition for the final token.
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).sendValue(balance);
            emit RefundForwarded(msg.sender, balance);
        }
        assert(address(this).balance == 0);
    }    
}

contract ALongTimePublicSaleEnded is Ownable {
    using Address for address payable;

    IPublicMintable immutable parent;

    constructor(IPublicMintable _parent) {
        parent = _parent;
    }

    function publicMint(uint256 n) external payable {
        require(n != 0);
        revert("Public sale has ended.");
    }    
}

contract ALongTime is ERC721ACommon, ArbitraryPriceSeller, IPublicMintable, IERC2981 {
    
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165Checker for address;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    string private _cdnBaseUrl;
    string private _externalUrl;
    string private _description;

    constructor(uint totalInventory)
        ERC721ACommon("A Long Time", "MOALALT")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: totalInventory,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockFreeQuota: false,
                lockTotalInventory: true
            }),
            payable(0x286e11928ab5b578Fc15eCbf819ed5Cb16096cB1)
        ) 
    {  
        _externalUrl = "https://creator.kohi.art/MOAL";
        _description = "'A LONG TIME' by MOAL is a unique 100-piece 1/1 photography & music collection.";
        _cdnBaseUrl = "ipfs://QmdUUc19QEyVWSkmzAp2PhyZhViNc7ynwx1FMaGWUR5TYv";
        setRoyaltyBeneficiary(payable(0x286e11928ab5b578Fc15eCbf819ed5Cb16096cB1));
    }

    /**
    @notice Sets external details.
    */
    function setDetails(string memory externalUrl, string memory description) public onlyOwner {
        _externalUrl = externalUrl;
        _description = description;
    } 

    /**
    @notice Sets CDN base URL, for updating metadata
    */
    function setCdnBaseUrl(string memory cdnBaseUrl) public onlyOwner {
        _cdnBaseUrl = cdnBaseUrl;
    } 
 
    /**
    @notice Minting price for presales.
     */
    uint256 public presalePrice = 0.19 ether;

    /**
    @notice Minting price for public minters.
     */
    uint256 public publicPrice = 0.35 ether;    

    /**
    @notice Updates the prices for the two tiers.
     */
    function setPrice(uint256 public_, uint256 presale) external onlyOwner {
        publicPrice = public_;
        presalePrice = presale;
    }

    /**
    @notice Proxy contract from which public minting requests are allowed.
     */
    address public _publicMinter;

    /**
    @notice Sets the public-minting contract.
     */
    function setPublicMinter(address publicMinter) external onlyOwner {
        _publicMinter = publicMinter;
    }

    /**
    @notice Mint as a member of the public, but only via minter contract.
    @dev This allows for arbitrary control of minting logic post deployment.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(msg.sender == _publicMinter, "Direct public minting");
        _purchase(to, n, publicPrice);
    }

    /**
    @notice Override of the Seller purchasing logic to mint the required number
    of tokens. The freeOfCharge boolean flag is deliberately ignored.
    */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
         _safeMint(to, n);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tokenUri = string(abi.encodePacked(_cdnBaseUrl, '/', Strings.toString(tokenId), '.json'));
        return tokenUri;
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
    @notice Defines royalty proportion in hundredths of a percent.
     */
    uint256 public royaltyBasisPoints = 1000;

    /**
    @notice The recipient of secondary revenues.
     */
    address payable private royaltyBeneficiary;

    uint256 private constant BASIS_POINT_DENOMINATOR = 100 * 100;

    /// @notice Sets the recipient of secondary revenues.
    function setRoyaltyBeneficiary(address payable _beneficiary) public onlyOwner {
        royaltyBeneficiary = _beneficiary;
    }

     /// @notice Sets the royalty basis points for secondary revenues.
    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) public onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
    @notice Implements ERC2981.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        // Probably safe to assume that salePrice will be less than max(uint256)/10000 ;)
        return (
            royaltyBeneficiary == address(0) ? Seller.beneficiary : royaltyBeneficiary, 
            (salePrice * royaltyBasisPoints) / BASIS_POINT_DENOMINATOR
        );
    }
    
    /**
    @notice Already-redeemed signed-minting messages.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint one token as a holder of a signature; most likely from the allow list.
     */
    function mintWithSignature(bytes calldata signature) external payable {
        signers.requireValidSignature(
            abi.encodePacked(msg.sender, uint16(1)),
            signature,
            usedMessages
        );
        _purchase(msg.sender, 1, presalePrice);
    }

    /**
    @notice Adds ERC2981 interface to the set of already-supported interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}