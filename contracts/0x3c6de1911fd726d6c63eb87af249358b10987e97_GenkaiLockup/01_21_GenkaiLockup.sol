// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
 *     ,_,
 *    (',')
 *    {/"\}
 *    -"-"-
 */

import "GenkaiRonin.sol";
import "Ownable.sol";

error NotOwner();
error IncorrectUnlockValue();

contract GenkaiLockup is Ownable {
	address public immutable GENKAI;
	uint256 public immutable START;
	uint256 public immutable END;
	uint256 public immutable PRICE;

	constructor(address _genkai, uint256 _start, uint256 _end, uint256 _price) {
		GENKAI = _genkai;
		START = _start;
		END = _end;
		PRICE = _price;
	}

	function get() external onlyOwner {
		(bool res, ) = msg.sender.call{value:address(this).balance}("");
		require(res);
	}

	function adminUnlock(uint256 _tokenId) external onlyOwner {
		Genkai(GENKAI).unlockId(_tokenId);
	}

	function airdropAndLockup(address[] calldata _tos, uint256[] calldata _tokenIds) external onlyOwner {
		uint256 len = _tos.length;
		for (uint256 i = 0; i < len; i++) {
			Genkai(GENKAI).mint(_tos[i], _tokenIds[i]);
			Genkai(GENKAI).lockId(_tokenIds[i]);
		}
	}

	function airdrop(address[] calldata _tos, uint256[] calldata _tokenIds) external onlyOwner {
		uint256 len = _tos.length;
		for (uint256 i = 0; i < len; i++) {
			Genkai(GENKAI).mint(_tos[i], _tokenIds[i]);
		}
	}

	function batchLock(address[] calldata _tos, uint256[] calldata _tokenIds) external onlyOwner {
		uint256 len = _tos.length;
		for (uint256 i = 0; i < len; i++) {
			Genkai(GENKAI).lockId(_tokenIds[i]);
		}
	}

	function batchUnlock(address[] calldata _tos, uint256[] calldata _tokenIds) external onlyOwner {
		uint256 len = _tos.length;
		for (uint256 i = 0; i < len; i++) {
			Genkai(GENKAI).unlockId(_tokenIds[i]);
		}
	}

	function unlock(uint256 _tokenId) external payable {
		uint256 unlockPrice = priceToUnlock();
		address owner = Genkai(GENKAI).ownerOf(_tokenId);
		if (owner != msg.sender) revert NotOwner();
		if (msg.value < unlockPrice) revert IncorrectUnlockValue();

		Genkai(GENKAI).unlockId(_tokenId);
		uint256 remainder = msg.value - unlockPrice;
		if (remainder > 0) {
			(bool res, ) = msg.sender.call{value:remainder}("");
			require(res);
		}
	}

	function priceToUnlock() public view returns(uint256) {
		uint256 remaining = END - _min(END, block.timestamp);
		return PRICE * remaining / (END - START);
	}

	function _min(uint256 a, uint256 b) internal pure returns(uint256) {
		return a > b ? b : a;
	}
}