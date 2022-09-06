// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GeneralERC721 is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721EnumerableUpgradeable, 
    PausableUpgradeable, 
    AccessControlEnumerableUpgradeable, 
    ERC721BurnableUpgradeable, 
    EIP712Upgradeable,
    UUPSUpgradeable
    {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    string private constant SIGNING_DOMAIN = "Gaming-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    string private _baseTokenURI;
    uint256 private _mintingFee;
    address private _feeTarget;

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;

        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;

        /// @notice The account who signed the signature
        address signer;

        /// @notice The intended receiver
        address receiver;

        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address owner,
        uint256 mintingFee
    ) public initializer {

        _baseTokenURI = baseTokenURI;

        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(UPGRADER_ROLE, owner);

        _feeTarget = owner;
        _mintingFee = mintingFee;
        emit MintingFeeSet(_msgSender(), mintingFee);
    }

    event MintingFeeSet (
        address indexed setBy,
        uint256 mintingFee
    );

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Sets the receiving address for the minting fees
    /// @param newTarget The address of the account which will receive minting fees
    function setFeeTarget(address newTarget) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GeneralERC721: must be admin to change target");
        _feeTarget = newTarget;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(NFTVoucher calldata voucher) public payable returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        require(signer == voucher.signer, "GeneralERC721: signer did not produce voucher");
        
        uint256 mintingFee = _mintingFee;
        // make sure that the tx signer is paying enough to cover the buyer's cost
        require(msg.value == mintingFee + voucher.minPrice, "GeneralERC721: Incorrect funds sent");

        (bool sent, ) = payable(_feeTarget).call{value: mintingFee}("");
        require(sent, "GeneralERC721: Failed to transfer minting fee");

        _safeMint(signer, voucher.tokenId);

        // transfer the token to the receiver
        _transfer(signer, voucher.receiver, voucher.tokenId);

        (bool signerPaid, ) = payable(signer).call{value: voucher.minPrice}("");
        require(signerPaid, "GeneralERC721: Failed to pay signer");

        return voucher.tokenId;
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return EIP712Upgradeable._hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,address signer,address receiver)"),
            voucher.tokenId,
            voucher.minPrice,
            voucher.signer,
            voucher.receiver
        )));
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
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     * to: Address to mint the new token to
     * uri: IPFS CID address that links to an NFT metadata json
     *
     * Issues:
     * Can be front-run 
     */
    function mint(address to, uint256 id) public payable virtual {
        require(msg.value == _mintingFee, "GeneralERC721: Insufficient funds sent");
     
        (bool sent, ) = payable(_feeTarget).call{value: msg.value}("");
        require(sent, "GeneralERC721: Failed to transfer minting fee");

        _safeMint(to, id);
    }

    /// @notice Sets the minting fee
    /// @param newMintingFee The new cost of minting
    function setMintingFee(uint256 newMintingFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GeneralERC721: Only admin can alter the fee");
        _mintingFee = newMintingFee;
        emit MintingFeeSet(_msgSender(), newMintingFee);
    }

    function getMintingFee() public view returns(uint256) {
        return _mintingFee;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}