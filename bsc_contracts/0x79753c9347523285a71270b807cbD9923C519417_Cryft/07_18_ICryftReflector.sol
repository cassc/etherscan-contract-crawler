// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";
import "./INoBSDynamicReflector.sol";

interface ICryftReflector is INoBSDynamicReflector {

    function setShare(address shareholder, uint256 amount) external;

    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
    function isEnrolled(address user) external view returns(bool);
}