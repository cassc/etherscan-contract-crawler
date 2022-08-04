// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2; // required to accept structs as function parameters
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GeneralERC1155 is 
    Initializable,
    ERC1155Upgradeable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable
    {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string private constant SIGNING_DOMAIN = "Gaming-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    uint256 private _mintingFee;
    address private _feeTarget;

    mapping(uint256 => bool) private _tokenMinted;
    mapping(uint256 => mapping(uint256 => bool)) private _mintingNonce;

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

        /// @notice The amount of tokens to mint
        uint256 amount;

        /// @notice The unique nonce for the voucher
        uint256 nonce;

        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    event MintingFeeSet (
        address indexed setBy,
        uint256 mintingFee
    );

    function initialize(
        string memory baseTokenURI,
        address owner,
        uint256 mintingFee
    ) public initializer {
        
        __ERC1155_init(baseTokenURI);
        __AccessControlEnumerable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);

        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(URI_SETTER_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(UPGRADER_ROLE, owner);

        _feeTarget = owner;
        _mintingFee = mintingFee;
        emit MintingFeeSet(owner, mintingFee);
    }

    /// @notice Sets the receiving address for the minting fees
    /// @param newTarget The address of the account which will receive minting fees
    function setFeeTarget(address newTarget) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GeneralERC1155: must be admin to change target");
        _feeTarget = newTarget;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(NFTVoucher calldata voucher) public payable returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        require(signer == voucher.signer, "GeneralERC1155: signer did not produce voucher");

        require(!_mintingNonce[voucher.tokenId][voucher.nonce], "GeneralERC1155: Voucher already used");
        _mintingNonce[voucher.tokenId][voucher.nonce] = true;

        bytes32 roleID = getRoleID(voucher.tokenId);
        if (_tokenMinted[voucher.tokenId]) {
            require (hasRole(roleID, voucher.signer), "GeneralERC1155: issuer not authorised");
        } else {
            _setupRole(roleID, voucher.signer);
            _tokenMinted[voucher.tokenId] = true;
        }

        uint256 mintingFee = _mintingFee;
        
        // make sure that the tx signer is paying enough to cover the buyer's cost
        require(msg.value == mintingFee + voucher.minPrice, "GeneralERC1155: Incorrect funds sent");

        (bool sent, ) = payable(_feeTarget).call{value: mintingFee}("");
        require(sent, "GeneralERC1155: Failed to transfer minting fee");

        _mint(signer, voucher.tokenId, voucher.amount, "");

        // transfer the token to the receiver
        _safeTransferFrom(signer, voucher.receiver, voucher.tokenId, voucher.amount, "");

        // record payment to signer's withdrawal balance
        (bool signerPaid, ) = payable(signer).call{value: voucher.minPrice}("");
        require(signerPaid, "GeneralERC1155: Failed to pay signer");

        return voucher.tokenId;
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return EIP712Upgradeable._hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,address signer,address receiver,uint256 amount,uint256 nonce)"),
            voucher.tokenId,
            voucher.minPrice,
            voucher.signer,
            voucher.receiver,
            voucher.amount,
            voucher.nonce
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
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - ID must be a blake208-b CID that points to the NFTs metadata json
     *
     * Issues:
     * Can be front-run 
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public payable virtual {
        require(msg.value == _mintingFee, "GeneralERC1155: Insufficient funds sent");
        bytes32 roleID = getRoleID(id);
        address msgSender = _msgSender();
        if (_tokenMinted[id]) {
            require (hasRole(roleID, msgSender), "GeneralERC1155: issuer not authorised");
        } else {
            _setupRole(roleID, msgSender);
            _tokenMinted[id] = true;
        }
        (bool success, ) = payable(_feeTarget).call{value: msg.value}("");
        require(success, "GeneralERC1155: Failed to transfer minting fee");

        _mint(to, id, amount, data);
    }

    /**
     * @dev Allows for batch mint
     *
     *
     * Requirements:
     *
     * - fee must be provided
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public payable virtual {
        uint256 fee = _mintingFee * ids.length;
        require(msg.value == fee, "GeneralERC1155: Insufficient funds sent");
        (bool success, ) = payable(_feeTarget).call{value: fee}("");
        require(success, "GeneralERC1155: Failed to transfer minting fee");

        _mintBatch(to, ids, amounts, data);
    }
    
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Sets the minting fee
    /// @param newMintingFee The new cost of minting
    function setMintingFee(uint256 newMintingFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "GeneralERC1155: Only admin can alter the fee");
        _mintingFee = newMintingFee;
        emit MintingFeeSet(_msgSender(), newMintingFee);
    }

    function getMintingFee() public view returns(uint256) {
        return _mintingFee;
    }

    function getRoleID(uint256 tokenId) internal view returns(bytes32){
        return keccak256(abi.encodePacked("MINTER_ROLE", tokenId));
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
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}