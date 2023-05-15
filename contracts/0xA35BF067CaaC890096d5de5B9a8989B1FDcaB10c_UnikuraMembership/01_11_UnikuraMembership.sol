// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1155Upgradeable} from "seadrop/src-upgradeable/lib/openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "seadrop/src-upgradeable/lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

library UnikuraMembershipStorage {
    struct Layout {
        /// @notice The only address that can burn tokens on this contract.
        address burnAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("seaDrop.contracts.storage.unikuraMembershipStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract UnikuraMembership is ERC1155Upgradeable, OwnableUpgradeable {
    using UnikuraMembershipStorage for UnikuraMembershipStorage.Layout;

    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;

    /**
     * @dev Emit an event when the URI for the token-level metadata
     *      is updated.
     */
    event TokenURIUpdated(string newUri);

    /**
     * @notice This error is emitted when an incorrect sender attempts to burn a token.
     * @dev The error includes the tokenId and the sender address, providing more context for the issue.
     * @param tokenId The token ID of the token that the sender attempted to burn.
     * @param sender The address of the sender that attempted the unauthorized burn.
     */
    error BurnIncorrectSender(uint256 tokenId, address sender);

    /**
     * @notice Modifier to ensure that the `receiver` does not already own a GOLD or SILVER membership token.
     * @dev This modifier checks whether the specified `receiver` owns any membership tokens and reverts if true.
     * @param to The address of the account to check for membership token ownership.
     * @param ids An array of token IDs being transferred.
     * @param amounts An array of token amounts being transferred.
     */
    modifier onlyOneToken(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) {
        if (to != owner()) {
            require(
                ids.length == 1,
                "You can only transact one token at a time"
            );
            require(
                amounts[0] == 1,
                "You can only transact one token at a time"
            );
            if (ids[0] == GOLD) {
                require(
                    balanceOf(to, GOLD) == 0,
                    "You already own a gold membership token"
                );
            }
            if (ids[0] == SILVER) {
                require(
                    balanceOf(to, SILVER) == 0,
                    "You already own a silver membership token"
                );
            }
        }
        _;
    }

    /**
     * @notice Initializes the contract with the given token `uri` and `contractUri`.
     * @dev This function is marked as `initializer` to ensure it is only called once.
     * @param uri The base token URI for the ERC1155 token.
     */
    function initialize(string memory uri) public initializer {
        ERC1155Upgradeable.__ERC1155_init(uri);
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @notice Checks whether the specified `account` owns a GOLD or SILVER membership token.
     * @dev This function is marked as `view` and does not modify the contract state.
     * @param account The address of the account to check for membership token ownership.
     * @return A boolean indicating whether the account owns a GOLD or SILVER membership token.
     */
    function ownsMembership(address account) public view returns (bool) {
        return (balanceOf(account, GOLD) > 0 || balanceOf(account, SILVER) > 0);
    }

    /**
     * @notice Hook that is called before any token transfer, including minting.
     * @dev This function enforces the `onlyOneToken` modifier for the `to` address.
     * @param operator The address performing the token transfer.
     * @param from The address tokens are being transferred from.
     * @param to The address tokens are being transferred to.
     * @param ids An array of token IDs being transferred.
     * @param amounts An array of token amounts being transferred.
     * @param data Additional data provided by the caller.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override onlyOneToken(to, ids, amounts) {}

    /**
     * @notice Mints `amount` tokens of token type `id` to `account`.
     * @dev This function is marked as `public` and can be called by any address.
     * @param account The address of the account to receive the minted tokens.
     * @param id The token type ID to be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual onlyOwner {
        _mint(account, id, amount, "");
    }

    /**
     * @notice Sets the token URI for contract metadata.
     * @param newUri The new token URI.
     */
    function setURI(string calldata newUri) external onlyOwner {
        _setURI(newUri);

        // Emit an event with the update.
        emit TokenURIUpdated(newUri);
    }

    /**
     * @notice Sets the burn address to `newBurnAddress`.
     * @dev This function can only be called by the contract owner.
     * @param newBurnAddress The address to be set as the new burn address.
     */
    function setBurnAddress(address newBurnAddress) external onlyOwner {
        UnikuraMembershipStorage.layout().burnAddress = newBurnAddress;
    }

    /**
     * @notice Returns the current burn address.
     * @dev This function is marked as `view` and does not modify the contract state.
     * @return The address currently set as the burn address.
     */
    function getBurnAddress() public view returns (address) {
        return UnikuraMembershipStorage.layout().burnAddress;
    }

    /**
     * @notice Destroys the specified amount of tokens with the given `tokenId` from the `from` address. Only callable by the set burn address.
     * @param from The address to burn tokens from.
     * @param id The token identifier for the tokens to be burned.
     * @param amount The amount of tokens to be burned.
     * @dev This function can only be called by the address set as the burn address, otherwise it emits the `BurnIncorrectSender` error. The burn address can be any address with a long pattern such as 0x000000000000000000000etc or 0x12345678901234567890 since the chance of someone ever creating the private key for that address is essentially impossible [reddit.com](https://www.reddit.com/r/solidity/comments/nfu20e/burn_address_dead_address/). The ERC20 standard does not mention burning specifically, but it does specify the `Transfer` event as `event Transfer(address indexed _from, address indexed _to, uint256 _value)` to be compatible with any software that meets the standard [stackoverflow.com](https://stackoverflow.com/questions/46043783/solidity-burn-event-vs-transfer-to-0-address).
     */
    function burn(address from, uint256 id, uint256 amount) external {
        if (msg.sender != UnikuraMembershipStorage.layout().burnAddress) {
            revert BurnIncorrectSender(id, msg.sender);
        }

        _burn(from, id, amount);
    }
}