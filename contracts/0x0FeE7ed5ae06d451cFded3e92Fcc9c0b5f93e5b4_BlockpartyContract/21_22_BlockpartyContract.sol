//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract BlockpartyContract is ERC165, ERC721URIStorage, EIP712, AccessControl, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    mapping (address => uint8) creatorFee;
    mapping (uint256 => address) tokenCreators;
    mapping (string => uint256) soldAssets;

    Counters.Counter private tokenIdentityGenerator;

    address private voucherSigner;

    /// @notice Creates a new instance of the lazy minting contract
    /// @param signer - the voucher signer account address
    /// @param domain - the signature domain informaation 
    /// used to prevent reusing the voucher accross networks
    /// @param version - the signature version informaation 
    /// used to prevent reusing the voucher across deployments
    constructor(
        address signer, 
        string memory domain, 
        string memory version)
        ERC721("At The Function by PRJKT2700", "ATF") 
        EIP712(domain, version) {
        voucherSigner = signer;
    }

    /// @notice Represents an un-minted NFT, 
    ///  which has not yet been recorded into 
    ///  the blockchain. A signed voucher can 
    ///  be redeemed for a real NFT using the 
    ///  redeem function.
    struct Voucher {
        /// @notice The asset identification generated
        /// by the backend system managing the collection assets.
        string key;

        /// @notice The minimum price (in wei) that the 
        /// NFT creator is willing to accept for the 
        /// initial sale of this NFT.
        uint256 price;

        /// @notice The address of the NFT creator
        /// selling the NFT.
        address from;

        /// @notice The address of the NFT buyer
        /// acquiring the NFT.
        address to;

        /// @notice The metadata URI to associate with 
        /// this token.
        string uri;

        /// @notice Flags the voucher as a giveaway so 
        /// all fees and costs are waived extraordinarelly.
        bool giveaway;

        /// @notice The deadline determines the block number
        /// beyond which the voucher can no longer be used.
        uint256 deadline;
        
        /// @notice The percent of sale paid
        /// to the platform.
        uint256 platformFee;

        /// @notice the EIP-712 signature of all other 
        /// fields in the Voucher struct. For a 
        /// voucher to be valid, it must be signed 
        /// by an account with the MINTER_ROLE.
        bytes signature;
    }

    /// @notice CAUTION: Changing the voucher signer invalidates unredeemed
    /// vouchers signed by the current signer.
    function changeSigner(
        address newSigner) 
        external onlyOwner {
        require(newSigner != address(0), "Signer cannot be empty.");
        require(newSigner != owner(), "Owner cannot be signer.");
        voucherSigner = newSigner;
    }

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice) 
        external view returns (
            address receiver, 
            uint256 royaltyAmount) {
        address creator = tokenCreators[tokenId];
        require(creator != address(0), "Creator not found");
        return (creator, (salePrice * 5) / 100);
    }

    event itemSold(
        uint256 tokenId, 
        string key,
        address from, 
        address to, 
        bool giveaway,
        uint256 soldPrice,
        string tokenUri);

    /// @notice Redeems an Voucher for an actual NFT, creating it in the process.
    function redeem(
        Voucher calldata voucher) public payable returns (uint256) {
        // make sure signature is valid and get the address of the creator
        uint256 tokenId = tokenIdentityGenerator.current() + 1;
        // verifies the voucher signature        
        require(_verify(voucher), "Invalid signature");

        // make sure expired vouchers can't be used beyond the dealine (number of blocks)
        require(block.number <= voucher.deadline, "Voucher expired");

        // make sure an asset can't be sold twice
        require(soldAssets[voucher.key] == 0, "Item is sold");

        // when the voucher is for a giveaway, no need to validate amounts or fees
        if (!voucher.giveaway) {
            // make sure the fees aren't lower than 5 percent
            require(voucher.platformFee >= 5, "Fee can't be less than 5%");

            // make sure that the buyer is paying enough to cover the buyer's cost
            // putting in a financial barrier to prevent free mints (airdrops, giveaways)
            require(msg.value >= 0.011 ether || msg.value >= voucher.price, "Insufficient funds");
        }

        // first assign the token to the creator, to establish provenance on-chain
        _safeMint(voucher.from, tokenId);
        _setTokenURI(tokenId, voucher.uri);

        // transfer the token to the buyer
        _transfer(voucher.from, voucher.to, tokenId);
        tokenIdentityGenerator.increment();

        // Fees and commissions are processed only when it isn't a giveaway
        if (!voucher.giveaway) {
            uint256 cut = (msg.value * voucher.platformFee) / 100;
            // the contract owner (marketplace) gets paid the platform fee
            payable(owner()).transfer(cut);
            // the creator gets the remainder of the sale profit
            payable(voucher.from).transfer(msg.value - cut);
        }

        // includes the creator on the royalties creator catalog
        tokenCreators[tokenId] = voucher.from;

        // Adds the asset information to the 'sold assets' catalog
        soldAssets[voucher.key] = tokenId;

        emit itemSold(
            tokenId, 
            voucher.key,
            voucher.from, 
            voucher.to, 
            voucher.giveaway,
            voucher.price,
            voucher.uri);

        // the ID of the newly delivered token
        return tokenId;
    }
    
    /// @notice Checks if it implements the interface defined by `interfaceId`.
    /// @param interfaceId The interface identification that will be verified.
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override (AccessControl, ERC165, ERC721) 
        returns (bool) {
        return ERC721.supportsInterface(interfaceId) 
            || ERC165.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }

    /// @notice Verifies the signature for a given Voucher, returning the verification result (bool).
    /// @dev Will revert if the signature is invalid. Does not verify that the creator is authorized to mint NFTs.
    /// @param voucher An Voucher describing an unminted NFT.
    function _verify(Voucher calldata voucher) internal view returns (bool) {
        bytes32 digest = _hash(voucher);
        return SignatureChecker.isValidSignatureNow(voucherSigner, digest, voucher.signature);
    }

    /// @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An Voucher to hash.
    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Voucher(string key,uint256 price,address from,address to,string uri,bool giveaway,uint256 deadline,uint256 platformFee)"),
            keccak256(bytes(voucher.key)),
            voucher.price,
            voucher.from,
            voucher.to,
            keccak256(bytes(voucher.uri)),
            voucher.giveaway,
            voucher.deadline,
            voucher.platformFee
        )));
    }
}