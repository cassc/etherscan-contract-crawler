/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
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

import "./IRecoveryHub.sol";
import "./IRecoverable.sol";
import "../ERC20/IERC20.sol";

contract RecoveryHub is IRecoveryHub {

    // A struct that represents a claim made
    struct Claim {
        address claimant; // the person who created the claim
        uint256 collateral; // the amount of collateral deposited
        uint256 timestamp;  // the timestamp of the block in which the claim was made
        IERC20 currencyUsed; // The currency (XCHF) can be updated, we record the currency used for every request
    }

    mapping(IRecoverable => mapping (address => Claim)) public claims; // there can be at most one claim per token and claimed address
    mapping(address => bool) public recoveryDisabled; // disable claimability (e.g. for long term storage)

    event ClaimMade(IRecoverable indexed token, address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimCleared(IRecoverable indexed token, address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(IRecoverable indexed token, address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(IRecoverable indexed token, address indexed lostAddress, address indexed claimant, uint256 collateral);

    function setRecoverable(bool enabled) external override {
        recoveryDisabled[msg.sender] = !enabled;
    }

    /**
     * Some users might want to disable claims for their address completely.
     * For example if they use a deep cold storage solution or paper wallet.
     */
    function isRecoverable(address target) public view returns (bool) {
        return !recoveryDisabled[target];
    }

  /** Anyone can declare that the private key to a certain address was lost by calling declareLost
    * providing a deposit/collateral. There are three possibilities of what can happen with the claim:
    * 1) The claim period expires and the claimant can get the deposit and the shares back by calling recover
    * 2) The "lost" private key is used at any time to call clearClaim. In that case, the claim is deleted and
    *    the deposit sent to the shareholder (the owner of the private key). It is recommended to call recover
    *    whenever someone transfers funds to let claims be resolved automatically when the "lost" private key is
    *    used again.
    * 3) The owner deletes the claim and assigns the deposit to the claimant. This is intended to be used to resolve
    *    disputes. Generally, using this function implies that you have to trust the issuer of the tokens to handle
    *    the situation well. As a rule of thumb, the contract owner should assume the owner of the lost address to be the
    *    rightful owner of the deposit.
    * It is highly recommended that the owner observes the claims made and informs the owners of the claimed addresses
    * whenever a claim is made for their address (this of course is only possible if they are known to the owner, e.g.
    * through a shareholder register).
    */
    function declareLost(IRecoverable token, IERC20 collateralType, address lostAddress) external {
        require(isRecoverable(lostAddress), "disabled");
        uint256 collateralRate = IRecoverable(token).getCollateralRate(collateralType);
        require(collateralRate > 0, "bad collateral");
        uint256 balance = IERC20(token).balanceOf(lostAddress);
        require(balance > 0, "empty");
        uint256 collateral = balance * collateralRate;
        IERC20 currency = IERC20(collateralType);
        require(claims[token][lostAddress].collateral == 0, "already claimed");

        claims[token][lostAddress] = Claim({
            claimant: msg.sender,
            collateral: collateral,
            // rely on time stamp is ok, no exact time stamp needed
            // solhint-disable-next-line not-rely-on-time
            timestamp: block.timestamp,
            currencyUsed: collateralType
        });
        emit ClaimMade(token, lostAddress, msg.sender, balance);
        
        require(currency.transferFrom(msg.sender, address(this), collateral), "transfer failed");

        IRecoverable(token).notifyClaimMade(lostAddress);
    }

    function getClaimant(IRecoverable token, address lostAddress) external view returns (address) {
        return claims[token][lostAddress].claimant;
    }

    function getCollateral(IRecoverable token, address lostAddress) external view returns (uint256) {
        return claims[token][lostAddress].collateral;
    }

    function getCollateralType(IRecoverable token, address lostAddress) external view returns (IERC20) {
        return claims[token][lostAddress].currencyUsed;
    }

    function getTimeStamp(IRecoverable token, address lostAddress) external view returns (uint256) {
        return claims[token][lostAddress].timestamp;
    }

    /**
     * Clears a claim after the key has been found again and assigns the collateral to the "lost" address.
     * This is the price an adverse claimer pays for filing a false claim and makes it risky to do so.
     */
    function clearClaimFromToken(address holder) external override {
        clearClaim(IRecoverable(msg.sender), holder);
    }

    function clearClaimFromUser(IRecoverable token) external {
        clearClaim(token, msg.sender);
    }

    function clearClaim(IRecoverable token, address holder) private {
        Claim memory claim = claims[token][holder];
        if (claim.collateral > 0){
            IERC20 currency = IERC20(claim.currencyUsed);
            delete claims[token][holder];
            require(currency.transfer(holder, claim.collateral), "could not return collateral");
            emit ClaimCleared(token, holder, claim.collateral);
        }
        IRecoverable(token).notifyClaimDeleted(holder);
    }

   /**
    * After the claim period has passed, the claimant can call this function to send the
    * tokens on the lost address as well as the collateral to himself.
    */
    function recover(IRecoverable token, address lostAddress) external {
        Claim memory claim = claims[token][lostAddress];
        address claimant = claim.claimant;
        require(claimant == msg.sender, "not claimant");
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "not found");
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        require(claim.timestamp + IRecoverable(token).claimPeriod() <= block.timestamp, "too early");
        delete claims[token][lostAddress];
        emit ClaimResolved(token, lostAddress, claimant, collateral);
        IRecoverable(token).notifyClaimDeleted(lostAddress);
        require(currency.transfer(claimant, collateral), "transfer failed");
        IRecoverable(token).recover(lostAddress, claimant);
    }

    /**
     * The token contract can delete claims. It is the responsibility of the token contract to make sure
     * only authorized parties can trigger such a call.
     */
    function deleteClaim(address lostAddress) external override {
        IRecoverable token = IRecoverable(msg.sender);
        Claim memory claim = claims[token][lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "not found");
        delete claims[token][lostAddress];
        emit ClaimDeleted(token, lostAddress, claim.claimant, claim.collateral);
        IRecoverable(token).notifyClaimDeleted(lostAddress);
        require(currency.transfer(claim.claimant, claim.collateral), "transfer failed");
    }

}