//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../util/SingleTokenVestingNonRevocable.sol";

/**
    Fork of badger vesting contracts at https://github.com/chimera-defi/badger-system/blob/adf58e75de994564b55ceb0529a666149d708c8c/contracts/badger-timelock/SmartVesting.sol
    With all executor capabilities removed
    and changed to not be upgradeable
    Previously reviewed by certik and immunefi
 */

/* 
    A token vesting contract that is capable of interacting with other smart contracts.
    This allows the beneficiary to participate in on-chain goverance processes, despite having locked tokens.
    The beneficiary can withdraw the appropriate vested amount at any time.
    Features safety functions to allow beneficiary to claim ETH & ERC20-compliant tokens sent to the timelock contract, accidentially or otherwise.
    An optional 'governor' address has the ability to allow the vesting to send it's tokens to approved destinations. 
    This is intended to allow the token holder to stake their tokens in approved mechanisms.
*/

contract SimpleVesting is SingleTokenVestingNonRevocable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal _transferAllowed;

    constructor(
        IERC20 token,
        address beneficiary,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration
    ) public SingleTokenVestingNonRevocable(token, beneficiary, start, cliffDuration, duration) {}

    event ClaimToken(IERC20 token, uint256 amount);
    event ClaimEther(uint256 amount);

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary(), "smart-timelock/only-beneficiary");
        _;
    }

    /**
     * @notice Claim ERC20-compliant tokens other than locked token.
     * @param tokenToClaim Token to claim balance of.
     */
    function claimToken(IERC20 tokenToClaim) external onlyBeneficiary() nonReentrant() {
        require(address(tokenToClaim) != address(token()), "smart-timelock/no-locked-token-claim");
        uint256 preAmount = token().balanceOf(address(this));

        uint256 claimableTokenAmount = tokenToClaim.balanceOf(address(this));
        require(claimableTokenAmount > 0, "smart-timelock/no-token-balance-to-claim");

        tokenToClaim.transfer(beneficiary(), claimableTokenAmount);

        uint256 postAmount = token().balanceOf(address(this));
        require(postAmount >= preAmount, "smart-timelock/locked-balance-check");

        emit ClaimToken(tokenToClaim, claimableTokenAmount);
    }

    /**
     * @notice Claim Ether in contract.
     */
    function claimEther() external onlyBeneficiary() nonReentrant() {
        uint256 preAmount = token().balanceOf(address(this));

        uint256 etherToTransfer = address(this).balance;
        require(etherToTransfer > 0, "smart-timelock/no-ether-balance-to-claim");

        payable(beneficiary()).transfer(etherToTransfer);

        uint256 postAmount = token().balanceOf(address(this));
        require(postAmount >= preAmount, "smart-timelock/locked-balance-check");

        emit ClaimEther(etherToTransfer);
    }

    /**
     * @notice Allow timelock to receive Ether
     */
    receive() external payable {}
}