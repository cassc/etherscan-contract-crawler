// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity >=0.8.0;

import './IBaseSwapper.sol';

/**
 * @dev Paraswap v5 swapper action interface
 */
interface IParaswapV5Swapper is IBaseSwapper {
    /**
     * @dev Emitted every time a quote signer is set
     */
    event QuoteSignerSet(address indexed quoteSigner);

    /**
     * @dev Tells the address of the allowed quote signer
     */
    function getQuoteSigner() external view returns (address);

    /**
     * @dev Sets the quote signer address. Sender must be authorized.
     * @param quoteSigner Address of the new quote signer to be set
     */
    function setQuoteSigner(address quoteSigner) external;

    /**
     * @dev Execution function
     */
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external;
}