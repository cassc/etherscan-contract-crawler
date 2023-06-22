// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "ERC1155Burnable.sol";
import "OwnableRoles.sol";
import "IShards.sol";

/// @title Prestige Shards for Isekai Meta Faction Wars.
/// @author ItsCuzzo

contract Shards is IShards, OwnableRoles, ERC1155Burnable {
    /// @dev Define `Shard` packed struct.
    struct Shard {
        uint120 supply;
        uint120 burned;
        bool tradeable;
    }

    Shard public shard;

    /// @dev `keccak256("AUTHORIZED_BURNER")`
    uint256 public constant AUTHORIZED_BURNER =
        0x6dfed56f3d168174131a4e9163c47d5ceb4882b561b6092a62ebfb58f2dc8604;

    constructor(string memory uri_) ERC1155(uri_) {
        _initializeOwner(msg.sender);
    }

    /// @notice Function used to airdrop shards to `receipients`.
    /// @param recipients Array of recipient addresses.
    function airdrop(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        unchecked {
            if (recipients.length == 0) revert NoRecipients();
            if (recipients.length != quantities.length)
                revert ArrayLengthMismatch();

            uint120 count;

            for (uint256 i = 0; i < recipients.length; i++) {
                if (quantities[i] == 0) revert NoShards();

                count += uint120(quantities[i]);

                _mint(recipients[i], 0, quantities[i], "");
            }

            shard.supply += count;
        }
    }

    /// @notice Function used to burn shards.
    /// @param from Address to burn from.
    /// @param amount Number of shards to burn.
    /// @dev No balance check of `amount` required as reverts within `_burn`.
    function burn(address from, uint256 amount)
        external
        onlyRoles(AUTHORIZED_BURNER)
    {
        unchecked {
            uint120 count = uint120(amount);

            shard.supply -= count;
            shard.burned += count;

            _burn(from, 0, amount);
        }
    }

    /// @notice Function used to toggle tradeability of shards.
    function toggleTradeability() external onlyOwner {
        shard.tradeable = !shard.tradeable;
    }

    /// @notice Function used to set a new `_uri` value.
    /// @param newURI Newly desired `_uri` value.
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    /// @notice Function used to view the URI value of `id`.
    /// @dev To adhere to the ERC1155 specification, `id` param must be passed.
    function uri(uint256 id) public view override returns (string memory) {
        if (id != 0) revert NonExistent();
        return string(abi.encodePacked(super.uri(0), "0"));
    }

    /// @dev Tradeability of shards can be enabled.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public override(IERC1155, ERC1155) {
        if (!shard.tradeable) revert Untradeable();
        super.safeTransferFrom(from, to, id, value, data);
    }

    /// @dev Tradeability of shards can be enabled.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public override(IERC1155, ERC1155) {
        if (!shard.tradeable) revert Untradeable();
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }
}