// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/UniERC20.sol";

import "./ClipperPool.sol";
import "./ClipperExchangeInterface.sol";

/*  Deposit contract for locked-up deposits into the vault
    This contract is created by the Pool contract
        
    The interaction is as follows:
    * User transfers tokens to the vault.
    * They register the deposit.
    * They are granted claim to some (unminted) pool tokens, which are reflected in the fullyDilutedSupply of the pool.
    * Once their lockup time passes, they can unlock their deposit, which mints the pool tokens.
*/
contract ClipperDeposit is ReentrancyGuard {
    using UniERC20 for ERC20;
    ClipperPool theExchange;

    constructor() {
        theExchange = ClipperPool(payable(msg.sender));
    }

    struct Deposit {
        uint lockedUntil;
        uint256 poolTokenAmount;
    }

    event Deposited(
        address indexed account,
        uint256 amount
    );

    mapping(address => Deposit) public deposits;

    function hasDeposit(address theAddress) internal view returns (bool) {
        return deposits[theAddress].lockedUntil > 0;
    }

    function canUnlockDeposit(address theAddress) public view returns (bool) {
        Deposit storage myDeposit = deposits[theAddress];
        return hasDeposit(theAddress) && (myDeposit.poolTokenAmount > 0) && (myDeposit.lockedUntil <= block.timestamp);
    }

    function unlockVestedDeposit() public nonReentrant returns (uint256 numTokens) {
        require(canUnlockDeposit(msg.sender), "Deposit cannot be unlocked");
        numTokens = deposits[msg.sender].poolTokenAmount;
        delete deposits[msg.sender];
        theExchange.recordUnlockedDeposit(msg.sender, numTokens);
    }

    /*
        Main deposit contract.

        Uses the deposit / sync / update modality for call simplicity.

        To use:
        Deposit tokens with the pool contract first, then call to record deposit.

        # uint nDays
        + nDays is the minimum contract time that someone is buying into the pool for.
        + After nDays, Clipper will return equitable amount of Clipper pool tokens, along 
          with some yield as reward for buying into the pool.
        + For the special case of nDays = 0, it becomes a simple swap of some ERC20 coins
          for Clipper coins.

        # external
        Publicly accessible and callable to anyone on the blockchain.

        # nonReentrant
        The property means the function cannot recursively call itself.
        It is common best practice to mark nonReentrant every function with side
        effects.
        A simple example is a withdraw function, which should not call withdraw
        again to avoid double spend.

        # uint256 newTokensToMint
        These are the Clipper tokens that is the reward for depositing ERC20 tokens
        into the pool.
    */
    function deposit(uint nDays) external nonReentrant returns(uint256 newTokensToMint) {
        // Check for sanity and depositability
        require((nDays < 2000) && ClipperExchangeInterface(theExchange.exchangeInterfaceContract()).approvalContract().approveDeposit(msg.sender, nDays), "Clipper: Deposit rejected");
        uint256 beforeDepositInvariant = theExchange.exchangeInterfaceContract().invariant();
        uint256 initialFullyDilutedSupply = theExchange.fullyDilutedSupply();

        // 'syncAll' forces the vault to recheck its balances
        // This will cause the invariant to change if a deposit has been made. 
        theExchange.syncAll();

        uint256 afterDepositInvariant = theExchange.exchangeInterfaceContract().invariant();

        // new_inv = (1+\gamma)*old_inv
        // new_tokens = \gamma * old_supply
        // SOLVING:
        // \gamma = new_inv/old_inv - 1
        // new_tokens = (new_inv/old_inv - 1)*old_supply
        // new_tokens = (new_inv*old_supply)/old_inv - old_supply
        newTokensToMint = (afterDepositInvariant*initialFullyDilutedSupply)/beforeDepositInvariant - initialFullyDilutedSupply;

        require(newTokensToMint > 0, "Deposit not large enough");

        theExchange.recordDeposit(newTokensToMint);

        if(nDays == 0 && !hasDeposit(msg.sender)){
            // Immediate unlock
            theExchange.recordUnlockedDeposit(msg.sender, newTokensToMint);
        } else {
            // Add on to existing deposit, if it exists
            Deposit storage curDeposit = deposits[msg.sender];
            uint lockDepositUntil = block.timestamp + (nDays*86400);
            Deposit memory myDeposit = Deposit({
                                            lockedUntil: curDeposit.lockedUntil > lockDepositUntil ? curDeposit.lockedUntil : lockDepositUntil,
                                            poolTokenAmount: newTokensToMint+curDeposit.poolTokenAmount
                                        });
            deposits[msg.sender] = myDeposit;
        }
        emit Deposited(msg.sender, newTokensToMint);        
    }

}