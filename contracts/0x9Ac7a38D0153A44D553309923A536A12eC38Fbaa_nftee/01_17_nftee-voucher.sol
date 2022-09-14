//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
// pragma experimental ABIEncoderV2;
pragma abicoder v2; // required to accept structs as function parameters
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract nftee is ERC721URIStorage, EIP712, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private constant SIGNING_DOMAIN = "nftee-voucher";
    string private constant SIGNATURE_VERSION = "1";

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    struct NFTVoucher {
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The metadata URI to associate with this token. Shall originate from IPFS
        string uri;
        /// @notice The address of the account that instantiated voucher creation
        address redeemer;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    constructor(address payable minter)
        ERC721("nftee_collectible", "nftee")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        // Grant the minter role to a specified account
        _setupRole(MINTER_ROLE, minter);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    /// -------------------------------------------------------------
    /// -------------------------------------------------------------
    /// ------------------------------------------------------------- VOUCHER PROCESSING
    /// -------------------------------------------------------------
    /// -------------------------------------------------------------

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 minPrice,address redeemer,string uri)"
                        ),
                        voucher.minPrice,
                        voucher.redeemer,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }

    /// @notice Derived contract must override function "supportsInterface" due to two or more base classes definition running function with same name and parameter types.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(address redeemer, NFTVoucher calldata voucher)
        public
        payable
        returns (uint256)
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        // make sure that the redeemer is the person that initiated voucher creation
        require(
            redeemer == voucher.redeemer,
            "Address provenance invalid or unauthorized"
        );

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(
            msg.value >= voucher.minPrice,
            "Incorrect payment to redeem the voucher"
        );

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        // first assign the token to the signer, to establish provenance on-chain
        // _mint(signer, voucher.tokenId);
        _safeMint(signer, tokenId);
        _setTokenURI(tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, tokenId);

        return tokenId;
    }
}