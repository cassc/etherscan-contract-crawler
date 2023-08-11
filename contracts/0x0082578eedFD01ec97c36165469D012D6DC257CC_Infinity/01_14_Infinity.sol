// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./libraries/InfiniteArt.sol";
import "./libraries/InfiniteBags.sol";
import "./libraries/InfiniteGenerator.sol";
import "./libraries/InfiniteMetadata.sol";

import "./standards/ERC1155.sol";

/// @title Infinity token contract.
/// @notice Imo notable.
/// @author Visualize Value
contract Infinity is ERC1155 {

    /// @notice The name of the collection.
    string public name = "Infinity";

    /// @notice The symbol of the collection.
    string public symbol = unicode"∞";

    /// @notice The price of an infinity token.
    uint public price = 0.008 ether;

    /// @dev VV creator account.
    address private constant VV = 0xc8f8e2F59Dd95fF67c3d39109ecA2e2A017D4c8a;

    /// @dev Instanciate the contract...
    constructor(address[] memory genesisRecipients) ERC1155() payable {
        _checkDeposit(genesisRecipients.length);

        uint count = genesisRecipients.length;
        for (uint i = 0; i < count;) {
            _mint(genesisRecipients[i], 0, 1, "");

            unchecked { ++i; }
        }
    }

    /// @notice Deposit ether, receive random infinities
    receive() external payable {
        _generateViaDeposit(msg.sender, _randomId());
    }

    /// @notice Create a new infinity check and deposit 0.008 ETH for each token.
    /// @param recipient The address that should receive the token.
    /// @param message Mint the token with an optional message.
    function generate(
        address recipient,
        string calldata message
    ) public payable {
        uint tokenId = _randomId();

        _generateViaDeposit(recipient, tokenId);

        _message(recipient, tokenId, message);
    }

    /// @notice Copy an existing infinity check owned by someone and deposit 0.008 ETH for each token.
    /// @param source The address of an existing owner of the token.
    /// @param recipient The address that should receive the token.
    /// @param tokenId The token ID to mint.
    /// @param message Mint the token with an optional message.
    function generateExisting(
        address source,
        address recipient,
        uint tokenId,
        string calldata message
    ) public payable {
        _validateId(tokenId, source);

        _generateViaDeposit(recipient, tokenId);

        _message(recipient, tokenId, message);
    }

    /// @notice Swap an inifinity token for a new one.
    /// @param id The token ID to burn.
    /// @param amount The token amount to burn / recreate.
    function regenerate(uint id, uint amount) public {
        // Execute burn
        _burn(msg.sender, id, amount);

        // Mint a new token
        _mint(msg.sender, _randomId(), amount, "");
    }

    /// @notice Destroy the token to withdraw its desposited ETH.
    /// @param id The token ID to destroy.
    /// @param amount The amount to degenerate (withdraws 0.008 ETH per item).
    function degenerate(
        uint id,
        uint amount
    ) public {
        // Execute burn
        _burn(msg.sender, id, amount);

        // Withdraw funds
        _send(msg.sender, amount * price);
    }

    /// @notice Create multiple infinity check tokens and deposit 0.008 ETH in each.
    /// @param recipients The addresses that should receive the token.
    /// @param amounts The number of tokens to send to each recipient.
    function generateMany(
        address[] calldata recipients,
        uint[] calldata amounts
    ) public payable {
        _checkDeposit(_totalAmount(amounts));

        uint count = recipients.length;
        for (uint i = 0; i < count;) {
            _mint(recipients[i], _randomId(), amounts[i], "");

            unchecked { ++i; }
        }
    }

    /// @notice Copy multiple infinity check tokens and deposit 0.008 ETH in each.
    /// @param sources The addresses of existing owners of each token.
    /// @param recipients The addresses that should receive the token.
    /// @param tokenIds The tokenIDs to mint.
    /// @param amounts The number of tokens to send for each token.
    function generateManyExisting(
        address[] calldata sources,
        address[] calldata recipients,
        uint[] calldata tokenIds,
        uint[] calldata amounts
    ) public payable {
        _checkDeposit(_totalAmount(amounts));

        uint count = sources.length;
        for (uint i = 0; i < count;) {
            _validateId(tokenIds[i], sources[i]);

            _mint(recipients[i], tokenIds[i], amounts[i], "");

            unchecked { ++i; }
        }
    }

    /// @notice Create multiple new infinity check tokens and deposit 0.008 ETH in each.
    /// @param ids The existing token IDs that should be destroyed in the process.
    /// @param degenerateAmounts The number of tokens per id to burn.
    /// @param amounts The number of tokens per id recreate.
    function regenerateMany(
        uint[] calldata ids,
        uint[] calldata degenerateAmounts,
        uint[] calldata amounts
    ) public payable {
        if (_totalAmount(degenerateAmounts) != _totalAmount(amounts)) revert InvalidInput();

        uint count = ids.length;
        for (uint i = 0; i < count;) {
            _burn(msg.sender, ids[i], degenerateAmounts[i]);
            _mint(msg.sender, _randomId(), amounts[i], "");

            unchecked { ++i; }
        }
    }

    /// @notice Degenerate multiple tokens at once.
    /// @param ids The tokenIDs to destroy.
    /// @param amounts The amounts to degenerate (withdraws 0.008 ETH per item).
    function degenerateMany(
        uint[] memory ids,
        uint[] memory amounts
    ) public {
        if (ids.length != amounts.length) revert InvalidInput();

        // Execute burn
        _burnBatch(msg.sender, ids, amounts);

        // Withdraw funds
        _send(msg.sender, _totalAmount(amounts) * price);
    }

    /// @notice Render SVG of the token.
    /// @param tokenId The token ID to render.
    function svg(uint tokenId) public pure returns (string memory) {
        return InfiniteArt.renderSVG(InfiniteGenerator.tokenData(tokenId));
    }

    /// @notice Render the encoded token metadata-URI.
    /// @param tokenId The token ID to get metadata for.
    function uri(uint tokenId) public pure override returns (string memory) {
        return InfiniteMetadata.tokenURI(InfiniteGenerator.tokenData(tokenId));
    }

    /// @notice Supply is (in)finite: (2^256 - 1)^2.
    function totalSupply() public pure returns (uint) { return type(uint).max; }
    function totalSupply(uint) public pure returns (uint) { return type(uint).max; }

    /// @dev Mint a token n times, based on the amount of ETH sent.
    function _generateViaDeposit(address recipient, uint tokenId) internal {
        uint amount  = msg.value / price;
        uint surplus = msg.value % price;

        if (amount == 0) revert InvalidDesposit();

        _mint(recipient, tokenId, amount, "");
        _send(recipient, surplus);
    }

    /// @dev Validate IDs to minted tokens or randomize for initial mints. Exception for VV mints.
    function _validateId(uint id, address source) internal view {
        bool minted = balanceOf(source, id) > 0;

        // If it's not already minted piece, or we are not VV, revert.
        if(! minted && msg.sender != VV) revert InvalidToken();
    }

    /// @dev Make a random generative token ID.
    function _randomId() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, msg.sender, gasleft())));
    }

    /// @dev Check whether the deposited Ether is a correct {price} multipe of the token {amount}
    function _checkDeposit(uint amount) internal {
        if (msg.value != amount * price) revert InvalidDesposit();
    }

    /// @dev Get the sum of all given amounts
    function _totalAmount(uint[] memory amounts) internal pure returns (uint amount) {
        for (uint i = 0; i < amounts.length; i++) {
            amount += amounts[i];
        }
    }

    /// @dev Send ETH to an address
    function _send(address to, uint value) internal {
        (bool success, ) = payable(to).call{value: value}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    /// @dev Emit a mint message, if provided
    function _message(address recipient, uint tokenId, string calldata message) internal {
        if (bytes(message).length > 0) {
            emit Message(msg.sender, recipient, tokenId, message);
        }
    }
}