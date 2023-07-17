/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2022 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../ERC20/ERC20Flaggable.sol";
import "./IRecoveryHub.sol";
import "./IRecoverable.sol";

/**
 * @title Recoverable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function on the recovery hub to post a deposit and claim that the shares assigned to a
 * specific address are lost.
 * If an attacker trying to claim shares belonging to someone else, they risk losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function, e.g. cases of front-running.
 * Most functionality is implemented in a shared RecoveryHub.
 */
abstract contract ERC20Recoverable is ERC20Flaggable, IRecoverable {

    uint8 private constant FLAG_CLAIM_PRESENT = 10;

    // ERC-20 token that can be used as collateral or 0x0 if disabled
    IERC20 public customCollateralAddress;
    // Rate the custom collateral currency is multiplied to be valued like one share.
    uint256 public customCollateralRate;

    uint256 constant CLAIM_PERIOD = 180 days;

    IRecoveryHub public override immutable recovery;

    constructor(IRecoveryHub recoveryHub){
        recovery = recoveryHub;
    }

    /**
     * Returns the collateral rate for the given collateral type and 0 if that type
     * of collateral is not accepted. By default, only the token itself is accepted at
     * a rate of 1:1.
     *
     * Subclasses should override this method if they want to add additional types of
     * collateral.
     */
    function getCollateralRate(IERC20 collateralType) public override virtual view returns (uint256) {
        if (address(collateralType) == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

    function claimPeriod() external pure override returns (uint256){
        return CLAIM_PERIOD;
    }

    /**
     * Allows subclasses to set a custom collateral besides the token itself.
     * The collateral must be an ERC-20 token that returns true on successful transfers and
     * throws an exception or returns false on failure.
     * Also, do not forget to multiply the rate in accordance with the number of decimals of the collateral.
     * For example, rate should be 7*10**18 for 7 units of a collateral with 18 decimals.
     */
    function _setCustomClaimCollateral(IERC20 collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (address(customCollateralAddress) == address(0)) {
            customCollateralRate = 0; // disabled
        } else {
            require(rate > 0, "zero");
            customCollateralRate = rate;
        }
    }

    function getClaimDeleter() virtual public view returns (address);

    function transfer(address recipient, uint256 amount) override(ERC20Flaggable, IERC20) virtual public returns (bool) {
        require(super.transfer(recipient, amount), "transfer");
        if (hasFlagInternal(msg.sender, FLAG_CLAIM_PRESENT)){
            recovery.clearClaimFromToken(msg.sender);
        }
        return true;
    }

    function notifyClaimMade(address target) external override {
        require(msg.sender == address(recovery), "not recovery");
        setFlag(target, FLAG_CLAIM_PRESENT, true);
    }

    function notifyClaimDeleted(address target) external override {
        require(msg.sender == address(recovery), "not recovery");
        setFlag(target, FLAG_CLAIM_PRESENT, false);
    }

    function deleteClaim(address lostAddress) external {
        require(msg.sender == getClaimDeleter(), "not claim deleter");
        recovery.deleteClaim(lostAddress);
    }

    function recover(address oldAddress, address newAddress) external override {
        require(msg.sender == address(recovery), "not recovery");
        _transfer(oldAddress, newAddress, balanceOf(oldAddress));
    }

}