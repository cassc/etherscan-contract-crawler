// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GrimNFT is
    ERC721AQueryable,
    Pausable,
    AccessControl,
    EIP712,
    PaymentSplitter
{
    using Strings for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MERKLE_ROOT_ROLE = keccak256("MERKLE_ROOT_ROLE");

    string public constant TOKEN_NAME = "Grim's Return";
    string public constant TOKEN_SYMBOL = "PSYCHOGR";

    string private constant SIGNING_DOMAIN = "psychonutz-gr";
    string private constant SIGNATURE_VERSION = "1.0.0";

    address[] payees = [0x0d0F15B7FF1F02EDBAF333A0176440cF73A887F0];
    uint256[] payeesShares = [100];

    string public GRIM_PROVENANCE;

    string public tokenBaseUri;

    uint256 public constant MAX_SUPPLY = 2009;

    struct NFTVoucher {
        address redeemer;
        uint256 maxMint;
        uint256 transactionQty;
        bytes signature;
    }

    mapping(address => uint256) public redeemedTokens;
    bool public voucherEnabled;

    enum MintType {
        Whitelist, // 0
        Public // 1
    }

    struct MintPhase {
        uint256 price;
        uint256 defaultLimitPerAddress;
        uint256 limitPerTransaction;
        bytes32 merkleRoot;
        mapping(address => uint256) limitPerAddress;
        mapping(address => uint256) mintsPerAddress;
        bool enabled;
    }

    mapping(MintType => MintPhase) public phaseStorage;

    ///// Events

    event ProvenanceHashSet(string _provenanceHash);

    event TokenUriBaseSet(string _tokenBaseUri);

    event VoucherEnabledSet(bool _enabled);

    event PhasePriceSet(uint256 _phase, uint256 _price);

    event PhaseDefaultLimitPerAddressSet(
        uint256 _phase,
        uint256 _defaultLimitPerAddress
    );

    event PhaseLimitPerTransactionSet(
        uint256 _phase,
        uint256 _limitPerTransaction
    );

    event PhaseMerkleRootSet(uint256 _phase, bytes32 _merkleRoot);

    event PhaseLimitPerAddressSet(
        uint256 _phase,
        address _addr,
        uint256 _limitPerAddress
    );

    event PhaseStatusSet(uint256 _phase, bool _status);

    ///// Constructor

    constructor()
        ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
        PaymentSplitter(payees, payeesShares)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROP_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MERKLE_ROOT_ROLE, msg.sender);
    }

    ///// Administrative tasks

    function setProvenanceHash(string calldata _provenanceHash)
        external
        onlyRole(ADMIN_ROLE)
    {
        GRIM_PROVENANCE = _provenanceHash;
        emit ProvenanceHashSet(_provenanceHash);
    }

    function setTokenBaseUri(string calldata _tokenBaseUri)
        external
        onlyRole(ADMIN_ROLE)
    {
        tokenBaseUri = _tokenBaseUri;
        emit TokenUriBaseSet(_tokenBaseUri);
    }

    function setVoucherEnabled(bool _enabled) external onlyRole(ADMIN_ROLE) {
        voucherEnabled = _enabled;
        emit VoucherEnabledSet(_enabled);
    }

    function setPhasePrice(uint256 _phase, uint256 _price)
        external
        onlyRole(ADMIN_ROLE)
    {
        phaseStorage[MintType(_phase)].price = _price;
        emit PhasePriceSet(_phase, _price);
    }

    function setPhaseDefaultLimitPerAddress(
        uint256 _phase,
        uint256 _defaultLimitPerAddress
    ) external onlyRole(ADMIN_ROLE) {
        phaseStorage[MintType(_phase)]
            .defaultLimitPerAddress = _defaultLimitPerAddress;
        emit PhaseDefaultLimitPerAddressSet(_phase, _defaultLimitPerAddress);
    }

    function setPhaseLimitPerTransaction(
        uint256 _phase,
        uint256 _limitPerTransaction
    ) external onlyRole(ADMIN_ROLE) {
        phaseStorage[MintType(_phase)]
            .limitPerTransaction = _limitPerTransaction;
        emit PhaseLimitPerTransactionSet(_phase, _limitPerTransaction);
    }

    function setPhaseMerkleRoot(uint256 _phase, bytes32 _merkleRoot)
        external
        onlyRole(MERKLE_ROOT_ROLE)
    {
        phaseStorage[MintType(_phase)].merkleRoot = _merkleRoot;
        emit PhaseMerkleRootSet(_phase, _merkleRoot);
    }

    function setPhaseLimitPerAddress(
        uint256 _phase,
        address _addr,
        uint256 _limitPerAddress
    ) external onlyRole(ADMIN_ROLE) {
        phaseStorage[MintType(_phase)].limitPerAddress[
            _addr
        ] = _limitPerAddress;
        emit PhaseLimitPerAddressSet(_phase, _addr, _limitPerAddress);
    }

    function setPhaseStatus(uint256 _phase, bool _status)
        external
        onlyRole(ADMIN_ROLE)
    {
        phaseStorage[MintType(_phase)].enabled = _status;
        emit PhaseStatusSet(_phase, _status);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    ///// Function modifiers

    modifier isPhaseEnabled(bool enabled) {
        require(enabled, "Sale phase is not active");
        _;
    }

    modifier validateLimitPerTransaction(
        uint256 _limitPerTransaction,
        uint256 _numberOfTokens
    ) {
        require(
            _numberOfTokens > 0 && _numberOfTokens <= _limitPerTransaction,
            "Requested number of tokens is incorrect"
        );
        _;
    }

    modifier validateLimitPerAddress(
        uint256 _limitPerAddress,
        uint256 _defaultLimitPerAddress,
        uint256 _mintedTokens,
        uint256 _numberOfTokens
    ) {
        require(
            (_limitPerAddress == 0 && _defaultLimitPerAddress == 0) ||
                (_limitPerAddress > 0 &&
                    _mintedTokens + _numberOfTokens <= _limitPerAddress) ||
                _mintedTokens + _numberOfTokens <= _defaultLimitPerAddress,
            "Exceeds number of allowed mints for current phase"
        );
        _;
    }

    modifier ensureAvailabilityFor(uint256 _numberOfTokens) {
        require(
            _totalMinted() + _numberOfTokens <= MAX_SUPPLY,
            "Requested number of tokens not available"
        );
        _;
    }

    modifier validateEthPayment(uint256 _price, uint256 _numberOfTokens) {
        require(
            _price * _numberOfTokens == msg.value,
            "Insufficient ether amount"
        );
        _;
    }

    ///// Internal

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
                            "NFTVoucher(address redeemer,uint256 maxMint)"
                        ),
                        voucher.redeemer,
                        voucher.maxMint
                    )
                )
            );
    }

    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _mintPhase(
        uint256 _phase,
        uint256 _numberOfTokens,
        address _to
    ) internal {
        phaseStorage[MintType(_phase)].mintsPerAddress[_to] += _numberOfTokens;
        _mint(_to, _numberOfTokens);
    }

    function _executeCommonValidations(
        bool _enabled,
        uint256 _limitPerTransaction,
        uint256 _limitPerAddress,
        uint256 _defaultLimitPerAddress,
        uint256 _mintedTokens,
        uint256 _numberOfTokens,
        uint256 _price
    )
        internal
        whenNotPaused
        isPhaseEnabled(_enabled)
        validateLimitPerTransaction(_limitPerTransaction, _numberOfTokens)
        validateLimitPerAddress(
            _limitPerAddress,
            _defaultLimitPerAddress,
            _mintedTokens,
            _numberOfTokens
        )
        ensureAvailabilityFor(_numberOfTokens)
        validateEthPayment(_price, _numberOfTokens)
    {}

    function _executeCommonValidations(uint256 _phase, uint256 _numberOfTokens)
        internal
    {
        _executeCommonValidations(
            phaseStorage[MintType(_phase)].enabled,
            phaseStorage[MintType(_phase)].limitPerTransaction,
            phaseStorage[MintType(_phase)].limitPerAddress[msg.sender],
            phaseStorage[MintType(_phase)].defaultLimitPerAddress,
            phaseStorage[MintType(_phase)].mintsPerAddress[msg.sender],
            _numberOfTokens,
            phaseStorage[MintType(_phase)].price
        );
    }

    ///// User actions

    function redeem(NFTVoucher calldata voucher) external payable {
        address signer = _verify(voucher);
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );
        require(
            msg.sender == voucher.redeemer,
            "You can't redeem this voucher"
        );
        uint256 _mintedTokens = redeemedTokens[voucher.redeemer];
        uint256 _limitPerAddress = voucher.maxMint - _mintedTokens;
        _executeCommonValidations(
            voucherEnabled, // _enabled
            _limitPerAddress, // _limitPerTransaction
            _limitPerAddress, // _limitPerAddress
            0, // _defaultLimitPerAddress
            _mintedTokens, // _mintedTokens
            voucher.transactionQty, // _numberOfTokens
            0 // _price
        );
        _mint(voucher.redeemer, voucher.transactionQty);
        redeemedTokens[voucher.redeemer] += voucher.transactionQty;
    }

    function getMintsPerAddress(uint256 _phase)
        external
        view
        returns (uint256)
    {
        return phaseStorage[MintType(_phase)].mintsPerAddress[msg.sender];
    }

    function isWhitelistEligible(
        uint256 _phase,
        address _addr,
        bytes32[] calldata _merkleProof
    ) public view whenNotPaused returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        bytes32 merkleRoot = phaseStorage[MintType(_phase)].merkleRoot;
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function mintWhitelist(
        uint256 _phase,
        bytes32[] calldata _merkleProof,
        uint256 _numberOfTokens
    ) external payable {
        _executeCommonValidations(_phase, _numberOfTokens);
        require(
            isWhitelistEligible(_phase, msg.sender, _merkleProof),
            "You are not eligible in whitelist"
        );
        _mintPhase(_phase, _numberOfTokens, msg.sender);
    }

    function mint(uint256 _phase, uint256 _numberOfTokens) external payable {
        _executeCommonValidations(_phase, _numberOfTokens);
        require(
            phaseStorage[MintType(_phase)].merkleRoot == 0,
            "Sale phase requires a merkle proof parameter"
        );
        _mintPhase(_phase, _numberOfTokens, msg.sender);
    }

    function mintAirdrop(address _to, uint256 _numberOfTokens)
        external
        payable
        whenNotPaused
        onlyRole(AIRDROP_ROLE)
        ensureAvailabilityFor(_numberOfTokens)
    {
        _mint(_to, _numberOfTokens);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid Token ID");
        return
            bytes(tokenBaseUri).length > 0
                ? string(
                    abi.encodePacked(tokenBaseUri, tokenId.toString(), ".json")
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}