/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2022 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

import "./BackedTokenImplementation.sol";

/**
 * @dev
 *
 * This contract is extension of the original BackedTokenImplementation
 * but includes minting limits
 */
contract BackedTokenImplementationV2 is BackedTokenImplementation {
    // @notice The amount of tokens that can be minted
    uint public mintingAllowance;

    // @notice The timestamp of when the minuting allowance was last increased
    uint public allowanceChangedTimestamp;

    /**
     * @notice Emitted when new minting allowance is set
     *
     * @param amount  The new minting allowance amount
     */
    event NewMintAllowance(uint amount);

    /**
     * @dev The minimum delay that needs to have passed before
     *  minting after increasing the minting allowance
     */
    uint private constant MINTING_DELAY = 24 * 60 * 60;

    /**
     * @inheritdoc BackedTokenImplementation
     */
    function mint(address account, uint256 amount) external virtual override {
        require(_msgSender() == minter, "BackedToken: Only minter");
        require(mintingAllowance >= amount, "BackedToken: Minting allowance low");
        require(block.timestamp > allowanceChangedTimestamp + MINTING_DELAY, "BackedToken: Minting time delay");

        mintingAllowance -= amount;
        _mint(account, amount);
    }


    /**
     * @dev Function to set new minting allowance value. If successfully called
     *  token minting will be not possible for { MINTING_DELAY } seconds
     *
     * Emits a { NewMintAllowance } event
     *
     * @param amount  The new minting allowance amount
     */
    function setMintAllowance(uint256 amount) public {
        require(_msgSender() == minter, "BackedToken: Only minter");

        mintingAllowance = amount;
        allowanceChangedTimestamp = block.timestamp;

        emit NewMintAllowance(amount);
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}