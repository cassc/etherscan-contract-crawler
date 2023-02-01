//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../interfaces/IGORJSAccessPass.sol";
import "../interfaces/IGorjsToken.sol";
import "../roles/AccessRoleUpgradeable.sol";


/**
 * @title GORJSAccessPass
 * @author Alan M.
 * @dev Implementation of MintPass NFT based on ERC1155
 */
// AUDIT: LCL-01 | CENTRALIZED CONTROL OF CONTRACT UPGRADE Category
/// @dev we transfer ownership of proxyAmdin to multi-sig public wallet
// AUDIT: LCL-05 | MISSING INHERITANCE
contract GORJSAccessPass is
    IGORJSAccessPass,
    Initializable,
    OwnableUpgradeable,
    AccessRoleUpgradeable,
    ERC721AUpgradeable,
    EIP712Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// @notice Emitted when oz defender contract is set.
    event SetDefender(address defender);

    /// @notice Emitted when dao token contract is set.
    event SetDaoToken(address daoToken);

    /// @notice Emitted when token price is set.
    event SetTokenPrice(uint256 tokenPrice);

    /// @notice Emitted when mint limit is set.
    event SetMintLimit(uint256 mintLimit);

    /// @notice Emitted when owner withdraw eth from SC.
    event Withdraw(address indexed owner, uint256 balance);

    enum SalesStatus {
        Whitelist,
        Public
    }

    /// @notice Flags for whitelist minting.
    mapping(address => bool) public whitelistMinted;

    /// @notice Amount of nft that minted per wallet.
    mapping(address => uint256) public mintedAmount;

    /// @notice Current sales status, either pre-sale(whitelist) or public sale.
    SalesStatus public salesStatus;

    // ERC20 based yielding token.
    IGorjsToken private _daoToken;

    /// @notice Token price in ETH.
    uint256 public tokenPrice;

    /// @notice Maximum supply of tokens.
    uint256 public maximumSupply;

    /// @dev Maximum amount of token to mint per transaction.
    uint256 private _mintLimitPerTx;

    /// @dev Maximum amount of token to mint in general sale period.
    uint256 private _mintLimit;

    /// @dev Hash of merkle tree root, which is used for whitelist proof.
    bytes32 private _merkleRoot;

    /// @dev OZ defender for EIP712 signature
    address private _defender;

    /// @dev base uri
    string private _baseURIString;

    // AUDIT: LCL-02 | UNPROTECTED INITIALIZER
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer for upgradeable smart contract.
     * @param uri_ The base URL for metadata.
     * @param _tokenPrice The price of an NFT.
     * @param mintLimit_ The maximum amount of NFTs a wallet can mint.
     * @param mintLimitPerTx_ The maximum amount of NFTs a wallet can mint per each transaction.
     * @param _maximumSupply The maximum supply of nft.
     * @param merkleRoot_ The hash of root of the merkle tree for whitelist mint.
     * @param adminWallet The wallet address of admin
     */
    // AUDIT: LCL-07 | FUNCTION SHOULD BE DECLARED EXTERNAL
    function initialize(
        string memory uri_,
        uint256 _tokenPrice,
        uint256 mintLimit_,
        uint256 mintLimitPerTx_,
        uint256 _maximumSupply,
        bytes32 merkleRoot_,
        address defender_,
        address adminWallet
    ) external initializerERC721A  initializer {
        __Context_init();
        __Ownable_init();
        __AccessRole_init(adminWallet);
        __ERC721A_init("GORJS ACCESS PASS", "GORJS");
        __EIP712_init("FKWME-PASS", "1");

        salesStatus = SalesStatus.Whitelist;
        maximumSupply = _maximumSupply;
        tokenPrice = _tokenPrice;

        _mintLimit = mintLimit_;
        _mintLimitPerTx = mintLimitPerTx_;
        _merkleRoot = merkleRoot_;

        _defender = defender_;

        _baseURIString = uri_;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return baseURI;
    }

    /**
     * @dev Base URI can only be set by an Admin.
     * @param baseURIString_ New sales status to be set.
     */
    function setBaseURI(string calldata baseURIString_) external onlyAdmin {
        _baseURIString = baseURIString_;
    }

    /**
     * @dev Sales status can only be set by an Admin.
     * @param _salesStatus New sales status to be set.
     */
    function setSalesStatus(SalesStatus _salesStatus) external onlyAdmin {
        salesStatus = _salesStatus;
    }

    /**
     * @dev Merkle root can only be set by an admin role.
     * @param merkleRoot_ New hash of root node of merkle tree.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyAdmin {
        _merkleRoot = merkleRoot_;
    }

    // AUDIT: LCL-04 | MISSING EMIT EVENTS
    /// @dev Event emitted on _mint function.
    /**
     * @param amount The amount of NFTs to mint.
     * @param signature An EIP-712 signature of minter wallet address in general mint.
     * @param merkleProof A list of hash for whitelist proof.
     */
    function mint(
        uint256 amount, 
        bytes calldata signature,
        bytes32[] calldata merkleProof
    )
        external
        payable
    {
        require(tx.origin == msg.sender, "Caller is SC");

        // AUDIT: GOR-02 | LOGICAL ISSUE OF THE CONDITION
        require(
            msg.value == amount * tokenPrice,
            "ETH amount sent is not enough."
        );
        require(
            totalSupply() + amount <= maximumSupply,
            "You can't mint more than maximum supply."
        );
        require(address(_daoToken) != address(0), "Yielding Token is not set.");
        require(
            amount <= _mintLimitPerTx,
            "You can't mint more than the limit in each transaction"
        );
        require(
            mintedAmount[msg.sender] + amount <= _mintLimit,
            "You can't mint more than the limit in general sale period"
        );

        address to = msg.sender;

        if (salesStatus == SalesStatus.Whitelist) {
            require(whitelistMinted[to] == false, "You've already minted");

            // Verify Merkle Tree
            bytes32 leaf = keccak256(abi.encodePacked(to, amount));
            require(
                MerkleProof.verify(merkleProof, _merkleRoot, leaf),
                "Not whitelisted"
            );
        } else {
            address signer = _verify(to, signature);
            require(signer == _defender, "Invalid signature");
        }

        // Update rewards
        _daoToken.updateRewardsOnMint(to, amount);

        _mint(to, amount);

        // Update nft minted amount
        mintedAmount[to] += amount;

        if (salesStatus == SalesStatus.Whitelist) {
            whitelistMinted[to] = true;
        }
    }

    
    /**
     * @dev OZ defender can only be set by an admin role.
     * @param defender_ The address of oz defender that is used to sign the EIP-712 signature.
     */
    function setDefender(address defender_) external onlyAdmin {
        _defender = defender_;
        emit SetDefender(defender_);
    }

    /**
     * @dev The contract address can only be set by Admin role.
     * @param daoToken_ The address of yielding token.
     */
    function setDaoToken(address daoToken_) external onlyAdmin {
        require(daoToken_ != address(0), "invalid mintPass");
        _daoToken = IGorjsToken(daoToken_);
        emit SetDaoToken(daoToken_);
    }

    /**
     * @dev Token price can only be set by Admin role.
     * @param _tokenPrice New token price.
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyAdmin {
        tokenPrice = _tokenPrice;
        emit SetTokenPrice(_tokenPrice);
    }

    /**
     * @dev Mint limit can only be set by Admin role.
     * @param mintLimit_ Maximum amount of tokens a wallet can mint.
     */
    function setMintLimit(uint256 mintLimit_) external onlyAdmin {
        _mintLimit = mintLimit_;
        emit SetMintLimit(mintLimit_);
    }
    

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev
     * @param from Account to transfer token from
     * @param to Account to transfer token to
     * @param id Token ID to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public payable override onlyAllowedOperator(from) {
        require(address(_daoToken) != address(0), "Yielding Token is not set.");

        _daoToken.updateRewardsOnTransfer(from, to);

        super.transferFrom(from, to, id);
    }

    /**
     * @notice Claim rewards by holding tokens.
     */
    function claimRewards() external override {
        require(address(_daoToken) != address(0), "Yielding Token is not set.");

        _daoToken.claimRewards(msg.sender);
    }

    /**
     * @dev Only owner can withdraw fund.
     */
    function withdraw() external onlyOwner {
        address payable owner = payable(msg.sender);
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Failed to withdraw");
        // AUDIT: LCL-04 | MISSING EMIT EVENTS
        emit Withdraw(owner, balance);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Verifies the signature for a given signature, returning the address of the signer.
     * @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
     * @param receiver A minter of nft.
     * @param signature An EIP-712 signature of minter wallet address in general mint.
     */
    
    function _verify(address receiver, bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address receiver)"),
            receiver
        )));
        return ECDSAUpgradeable.recover(digest, signature);
    }
}