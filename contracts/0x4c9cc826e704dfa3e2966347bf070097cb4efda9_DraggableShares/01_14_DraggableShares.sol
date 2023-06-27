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

import "../recovery/ERC20Recoverable.sol";
import "../draggable/ERC20Draggable.sol";
import "../ERC20/ERC20PermitLight.sol";

/**
 * @title CompanyName AG Shares SHA
 * @author Luzius Meisser, [email protected]
 *
 * This is an ERC-20 token representing share tokens of CompanyName AG that are bound to
 * a shareholder agreement that can be found at the URL defined in the constant 'terms'.
 */
contract DraggableShares is ERC20Draggable, ERC20Recoverable, ERC20PermitLight {

    string public terms;

    constructor(
        string memory _terms,
        IERC20 _wrappedToken,
        uint256 _quorumBps,
        uint256 _quorumMigration,
        uint256 _votePeriodSeconds,
        IRecoveryHub _recoveryHub,
        IOfferFactory _offerFactory,
        address _oracle
    )
        ERC20Draggable(_wrappedToken, _quorumBps, _quorumMigration, _votePeriodSeconds, _offerFactory, _oracle)
        ERC20Recoverable(_recoveryHub)
        ERC20PermitLight() 
    {
        terms = _terms; // to update the terms, migrate to a new contract. That way it is ensured that the terms can only be updated when the quorom agrees.
        _recoveryHub.setRecoverable(false);
    }

    function transfer(address to, uint256 value) virtual override(ERC20Flaggable, ERC20Recoverable) public returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * Let the oracle act as deleter of invalid claims. In earlier versions, this was referring to the claim deleter
     * of the wrapped token. But that stops working after a successful acquisition as the acquisition currency most
     * likely does not have a claim deleter.
     */
    function getClaimDeleter() public view override returns (address) {
        return oracle;
    }

    function getCollateralRate(IERC20 collateralType) public view override returns (uint256) {
        uint256 rate = super.getCollateralRate(collateralType);
        if (rate > 0) {
            return rate;
        } else {
            // as long as it is binding, the conversion rate is 1:1
            uint256 factor = isBinding() ? 1 : unwrapConversionFactor;
            if (address(collateralType) == address(wrapped)) {
                // allow wrapped token as collateral
                return factor;
            } else {
                // If the wrapped contract allows for a specific collateral, we should too.
                // If the wrapped contract is not IRecoverable, we will fail here, but would fail anyway.
                return IRecoverable(address(wrapped)).getCollateralRate(collateralType) * factor;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Flaggable, ERC20Draggable) internal {
        super._beforeTokenTransfer(from, to, amount);
    }

}