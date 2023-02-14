// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

error BuffPurchasesNotEnabled();
error InvalidInput();

/**
 * @title Open JTM Buff Boosts V2
 */

contract OpenJimmyTheMonkeyBuffsV2 is Ownable {
    uint256 public constant BUFF_TIME_INCREASE = 600;
    uint256 public constant BUFF_TIME_INCREASE_PADDING = 60;
    uint256 public constant MAX_BUFFS_PER_TRANSACTIONS = 48;
    uint256 public immutable buffCost;
    address public immutable apeCoinContract;
    bool public buffPurchasesEnabled;
    mapping(address => uint256) public playerAddressToBuffTimestamp;

    event BuffPurchased(
        address indexed playerAddress,
        uint256 indexed buffTimestamp,
        uint256 quantityPurchased
    );

    constructor(
        address _apeCoinContract,
        uint256 _buffCost
    ) {
        apeCoinContract = _apeCoinContract;
        buffCost = _buffCost;
    }

    /**
     * @notice Purchase a buff boost - time starts when the transaction is confirmed
     * @param quantity amount of boosts to purchase
     */
    function purchaseBuffs(uint256 quantity) external {
        if (!buffPurchasesEnabled) revert BuffPurchasesNotEnabled();
        if (quantity < 1 || quantity > MAX_BUFFS_PER_TRANSACTIONS)
            revert InvalidInput();

        uint256 newTimestamp;
        uint256 totalBuffIncrease;
        uint256 totalBuffCost;

        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[
            _msgSender()
        ];

        unchecked {
            totalBuffIncrease = quantity * BUFF_TIME_INCREASE;
            totalBuffCost = quantity * buffCost;
        }

        // player has V2 seconds remaining
        if (currentBuffTimestamp > block.timestamp) {
            unchecked {
                newTimestamp = currentBuffTimestamp + totalBuffIncrease;
            }
        } else {
            // player has no V2 seconds remaining
            unchecked {
                newTimestamp =
                    block.timestamp +
                    totalBuffIncrease +
                    BUFF_TIME_INCREASE_PADDING;
            }
        }

        IERC20(apeCoinContract).transferFrom(
            _msgSender(),
            address(this),
            totalBuffCost
        );

        emit BuffPurchased(_msgSender(), newTimestamp, quantity);
        playerAddressToBuffTimestamp[_msgSender()] = newTimestamp;
    }

    /**
     * @notice Get the ending boost timestamp for a player address
     * @param playerAddress the address of the player
     * @return uint256 unix timestamp
     */
    function getBuffTimestampForPlayer(
        address playerAddress
    ) external view returns (uint256) {
        return playerAddressToBuffTimestamp[playerAddress];
    }

    /**
     * @notice Get the seconds remaining in the boost for a player address
     * @param playerAddress the address of the player
     * @return uint256 seconds of boost remaining
     */
    function getRemainingBuffTimeInSeconds(
        address playerAddress
    ) external view returns (uint256) {
        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[
            playerAddress
        ];
        if (currentBuffTimestamp > block.timestamp) {
            return currentBuffTimestamp - block.timestamp;
        }
        return 0;
    }

    // Operator functions

    /**
     * @notice Toggle the purchase state of buffs
     */
    function flipBuffPurchasesEnabled() external onlyOwner {
        buffPurchasesEnabled = !buffPurchasesEnabled;
    }

    /**
     * @notice Withdraw erc-20 tokens
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOwner {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(msg.sender, balance);
        }
    }
}