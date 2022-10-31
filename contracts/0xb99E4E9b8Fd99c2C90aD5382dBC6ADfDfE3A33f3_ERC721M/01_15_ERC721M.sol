//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./IERC721M.sol";

contract ERC721M is IERC721M, ERC721AQueryable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    bool private _mintable;
    bool private _baseURIPermanent;
    // @notice Specify how long a signature from cosigner is valid for, recommend 300 seconds
    uint64 private _timestampExpirySeconds;
    address private _cosigner;
    address private _crossmintAddress;
    uint256 private _maxMintableSupply;
    uint256 private _globalWalletLimit;
    string private _currentBaseURI;
    string private _tokenURISuffix;

    MintStageInfo[] private _mintStages;

    mapping(uint256 => mapping(address => uint32))
        private _stageMintedCountsPerWallet;
    mapping(uint256 => uint256) private _stageMintedCounts;

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory tokenURISuffix,
        uint256 maxMintableSupply,
        uint256 globalWalletLimit,
        address cosigner,
        uint64 timestampExpirySeconds
    ) ERC721A(collectionName, collectionSymbol) {
        if (globalWalletLimit > maxMintableSupply)
            revert GlobalWalletLimitOverflow();

        _mintable = false;
        _maxMintableSupply = maxMintableSupply;
        _globalWalletLimit = globalWalletLimit;
        _tokenURISuffix = tokenURISuffix;
        _cosigner = cosigner; // ethers.constants.AddressZero for no cosigning
        _timestampExpirySeconds = timestampExpirySeconds;
    }

    modifier canMint() {
        if (!_mintable) revert NotMintable();
        _;
    }

    modifier cannotMint() {
        if (_mintable) revert Mintable();
        _;
    }

    modifier hasSupply(uint256 qty) {
        if (totalSupply() + qty > _maxMintableSupply) revert NoSupplyLeft();
        _;
    }

    function getCosigner() external view override returns (address) {
        return _cosigner;
    }

    function getCosignNonce(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    function setCosigner(address cosigner) external onlyOwner {
        _cosigner = cosigner;
        emit SetCosigner(cosigner);
    }

    function setTimestampExpirySeconds(uint64 expiry) external onlyOwner {
        _timestampExpirySeconds = expiry;
        emit SetTimestampExpirySeconds(expiry);
    }

    function getCrossmintAddress() external view override returns (address) {
        return _crossmintAddress;
    }

    function setCrossmintAddress(address crossmintAddress) external onlyOwner {
        _crossmintAddress = crossmintAddress;
        emit SetCrossmintAddress(crossmintAddress);
    }

    function setStages(MintStageInfo[] calldata newStages) external onlyOwner {
        uint256 originalSize = _mintStages.length;
        for (uint256 i = 0; i < originalSize; i++) {
            _mintStages.pop();
        }

        uint64 timestampExpirySeconds = getTimestampExpirySeconds();
        for (uint256 i = 0; i < newStages.length; i++) {
            if (i >= 1) {
                if (
                    newStages[i].startTimeUnixSeconds <
                    newStages[i - 1].endTimeUnixSeconds + timestampExpirySeconds
                ) {
                    revert InsufficientStageTimeGap();
                }
            }
            _assertValidStartAndEndTimestamp(
                newStages[i].startTimeUnixSeconds,
                newStages[i].endTimeUnixSeconds
            );
            _mintStages.push(
                MintStageInfo({
                    price: newStages[i].price,
                    walletLimit: newStages[i].walletLimit,
                    merkleRoot: newStages[i].merkleRoot,
                    maxStageSupply: newStages[i].maxStageSupply,
                    startTimeUnixSeconds: newStages[i].startTimeUnixSeconds,
                    endTimeUnixSeconds: newStages[i].endTimeUnixSeconds
                })
            );
            emit UpdateStage(
                i,
                newStages[i].price,
                newStages[i].walletLimit,
                newStages[i].merkleRoot,
                newStages[i].maxStageSupply,
                newStages[i].startTimeUnixSeconds,
                newStages[i].endTimeUnixSeconds
            );
        }
    }

    function getMintable() external view override returns (bool) {
        return _mintable;
    }

    function setMintable(bool mintable) external onlyOwner {
        _mintable = mintable;
        emit SetMintable(mintable);
    }

    function getNumberStages() external view override returns (uint256) {
        return _mintStages.length;
    }

    function getMaxMintableSupply() external view override returns (uint256) {
        return _maxMintableSupply;
    }

    function setMaxMintableSupply(uint256 maxMintableSupply)
        external
        onlyOwner
    {
        if (maxMintableSupply > _maxMintableSupply) {
            revert CannotIncreaseMaxMintableSupply();
        }
        _maxMintableSupply = maxMintableSupply;
        emit SetMaxMintableSupply(maxMintableSupply);
    }

    function getGlobalWalletLimit() external view override returns (uint256) {
        return _globalWalletLimit;
    }

    function setGlobalWalletLimit(uint256 globalWalletLimit)
        external
        onlyOwner
    {
        if (globalWalletLimit > _maxMintableSupply)
            revert GlobalWalletLimitOverflow();
        _globalWalletLimit = globalWalletLimit;
        emit SetGlobalWalletLimit(globalWalletLimit);
    }

    function totalMintedByAddress(address a)
        external
        view
        override
        returns (uint256)
    {
        return _numberMinted(a);
    }

    function getStageInfo(uint256 index)
        external
        view
        override
        returns (
            MintStageInfo memory,
            uint32,
            uint256
        )
    {
        if (index >= _mintStages.length) {
            revert("InvalidStage");
        }
        uint32 walletMinted = _stageMintedCountsPerWallet[index][msg.sender];
        uint256 stageMinted = _stageMintedCounts[index];
        return (_mintStages[index], walletMinted, stageMinted);
    }

    function updateStage(
        uint256 index,
        uint80 price,
        uint32 walletLimit,
        bytes32 merkleRoot,
        uint24 maxStageSupply,
        uint64 startTimeUnixSeconds,
        uint64 endTimeUnixSeconds
    ) external onlyOwner {
        if (index >= _mintStages.length) revert InvalidStage();
        if (index >= 1) {
            if (
                startTimeUnixSeconds <
                _mintStages[index - 1].endTimeUnixSeconds +
                    getTimestampExpirySeconds()
            ) {
                revert InsufficientStageTimeGap();
            }
        }
        _assertValidStartAndEndTimestamp(
            startTimeUnixSeconds,
            endTimeUnixSeconds
        );
        _mintStages[index].price = price;
        _mintStages[index].walletLimit = walletLimit;
        _mintStages[index].merkleRoot = merkleRoot;
        _mintStages[index].maxStageSupply = maxStageSupply;
        _mintStages[index].startTimeUnixSeconds = startTimeUnixSeconds;
        _mintStages[index].endTimeUnixSeconds = endTimeUnixSeconds;

        emit UpdateStage(
            index,
            price,
            walletLimit,
            merkleRoot,
            maxStageSupply,
            startTimeUnixSeconds,
            endTimeUnixSeconds
        );
    }

    function mint(
        uint32 qty,
        bytes32[] calldata proof,
        uint64 timestamp,
        bytes calldata signature
    ) external payable nonReentrant {
        _mintInternal(qty, msg.sender, proof, timestamp, signature);
    }

    function crossmint(
        uint32 qty,
        address to,
        bytes32[] calldata proof,
        uint64 timestamp,
        bytes calldata signature
    ) external payable nonReentrant {
        if (_crossmintAddress == address(0)) revert CrossmintAddressNotSet();

        // Check the caller is Crossmint
        if (msg.sender != _crossmintAddress) revert CrossmintOnly();

        _mintInternal(qty, to, proof, timestamp, signature);
    }

    function _mintInternal(
        uint32 qty,
        address to,
        bytes32[] calldata proof,
        uint64 timestamp,
        bytes calldata signature
    ) internal canMint hasSupply(qty) {
        uint64 stageTimestamp = uint64(block.timestamp);

        MintStageInfo memory stage;
        if (_cosigner != address(0)) {
            assertValidCosign(msg.sender, qty, timestamp, signature);
            _assertValidTimestamp(timestamp);
            stageTimestamp = timestamp;
        }

        uint256 activeStage = getActiveStageFromTimestamp(stageTimestamp);

        stage = _mintStages[activeStage];

        // Check value
        if (msg.value < stage.price * qty) revert NotEnoughValue();

        // Check stage supply if applicable
        if (stage.maxStageSupply > 0) {
            if (_stageMintedCounts[activeStage] + qty > stage.maxStageSupply)
                revert StageSupplyExceeded();
        }

        // Check global wallet limit if applicable
        if (_globalWalletLimit > 0) {
            if (_numberMinted(to) + qty > _globalWalletLimit)
                revert WalletGlobalLimitExceeded();
        }

        // Check wallet limit for stage if applicable, limit == 0 means no limit enforced
        if (stage.walletLimit > 0) {
            if (
                _stageMintedCountsPerWallet[activeStage][to] + qty >
                stage.walletLimit
            ) revert WalletStageLimitExceeded();
        }

        // Check merkle proof if applicable, merkleRoot == 0x00...00 means no proof required
        if (stage.merkleRoot != 0) {
            if (
                MerkleProof.processProof(
                    proof,
                    keccak256(abi.encodePacked(to))
                ) != stage.merkleRoot
            ) revert InvalidProof();
        }

        _stageMintedCountsPerWallet[activeStage][to] += qty;
        _stageMintedCounts[activeStage] += qty;
        _safeMint(to, qty);
    }

    function ownerMint(uint32 qty, address to)
        external
        onlyOwner
        hasSupply(qty)
    {
        _safeMint(to, qty);
    }

    function withdraw() external onlyOwner {
        uint256 value = address(this).balance;
        (bool success, ) = msg.sender.call{value: value}("");
        if (!success) revert WithdrawFailed();
        emit Withdraw(value);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        if (_baseURIPermanent) revert CannotUpdatePermanentBaseURI();
        _currentBaseURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    function setBaseURIPermanent() external onlyOwner {
        _baseURIPermanent = true;
        emit PermanentBaseURI(_currentBaseURI);
    }

    function getTokenURISuffix()
        external
        view
        override
        returns (string memory)
    {
        return _tokenURISuffix;
    }

    function setTokenURISuffix(string calldata suffix) external onlyOwner {
        _tokenURISuffix = suffix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _currentBaseURI;
        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        _toString(tokenId),
                        _tokenURISuffix
                    )
                )
                : "";
    }

    function getCosignDigest(
        address minter,
        uint32 qty,
        uint64 timestamp
    ) public view returns (bytes32) {
        if (_cosigner == address(0)) revert CosignerNotSet();
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    minter,
                    qty,
                    _cosigner,
                    timestamp,
                    _chainID(),
                    getCosignNonce(minter)
                )
            ).toEthSignedMessageHash();
    }

    function assertValidCosign(
        address minter,
        uint32 qty,
        uint64 timestamp,
        bytes memory signature
    ) public view override {
        if (
            !SignatureChecker.isValidSignatureNow(
                _cosigner,
                getCosignDigest(minter, qty, timestamp),
                signature
            )
        ) revert InvalidCosignSignature();
    }

    function getActiveStageFromTimestamp(uint64 timestamp)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 i = 0; i < _mintStages.length; i++) {
            if (
                timestamp >= _mintStages[i].startTimeUnixSeconds &&
                timestamp < _mintStages[i].endTimeUnixSeconds
            ) {
                return i;
            }
        }
        revert InvalidStage();
    }

    function getTimestampExpirySeconds() public view override returns (uint64) {
        return _timestampExpirySeconds;
    }

    function _assertValidTimestamp(uint64 timestamp) internal view {
        if (timestamp < block.timestamp - getTimestampExpirySeconds())
            revert TimestampExpired();
    }

    function _assertValidStartAndEndTimestamp(uint64 start, uint64 end)
        internal
        pure
    {
        if (start >= end) revert InvalidStartAndEndTimestamp();
    }

    function _chainID() private view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }
}