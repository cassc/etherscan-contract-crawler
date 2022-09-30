// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IS7NSManagement.sol";

contract S7NSFruit is ERC721Enumerable, Ownable {
	
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

	event Harvest(address indexed to, uint256 indexed tokenId);
	event ToTheAsh(address indexed operator, uint256[] IDs);

	constructor(address _management, string memory _uri) ERC721("S7 GoldenFruit", "S7GF") {
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
	function setBaseURI(string calldata baseURI_) external onlyManager {
		baseURI = baseURI_;
	}

    /**
       	@notice Mint Fruit to `_beneficiary`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiary			Address of the Receiver
		@param	_tokenId			    TokenId to be minted
    */
	function harvest(address _beneficiary, uint256 _tokenId) external onlyMinter {
        _harvest(_beneficiary, _tokenId);
	}

	/**
       	@notice Mint Batch of Fruits to `_beneficiaries`
       	@dev  Caller must have MINTER_ROLE
		@param	_beneficiaries			A list of receiving addresses
		@param	_tokenIds			    A list of `_tokenIds` to be minted
    */
	function harvestBatch(address[] calldata _beneficiaries, uint256[] calldata _tokenIds) external onlyMinter {
        uint256 _len = _beneficiaries.length;
        require(
            _tokenIds.length == _len, "Length mismatch"
        );

		for (uint256 i; i < _len; i++) 
            _harvest(_beneficiaries[i], _tokenIds[i]);
	}

	/**
       	@notice Burn Fruits from `msg.sender`
       	@dev  Caller can be ANY
		@param	_ids				A list of `tokenIds` to be burned
		
		Note: MINTER_ROLE is granted a priviledge to burn Fruits
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
       	@notice Query a list of Fruits that owned by `_account`
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

    function _harvest(address _beneficiary, uint256 _tokenId) private {
        _safeMint(_beneficiary, _tokenId);

        emit Harvest(_beneficiary, _tokenId);
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