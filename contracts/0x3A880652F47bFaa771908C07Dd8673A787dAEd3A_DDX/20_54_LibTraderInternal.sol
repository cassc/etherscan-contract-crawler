// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import { LibClone } from "../../libs/LibClone.sol";
import { SafeMath96 } from "../../libs/SafeMath96.sol";
import { TraderDefs } from "../../libs/defs/TraderDefs.sol";
import { LibDiamondStorageDerivaDEX } from "../../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStorageTrader } from "../../storage/LibDiamondStorageTrader.sol";
import { IDDX } from "../../tokens/interfaces/IDDX.sol";
import { IDDXWalletCloneable } from "../../tokens/interfaces/IDDXWalletCloneable.sol";

/**
 * @title TraderInternalLib
 * @author DerivaDEX
 * @notice This is a library of internal functions mainly defined in
 *         the Trader facet, but used in other facets.
 */
library LibTraderInternal {
    using SafeMath96 for uint96;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event DDXRewardIssued(address trader, uint96 amount);

    /**
     * @notice This function creates a new DDX wallet for a trader.
     * @param _trader Trader address.
     */
    function createDDXWallet(address _trader) internal {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        // Leveraging the minimal proxy contract/clone factory pattern
        // as described here (https://eips.ethereum.org/EIPS/eip-1167)
        IDDXWalletCloneable ddxWallet = IDDXWalletCloneable(LibClone.createClone(address(dsTrader.ddxWalletCloneable)));

        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Cloneable contracts have no constructor, so instead we use
        // an initialize function. This initialize delegates this
        // on-chain DDX wallet back to the trader and sets the allowance
        // for the DerivaDEX Proxy contract to be unlimited.
        ddxWallet.initialize(_trader, dsDerivaDEX.ddxToken, address(this));

        // Store the on-chain wallet address in the trader's storage
        dsTrader.traders[_trader].ddxWalletContract = address(ddxWallet);
    }

    /**
     * @notice This function issues DDX rewards to a trader. It can be
     *         called by any facet part of the diamond.
     * @param _amount DDX tokens to be rewarded.
     * @param _trader Trader address.
     */
    function issueDDXReward(uint96 _amount, address _trader) internal {
        LibDiamondStorageTrader.DiamondStorageTrader storage dsTrader = LibDiamondStorageTrader.diamondStorageTrader();

        TraderDefs.Trader storage trader = dsTrader.traders[_trader];

        // If trader does not have a DDX on-chain wallet yet, create one
        if (trader.ddxWalletContract == address(0)) {
            createDDXWallet(_trader);
        }

        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();

        // Add trader's DDX balance in the contract
        trader.ddxBalance = trader.ddxBalance.add96(_amount);

        // Transfer DDX from trader to trader's on-chain wallet
        dsDerivaDEX.ddxToken.mint(trader.ddxWalletContract, _amount);

        emit DDXRewardIssued(_trader, _amount);
    }
}