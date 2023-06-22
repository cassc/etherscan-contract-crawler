// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "ERC1155.sol";
import "Counters.sol";
import "OwnableRoles.sol";
import "LibString.sol";
import "ECDSA.sol";
import "ICoins.sol";
import "IShards.sol";

/// @title Prestige Coins for Isekai Meta Faction Wars.
/// @author ItsCuzzo

contract Coins is ICoins, OwnableRoles, ERC1155 {
    using Counters for Counters.Counter;
    using LibString for uint256;
    using ECDSA for bytes32;

    /// @dev Define `Coin` packed struct.
    struct Coin {
        uint248 supply;
        bool claimable;
    }

    Counters.Counter private _counter;
    address private _signer;

    mapping(uint256 => Coin) public coins;

    IShards public shards;
    uint256 public shardsToBurn = 4;

    /// @dev Since O(1) lookup is required in the Prestige Traits contract, we
    /// opt to use a mapping of an `address` to a `uint256` value. Each bit of
    /// the `uint256` value is representative of a coin `id`. If the returned
    /// value is non-zero, the claimer owns at least 1 coin.
    mapping(address => uint256) private _claimed;

    constructor(string memory uri_, address shards_) ERC1155(uri_) {
        _initializeOwner(msg.sender);
        shards = IShards(shards_);
    }

    /// @notice Function used to claim a Prestige Coin via burning Shards.
    function burnShardsForCoin(uint256 id) external {
        unchecked {
            if (!_exists(id)) revert NonExistent();

            Coin storage coin = coins[id];

            if (!coin.claimable) revert NotClaimable();

            /// Get the bit stored at position `id`.
            uint256 bit = (_claimed[msg.sender] >> id) & 1;

            if (bit != 0) revert HasClaimed();

            shards.burn(msg.sender, shardsToBurn);

            /// Set the bit stored at position `id` to 1.
            _claimed[msg.sender] = _claimed[msg.sender] | (1 << id);

            ++coin.supply;

            _mint(msg.sender, id, 1, "");
        }
    }

    /// @notice Function used to claim a Prestige Coin for winners.
    /// @param id Prestige Coin identifier.
    /// @param signature A signed message digest.
    function claimCoin(uint256 id, bytes calldata signature) external {
        unchecked {
            if (!_exists(id)) revert NonExistent();

            Coin storage coin = coins[id];

            if (!coin.claimable) revert NotClaimable();

            /// Get the bit stored at position `id`.
            uint256 bit = (_claimed[msg.sender] >> id) & 1;

            if (bit != 0) revert HasClaimed();

            /// Utilise `COIN` as a type of domain seperator.
            bytes32 _hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, uint48(id), "COIN"))
                )
            );

            if (_hash.recover(signature) != _signer) revert SignerMismatch();

            /// Set the bit stored at position `id` to 1.
            _claimed[msg.sender] = _claimed[msg.sender] | (1 << id);

            ++coin.supply;

            _mint(msg.sender, id, 1, "");
        }
    }

    /// @notice Function used to toggle Prestige Coin claim status.
    /// @param id Prestige Coin identifier.
    function toggleClaim(uint256 id) external onlyOwner {
        if (!_exists(id)) revert NonExistent();
        coins[id].claimable = !coins[id].claimable;
    }

    /// @notice Function used to add a new Prestige Coin.
    function addCoin() external onlyOwner {
        _counter.increment();
    }

    /// @notice Function used to set the `IShards` address.
    function setShardsContract(address shardsContrant) external onlyOwner {
        shards = IShards(shardsContrant);
    }

    /// @notice Function used to set a new `shardsToBurn` value.
    function setShardsToBurn(uint256 amount) external onlyOwner {
        shardsToBurn = amount;
    }

    function setSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    /// @notice Function used to set a new `_uri` value.
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    /// @notice Function used to determine if `id` exists.
    /// @param id Prestige Coin identifier.
    /// @return bool `true` if `id` exists, `false` otherwise.
    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    /// @notice Function used to view the current number of Prestige Coins.
    function coinCount() external view returns (uint256) {
        return _counter.current();
    }

    /// @notice Function used to view the coins held by `account`.
    /// @param account Address of account to check.
    /// @return results An array of Prestige Coin ids held by `account`.
    function coinsOfAccount(address account)
        external
        view
        returns (uint256[] memory results)
    {
        unchecked {
            uint256 items = _counter.current();
            uint256 count;
            uint256 index;

            for (uint256 id = 0; id < items; id++) {
                if (balanceOf(account, id) != 0) ++count;
            }

            results = new uint256[](count);

            for (uint256 id = 0; id < items; id++) {
                if (balanceOf(account, id) != 0) {
                    results[index] = id;
                    index++;
                }
            }
        }
    }

    /// @notice Function used to determine if `account` holds a Prestige Coin.
    function holdsCoin(address account) external view returns (bool) {
        return _claimed[account] == 0 ? false : true;
    }

    /// @notice Function used to determine if `account` has claimed Prestige Coin `id`.
    function claimed(uint256 id, address account) external view returns (bool) {
        return (_claimed[account] >> id) & 1 != 0 ? true : false;
    }

    function signer() external view returns (address) {
        return _signer;
    }

    /// @notice Function used to view the URI value of `id`.
    function uri(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert NonExistent();
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    /// @dev Prestige Coins are soulbound tokens that aren't tradeable.
    function safeTransferFrom(
        address from,
        address to,
        uint256,
        uint256,
        bytes memory
    ) public pure override(IERC1155, ERC1155) {
        if (from != to) revert Soulbound();
    }

    /// @dev Prestige Coins are soulbound tokens that aren't tradeable.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override(IERC1155, ERC1155) {
        if (from != to) revert Soulbound();
    }

    function _exists(uint256 id) internal view returns (bool) {
        return _counter.current() > id;
    }
}