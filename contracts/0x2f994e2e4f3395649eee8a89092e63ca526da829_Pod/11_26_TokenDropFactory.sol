// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

// Module Interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// Libraries
import "./external/ProxyFactory.sol";

// Clone Contracts
import "./Pod.sol";
import "./TokenDrop.sol";

/**
 * @title TokenDropFactory (ProxyFactory) - Clones a TokenDrop Instance
 * @notice Create a TokenDrop smart contract, which is associated with Pod smart contract for distribution of an asset token (i.e. POOL).
 * @dev The PodFactory creates/initializes TokenDrop smart contract. The factory will generally be called from the PodFactory smart contract directly.
 * @author Kames Geraghty
 */
contract TokenDropFactory is ProxyFactory {
    /***********************************|
    |   Constants                       |
    |__________________________________*/
    /**
     * @notice Contract template for deploying proxied Comptrollers
     */
    TokenDrop public tokenDropInstance;

    /***********************************|
    |   Constructor                     |
    |__________________________________*/
    /**
     * @notice Initializes the TokenDropFactory.
     * @dev Initializes the Factory with a TokenDrop instance.
     */
    constructor() {
        // TokenDrop Instance
        tokenDropInstance = new TokenDrop();
    }

    /**
     * @notice Create a TokenDrop smart contract
     * @dev Creates and initializes the TokenDrop Smart Contract with the measure (i.e. Pod) and asset (i.e. POOL) variables
     * @param _measure The token being tracked to calculate user asset rewards
     * @param _asset The token being rewarded when maintaining a positive balance of the "measure" token
     */
    function create(IERC20Upgradeable _measure, IERC20Upgradeable _asset)
        external
        returns (TokenDrop)
    {
        // TokenDrop Deployed
        TokenDrop tokenDrop =
            TokenDrop(deployMinimal(address(tokenDropInstance), ""));

        // TokenDrop Initialize
        tokenDrop.initialize(_measure, _asset);

        // Return TokenDrop addresses
        return tokenDrop;
    }
}