// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/IERC721A.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";

contract LosVagosNFT is
    ERC721AQueryable,
    Pausable,
    Ownable,
    EIP712,
    PaymentSplitter,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    string public constant TOKEN_NAME = "LosVagosNFT";
    string public constant TOKEN_SYMBOL = "VAGOS";

    string private constant SIGNING_DOMAIN = "gblsts";
    string private constant SIGNATURE_VERSION = "1.0.0";

    address[] public payees = [0x15738f0d2cAB52d172F6D10828894f785a5D9ba5];
    uint256[] public payeesShares = [100];

    enum MintType {
        Free, // 0
        Presale, // 1
        Public // 2
    }

    struct DropInfo {
        string provenanceHash;
        string tokenBaseUri;
        uint256 internalTokenId;
        uint256 maxSupply;
    }

    struct TokenInfo {
        uint256 dropId;
        uint256 internalTokenId;
    }

    struct NFTVoucher {
        address redeemer;
        uint256 maxMint;
        uint256 transactionQty;
        bytes signature;
    }

    mapping(address => uint256) public redeemedTokens;
    bool public voucherEnabled;

    struct MintPhase {
        uint256 price;
        uint256 defaultLimitPerAddress;
        uint256 limitPerTransaction;
        bytes32 merkleRoot;
        mapping(address => uint256) limitPerAddress;
        mapping(address => uint256) mintsPerAddress;
        bool enabled;
    }

    string metadataUri;
    address signer;
    mapping(MintType => MintPhase) public phaseStorage;
    uint256[] availableDrops;
    DropInfo[] public drops;
    mapping(uint256 => uint256) dropsToAvailableDropMap;
    TokenInfo[] internalTokenIds;
    uint256 MAX_INT = 2**256 - 1;
    uint256 public globalMintedTokens;
    uint256 public globalMaxSupply;

    ///// Events

    event ContractUriSet(string _metadataUri);

    event SignerSet(address _signer);

    event DropAdded(uint256 _id);

    event DropEnabled(uint256 _id);

    event DropDisabled(uint256 _id);

    event ProvenanceHashSet(uint256 _id, string _provenanceHash);

    event TokenUriBaseSet(uint256 _id, string _tokenBaseUri);

    event MaxSupplySet(uint256 _id, uint256 _maxSupply);

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

    event VoucherEnabledSet(bool _enabled);

    ///// Constructor

    constructor()
        ERC721A(TOKEN_NAME, TOKEN_SYMBOL)
        PaymentSplitter(payees, payeesShares)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    ///// Administrative tasks

    function setContractUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
        emit ContractUriSet(_metadataUri);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
        emit SignerSet(_signer);
    }

    function addDrop(
        string calldata _provenanceHash,
        string calldata _tokenBaseUri,
        uint256 _maxSupply
    ) external onlyOwner {
        DropInfo memory drop = DropInfo(
            _provenanceHash,
            _tokenBaseUri,
            0,
            _maxSupply
        );
        uint256 id = drops.length;
        drops.push(drop);
        dropsToAvailableDropMap[id] = availableDrops.length;
        availableDrops.push(id);
        globalMaxSupply += _maxSupply;
        emit DropAdded(id);
    }

    function enableDrop(uint256 _id) external onlyOwner isValidDropId(_id) {
        require(
            dropsToAvailableDropMap[_id] == MAX_INT,
            "Drop is already ENABLED"
        );
        require(
            drops[_id].internalTokenId < drops[_id].maxSupply,
            "Drop cannot be enabled because it doesn't have supply"
        );
        availableDrops.push(_id);
        dropsToAvailableDropMap[_id] = availableDrops.length - 1;
        globalMintedTokens += drops[_id].internalTokenId;
        globalMaxSupply += drops[_id].maxSupply;
        emit DropEnabled(_id);
    }

    function disableDrop(uint256 _id) external onlyOwner isValidDropId(_id) {
        _disableDrop(_id);
    }

    function setProvenanceHash(uint256 _id, string calldata _provenanceHash)
        external
        onlyOwner
    {
        drops[_id].provenanceHash = _provenanceHash;
        emit ProvenanceHashSet(_id, _provenanceHash);
    }

    function setTokenBaseUri(uint256 _id, string calldata _tokenBaseUri)
        external
        onlyOwner
    {
        drops[_id].tokenBaseUri = _tokenBaseUri;
        emit TokenUriBaseSet(_id, _tokenBaseUri);
    }

    function setMaxSupply(uint256 _id, uint256 _maxSupply) external onlyOwner {
        drops[_id].maxSupply = _maxSupply;
        emit MaxSupplySet(_id, _maxSupply);
    }

    function setPhasePrice(uint256 _phase, uint256 _price) external onlyOwner {
        phaseStorage[MintType(_phase)].price = _price;
        emit PhasePriceSet(_phase, _price);
    }

    function setPhaseDefaultLimitPerAddress(
        uint256 _phase,
        uint256 _defaultLimitPerAddress
    ) external onlyOwner {
        phaseStorage[MintType(_phase)]
            .defaultLimitPerAddress = _defaultLimitPerAddress;
        emit PhaseDefaultLimitPerAddressSet(_phase, _defaultLimitPerAddress);
    }

    function setPhaseLimitPerTransaction(
        uint256 _phase,
        uint256 _limitPerTransaction
    ) external onlyOwner {
        phaseStorage[MintType(_phase)]
            .limitPerTransaction = _limitPerTransaction;
        emit PhaseLimitPerTransactionSet(_phase, _limitPerTransaction);
    }

    function setPhaseMerkleRoot(uint256 _phase, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        phaseStorage[MintType(_phase)].merkleRoot = _merkleRoot;
        emit PhaseMerkleRootSet(_phase, _merkleRoot);
    }

    function setPhaseLimitPerAddress(
        uint256 _phase,
        address _addr,
        uint256 _limitPerAddress
    ) external onlyOwner {
        phaseStorage[MintType(_phase)].limitPerAddress[
            _addr
        ] = _limitPerAddress;
        emit PhaseLimitPerAddressSet(_phase, _addr, _limitPerAddress);
    }

    function setPhaseStatus(uint256 _phase, bool _status) external onlyOwner {
        phaseStorage[MintType(_phase)].enabled = _status;
        emit PhaseStatusSet(_phase, _status);
    }

    function setVoucherEnabled(bool _enabled) external onlyOwner {
        voucherEnabled = _enabled;
        emit VoucherEnabledSet(_enabled);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///// Function modifiers

    modifier isValidDropId(uint256 _id) {
        require(_id < drops.length, "Drop ID doesn't exist");
        _;
    }

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

    modifier validateEthPayment(uint256 _price, uint256 _numberOfTokens) {
        require(
            _price * _numberOfTokens == msg.value,
            "Insufficient ether amount"
        );
        _;
    }

    ///// Internal

    function _disableDrop(uint256 _id) internal isValidDropId(_id) {
        require(
            dropsToAvailableDropMap[_id] < MAX_INT,
            "Drop is already DISABLED"
        );

        uint256 tmpIndex = availableDrops[availableDrops.length - 1];
        uint256 tmpValue = dropsToAvailableDropMap[_id];
        availableDrops[tmpValue] = tmpIndex;
        availableDrops.pop();
        dropsToAvailableDropMap[tmpIndex] = tmpValue;
        dropsToAvailableDropMap[_id] = MAX_INT;
        globalMintedTokens -= drops[_id].internalTokenId;
        globalMaxSupply -= drops[_id].maxSupply;
        emit DropDisabled(_id);
    }

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

    function _isAvailable(uint256 _numberOfTokens)
        internal
        view
        returns (bool available)
    {
        return globalMintedTokens + _numberOfTokens <= globalMaxSupply;
    }

    function _random(uint256 num) private view returns (uint256) {
        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    globalMintedTokens
                )
            )
        ) % num;
        return randomValue;
    }

    function _mint(
        uint256 _phase,
        uint256 _numberOfTokens,
        address _to
    ) internal {
        require(
            _isAvailable(_numberOfTokens),
            "Requested number of tokens not available"
        );
        phaseStorage[MintType(_phase)].mintsPerAddress[_to] += _numberOfTokens;
        _mint(_to, _numberOfTokens);
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            globalMintedTokens++;
            uint256 _randomDrop = _random(availableDrops.length);
            uint256 dropId = availableDrops[_randomDrop];
            drops[dropId].internalTokenId++;
            TokenInfo memory internalToken = TokenInfo(
                dropId,
                drops[dropId].internalTokenId
            );
            internalTokenIds.push(internalToken);
            if (drops[dropId].internalTokenId >= drops[dropId].maxSupply) {
                _disableDrop(dropId);
            }
        }
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ///// User actions

    function redeem(NFTVoucher calldata voucher) external payable {
        address _signer = _verify(voucher);
        require(signer == _signer, "Signature invalid or unauthorized");
        require(
            msg.sender == voucher.redeemer,
            "You can't redeem this voucher"
        );
        require(
            _isAvailable(voucher.transactionQty),
            "Requested number of tokens not available"
        );
        uint256 _mintedTokens = redeemedTokens[voucher.redeemer];
        _executeCommonValidations(
            voucherEnabled, // _enabled
            voucher.maxMint - _mintedTokens, // _limitPerTransaction
            voucher.maxMint, // _limitPerAddress
            0, // _defaultLimitPerAddress
            _mintedTokens, // _mintedTokens
            voucher.transactionQty, // _numberOfTokens
            0 // _price
        );
        _mint(voucher.redeemer, voucher.transactionQty);
        redeemedTokens[voucher.redeemer] += voucher.transactionQty;
        for (uint256 i = 0; i < voucher.transactionQty; i++) {
            globalMintedTokens++;
            uint256 _randomDrop = _random(availableDrops.length);
            uint256 dropId = availableDrops[_randomDrop];
            drops[dropId].internalTokenId++;
            TokenInfo memory internalToken = TokenInfo(
                dropId,
                drops[dropId].internalTokenId
            );
            internalTokenIds.push(internalToken);
            if (drops[dropId].internalTokenId >= drops[dropId].maxSupply) {
                _disableDrop(dropId);
            }
        }
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
        _mint(_phase, _numberOfTokens, msg.sender);
    }

    function mint(uint256 _phase, uint256 _numberOfTokens) external payable {
        _executeCommonValidations(_phase, _numberOfTokens);
        require(
            phaseStorage[MintType(_phase)].merkleRoot == 0,
            "Sale phase requires a merkle proof parameter"
        );
        _mint(_phase, _numberOfTokens, msg.sender);
    }

    function mintAirdrop(
        uint256 _phase,
        uint256 _numberOfTokens,
        address _to
    ) external payable whenNotPaused onlyOwner {
        _mint(_phase, _numberOfTokens, _to);
    }

    /**
     * Contract-level metadata needed to automatically import the collection
     * into OpenSea (see: https://docs.opensea.io/docs/contract-level-metadata)
     */
    function contractURI() public view returns (string memory) {
        return metadataUri;
    }

    function getSigner() public view returns (address) {
        return signer;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid Token ID");
        TokenInfo memory token = internalTokenIds[tokenId - 1];
        string memory tokenBaseUri = drops[token.dropId].tokenBaseUri;
        return
            bytes(tokenBaseUri).length > 0
                ? string(
                    abi.encodePacked(
                        tokenBaseUri,
                        token.internalTokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}