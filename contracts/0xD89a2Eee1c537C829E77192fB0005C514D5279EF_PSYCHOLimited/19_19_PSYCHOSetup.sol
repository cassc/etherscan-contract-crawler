// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "@0xver/solver/supports/ERC165.sol";
import "@0xver/solver/auth/extensions/Operator.sol";
import "@0xver/solver/token/metadata/ERC721Metadata.sol";
import "./IPSYCHOLimitedErrors.sol";

contract PSYCHOSetup is IPSCYHOLimitedErrors, ERC165, Operator, ERC721Metadata {
	error ExceedsChestLimit(uint256 _excess);
	error InitiatedStatus(bool _status);

	bool private _initiated = false;
	bool private _locked = false;

	uint256 private _stockCount = 0;
	uint256 private _chestCount = 0;
	uint256 private _weiFee = 66600000000000000;

	mapping(uint256 => uint256) private _block;
	mapping(uint256 => string) private _customImage;
	mapping(uint256 => string) private _customAnimation;

	event Withdraw(address operator, address receiver, uint256 value);

	receive() external payable {}

	fallback() external payable {}

	constructor()
		ERC721Metadata("PSYCHO Limited", "PSYCHO")
		Operator(msg.sender)
	{
		_mint(msg.sender, 1);
		_addChestCount(1);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public pure virtual override(ERC165) returns (bool) {
		return
			interfaceId == type(IERC173).interfaceId ||
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Receiver).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function withdraw(address _to) public ownership {
		_withdraw(_to);
	}

	function initialize() public ownership {
		if (_initiated == false) {
			_initiated = true;
		} else {
			revert InitiatedStatus(_initiated);
		}
	}

	function setFee(uint256 _wei) public ownership {
		_weiFee = _wei;
	}

	function _initialized() internal view returns (bool) {
		if (totalSupply() != 1101) {
			return _initiated;
		} else {
			return false;
		}
	}

	function _fee(uint256 _multiplier) internal view returns (uint256) {
		return _weiFee * _multiplier;
	}

	function _stock() internal view returns (uint256) {
		if (_initialized()) {
			return 1001 - _stockCount;
		} else {
			return 0;
		}
	}

	function _chest() public view returns (uint256) {
		return 100 - _chestCount;
	}

	function _addStockCount(uint256 _amount) internal {
		unchecked {
			_stockCount += _amount;
		}
	}

	function _addChestCount(uint256 _amount) internal {
		unchecked {
			_chestCount += _amount;
		}
	}

	function _isOwnerOrOperator(address _address) internal view returns (bool) {
		return owner() == _address || operator() == _address;
	}

	function _mintHook(uint256 _avatarId) internal override(ERC721) {
		_block[_avatarId] = block.number;
	}

	function _extendedTokenURI(
		uint256 _avatarId
	) internal view override(ERC721Metadata) returns (bytes memory) {
		return
			abi.encodePacked(
				_description(_avatarId),
				',"image":"ipfs://bafybeidob7iaynjg6h6c3igqnac2qnprlzsfatybuqkxhcizcgpfowwgm4",',
				'"animation_url":"ipfs://bafybeihmygiurvygn7oaruaz66njkvlicbfg7lnsc64ttxbc3o3x4fezfi",',
				_attributes(_avatarId)
			);
	}

	function _customTokenURI(
		uint256 _avatarId
	) internal view override(ERC721Metadata) returns (bytes memory) {
		if (abi.encodePacked(_customImage[_avatarId]).length == 0) {
			return "";
		} else {
			return
				abi.encodePacked(
					_description(_avatarId),
					",",
					_customExtension(_avatarId),
					",",
					_attributes(_avatarId)
				);
		}
	}

	function _customExtension(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		if (abi.encodePacked(_customAnimation[_avatarId]).length == 0) {
			return abi.encodePacked('"image":', _customImage[_avatarId]);
		} else {
			return
				abi.encodePacked(
					'"image":',
					_customImage[_avatarId],
					',"animation_url":',
					_customAnimation[_avatarId]
				);
		}
	}

	function _setCustomImage(uint256 _avatarId, string memory _url) internal {
		_customImage[_avatarId] = _url;
	}

	function _setCustomAnimation(
		uint256 _avatarId,
		string memory _url
	) internal {
		_customAnimation[_avatarId] = _url;
	}

	function _description(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		return
			abi.encodePacked(
				'"description":"',
				Encode.toString(_block[_avatarId]),
				'"'
			);
	}

	function _attributes(
		uint256 _avatarId
	) internal view returns (bytes memory) {
		return
			abi.encodePacked(
				'"attributes":[{"trait_type":"Block","value":"',
				Encode.toHexString(_block[_avatarId]),
				'"}]'
			);
	}

	function _withdraw(address _to) private {
		uint256 balance = address(this).balance;
		(bool success, ) = payable(_to).call{value: address(this).balance}("");
		require(success, "ETH_TRANSFER_FAILED");
		emit Withdraw(msg.sender, _to, balance);
	}
}