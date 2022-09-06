// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ITokenUriDelegate.sol";

/// @dev
/// An `OptionalUint` is either absent (the default, uninitialized value) or a
/// `uint256` from `0` through `type(uint256).max - 1`, inclusive. Note that an
/// `OptionalUint` cannot represent the max value of a `uint256`.
type OptionalUint is uint256;

/// @dev
/// Operations on `OptionalUint` values.
///
/// This library uses the terms `encode` and decode rather than the more
/// standard `wrap` and `unwrap` to avoid confusion with the built-in methods
/// on the `OptionalUint` user-defined value type.
library OptionalUints {
    OptionalUint internal constant NONE = OptionalUint.wrap(0);

    /// @dev Tests whether the given `OptionalUint` is present. If it is, call
    /// `decode` to get its value.
    function isPresent(OptionalUint ox) internal pure returns (bool) {
        return OptionalUint.unwrap(ox) != 0;
    }

    /// @dev Encodes a `uint256` as an `OptionalUint` that is present with the
    /// given value, which must be at most `type(uint256).max - 1`. It always
    /// holds that `OptionalUints.encode(x).decode() == x`.
    function encode(uint256 x) internal pure returns (OptionalUint) {
        return OptionalUint.wrap(x + 1);
    }

    /// @dev Decodes a `uint256` that is known to be present. If `ox` is not
    /// actually present, execution reverts. See `isPresent`.
    function decode(OptionalUint ox) internal pure returns (uint256 x) {
        return OptionalUint.unwrap(ox) - 1;
    }
}

struct ShardData {
    uint24 shareMicros;
    uint64 firstSibling;
    uint64 numSiblings; // including self
}

struct ChildSpec {
    uint24 shareMicros;
    address recipient;
}

/// A wallet that divides a stream of revenue into *shards*, with a
/// distribution that may be altered at runtime by the shardbearers. Each shard
/// is entitled to some integer number of millionths of the ETH and ERC-20
/// tokens sent to this wallet. This number is called its *share*. Initially,
/// there is a single genesis shard that is entitled to the entire stream. At
/// any point, a shard may be split into child shards with an arbitrary
/// distribution of the parent's share, and child shards may be merged back
/// together by a common owner/operator.
///
/// When created, a shard is assigned an ID, and an ERC-721 token with the same
/// ID is minted. As long as that ERC-721 token exists, we say that the shard
/// is "active". A shard becomes inactive when it is reforged into one or more
/// child shards. That is, a shard is active if and only if it is not a parent
/// of any other shard.
///
/// Methods on this contract use the parameter name `tokenId` when referring to
/// a shard that must be active, or `shardId` to refer to any shard. Any
/// parameter of type `IERC20` may be `address(0)` to denote ETH or a non-zero
/// address to denote an ERC-20 token.
///
/// @dev
/// Shard IDs are represented internally as `uint64`s. This implies that not
/// more than 2^64 shards can be created (actually 2^64 - 2), which is not a
/// big deal since IDs are sequentially allocated and so it would take an
/// enormous amount of gas to approach that point. Because the ERC-721 APIs all
/// use `uint256` token IDs, we also use `uint256`s at our API boundaries for
/// compatibility; only internal data stuctures use `uint64`s for shard IDs.
/// Most of the time, this shouldn't be a problem; just be careful not to
/// accidentally truncate a `uint256` to a `uint64` without first checking
/// whether the shard exists or similar.
contract Shardwallet is ERC721, Initializable, Ownable {
    using OptionalUints for OptionalUint;

    uint24 internal constant ONE_MILLION = 1000000;

    uint64 nextTokenId_;
    mapping(uint64 => ShardData) shardData_;
    mapping(uint64 => uint64[]) parents_; // keyed by ID of first child
    mapping(IERC20 => mapping(uint64 => OptionalUint)) claimRecord_;

    mapping(IERC20 => uint256) distributed_;

    ITokenUriDelegate tokenUriDelegate_;
    string name_;
    string symbol_;

    /// Emitted when the given parent shards are reforged into one or more
    /// children with a new distribution of shares.
    event Reforging(
        uint256[] parents,
        uint256 firstChildId,
        uint24[] childrenSharesMicros
    );

    /// Emitted when a shardbearer claims revenues for a given currency. This
    /// event is emitted even when the `amount` is zero (though in that case no
    /// call to transfer ether or ERC-20s will actually be made).
    event Claim(
        uint256 indexed tokenId,
        IERC20 indexed currency,
        uint256 amount
    );

    constructor() ERC721("", "") {}

    function initialize(
        address owner,
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        _transferOwnership(owner);
        name_ = _name;
        symbol_ = _symbol;

        nextTokenId_ = 2;
        shardData_[1] = ShardData({
            shareMicros: ONE_MILLION,
            firstSibling: 1,
            numSiblings: 1
        });
        // (`parents_[1]` is empty by default, which is correct.)
        _safeMint(owner, 1);
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return name_;
    }

    function symbol() public view override returns (string memory) {
        return symbol_;
    }

    /// Combines one or more shards and redistributes their share to one or
    /// more children. The parents must all be distinct, active shards, and the
    /// caller must be an owner or operator of each parent. The total shares of
    /// the children must add to the total shares of the parents.
    ///
    /// The children are assigned consecutive IDs, with the same order as given
    /// by `splits`. The return value is the ID of the first child shard.
    function reforge(uint256[] memory parents, ChildSpec[] memory splits)
        public
        returns (uint256)
    {
        if (parents.length == 0) {
            // Don't allow arbitrary callers to mint zero-share tokens.
            revert("Shardwallet: no parents");
        }
        uint64 firstChildId = nextTokenId_;
        {
            uint256 newNextTokenId = firstChildId + splits.length;
            if (newNextTokenId > type(uint64).max) {
                // Technically possible, but would require paying an enormous
                // amount of gas to mint this many tokens.
                revert();
            }
            nextTokenId_ = uint64(newNextTokenId);
        }

        uint24 totalShareMicros = 0;
        uint64[] memory parents64 = new uint64[](parents.length);
        for (uint256 i = 0; i < parents.length; i++) {
            uint256 parent = parents[i];
            if (!_isApprovedOrOwner(msg.sender, parent)) {
                revert("Shardwallet: unauthorized");
            }
            _burn(parent);
            uint64 parent64 = uint64(parent);
            // Truncation should be lossless, because we only mint tokens with
            // IDs that fit into `uint64`s, and we just burned this token.
            assert(parent64 == parent);
            parents64[i] = parent64;
            totalShareMicros += shardData_[parent64].shareMicros;
        }
        parents_[firstChildId] = parents64;

        uint24[] memory childrenSharesMicros = new uint24[](splits.length);
        uint64 nextTokenId = firstChildId;
        for (uint256 i = 0; i < splits.length; i++) {
            uint24 micros = splits[i].shareMicros;
            if (micros == 0) {
                revert("Shardwallet: null share");
            }
            if (micros > totalShareMicros) {
                revert("Shardwallet: share too large");
            }
            totalShareMicros -= micros;
            childrenSharesMicros[i] = micros;
            uint64 child = nextTokenId++;
            // Cast is lossless because `firstChildId + splits.length` was
            // previously shown to fit in a `uint64`.
            shardData_[child] = ShardData({
                shareMicros: micros,
                firstSibling: firstChildId,
                numSiblings: uint64(splits.length)
            });
        }
        if (totalShareMicros != 0) {
            revert("Shardwallet: share too small");
        }

        emit Reforging({
            parents: parents,
            firstChildId: firstChildId,
            childrenSharesMicros: childrenSharesMicros
        });

        nextTokenId = firstChildId;
        for (uint256 i = 0; i < splits.length; i++) {
            _safeMint(splits[i].recipient, nextTokenId++);
        }

        return firstChildId;
    }

    /// Splits a shard into one or more child shards, with shares and ownership
    /// distributed according to `splits`. The caller must be an owner or
    /// operator of the parent shard.
    ///
    /// The children are assigned consecutive IDs, with the same order as given
    /// by `splits`. The return value is the ID of the first child shard.
    function split(uint256 tokenId, ChildSpec[] memory splits)
        external
        returns (uint256 firstChildId)
    {
        uint256[] memory parents = new uint256[](1);
        parents[0] = tokenId;
        return reforge(parents, splits);
    }

    /// Merges multiple shards into one new shard, owned by the caller. The
    /// parents must all be distinct, active shards, and the caller must be an
    /// owner or operator of each parent.
    ///
    /// The return value includes the new shard's ID and share, which equals
    /// the combined shares of all the parents.
    function merge(uint256[] memory parents)
        external
        returns (uint256 child, uint24 shareMicros)
    {
        uint256 shareMicrosWord = 0;
        for (uint256 i = 0; i < parents.length; i++) {
            // If this cast to `uint64` is lossy, then `parents[i]` can't be a
            // real token, so we'll fail anyway when `reforge` checks that
            // `msg.sender` can operate the parent (which is provided before
            // truncation).
            shareMicrosWord += shardData_[uint64(parents[i])].shareMicros;
        }
        shareMicros = uint24(shareMicrosWord);
        ChildSpec[] memory splits = new ChildSpec[](1);
        splits[0].recipient = msg.sender;
        splits[0].shareMicros = shareMicros;
        child = reforge(parents, splits);
        // Truncation should be lossless, since `reforge` succeeding means that
        // there weren't any duplicates in the parent list.
        assert(shareMicrosWord == shareMicros);
        return (child, shareMicros);
    }

    /// Returns the portion of `amount` that should be allocated to the child
    /// at `childIndex` among `shares`. When computed for each `childIndex`
    /// from `0` through `shares.length - 1`, the results sum to `amount` and
    /// are distributed according to `shares` to within 0.5 ulp.
    function splitClaim(
        uint256 amount,
        uint24[] memory shareMicros,
        uint256 childIndex
    ) internal pure returns (uint256) {
        uint256 n = shareMicros.length;
        uint256 totalShare = 0;
        for (uint256 i = 0; i < shareMicros.length; i++) {
            totalShare += shareMicros[i];
        }

        uint256 mainClaimMicros = amount * shareMicros[childIndex];
        uint256 result = mainClaimMicros / totalShare;
        uint256 mainLoss = mainClaimMicros - (result * totalShare);
        if (mainLoss == 0) return result;

        uint256 totalLoss = mainLoss;
        uint256 numOutranking = 0;
        for (uint256 i = 0; i < n; i++) {
            if (i == childIndex) continue;
            uint256 thisClaimMicros = amount * shareMicros[i];
            uint256 thisClaim = thisClaimMicros / totalShare;
            uint256 thisLoss = thisClaimMicros - (thisClaim * totalShare);
            totalLoss += thisLoss;
            if (
                thisLoss > mainLoss || (thisLoss == mainLoss && i > childIndex)
            ) {
                numOutranking++;
            }
        }

        uint256 dust = totalLoss / totalShare; // should be exact
        assert(dust * totalShare == totalLoss);
        if (numOutranking < dust) result++;
        return result;
    }

    /// Computes and stores the amount of the given currency that the given
    /// shard has claimed, including any claim or partial claim inherited from
    /// the shard's parents.
    ///
    /// It is valid and can be useful to call this method even if the given
    /// shard is no longer active. For instance, if an active shard has a long
    /// line of ancestors, and no ancestor has an explicit claim record for a
    /// currency, then attempting to directly compute the claim for the active
    /// shard may run out of gas or overflow the stack. Instead, any caller can
    /// split this computation into multiple calls or transactions, by first
    /// computing the claim for some ancestor.
    function computeClaimed(uint256 shardId, IERC20 currency)
        public
        returns (uint256)
    {
        uint64 shardId64 = uint64(shardId);
        if (shardId64 != shardId) return 0; // not a valid shard
        {
            OptionalUint cr = claimRecord_[currency][shardId64];
            if (cr.isPresent()) return cr.decode();
        }
        if (shardId64 == 1) {
            // Genesis token: no parents, so no claim to inherit.
            return 0;
        }
        ShardData memory data = shardData_[shardId64];
        if (data.shareMicros == 0) {
            // No claim, but do not store, as this token could later be created
            // as a child of a token that *has* claimed.
            return 0;
        }

        assert(shardId64 >= data.firstSibling);
        uint256 childIndex = shardId64 - data.firstSibling;
        assert(childIndex < data.numSiblings);

        uint64[] memory parents = parents_[data.firstSibling];
        uint256 parentsClaimed = 0;
        for (uint256 i = 0; i < parents.length; i++) {
            // Note: potential optimization here if the parent was burned
            // before we first distributed this currency, in which case we can
            // prune the whole tree. But that requires storing more state, so
            // not obvious under which conditions it's a win.
            parentsClaimed += computeClaimed(parents[i], currency);
        }
        uint24[] memory siblingSharesMicros = new uint24[](data.numSiblings);
        for (uint256 i = 0; i < data.numSiblings; i++) {
            uint24 shareMicros;
            uint64 sibling = data.firstSibling + uint64(i);
            if (sibling == shardId64) {
                shareMicros = data.shareMicros;
            } else {
                shareMicros = shardData_[sibling].shareMicros;
            }
            siblingSharesMicros[i] = shareMicros;
        }
        uint256 claimed = splitClaim(
            parentsClaimed,
            siblingSharesMicros,
            childIndex
        );
        claimRecord_[currency][shardId64] = OptionalUints.encode(claimed);
        return claimed;
    }

    function _claimSingleCurrencyTo(
        uint256 tokenId256,
        IERC20 currency,
        address payable recipient
    ) internal {
        if (!_isApprovedOrOwner(msg.sender, tokenId256)) {
            revert("Shardwallet: unauthorized");
        }
        uint64 tokenId = uint64(tokenId256);
        assert(tokenId == tokenId256);
        uint24 shareMicros = shardData_[tokenId].shareMicros;

        uint256 balance;
        if (address(currency) == address(0)) {
            balance = address(this).balance;
        } else {
            balance = currency.balanceOf(address(this));
        }
        uint256 distributed = distributed_[currency];
        uint256 received = balance + distributed;

        uint256 entitlement = (received * shareMicros) / ONE_MILLION;
        uint256 priorClaim = computeClaimed(tokenId, currency);
        uint256 amount = 0;
        // `priorClaim` can exceed `entitlement` by up to 1 unit in the
        // aftermath of a split that cannot be wholly divided. (E.g., consider
        // a shard that claims 1 unit of currency and then splits.)
        //
        // `priorClaim` can also exceed `entitlement` if the amount of currency
        // has decreased due to an external actor: e.g., if the currency is an
        // ERC-20 whose admin can unilaterally transfer tokens.
        if (entitlement > priorClaim) {
            amount = entitlement - priorClaim;
            // If balance has decreased due to an external actor, give what we
            // can.
            if (amount > balance) amount = balance;
        }
        emit Claim({tokenId: tokenId, currency: currency, amount: amount});
        if (amount == 0) return;

        uint256 newClaim = priorClaim + amount;
        claimRecord_[currency][tokenId] = OptionalUints.encode(newClaim);
        distributed_[currency] = distributed + amount;
        if (address(currency) == address(0)) {
            recipient.transfer(amount);
        } else {
            if (!currency.transfer(recipient, amount)) {
                revert("Shardwallet: transfer failed");
            }
        }
    }

    /// Claims payments in the given currencies on behalf of the given shard,
    /// sending the funds to `recipient`. The caller must be an owner or
    /// approved operator for the given shard.
    function claimTo(
        uint256 tokenId,
        IERC20[] calldata currencies,
        address payable recipient
    ) public {
        for (uint256 i = 0; i < currencies.length; i++) {
            _claimSingleCurrencyTo(tokenId, currencies[i], recipient);
        }
    }

    /// Claims payments in the given currencies on behalf of the given shard,
    /// sending the funds to the caller. The caller must be an owner or
    /// approved operator for the given shard. This is a convenience method for
    /// `claimTo` where `recipient == msg.sender`.
    function claim(uint256 tokenId, IERC20[] calldata currencies) external {
        claimTo(tokenId, currencies, payable(msg.sender));
    }

    /// Gets the share of the pot allotted to the given shard, in micros. For
    /// example, a return value of `500000` indicates that the shard is
    /// entitled to 50% of the funds that the wallet receives.
    ///
    /// The ERC-721 token for the shard may have been burned, in which case
    /// this method returns historical data. If the shard has never existed,
    /// the result is `0` (which is not a valid return value for a shard that
    /// has existed, since each shard must have a positive share). This method
    /// never reverts.
    function getShareMicros(uint256 shardId) external view returns (uint24) {
        uint64 shardId64 = uint64(shardId);
        if (shardId64 != shardId) return 0;
        return shardData_[shardId64].shareMicros;
    }

    /// Gets the parent shards of the given shard.
    ///
    /// The result is an empty array if `shardId == 1` (the genesis shard has
    /// no parents) or if the shard has never existed.
    function getParents(uint256 shardId)
        external
        view
        returns (uint256[] memory)
    {
        uint64 shardId64 = uint64(shardId);
        if (shardId64 != shardId) return new uint256[](0);
        uint64[] memory parents = parents_[shardData_[shardId64].firstSibling];
        uint256[] memory result = new uint256[](parents.length);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = parents[i];
        }
        return result;
    }

    /// Gets the number of units of the given currency that have been
    /// distributed to shards.
    function getDistributed(IERC20 currency) external view returns (uint256) {
        return distributed_[currency];
    }

    function setTokenUriDelegate(ITokenUriDelegate delegate)
        external
        onlyOwner
    {
        tokenUriDelegate_ = delegate;
    }

    function tokenUriDelegate() external view returns (ITokenUriDelegate) {
        return tokenUriDelegate_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert("ERC721: invalid token ID");
        ITokenUriDelegate delegate = tokenUriDelegate_;
        if (address(delegate) == address(0)) return "";
        return delegate.tokenURI(tokenId);
    }
}