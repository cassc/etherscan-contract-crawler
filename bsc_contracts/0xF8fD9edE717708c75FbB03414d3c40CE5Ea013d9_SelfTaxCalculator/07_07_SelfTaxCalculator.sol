// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IReferralHandler.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IRebaserNew.sol";
import "./interfaces/IETFNew.sol";
import "./interfaces/ITaxManager.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SelfTaxCalculator {
    using SafeMath for uint256;
    uint256 public BASE = 1e18;
    address public factory;
    address public token;


    constructor(address _token, address _factory) {
        factory = _factory;
        token = _token;
    }

    function getRebaser() public view returns (IRebaser) {
        address rebaser = INFTFactory(factory).getRebaser() ;
        return IRebaser(rebaser);
    }

    function getTaxManager() public view returns (ITaxManager) {
        address taxManager = INFTFactory(factory).getTaxManager() ;
        return ITaxManager(taxManager);
    }

    function getSelfTax(address user) public view returns (uint256) {
        ITaxManager taxManager =  getTaxManager();
        uint256 taxDivisor = taxManager.getTaxBaseDivisor();
        uint256 currentEpoch = getRebaser().getPositiveEpochCount();
        address handler = INFTFactory(factory).getHandlerForUser(user);
        uint256 remainingClaims = IReferralHandler(handler).remainingClaims();
        if(remainingClaims > 0) {
            uint256 claimedEpoch =  currentEpoch.sub(remainingClaims);
            uint256 epochToClaim = claimedEpoch.add(1);
            uint256 rebaseRate = getRebaser().getDeltaForPositiveEpoch(epochToClaim);
            if(rebaseRate != 0) {
                uint256 blockForRebase = getRebaser().getBlockForPositiveEpoch(epochToClaim);
                uint256 balanceDuringRebase = IETF(token).getPriorBalance(user, blockForRebase); // We deal only with underlying balances
                balanceDuringRebase = balanceDuringRebase.div(1e6); // 4.0 token internally stores 1e24 not 1e18
                uint256 expectedBalance = balanceDuringRebase.mul(BASE.add(rebaseRate)).div(BASE);
                uint256 balanceToMint = expectedBalance.sub(balanceDuringRebase);
                uint256 selfTaxRate = taxManager.getSelfTaxRate();
                uint256 preTaxAmountReward = balanceToMint.mul(selfTaxRate).div(taxDivisor);
                return preTaxAmountReward;
            }
        }
        return 0;
    }

}