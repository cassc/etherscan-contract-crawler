// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Omni Chain Fungible Token powered by layer zero. mPendle will be able to be bridged between Ethereum and Arbitrum

/// @author Magpie Team
/// @notice mPendle is minted by mPendleConvertor upon each Pendle convert on Penpie.

contract mPendleOFT is OFTV2, Pausable {

	/* ============ State Variables ============ */
	
	address public minter;

	/* ============ Constructor ============ */

    constructor(
		string memory _tokenName,
		string memory _symbol,
		address _endpoint
	) OFTV2(_tokenName, _symbol, 8, _endpoint) {
	}

	/* ============ Events ============ */

	event MinterUpdated(address _oldMinter, address _newMinter);

	/* ============ Errors ============ */

	error OnlyMinter();
	
	/* ============ Modifier Functions ============ */		
	
    modifier _onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }

	/* ============ External Functions ============ */	

	function mint(address _to, uint256 _amount) _onlyMinter public {
		_mint(_to, _amount);
	}	

	/* ============ Internal Functions ============ */

	function _debitFrom(
		address _from,
		uint16 _dstChainId,
		bytes32 _toAddress,
		uint _amount
	) internal override whenNotPaused returns (uint) {
		return super._debitFrom(_from, _dstChainId, _toAddress, _amount);
	}

	function _creditTo(uint16 _srcChainId, address _toAddress, uint _amount) internal override whenNotPaused returns (uint) {
		return super._creditTo(_srcChainId, _toAddress, _amount);
	}

	/* ============ Admin Functions ============ */

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function setMinter(address _newMinter) public onlyOwner {
		address _oldMinter = minter;
		minter = _newMinter;

		emit MinterUpdated(_oldMinter, minter);
	}	
}