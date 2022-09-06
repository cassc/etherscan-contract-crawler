// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/IS7NSManagement.sol";

contract S7NSAvatar is ERC721Enumerable {
	
	IS7NSManagement public management;
	
	bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

	string public baseURI;
	mapping(uint256 => mapping(address => uint256)) public nonces;

	modifier isHalted() {
		require(!management.halted(), "Maintenance");
		_;
	}
	
	modifier onlyMinter() {
		require(
			management.hasRole(MINTER_ROLE, _msgSender()), "OnlyMinter"
		);
        _;
    }

	modifier onlyManager() {
		require(
			management.hasRole(MANAGER_ROLE, _msgSender()), "OnlyManager"
		);
        _;
    }

	event Printed(address indexed to, uint256 indexed fromID, uint256 indexed toID);
	event ToTheAsh(address indexed operator, uint256[] IDs);

	constructor(address _management, string memory _uri) ERC721("S7NS", "S7NS") {
		management = IS7NSManagement(_management);
		baseURI = _uri;
	}

	/**
       	@notice Update Address of S7NSManagement contract
       	@dev  Caller must have MANAGER_ROLE
		@param	_management				Address of S7NSManagement contract
    */
	function setManagement(address _management) external onlyManager {
		require(_management != address(0), "AddressZero");

		management = IS7NSManagement(_management);
	}

	/**
       	@notice Update new value of Base URI
       	@dev  Caller must have MANAGER_ROLE
       	@param 	baseURI_			New string of `baseURI`
    */
	function setBaseURI(string memory baseURI_) external onlyManager {
		baseURI = baseURI_;
	}

	/**
       	@notice Mint Avatar to `_beneficiary`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiary			Address of Beneficiary
		@param	_fromID					Start of TokenID
		@param	_amount					Amount of NFTs to be minted
    */
	function print(address _beneficiary, uint256 _fromID, uint256 _amount) external onlyMinter {
		for (uint256 i = _fromID; i < _fromID + _amount; i++) 
			_safeMint(_beneficiary, i);

		emit Printed(_beneficiary, _fromID, _fromID + _amount - 1);
	}

	/**
       	@notice Burn Avatars from `msg.sender`
       	@dev  Caller can be ANY
		@param	_ids				A list of `tokenIds` to be burned
		
		Note: MINTER_ROLE is granted a priviledge to burn NFTs
    */
	function burn(uint256[] calldata _ids) external {
		bool isAuthorized;
		address _operator = _msgSender();
		if (management.hasRole(MINTER_ROLE, _operator)) isAuthorized = true;

		uint256 _amounts = _ids.length;
		uint256 _tokenId;
		for (uint256 i; i < _amounts; i++) {
			_tokenId = _ids[i];
			require(
				ownerOf(_tokenId) == _operator || isAuthorized,
				"NotAuthorizedNorOwner"
			);

			_burn(_tokenId);
		}

		emit ToTheAsh(_operator, _ids);
	}

	/**
       	@notice Query a list of NFT that owned by `_account`
       	@dev  Caller can be ANY
		@param	_account			Account's address to query
		@param	_fromIdx			Starting index
		@param	_toIdx				Ending index
    */
	function tokensByOwner(address _account, uint256 _fromIdx, uint256 _toIdx) external view returns (uint256[] memory _tokens) {
		uint256 _size = _toIdx - _fromIdx + 1;
		_tokens = new uint256[](_size);

		for(uint256 i; i < _size; i++) 
			_tokens[i] = tokenOfOwnerByIndex(_account, _fromIdx + i);
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override isHalted {
		super._beforeTokenTransfer(from, to, tokenId);
    }

	function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override {
		nonces[tokenId][from] += 1;
		nonces[tokenId][to] += 1;
	}
}