// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Storage for LPToken, V1
 */
abstract contract LPTokenStorageV1 {
    /**
     * @notice Redemption state for account
     * @param pending Pending redemption amount
     * @param withdrawn Withdrawn redemption amount
     * @param redemptionQueueTarget Target in vault's redemption queue
     */
    struct Redemption {
        uint256 pending;
        uint256 withdrawn;
        uint256 redemptionQueueTarget;
    }

    /**
     * @dev Mapping of account to redemption state
     */
    mapping(address => Redemption) internal _redemptions;
}

/**
 * @title Storage for LPToken, aggregated
 */
abstract contract LPTokenStorage is LPTokenStorageV1 {

}

/**
 * @title Liquidity Provider (LP) Token for Vault Tranches
 */
contract LPToken is Initializable, OwnableUpgradeable, ERC20Upgradeable, LPTokenStorage {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Insufficient balance
     */
    error InsufficientBalance();

    /**
     * @notice Redemption in progress
     */
    error RedemptionInProgress();

    /**
     * @notice Invalid amount
     */
    error InvalidAmount();

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice LPToken constructor (for proxy)
     * @param name Token name
     * @param symbol Token symbol
     */
    function initialize(string memory name, string memory symbol) external initializer {
        __Ownable_init();
        __ERC20_init(name, symbol);
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @notice Get redemption state for account
     * @param account Account
     * @return Redemption state
     */
    function redemptions(address account) external view returns (Redemption memory) {
        return _redemptions[account];
    }

    /**
     * @notice Get amount of redemption available for withdraw for account
     * @param account Account
     * @param processedRedemptionQueue Current value of vault's processed
     * redemption queue
     * @return Amount available for withdraw
     */
    function redemptionAvailable(address account, uint256 processedRedemptionQueue) public view returns (uint256) {
        Redemption storage redemption = _redemptions[account];

        if (redemption.pending == 0) {
            /* No redemption pending */
            return 0;
        } else if (processedRedemptionQueue >= redemption.redemptionQueueTarget + redemption.pending) {
            /* Full redemption available for withdraw */
            return redemption.pending - redemption.withdrawn;
        } else if (processedRedemptionQueue > redemption.redemptionQueueTarget) {
            /* Partial redemption available for withdraw */
            return processedRedemptionQueue - redemption.redemptionQueueTarget - redemption.withdrawn;
        } else {
            /* No redemption available for withdraw */
            return 0;
        }
    }

    /**************************************************************************/
    /* Privileged API */
    /**************************************************************************/

    /**
     * @notice Mint tokens to account
     * @param to Recipient account
     * @param amount Amount of LP tokens
     */
    function mint(address to, uint256 amount) external virtual onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens from account for redemption
     * @param account Redeeming account
     * @param amount Amount of LP tokens
     * @param currencyAmount Amount of currency tokens
     * @param redemptionQueueTarget Target in vault's redemption queue
     */
    function redeem(
        address account,
        uint256 amount,
        uint256 currencyAmount,
        uint256 redemptionQueueTarget
    ) external onlyOwner {
        Redemption storage redemption = _redemptions[account];

        if (balanceOf(account) < amount) revert InsufficientBalance();
        if (redemption.pending != 0) revert RedemptionInProgress();

        redemption.pending = currencyAmount;
        redemption.withdrawn = 0;
        redemption.redemptionQueueTarget = redemptionQueueTarget;

        _burn(account, amount);
    }

    /**
     * @notice Update account's redemption state for withdraw
     * @param account Redeeming account
     * @param currencyAmount Amount of currency tokens
     * @param processedRedemptionQueue Current value of vault's processed
     * redemption queue
     */
    function withdraw(
        address account,
        uint256 currencyAmount,
        uint256 processedRedemptionQueue
    ) external onlyOwner {
        Redemption storage redemption = _redemptions[account];

        if (redemptionAvailable(account, processedRedemptionQueue) < currencyAmount) revert InvalidAmount();

        if (redemption.withdrawn + currencyAmount == redemption.pending) {
            delete _redemptions[account];
        } else {
            redemption.withdrawn += currencyAmount;
        }
    }
}