// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../validation/TimedCrowdsale.sol";
import "../Secondary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../validation/CappedCrowdsale.sol";

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
abstract contract PostDeliveryCrowdsale is CappedCrowdsale {
    using SafeMath for uint256;
    mapping(address => bool) public withdrawHalf;

    mapping(address => uint256) private _balances;
    __unstable__TokenVault private _vault;

    constructor() {
        _vault = new __unstable__TokenVault();
    }

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param beneficiary Whose tokens will be withdrawn.
     */

     function withdrawTokens(address beneficiary) public {
        require(hasClosed() || capReached() || hasEnded() , "PostDeliveryCrowdsale: not closed");
        require(!isContract(msg.sender), "Contract address revoked");
        require(block.timestamp >= closingTime() + 30 days, "30 days lock up");

        uint256 amount = _balances[beneficiary];
        require(amount > 0, "FlexvisPresale: beneficiary is not due to any tokens");

        if(block.timestamp >= closingTime() + 60 days){
             _vault.transfer(token(), beneficiary, amount);
            _balances[beneficiary] = 0;
        }
        else if (block.timestamp >= closingTime() + 30 days){
            require(withdrawHalf[beneficiary] == false, "Withdrawn half");

            withdrawHalf[beneficiary] = true;
            _vault.transfer(token(), beneficiary, amount / 2);
            _balances[beneficiary] = amount / 2;
        }
    }


    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
     * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
     * `_deliverTokens` was called later).
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal override{
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _deliverTokens(address(_vault), tokenAmount);
    }
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
contract __unstable__TokenVault is Secondary {
    function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
}