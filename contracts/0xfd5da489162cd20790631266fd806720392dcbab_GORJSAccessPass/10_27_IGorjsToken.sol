//SPDX-License-Identifier: UNLICENSED
// AUDIT: LCL-06 | UNLOCKED COMPILER VERSION
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGorjsToken is IERC20Upgradeable{
    
    function updateRewardsOnMint(address account, uint256 amountMinted) external;
    
    function updateRewardsOnTransfer(address from, address to) external;

    function claimRewards(address account) external;

    function lockToken(address account, uint256 proposalId, uint256 amount) external;

    function unlockToken(address account) external;

    function getLockedAmount(address account) external view returns(uint256);
}