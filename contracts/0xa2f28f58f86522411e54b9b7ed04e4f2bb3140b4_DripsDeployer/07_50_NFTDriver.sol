// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {
    AccountMetadata, Drips, StreamReceiver, IERC20, SafeERC20, SplitsReceiver
} from "./Drips.sol";
import {DriverTransferUtils, ERC2771Context} from "./DriverTransferUtils.sol";
import {Managed} from "./Managed.sol";
import {
    Context,
    ERC721,
    ERC721Burnable,
    IERC721,
    IERC721Metadata
} from "openzeppelin-contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @notice A Drips driver implementing token-based account identification.
/// Anybody can mint a new token and create a new identity.
/// Only the current holder of the token can control its account ID.
/// The token ID and the account ID controlled by it are always equal.
contract NFTDriver is ERC721Burnable, DriverTransferUtils, Managed {
    using SafeERC20 for IERC20;

    /// @notice The Drips address used by this driver.
    Drips public immutable drips;
    /// @notice The driver ID which this driver uses when calling Drips.
    uint32 public immutable driverId;
    /// @notice The ERC-1967 storage slot holding a single `NFTDriverStorage` structure.
    bytes32 private immutable _nftDriverStorageSlot = _erc1967Slot("eip1967.nftDriver.storage");

    struct NFTDriverStorage {
        /// @notice The number of tokens minted without salt.
        uint64 mintedTokens;
        /// @notice The salts already used for minting tokens.
        mapping(address minter => mapping(uint64 salt => bool)) isSaltUsed;
    }

    /// @param drips_ The Drips contract to use.
    /// @param forwarder The ERC-2771 forwarder to trust. May be the zero address.
    /// @param driverId_ The driver ID to use when calling Drips.
    constructor(Drips drips_, address forwarder, uint32 driverId_)
        DriverTransferUtils(forwarder)
        ERC721("", "")
    {
        drips = drips_;
        driverId = driverId_;
    }

    /// @notice Returns the address of the Drips contract to use for ERC-20 transfers.
    function _drips() internal view override returns (Drips) {
        return drips;
    }

    modifier onlyHolder(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _;
    }

    /// @notice Get the ID of the next minted token.
    /// Every token ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | zeros (160 bits) | mintedTokensCounter (64 bits)`.
    /// @return tokenId The token ID. It's equal to the account ID controlled by it.
    function nextTokenId() public view returns (uint256 tokenId) {
        return calcTokenIdWithSalt(address(0), _nftDriverStorage().mintedTokens);
    }

    /// @notice Calculate the ID of the token minted with salt.
    /// Every token ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | minter (160 bits) | salt (64 bits)`.
    /// @param minter The minter of the token.
    /// @param salt The salt used for minting the token.
    /// @return tokenId The token ID. It's equal to the account ID controlled by it.
    function calcTokenIdWithSalt(address minter, uint64 salt)
        public
        view
        returns (uint256 tokenId)
    {
        // By assignment we get `tokenId` value:
        // `zeros (224 bits) | driverId (32 bits)`
        tokenId = driverId;
        // By bit shifting we get `tokenId` value:
        // `zeros (64 bits) | driverId (32 bits) | zeros (160 bits)`
        // By bit masking we get `tokenId` value:
        // `zeros (64 bits) | driverId (32 bits) | minter (160 bits)`
        tokenId = (tokenId << 160) | uint160(minter);
        // By bit shifting we get `tokenId` value:
        // `driverId (32 bits) | minter (160 bits) | zeros (64 bits)`
        // By bit masking we get `tokenId` value:
        // `driverId (32 bits) | minter (160 bits) | salt (64 bits)`
        tokenId = (tokenId << 64) | salt;
    }

    /// @notice Checks if the salt has already been used for minting a token.
    /// Each minter can use each salt only once, to mint a single token.
    /// @param minter The minter of the token.
    /// @param salt The salt used for minting the token.
    /// @return isUsed True if the salt has been used, false otherwise.
    function isSaltUsed(address minter, uint64 salt) public view returns (bool isUsed) {
        return _nftDriverStorage().isSaltUsed[minter][salt];
    }

    /// @notice Mints a new token controlling a new account ID and transfers it to an address.
    /// Emits account metadata for the new token.
    /// Usage of this method is discouraged, use `safeMint` whenever possible.
    /// @param to The address to transfer the minted token to.
    /// @param accountMetadata The list of account metadata to emit for the minted token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return tokenId The minted token ID. It's equal to the account ID controlled by it.
    function mint(address to, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        tokenId = _registerTokenId();
        _mint(to, tokenId);
        _emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @notice Mints a new token controlling a new account ID,
    /// and safely transfers it to an address.
    /// Emits account metadata for the new token.
    /// @param to The address to transfer the minted token to.
    /// @param accountMetadata The list of account metadata to emit for the minted token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return tokenId The minted token ID. It's equal to the account ID controlled by it.
    function safeMint(address to, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        tokenId = _registerTokenId();
        _safeMint(to, tokenId);
        _emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @notice Registers the next token ID when minting.
    /// @return tokenId The registered token ID.
    function _registerTokenId() internal returns (uint256 tokenId) {
        tokenId = nextTokenId();
        _nftDriverStorage().mintedTokens++;
    }

    /// @notice Mints a new token controlling a new account ID and transfers it to an address.
    /// The token ID is deterministically derived from the caller's address and the salt.
    /// Each caller can use each salt only once, to mint a single token.
    /// Emits account metadata for the new token.
    /// Usage of this method is discouraged, use `safeMint` whenever possible.
    /// @param to The address to transfer the minted token to.
    /// @param accountMetadata The list of account metadata to emit for the minted token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return tokenId The minted token ID. It's equal to the account ID controlled by it.
    /// The ID is calculated using `calcTokenIdWithSalt` for the caller's address and the used salt.
    function mintWithSalt(uint64 salt, address to, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        tokenId = _registerTokenIdWithSalt(salt);
        _mint(to, tokenId);
        _emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @notice Mints a new token controlling a new account ID,
    /// and safely transfers it to an address.
    /// The token ID is deterministically derived from the caller's address and the salt.
    /// Each caller can use each salt only once, to mint a single token.
    /// Emits account metadata for the new token.
    /// @param to The address to transfer the minted token to.
    /// @param accountMetadata The list of account metadata to emit for the minted token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return tokenId The minted token ID. It's equal to the account ID controlled by it.
    /// The ID is calculated using `calcTokenIdWithSalt` for the caller's address and the used salt.
    function safeMintWithSalt(uint64 salt, address to, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        tokenId = _registerTokenIdWithSalt(salt);
        _safeMint(to, tokenId);
        _emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @notice Registers the token ID minted with salt by the caller.
    /// Reverts if the caller has already used the salt.
    /// @return tokenId The registered token ID.
    function _registerTokenIdWithSalt(uint64 salt) internal returns (uint256 tokenId) {
        address minter = _msgSender();
        require(!isSaltUsed(minter, salt), "ERC721: token already minted");
        _nftDriverStorage().isSaltUsed[minter][salt] = true;
        return calcTokenIdWithSalt(minter, salt);
    }

    /// @notice Collects the account's received already split funds
    /// and transfers them out of the Drips contract.
    /// @param tokenId The ID of the token representing the collecting account ID.
    /// The caller must be the owner of the token or be approved to use it.
    /// The token ID is equal to the account ID controlled by it.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param transferTo The address to send collected funds to
    /// @return amt The collected amount
    function collect(uint256 tokenId, IERC20 erc20, address transferTo)
        public
        whenNotPaused
        onlyHolder(tokenId)
        returns (uint128 amt)
    {
        amt = drips.collect(tokenId, erc20);
        if (amt > 0) drips.withdraw(erc20, transferTo, amt);
    }

    /// @notice Gives funds from the account to the receiver.
    /// The receiver can split and collect them immediately.
    /// Transfers the funds to be given from the message sender's wallet to the Drips contract.
    /// @param tokenId The ID of the token representing the giving account ID.
    /// The caller must be the owner of the token or be approved to use it.
    /// The token ID is equal to the account ID controlled by it.
    /// @param receiver The receiver account ID.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param amt The given amount
    function give(uint256 tokenId, uint256 receiver, IERC20 erc20, uint128 amt)
        public
        whenNotPaused
        onlyHolder(tokenId)
    {
        _giveAndTransfer(tokenId, receiver, erc20, amt);
    }

    /// @notice Sets the account's streams configuration.
    /// Transfers funds between the message sender's wallet and the Drips contract
    /// to fulfil the change of the streams balance.
    /// @param tokenId The ID of the token representing the configured account ID.
    /// The caller must be the owner of the token or be approved to use it.
    /// The token ID is equal to the account ID controlled by it.
    /// @param erc20 The used ERC-20 token.
    /// It must preserve amounts, so if some amount of tokens is transferred to
    /// an address, then later the same amount must be transferable from that address.
    /// Tokens which rebase the holders' balances, collect taxes on transfers,
    /// or impose any restrictions on holding or transferring tokens are not supported.
    /// If you use such tokens in the protocol, they can get stuck or lost.
    /// @param currReceivers The current streams receivers list.
    /// It must be exactly the same as the last list set for the account with `setStreams`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The streams balance change to be applied.
    /// Positive to add funds to the streams balance, negative to remove them.
    /// @param newReceivers The list of the streams receivers of the sender to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @param maxEndHint1 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The first hint for finding the maximum end time when all streams stop due to funds
    /// running out after the balance is updated and the new receivers list is applied.
    /// Hints have no effect on the results of calling this function, except potentially saving gas.
    /// Hints are Unix timestamps used as the starting points for binary search for the time
    /// when funds run out in the range of timestamps from the current block's to `2^32`.
    /// Hints lower than the current timestamp are ignored.
    /// You can provide zero, one or two hints. The order of hints doesn't matter.
    /// Hints are the most effective when one of them is lower than or equal to
    /// the last timestamp when funds are still streamed, and the other one is strictly larger
    /// than that timestamp,the smaller the difference between such hints, the higher gas savings.
    /// The savings are the highest possible when one of the hints is equal to
    /// the last timestamp when funds are still streamed, and the other one is larger by 1.
    /// It's worth noting that the exact timestamp of the block in which this function is executed
    /// may affect correctness of the hints, especially if they're precise.
    /// Hints don't provide any benefits when balance is not enough to cover
    /// a single second of streaming or is enough to cover all streams until timestamp `2^32`.
    /// Even inaccurate hints can be useful, and providing a single hint
    /// or two hints that don't enclose the time when funds run out can still save some gas.
    /// Providing poor hints that don't reduce the number of binary search steps
    /// may cause slightly higher gas usage than not providing any hints.
    /// @param maxEndHint2 An optional parameter allowing gas optimization, pass `0` to ignore it.
    /// The second hint for finding the maximum end time, see `maxEndHint1` docs for more details.
    /// @param transferTo The address to send funds to in case of decreasing balance
    /// @return realBalanceDelta The actually applied streams balance change.
    function setStreams(
        uint256 tokenId,
        IERC20 erc20,
        StreamReceiver[] calldata currReceivers,
        int128 balanceDelta,
        StreamReceiver[] calldata newReceivers,
        // slither-disable-next-line similar-names
        uint32 maxEndHint1,
        uint32 maxEndHint2,
        address transferTo
    ) public whenNotPaused onlyHolder(tokenId) returns (int128 realBalanceDelta) {
        return _setStreamsAndTransfer(
            tokenId,
            erc20,
            currReceivers,
            balanceDelta,
            newReceivers,
            maxEndHint1,
            maxEndHint2,
            transferTo
        );
    }

    /// @notice Sets the account splits configuration.
    /// The configuration is common for all ERC-20 tokens.
    /// Nothing happens to the currently splittable funds, but when they are split
    /// after this function finishes, the new splits configuration will be used.
    /// Because anybody can call `split` on `Drips`, calling this function may be frontrun
    /// and all the currently splittable funds will be split using the old splits configuration.
    /// @param tokenId The ID of the token representing the configured account ID.
    /// The caller must be the owner of the token or be approved to use it.
    /// The token ID is equal to the account ID controlled by it.
    /// @param receivers The list of the account's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the account.
    /// If the sum of weights of all receivers is less than `_TOTAL_SPLITS_WEIGHT`,
    /// some funds won't be split, but they will be left for the account to collect.
    /// It's valid to include the account's own `accountId` in the list of receivers,
    /// but funds split to themselves return to their splittable balance and are not collectable.
    /// This is usually unwanted, because if splitting is repeated,
    /// funds split to themselves will be again split using the current configuration.
    /// Splitting 100% to self effectively blocks splitting unless the configuration is updated.
    function setSplits(uint256 tokenId, SplitsReceiver[] calldata receivers)
        public
        whenNotPaused
        onlyHolder(tokenId)
    {
        drips.setSplits(tokenId, receivers);
    }

    /// @notice Emits the account metadata for the given token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param tokenId The ID of the token representing the emitting account ID.
    /// The caller must be the owner of the token or be approved to use it.
    /// The token ID is equal to the account ID controlled by it.
    /// @param accountMetadata The list of account metadata.
    function emitAccountMetadata(uint256 tokenId, AccountMetadata[] calldata accountMetadata)
        public
        whenNotPaused
        onlyHolder(tokenId)
    {
        _emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @notice Emits the account metadata for the given token.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @param tokenId The ID of the token representing the emitting account ID.
    /// The token ID is equal to the account ID controlled by it.
    /// @param accountMetadata The list of account metadata.
    function _emitAccountMetadata(uint256 tokenId, AccountMetadata[] calldata accountMetadata)
        internal
    {
        if (accountMetadata.length == 0) return;
        drips.emitAccountMetadata(tokenId, accountMetadata);
    }

    /// @inheritdoc IERC721Metadata
    function name() public pure override returns (string memory) {
        return "Drips identity";
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public pure override returns (string memory) {
        return "DHI";
    }

    /// @inheritdoc ERC721Burnable
    function burn(uint256 tokenId) public override whenNotPaused {
        super.burn(tokenId);
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public override whenNotPaused {
        super.approve(to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        whenNotPaused
    {
        super.transferFrom(from, to, tokenId);
    }

    // Workaround for https://github.com/ethereum/solidity/issues/12554
    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    // Workaround for https://github.com/ethereum/solidity/issues/12554
    // slither-disable-next-line dead-code
    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    /// @notice Returns the NFTDriver storage.
    /// @return storageRef The storage.
    function _nftDriverStorage() internal view returns (NFTDriverStorage storage storageRef) {
        bytes32 slot = _nftDriverStorageSlot;
        // slither-disable-next-line assembly
        assembly {
            storageRef.slot := slot
        }
    }
}