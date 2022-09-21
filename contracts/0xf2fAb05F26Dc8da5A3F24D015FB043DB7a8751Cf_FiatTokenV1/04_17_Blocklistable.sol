/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 * Copyright (c) 2022 JPYC
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

pragma solidity 0.8.11;

import "./Ownable.sol";

/**
 * @dev Forked from https://github.com/centrehq/centre-tokens/blob/37039f00534d3e5148269adf98bd2d42ea9fcfd7/contracts/v1/Blacklistable.sol
 * Modifications:
 * 1. Change solidity version to 0.8.11
 * 2. Change bool -> uint256 for gas optimization
 * 3. Change blacklist -> blocklist
 * 4. Add gap
 */
/**
 * @title Blocklistable Token
 * @dev Allows accounts to be blocklisted by a "blocklister" role
 */
contract Blocklistable is Ownable {
    address public blocklister;
    mapping(address => uint256) internal blocklisted;

    event Blocklisted(address indexed _account);
    event UnBlocklisted(address indexed _account);
    event BlocklisterChanged(address indexed newBlocklister);

    /**
     * @dev Throws if called by any account other than the blocklister
     */
    modifier onlyBlocklister() {
        require(
            msg.sender == blocklister,
            "Blocklistable: caller is not the blocklister"
        );
        _;
    }

    /**
     * @dev Throws if argument account is blocklisted
     * @param _account The address to check
     */
    modifier notBlocklisted(address _account) {
        require(
            blocklisted[_account] == 0,
            "Blocklistable: account is blocklisted"
        );
        _;
    }

    /**
     * @dev Checks if account is blocklisted
     * @param _account The address to check
     * @return True if account is blocklisted
     */
    function isBlocklisted(address _account) external view returns (bool) {
        return blocklisted[_account] == 1;
    }

    /**
     * @dev Adds account to blocklist
     * @param _account The address to blocklist
     */
    function blocklist(address _account) external onlyBlocklister {
        blocklisted[_account] = 1;
        emit Blocklisted(_account);
    }

    /**
     * @dev Removes account from blocklist
     * @param _account The address to remove from the blocklist
     */
    function unBlocklist(address _account) external onlyBlocklister {
        blocklisted[_account] = 0;
        emit UnBlocklisted(_account);
    }

    function updateBlocklister(address _newBlocklister) external onlyOwner {
        require(
            _newBlocklister != address(0),
            "Blocklistable: new blocklister is the zero address"
        );
        blocklister = _newBlocklister;
        emit BlocklisterChanged(blocklister);
    }

    uint256[50] private __gap;
}