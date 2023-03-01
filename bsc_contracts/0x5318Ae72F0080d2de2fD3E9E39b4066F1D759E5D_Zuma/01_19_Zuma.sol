/*
	This file is part of Yuzumax.
	See <http://www.gnu.org/licenses/>.
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./CrossChainERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Zuma is CrossChainERC20, AccessControl {
    constructor(uint256 supply, address genericHandler_) CrossChainERC20("Yuzumax", "ZUMA", genericHandler_) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, supply);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, CrossChainERC20) returns (bool) {
        return interfaceId == type(ICrossChainERC20).interfaceId || interfaceId == type(ICrossChainERC20Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    /* ADMINISTRATIVE FUNCTIONS */

    function setLinker(address _linker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setLink(_linker);
    }

    function setFeeAddress(address _feeAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setFeeToken(_feeAddress);
    }

    function setCrossChainGasLimit(uint256 _gasLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setCrossChainGasLimit(_gasLimit);
    }

    function approveFee(address _feeToken, uint256 _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        approveFees(_feeToken, _value);
    }

    /* ADMINISTRATIVE FUNCTIONS END */
}