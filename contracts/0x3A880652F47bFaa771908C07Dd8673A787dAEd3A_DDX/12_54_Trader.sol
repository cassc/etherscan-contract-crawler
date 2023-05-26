// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath96 } from "../../libs/SafeMath96.sol";
import { TraderDefs } from "../../libs/defs/TraderDefs.sol";
import { LibDiamondStorageDerivaDEX } from "../../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStorageTrader } from "../../storage/LibDiamondStorageTrader.sol";
import { DDXWalletCloneable } from "../../tokens/DDXWalletCloneable.sol";
import { IDDX } from "../../tokens/interfaces/IDDX.sol";
import { IDDXWalletCloneable } from "../../tokens/interfaces/IDDXWalletCloneable.sol";
import { LibTraderInternal } from "./LibTraderInternal.sol";

/**
 * @title Trader
 * @author DerivaDEX
 * @notice This is a facet to the DerivaDEX proxy contract that handles
 *         the logic pertaining to traders - staking DDX, withdrawing
 *         DDX, receiving DDX rewards, etc.
 */
contract Trader {
    using SafeMath96 for uint96;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event RewardCliffSet(bool rewardCliffSet);

    event DDXRewardIssued(address trader, uint96 amount);

    /**
     * @notice Limits functions to only be called via governance.
     */
    modifier onlyAdmin {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        require(msg.sender == dsDerivaDEX.admin, "Trader: must be called by Gov.");
        _;
    }

    /**
     * @notice Limits functions to only be called post reward cliff.
     */
    modifier postRewardCliff {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();
        require(dsTrader.rewardCliff, "Trader: prior to reward cliff.");
        _;
    }

    /**
     * @notice This function initializes the state with some critical
     *         information, including the on-chain wallet cloneable
     *         contract address. This can only be called via governance.
     * @dev This function is best called as a parameter to the
     *      diamond cut function. This is removed prior to the selectors
     *      being added to the diamond, meaning it cannot be called
     *      again.
     * @dev This function is best called as a parameter to the
     *      diamond cut function. This is removed prior to the selectors
     *      being added to the diamond, meaning it cannot be called
     *      again.
     */
    function initialize(IDDXWalletCloneable _ddxWalletCloneable) external onlyAdmin {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        // Set the on-chain DDX wallet cloneable contract address
        dsTrader.ddxWalletCloneable = _ddxWalletCloneable;
    }

    /**
     * @notice This function sets the reward cliff.
     * @param _rewardCliff Reward cliff.
     */
    function setRewardCliff(bool _rewardCliff) external onlyAdmin {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        // Set the reward cliff (boolean value)
        dsTrader.rewardCliff = _rewardCliff;

        emit RewardCliffSet(_rewardCliff);
    }

    /**
     * @notice This function issues DDX rewards to a trader. It can
     *         only be called via governance.
     * @param _amount DDX tokens to be rewarded.
     * @param _trader Trader recipient address.
     */
    function issueDDXReward(uint96 _amount, address _trader) external onlyAdmin {
        // Call the internal function to issue DDX rewards. This
        // internal function is shareable with other facets that import
        // the LibTraderInternal library.
        LibTraderInternal.issueDDXReward(_amount, _trader);
    }

    /**
     * @notice This function issues DDX rewards to an external address.
     *         It can only be called via governance.
     * @param _amount DDX tokens to be rewarded.
     * @param _recipient External recipient address.
     */
    function issueDDXToRecipient(uint96 _amount, address _recipient) external onlyAdmin {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Transfer DDX from trader to trader's on-chain wallet
        dsDerivaDEX.ddxToken.mint(_recipient, _amount);

        emit DDXRewardIssued(_recipient, _amount);
    }

    /**
     * @notice This function lets traders take DDX from their wallet
     *         into their on-chain DDX wallet. It's important to note
     *         that any DDX staked from the trader to this wallet
     *         delegates the voting rights of that stake back to the
     *         user. To be more explicit, if Alice's personal wallet is
     *         delegating to Bob, and she now stakes a portion of her
     *         DDX into this on-chain DDX wallet of hers, those tokens
     *         will now count towards her voting power, not Bob's, since
     *         her on-chain wallet is automatically delegating back to
     *         her.
     * @param _amount The DDX tokens to be staked.
     */
    function stakeDDXFromTrader(uint96 _amount) external {
        transferDDXToWallet(msg.sender, _amount);
    }

    /**
     * @notice This function lets traders send DDX from their wallet
     *         into another trader's on-chain DDX wallet. It's
     *         important to note that any DDX staked to this wallet
     *         delegates the voting rights of that stake back to the
     *         user.
     * @param _trader Trader address to receive DDX (inside their
     *        wallet, which will be created if it does not already
     *        exist).
     * @param _amount The DDX tokens to be staked.
     */
    function sendDDXFromTraderToTraderWallet(address _trader, uint96 _amount) external {
        transferDDXToWallet(_trader, _amount);
    }

    /**
     * @notice This function lets traders withdraw DDX from their
     *         on-chain DDX wallet to their personal wallet. It's
     *         important to note that the voting rights for any DDX
     *         withdrawn are returned back to the delegatee of the
     *         user's personal wallet. To be more explicit, if Alice is
     *         personal wallet is delegating to Bob, and she now
     *         withdraws a portion of her DDX from this on-chain DDX
     *         wallet of hers, those tokens will now count towards Bob's
     *         voting power, not her's, since her on-chain wallet is
     *         automatically delegating back to her, but her personal
     *         wallet is delegating to Bob. Withdrawals can only happen
     *         when the governance cliff is lifted.
     * @param _amount The DDX tokens to be withdrawn.
     */
    function withdrawDDXToTrader(uint96 _amount) external postRewardCliff {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        TraderDefs.Trader storage trader = dsTrader.traders[msg.sender];

        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Subtract trader's DDX balance in the contract
        trader.ddxBalance = trader.ddxBalance.sub96(_amount);

        // Transfer DDX from trader's on-chain wallet to the trader
        dsDerivaDEX.ddxToken.transferFrom(trader.ddxWalletContract, msg.sender, _amount);
    }

    /**
     * @notice This function gets the attributes for a given trader.
     * @param _trader Trader address.
     */
    function getTrader(address _trader) external view returns (TraderDefs.Trader memory) {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        return dsTrader.traders[_trader];
    }

    /**
     * @notice This function transfers DDX from the sender
     *         to another trader's DDX wallet.
     * @param _trader Trader address' DDX wallet address to transfer
     *        into.
     * @param _amount Amount of DDX to transfer.
     */
    function transferDDXToWallet(address _trader, uint96 _amount) internal {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        TraderDefs.Trader storage trader = dsTrader.traders[_trader];

        // If trader does not have a DDX on-chain wallet yet, create one
        if (trader.ddxWalletContract == address(0)) {
            LibTraderInternal.createDDXWallet(_trader);
        }

        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Add trader's DDX balance in the contract
        trader.ddxBalance = trader.ddxBalance.add96(_amount);

        // Transfer DDX from trader to trader's on-chain wallet
        dsDerivaDEX.ddxToken.transferFrom(msg.sender, trader.ddxWalletContract, _amount);
    }
}