// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaSpacecyAsset.sol";
import "./meta-transaction/TokenIdentifiers.sol";
import "../utils/ReentrancyGuard.sol";

contract MetaspacecyAssetShared is MetaspacecyAsset, ReentrancyGuard {
	using TokenIdentifiers for uint256;

	MetaspacecyAssetShared public migrationTarget;

	mapping(address => bool) public sharedProxyAddresses;

	struct Ownership {
		uint256 id;
		address owner;
	}

	mapping(uint256 => address) internal _creatorOverride;

	event CreatorChanged(uint256 indexed _id, address indexed _creator);

	modifier creatorOnly(uint256 _id) {
		require(_isCreatorOrProxy(_id, _msgSender()), "MAS: only creator");
		_;
	}

	modifier onlyFullTokenOwner(uint256 _id) {
		require(_ownsTokenAmount(_msgSender(), _id, _id.tokenMaxSupply()), "MAS: only full token's owner");
		_;
	}

	constructor(
		string memory _name,
		string memory _symbol,
		address _proxyRegistryAddress,
		string memory _templateURI,
		address _migrationAddress
	) MetaspacecyAsset(_name, _symbol, _proxyRegistryAddress, _templateURI) {
		migrationTarget = MetaspacecyAssetShared(_migrationAddress);
	}

	function setProxyRegistryAddress(address _address) public onlyOwnerOrProxy {
		proxyRegistryAddress = _address;
	}

	function addSharedProxyAddress(address _address) public onlyOwnerOrProxy {
		sharedProxyAddresses[_address] = true;
	}

	function removeSharedProxyAddress(address _address) public onlyOwnerOrProxy {
		delete sharedProxyAddresses[_address];
	}

	function disableMigrate() public onlyOwnerOrProxy {
		migrationTarget = MetaspacecyAssetShared(address(0));
	}

	function migrate(Ownership[] memory _ownerships) public onlyOwnerOrProxy {
		MetaspacecyAssetShared _migrationTarget = migrationTarget;
		require(_migrationTarget != MetaspacecyAssetShared(address(0)), "MAS: migrate disabled");

		string memory _migrationTargetTemplateURI = _migrationTarget.templateURI();

		for (uint256 i = 0; i < _ownerships.length; ++i) {
			uint256 id = _ownerships[i].id;
			address owner = _ownerships[i].owner;

			require(owner != address(0), "MAS: zero address");

			uint256 previousAmount = _migrationTarget.balanceOf(owner, id);

			if (previousAmount == 0) {
				continue;
			}

			_mint(owner, id, previousAmount, "");

			if (keccak256(bytes(_migrationTarget.uri(id))) != keccak256(bytes(_migrationTargetTemplateURI))) {
				_setPermanentURI(id, _migrationTarget.uri(id));
			}
		}
	}

	function mint(
		address _to,
		uint256 _id,
		uint256 _quantity,
		bytes memory _data
	) public override nonReentrant creatorOnly(_id) {
		_mint(_to, _id, _quantity, _data);
	}

	function batchMint(
		address _to,
		uint256[] memory _ids,
		uint256[] memory _quantities,
		bytes memory _data
	) public override nonReentrant {
		for (uint256 i = 0; i < _ids.length; i++) {
			require(_isCreatorOrProxy(_ids[i], _msgSender()), "MAS: only creator");
		}
		_batchMint(_to, _ids, _quantities, _data);
	}

	function setURI(uint256 _id, string memory _uri) public override creatorOnly(_id) onlyFullTokenOwner(_id) {
		_setURI(_id, _uri);
	}

	function setPermanentURI(uint256 _id, string memory _uri) public override creatorOnly(_id) onlyImpermanentURI(_id) onlyFullTokenOwner(_id) {
		_setPermanentURI(_id, _uri);
	}

	function setCreator(uint256 _id, address _to) public creatorOnly(_id) {
		require(_to != address(0), "MAS: zero address");
		_creatorOverride[_id] = _to;

		emit CreatorChanged(_id, _to);
	}

	function creator(uint256 _id) public view returns (address) {
		if (_creatorOverride[_id] != address(0)) {
			return _creatorOverride[_id];
		} else {
			return _id.tokenCreator();
		}
	}

	function maxSupply(uint256 _id) public pure returns (uint256) {
		return _id.tokenMaxSupply();
	}

	function _origin(uint256 _id) internal pure returns (address) {
		return _id.tokenCreator();
	}

	function _requireMintable(address _address, uint256 _id) internal view {
		require(_isCreatorOrProxy(_id, _address), "MAS: only creator");
	}

	function _remainingSupply(uint256 _id) internal view override returns (uint256) {
		return maxSupply(_id) - totalSupply(_id);
	}

	function _isCreatorOrProxy(uint256 _id, address _address) internal view override returns (bool) {
		address creator_ = creator(_id);
		return creator_ == _address || _isProxyForUser(creator_, _address);
	}

	function _isProxyForUser(address _user, address _address) internal view override returns (bool) {
		if (sharedProxyAddresses[_address]) {
			return true;
		}
		return super._isProxyForUser(_user, _address);
	}
}