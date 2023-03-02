//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LazyNFT is ERC721URIStorage, EIP712, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string private constant SIGNING_DOMAIN = "LazyNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    address fonooniWallet = 0x96745aaA31A4f7b1b9e2D9221Ee64fF87d8dC174;
    uint256 percentRoyalty = 35;

    mapping(address => uint256) pendingWithdrawals;
    mapping(uint256 => address) public ownerOfId;

    event hashed(bytes32 voucher_hash);

    event signedBy(address indexed signer);

    event redeemed(
        uint256 indexed tokenId,
        address indexed redeemer,
        address indexed signer,
        uint256 price
    );

    constructor(address payable minter)
        ERC721("LazyNFT", "LAZ")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _setupRole(MINTER_ROLE, minter);
        _setupRole(ADMIN_ROLE, minter);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    }

    // @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        // @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        // @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        // @notice The metadata URI to associate with this token.
        string uri;
        // @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(address redeemer, NFTVoucher calldata voucher)
        public
        payable
    {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        emit signedBy(signer);

        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        emit redeemed(voucher.tokenId, msg.sender, signer, voucher.minPrice);

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, voucher.tokenId);

        // mark the tokenId to the ownerWallet
        ownerOfId[voucher.tokenId] = signer;

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += msg.value;
    }

    function ownerOfToken(uint256 tokenId) external view returns (address) {
        return ownerOfId[tokenId];
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw(address _artistAddress) public {
        require(
            hasRole(MINTER_ROLE, _artistAddress),
            "Only authorized minters can withdraw"
        );

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(_artistAddress);
        address payable fonooniAddress = payable(fonooniWallet);
        uint256 pWithdrawals = pendingWithdrawals[receiver];
        pendingWithdrawals[receiver] = 0;

        uint256 royalties = (pWithdrawals * percentRoyalty) / 100;
        (bool fonooniSent, ) = payable(fonooniAddress).call{value: royalties}(
            ""
        );

        require(
            fonooniSent,
            "Marketplace: Fonooni failed to recieve their funds"
        );

        uint256 amount = pWithdrawals - royalties;

        // zero account before transfer to prevent re-entrancy attack
        receiver.transfer(amount);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw(address _artistAddress)
        public
        view
        returns (uint256)
    {
        return pendingWithdrawals[_artistAddress];
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
                            "NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"
                        ),
                        voucher.tokenId,
                        voucher.minPrice,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
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

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        // emit hashed( digest);
        return ECDSA.recover(digest, voucher.signature);
    }

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

    function setFonooniAddress(address newWallet) external onlyOwner {
        fonooniWallet = newWallet;
    }

    function setRoyalties(uint256 _percentRoyalty) external onlyOwner {
        percentRoyalty = _percentRoyalty;
    }

    function getRoyalties() external view returns (uint256) {
        return percentRoyalty;
    }

    function getFonooniAddress() external view returns (address) {
        return fonooniWallet;
    }
}