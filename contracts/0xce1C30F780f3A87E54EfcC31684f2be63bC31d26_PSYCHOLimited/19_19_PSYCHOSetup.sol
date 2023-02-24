// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "@0xver/solver/supports/ERC165.sol";
import "@0xver/solver/auth/extensions/Operator.sol";
import "@0xver/solver/token/metadata/ERC721Metadata.sol";
import "./IPSYCHOLimitedErrors.sol";

contract PSYCHOSetup is IPSCYHOLimitedErrors, ERC165, Operator, ERC721Metadata {
	error InitiateStatus(bool _status);

	bool private _initiated = false;
	bool private _locked = false;

	uint256 private _countMasterInt = 0;
	uint256 private _weiFee = 22200000000000000;

	mapping(uint256 => uint256) private _block;
	mapping(uint256 => string) private _customExtensionString;

	event Withdraw(address operator, address receiver, uint256 value);

	constructor()
		ERC721Metadata("PSYCHO Limited", "PSYCHO")
		Operator(msg.sender)
	{
		_mint(msg.sender, 1);
		_addCountMaster();
	}

	receive() external payable {}

	fallback() external payable {}

	function withdraw(address _to) public operatorship {
		_withdraw(_to);
	}

	function initialize() public operatorship {
		if (_initiated == false) {
			_initiated = true;
		} else {
			revert InitiateStatus(_initiated);
		}
	}

	function setFee(uint256 _wei) public operatorship {
		_weiFee = _wei;
	}

	function resign(bool _bool) public operatorship {
		require(_bool == true);
		_weiFee = 0;
		_withdraw(msg.sender);
		_transferOwnership(address(0));
		_locked = true;
	}

	function resigned() public view returns (bool) {
		return _locked;
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

	function _generative() internal view returns (bool) {
		if (totalSupply() != 1101) {
			return _initiated;
		} else {
			return false;
		}
	}

	function _fee(uint256 _multiplier) internal view returns (uint256) {
		return _weiFee * _multiplier;
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
		if (_customExtension(_avatarId).length == 0) {
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
		uint256 _tokenId
	) internal view returns (bytes memory) {
		return abi.encodePacked(_customExtensionString[_tokenId]);
	}

	function _setCustomExtension(
		uint256 _tokenId,
		string memory _json
	) internal {
		_customExtensionString[_tokenId] = _json;
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

	function _addCountMaster() internal {
		unchecked {
			_countMasterInt += 1;
		}
	}

	function _subtractCountMaster() internal {
		unchecked {
			_countMasterInt -= 1;
		}
	}

	function _countMaster() internal view returns (uint256) {
		return _countMasterInt;
	}

	function _isOwnerOrOperator(address _address) internal view returns (bool) {
		return owner() == _address || operator() == _address;
	}

	function _withdraw(address _to) private {
		uint256 balance = address(this).balance;
		(bool success, ) = payable(_to).call{value: address(this).balance}("");
		require(success, "ETH_TRANSFER_FAILED");
		emit Withdraw(msg.sender, _to, balance);
	}
}