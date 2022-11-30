// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import '@openzeppelin/contracts/utils/Address.sol';
import './interfaces/IAssimilator.sol';
import './lib/ABDKMath64x64.sol';
import './Storage.sol';

library Assimilators {
    using ABDKMath64x64 for int128;
    using Address for address;

    IAssimilator public constant iAsmltr = IAssimilator(address(0));

    function delegate(address _callee, bytes memory _data) internal returns (bytes memory) {
        require(_callee.isContract(), 'Assimilators/callee-is-not-a-contract');

        // solhint-disable-next-line
        (bool _success, bytes memory returnData_) = _callee.delegatecall(_data);

        // solhint-disable-next-line
        assembly {
            if eq(_success, 0) {
                revert(add(returnData_, 0x20), returndatasize())
            }
        }

        return returnData_;
    }

    function getRate(address _assim) internal view returns (uint256 amount_) {
        amount_ = IAssimilator(_assim).getRate();
    }

    function viewRawAmount(address _assim, int128 _amt) internal view returns (uint256 amount_) {
        amount_ = IAssimilator(_assim).viewRawAmount(_amt);
    }

    function viewRawAmountLPRatio(
        address _assim,
        uint256 _baseWeight,
        uint256 _quoteWeight,
        int128 _amount,
        // Storage.Curve storage curve
        address vault,
        bytes32 poolId
    ) internal view returns (uint256 amount_) {
        amount_ = IAssimilator(_assim).viewRawAmountLPRatio(
            _baseWeight,
            _quoteWeight,
            // curve.weights[0].mulu(1e18),
            // curve.weights[1].mulu(1e18),
            _amount,
            vault,
            poolId
        );
    }

    function viewNumeraireAmount(address _assim, uint256 _amt) internal view returns (int128 amt_) {
        amt_ = IAssimilator(_assim).viewNumeraireAmount(_amt);
    }

    function viewNumeraireAmountAndBalance(
        address _assim,
        uint256 _amt,
        address vault,
        bytes32 poolId
    ) internal view returns (int128 amt_, int128 bal_) {
        (amt_, bal_) = IAssimilator(_assim).viewNumeraireAmountAndBalance(_amt, vault, poolId);
    }

    function viewNumeraireBalance(
        address _assim,
        address vault,
        bytes32 poolId
    ) internal view returns (int128 bal_) {
        bal_ = IAssimilator(_assim).viewNumeraireBalance(vault, poolId);
    }

    function virtualViewNumeraireBalanceIntake(
        address _assim,
        address vault,
        bytes32 poolId,
        uint256 intakeAmount
    ) internal view returns (int128 bal_) {
        bal_ = IAssimilator(_assim).virtualViewNumeraireBalanceIntake(vault, poolId, intakeAmount);
    }

    function virtualViewNumeraireBalanceOutput(
        address _assim,
        address vault,
        bytes32 poolId,
        uint256 outputAmount
    ) internal view returns (int128 bal_) {
        bal_ = IAssimilator(_assim).virtualViewNumeraireBalanceOutput(vault, poolId, outputAmount);
    }

    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _assim,
        address vault,
        bytes32 poolId
    ) internal view returns (int128 bal_) {
        bal_ = IAssimilator(_assim).viewNumeraireBalanceLPRatio(
            _baseWeight,
            _quoteWeight,
            // address(this),
            vault,
            poolId
        );
    }
}