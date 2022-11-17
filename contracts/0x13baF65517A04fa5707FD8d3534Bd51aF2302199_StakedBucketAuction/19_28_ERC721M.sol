//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./IERC721M.sol";

/**
 * @title ERC721M
 *
 * @dev ERC721A subclass with MagicEden launchpad features including
 *  - multiple minting stages with time-based auto stage switch
 *  - global and stage wallet-level minting limit
 *  - whitelist using merkle tree
 *  - crossmint support
 *  - anti-botting
 */
contract ERC721M is IERC721M, ERC721AQueryable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    event Mint( address to, uint256 qty );


    // Whether this contract is mintable.
    bool private _mintable;

    // Whether base URI is permanent. Once set, base URI is immutable.
    bool private _baseURIPermanent;

    // Specify how long a signature from cosigner is valid for, recommend 300 seconds.
    uint64 private _timestampExpirySeconds;

    // The address of the cosigner server.
    address private _cosigner;

    // The crossmint address. Need to set if using crossmint.
    address private _crossmintAddress;

    // The total mintable supply.
    uint256 private _maxMintableSupply;

    // Global wallet limit, across all stages.
    uint256 private _globalWalletLimit;

    // Current base URI.
    string private _currentBaseURI;

    // The suffix for the token URL, e.g. ".json".
    string private _tokenURISuffix;

    // Mint stage infomation. See MintStageInfo for details.
    MintStageInfo[] private _mintStages;

    // Minted count per stage per wallet.
    mapping(uint256 => mapping(address => uint32))
        private _stageMintedCountsPerWallet;

    // Minted count per stage.
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

    /**
     * @dev Returns whether mintable.
     */
    modifier canMint() {
        if (!_mintable) revert NotMintable();
        _;
    }

    /**
     * @dev Returns whether NOT mintable.
     */
    modifier cannotMint() {
        if (_mintable) revert Mintable();
        _;
    }

    /**
     * @dev Returns whether it has enough supply for the given qty.
     */
    modifier hasSupply(uint256 qty) {
        if (totalSupply() + qty > _maxMintableSupply) revert NoSupplyLeft();
        _;
    }

    /**
     * @dev Returns cosigner address.
     */
    function getCosigner() external view override returns (address) {
        return _cosigner;
    }

    /**
     * @dev Returns cosign nonce.
     */
    function getCosignNonce(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    /**
     * @dev Sets cosigner.
     */
    function setCosigner(address cosigner) external onlyOwner {
        _cosigner = cosigner;
        emit SetCosigner(cosigner);
    }

    /**
     * @dev Returns expiry in seconds.
     */
    function getTimestampExpirySeconds() public view override returns (uint64) {
        return _timestampExpirySeconds;
    }

    /**
     * @dev Sets expiry in seconds. This timestamp specifies how long a signature from cosigner is valid for.
     */
    function setTimestampExpirySeconds(uint64 expiry) external onlyOwner {
        _timestampExpirySeconds = expiry;
        emit SetTimestampExpirySeconds(expiry);
    }

    /**
     * @dev Returns crossmint address.
     */
    function getCrossmintAddress() external view override returns (address) {
        return _crossmintAddress;
    }

    /**
     * @dev Sets crossmint address if using crossmint. This allows the specified address to call `crossmint`.
     */
    function setCrossmintAddress(address crossmintAddress) external onlyOwner {
        _crossmintAddress = crossmintAddress;
        emit SetCrossmintAddress(crossmintAddress);
    }

    /**
     * @dev Sets stages in the format of an array of `MintStageInfo`.
     *
     * Following is an example of launch with two stages. The first stage is exclusive for whitelisted wallets
     * specified by merkle root.
     *    [{
     *      price: 10000000000000000000,
     *      maxStageSupply: 2000,
     *      walletLimit: 1,
     *      merkleRoot: 0x559fadeb887449800b7b320bf1e92d309f329b9641ac238bebdb74e15c0a5218,
     *      startTimeUnixSeconds: 1667768000,
     *      endTimeUnixSeconds: 1667771600,
     *     },
     *     {
     *      price: 20000000000000000000,
     *      maxStageSupply: 3000,
     *      walletLimit: 2,
     *      merkleRoot: 0,
     *      startTimeUnixSeconds: 1667771600,
     *      endTimeUnixSeconds: 1667775200,
     *     }
     * ]
     */
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

    /**
     * @dev Gets whether mintable.
     */
    function getMintable() external view override returns (bool) {
        return _mintable;
    }

    /**
     * @dev Sets mintable.
     */
    function setMintable(bool mintable) external onlyOwner {
        _mintable = mintable;
        emit SetMintable(mintable);
    }

    /**
     * @dev Returns number of stages.
     */
    function getNumberStages() external view override returns (uint256) {
        return _mintStages.length;
    }

    /**
     * @dev Returns maximum mintable supply.
     */
    function getMaxMintableSupply() external view override returns (uint256) {
        return _maxMintableSupply;
    }

    /**
     * @dev Sets maximum mintable supply.
     *
     * New supply cannot be larger than the old.
     */
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

    /**
     * @dev Returns global wallet limit. This is the max number of tokens can be minted by one wallet.
     */
    function getGlobalWalletLimit() external view override returns (uint256) {
        return _globalWalletLimit;
    }

    /**
     * @dev Sets global wallet limit.
     */
    function setGlobalWalletLimit(uint256 globalWalletLimit)
        external
        onlyOwner
    {
        if (globalWalletLimit > _maxMintableSupply)
            revert GlobalWalletLimitOverflow();
        _globalWalletLimit = globalWalletLimit;
        emit SetGlobalWalletLimit(globalWalletLimit);
    }

    /**
     * @dev Returns number of minted token for a given address.
     */
    function totalMintedByAddress(address a)
        external
        view
        override
        returns (uint256)
    {
        return _numberMinted(a);
    }

    /**
     * @dev Returns info for one stage specified by index (starting from 0).
     */
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

    /**
     * @dev Updates info for one stage specified by index (starting from 0).
     */
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

    /**
     * @dev Mints token(s).
     *
     * qty - number of tokens to mint
     * proof - the merkle proof generated on client side. This applies if using whitelist.
     * timestamp - the current timestamp
     * signature - the signature from cosigner if using cosigner.
     */
    function mint(
        uint32 qty,
        bytes32[] calldata proof,
        uint64 timestamp,
        bytes calldata signature
    ) external payable nonReentrant {
        _mintInternal(qty, msg.sender, proof, timestamp, signature);
    }

    /**
     * @dev Mints token(s) through crossmint. This function is supposed to be called by crossmint.
     *
     * qty - number of tokens to mint
     * to - the address to mint tokens to
     * proof - the merkle proof generated on client side. This applies if using whitelist.
     * timestamp - the current timestamp
     * signature - the signature from cosigner if using cosigner.
     */
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

    /**
     * @dev Implementation of minting.
     */
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
            if (stageReservations(activeStage, to) + qty > _globalWalletLimit)
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
        emit Mint( to, qty );
    }

    function stageReservations(uint256 mintStage, address account) public view returns(uint256){
        return _stageMintedCountsPerWallet[mintStage][account];
    }

    /**
     * @notice send all of an address's purchased tokens.
     * @param mintStage stage to send tokens for.
     * @param to address to send tokens to.
     */
    function sendMintTokens(uint256 mintStage, address to) public onlyOwner nonReentrant{
        uint256 prev = _numberMinted(to);
        uint256 qty = stageReservations(mintStage, to);
        if (qty <= prev) return;

        qty -= prev;
        if (totalSupply() + qty > _maxMintableSupply) revert NoSupplyLeft();

        _safeMint(to, qty);
    }

    /**
     * @notice send tokens to a batch of addresses.
     * @param mintStage stage to send tokens for.
     * @param addresses array of addresses to send tokens to.
     */
    function sendMintTokensBatch(uint256 mintStage, address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            sendMintTokens(mintStage, addresses[i]);
        }
    }

    /**
     * @dev Mints token(s) by owner.
     *
     * NOTE: This function bypasses validations thus only available for owner.
     * This is typically used for owner to  pre-mint or mint the remaining of the supply.
     */
    function ownerMint(uint32 qty, address to)
        external
        onlyOwner
        hasSupply(qty)
    {
        _safeMint(to, qty);
    }

    /**
     * @dev Withdraws funds by owner.
     */
    function withdraw() external onlyOwner {
        uint256 value = address(this).balance;
        (bool success, ) = msg.sender.call{value: value}("");
        if (!success) revert WithdrawFailed();
        emit Withdraw(value);
    }

    /**
     * @dev Sets token base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        if (_baseURIPermanent) revert CannotUpdatePermanentBaseURI();
        _currentBaseURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    /**
     * @dev Sets token base URI permanent. Cannot revert.
     */
    function setBaseURIPermanent() external onlyOwner {
        _baseURIPermanent = true;
        emit PermanentBaseURI(_currentBaseURI);
    }

    /**
     * @dev Returns token URI suffix.
     */
    function getTokenURISuffix()
        external
        view
        override
        returns (string memory)
    {
        return _tokenURISuffix;
    }

    /**
     * @dev Sets token URI suffix. e.g. ".json".
     */
    function setTokenURISuffix(string calldata suffix) external onlyOwner {
        _tokenURISuffix = suffix;
    }

    /**
     * @dev Returns token URI for a given token id.
     */
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

    /**
     * @dev Returns data hash for the given minter, qty and timestamp.
     */
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

    /**
     * @dev Validates the the given signature.
     */
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

    /**
     * @dev Returns the current active stage based on timestamp.
     */
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

    /**
     * @dev Validates the timestamp is not expired.
     */
    function _assertValidTimestamp(uint64 timestamp) internal view {
        if (timestamp < block.timestamp - getTimestampExpirySeconds())
            revert TimestampExpired();
    }

    /**
     * @dev Validates the start timestamp is before end timestamp. Used when updating stages.
     */
    function _assertValidStartAndEndTimestamp(uint64 start, uint64 end)
        internal
        pure
    {
        if (start >= end) revert InvalidStartAndEndTimestamp();
    }

    /**
     * @dev Returns chain id.
     */
    function _chainID() private view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }
}