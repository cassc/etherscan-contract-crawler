// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./base/ERC721AntiScam/ERC721AntiScam.sol";
import { DataType } from "./lib/type/DataType.sol";
import "./interface/IZuttoMamo.sol";
import "./interface/IZuttoMamoStage.sol";
import "./interface/IParentLinkSbt.sol";
import "./interface/IERC5192PLConnector.sol";
import "./interface/IERC4906.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ZuttoMamoConfig {
	// =============================================================
	//   EXTERNAL CONTRACT
	// =============================================================

	IZuttoMamoStage public zuttoMamoStage;

	IERC5192PLConnector public connector;

	// =============================================================
	//   CONSTANTS
	// =============================================================

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

	bytes32 public constant METADATA_ROLE = keccak256("METADATA");

	bytes32 public constant MINTER_ROLE = keccak256("MINTER");

	// =============================================================
	//   STORAGE
	// =============================================================

	uint256 public maxSupply = 5210;

	uint256 public unlockLeadTime = 3 hours;

	uint96 public royaltyFee = 1000;

	address public royaltyAddress = 0x853dac8E9115E30220857C8bDb4486e34Ba93fEa;

	/* time lock  */
	// tokenId -> unlock time
	mapping(uint256 => uint256) internal unlockTokenTimestamp;

	// wallet -> unlock time
	mapping(address => uint256) internal unlockWalletTimestamp;

	mapping(uint256 => DataType.TokenLocation) internal tokenLocation;
}

abstract contract ZuttoMamoAdmin is
	ZuttoMamoConfig,
	Ownable,
	AccessControl,
	ERC721AntiScam,
	ERC2981,
	IZuttoMamo,
	IERC4906
{
	// =============================================================
	//   SUPPORTS INTERFACE
	// =============================================================

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC721AntiScam, AccessControl, IERC721A, ERC2981) returns (bool) {
		return
			AccessControl.supportsInterface(interfaceId) ||
			ERC721AntiScam.supportsInterface(interfaceId) ||
			ERC2981.supportsInterface(interfaceId) ||
			interfaceId == bytes4(0x49064906) ||
			ERC165.supportsInterface(interfaceId) ||
			super.supportsInterface(interfaceId);
	}

	// =============================================================
	//   ACCESS CONTROL
	// =============================================================

	function grantAdmin(address _account) external onlyOwner {
		_grantRole(ADMIN_ROLE, _account);
	}

	function revokeAdmin(address _account) external onlyOwner {
		_revokeRole(ADMIN_ROLE, _account);
	}

	// =============================================================
	//   EXTERNAL CONTRACT
	// =============================================================

	function setZuttoMamoStage(IZuttoMamoStage _zuttoMamoStage) external onlyRole(ADMIN_ROLE) {
		zuttoMamoStage = _zuttoMamoStage;
	}

	function setERC5192PLConnector(IERC5192PLConnector _address) external onlyRole(ADMIN_ROLE) {
		connector = _address;
	}

	// =============================================================
	//   ERC-2981
	// =============================================================

	function setRoyaltyFee(uint96 _value) external onlyRole(ADMIN_ROLE) {
		royaltyFee = _value;
		_setDefaultRoyalty(royaltyAddress, royaltyFee);
	}

	function setRoyaltyAddress(address _royaltyAddress) external onlyRole(ADMIN_ROLE) {
		royaltyAddress = _royaltyAddress;
		_setDefaultRoyalty(royaltyAddress, royaltyFee);
	}

	// =============================================================
	//   ERC-4906
	// =============================================================

	function refreshMetadata(uint256 _tokenId) external onlyRole(METADATA_ROLE) {
		emit MetadataUpdate(_tokenId);
	}

	function refreshMetadata(uint256 _fromTokenId, uint256 _toTokenId) external onlyRole(METADATA_ROLE) {
		emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
	}

	// =============================================================
	//   OVERRIDES ERC721RESTRICT APPROVE
	// =============================================================

	function setEnableRestrict(bool _value) external onlyOwner {
		enableRestrict = _value;
	}

	function setCALLevel(uint256 _level) external override onlyRole(ADMIN_ROLE) {
		CALLevel = _level;
	}

	function setCAL(address _calAddress) external onlyRole(ADMIN_ROLE) {
		_setCAL(_calAddress);
	}

	function addLocalContractAllowList(address _transferer) external onlyRole(ADMIN_ROLE) {
		_addLocalContractAllowList(_transferer);
	}

	function removeLocalContractAllowList(address _transferer) external onlyRole(ADMIN_ROLE) {
		_removeLocalContractAllowList(_transferer);
	}

	// =============================================================
	//   ERC721LOCKABLE
	// =============================================================

	function setEnableLock(bool _value) external onlyOwner {
		enableLock = _value;
	}

	function setContractLock(LockStatus _lockStatus) external override onlyOwner {
		_setContractLock(_lockStatus);
	}

	function setUnlockLeadTime(uint256 _value) external onlyRole(ADMIN_ROLE) {
		unlockLeadTime = _value;
	}

	function setTokenLockByAdmin(uint256[] calldata _tokenIds, LockStatus _lockStatus) external onlyRole(ADMIN_ROLE) {
		require(_tokenIds.length > 0, "tokenIds must be greater than 0");
		_setTokenLock(_tokenIds, _lockStatus);
	}

	// =============================================================
	//   MINT FUNCTION
	// =============================================================

	function airdropMint(
		address[] calldata _to,
		uint256[] calldata _quantity,
		bool _withSleep
	) external onlyRole(ADMIN_ROLE) {
		require(_to.length == _quantity.length, "the address and quantity do not match");
		for (uint256 i = 0; i < _quantity.length; i++) {
			require(_quantity[i] != 0, "the quantity is zero");
			if (_withSleep) {
				_birthWithSleeping(_to[i], _quantity[i]);
			} else {
				_birth(_to[i], _quantity[i]);
			}
		}
	}

	function birth(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
		_birth(_to, _amount);
	}

	function birthWithSleeping(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
		_birthWithSleeping(_to, _amount);
	}

	/**
	 *  @dev Minted time and period to grow to token ID and transfer NFT to address.
	 */
	function _birth(address _to, uint256 _amount) private {
		for (uint256 i = 0; i < _amount; i++) {
			uint256 tokenId = _nextTokenId() + i;
			tokenLocation[tokenId] = DataType.TokenLocation.Other;
		}
		_mint(_to, _amount);
	}

	function _birthWithSleeping(address _to, uint256 _amount) private {
		uint256 startTokenId = _nextTokenId();
		_mint(_to, _amount);
		for (uint256 i = 0; i < _amount; i++) {
			uint256 tokenId = startTokenId + i;
			tokenLocation[tokenId] = DataType.TokenLocation.Operator;
		}
	}

	// =============================================================
	//   OTHER FUNCTION
	// =============================================================

	function setMaxSupply(uint256 _value) external onlyRole(ADMIN_ROLE) {
		maxSupply = _value;
	}
}

contract ZuttoMamo is ZuttoMamoAdmin, RevokableDefaultOperatorFilterer {
	// =============================================================
	//   CONSTRUCTOR
	// =============================================================

	constructor() ERC721A("ZUTTO MAMORU", "ZM") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
		_grantRole(ADMIN_ROLE, msg.sender);
		_grantRole(METADATA_ROLE, msg.sender);
		_setDefaultRoyalty(royaltyAddress, royaltyFee);
	}

	// =============================================================
	//   OVERRIDES ERC721RESTRICT APPROVE
	// =============================================================

	function getLocalContractAllowList() external view returns (address[] memory) {
		return _getLocalContractAllowList();
	}

	// =============================================================
	//   OVERRIDES ERC721LOCKABLE
	// =============================================================

	function setTokenLock(uint256[] calldata _tokenIds, LockStatus _newLockStatus) external {
		require(_tokenIds.length > 0, "tokenIds must be greater than 0");

		for (uint256 i = 0; i < _tokenIds.length; i++) {
			require(msg.sender == ownerOf(_tokenIds[i]), "not owner");
		}

		for (uint256 i = 0; i < _tokenIds.length; i++) {
			if (_isTokenLockToUnlock(_tokenIds[i], _newLockStatus)) {
				unlockTokenTimestamp[_tokenIds[i]] = block.timestamp;
			}
		}
		_setTokenLock(_tokenIds, _newLockStatus);

		for (uint256 i = 0; i < _tokenIds.length; i++) {
			emit MetadataUpdate(_tokenIds[i]);
		}
	}

	function setWalletLock(address _to, LockStatus _lockStatus) external {
		require(msg.sender == _to, "only yourself");

		if (walletLock[_to] == LockStatus.Lock && _lockStatus != LockStatus.Lock) {
			unlockWalletTimestamp[_to] = block.timestamp;
		}

		_setWalletLock(_to, _lockStatus);
	}

	function _isTokenLockToUnlock(uint256 _tokenId, LockStatus _newLockStatus) private view returns (bool) {
		if (_newLockStatus == LockStatus.UnLock) {
			LockStatus currentWalletLock = walletLock[msg.sender];
			bool isWalletLock_TokenLockOrUnset = (currentWalletLock == LockStatus.Lock &&
				tokenLock[_tokenId] != LockStatus.UnLock);
			bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock != LockStatus.Lock &&
				tokenLock[_tokenId] == LockStatus.Lock);

			return isWalletLock_TokenLockOrUnset || isWalletUnlockOrUnset_TokenLock;
		} else if (_newLockStatus == LockStatus.UnSet) {
			LockStatus currentWalletLock = walletLock[msg.sender];
			bool isNotWalletLock = currentWalletLock != LockStatus.Lock;
			bool isTokenLock = tokenLock[_tokenId] == LockStatus.Lock;

			return isNotWalletLock && isTokenLock;
		} else {
			return false;
		}
	}

	function _isTokenTimeLock(uint256 _tokenId) private view returns (bool) {
		return unlockTokenTimestamp[_tokenId] + unlockLeadTime > block.timestamp;
	}

	function _isWalletTimeLock(uint256 _tokenId) private view returns (bool) {
		return unlockWalletTimestamp[ownerOf(_tokenId)] + unlockLeadTime > block.timestamp;
	}

	function isLocked(uint256 _tokenId) public view override(IERC721Lockable, ERC721Lockable) returns (bool) {
		return ERC721Lockable.isLocked(_tokenId) || _isTokenTimeLock(_tokenId) || _isWalletTimeLock(_tokenId);
	}

	// =============================================================
	//   ERC-5192PL CONNECTOR
	// =============================================================

	function _afterParentTokenTransfer(DataType.AfterParentTokenTransferParams memory _params) private {
		for (uint256 i = 0; i < _params.totalAmountParentLinkSbtContracts; i++) {
			address parentLinkSbtContract = connector.getParentLinkSbtContractByIndex(_params.tokenId, i);
			uint256 parentLinkSbtTokenId = connector.getParentLinkSbtTokenByIndex(_params.tokenId, parentLinkSbtContract, 0);
			require(_params.to == ownerOfParentLinkSbt(parentLinkSbtContract, parentLinkSbtTokenId), "not token owner");
			IParentLinkSbt(parentLinkSbtContract).setIsTokenUnLocked(parentLinkSbtTokenId, true);
			IERC721(parentLinkSbtContract).transferFrom(_params.from, _params.to, parentLinkSbtTokenId);
		}
	}

	/**
	 * @dev Returns the owner's address by retrieving the token ID associated with the parent link sbt.
	 */
	function ownerOfParentLinkSbt(
		address _parentLinkSbtContract,
		uint256 _parentLinkSbtTokenId
	) public view returns (address parentTokenOwner) {
		uint256 parentTokenId = connector.getParentLinkSbtTokenOwnerId(_parentLinkSbtContract, _parentLinkSbtTokenId);
		require(
			parentTokenId > 0 ||
				connector.getParentLinkSbtTokenIndex(parentTokenId, _parentLinkSbtContract, _parentLinkSbtTokenId) > 0,
			"not parent link sbt token"
		);
		return ownerOf(parentTokenId);
	}

	// =============================================================
	//   ERC-721A OVERRIDE
	// =============================================================

	function _mint(address _to, uint256 _quantity) internal override {
		require(_quantity + totalSupply() <= maxSupply, "claim is over the max supply");
		super._mint(_to, _quantity);
	}

	function setApprovalForAll(
		address operator,
		bool approved
	) public override(ERC721AntiScam, IERC721A) onlyAllowedOperatorApproval(operator) {
		super.setApprovalForAll(operator, approved);
	}

	function approve(
		address operator,
		uint256 tokenId
	) public payable override(ERC721AntiScam, IERC721A) onlyAllowedOperatorApproval(operator) {
		super.approve(operator, tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 * If parent link sbt are tied to Zuttomamo NFT, they are moved together.
	 */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
		uint256 totalAmountParentLinkSbtContracts = address(connector) != address(0)
			? connector.getTotalParentLinkSbtContracts(_tokenId)
			: 0;

		super.transferFrom(_from, _to, _tokenId);

		if (totalAmountParentLinkSbtContracts != 0) {
			_afterParentTokenTransfer(
				DataType.AfterParentTokenTransferParams(_from, _to, _tokenId, totalAmountParentLinkSbtContracts)
			);
		}
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
		super.safeTransferFrom(_from, _to, _tokenId);
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
		super.safeTransferFrom(_from, _to, _tokenId, _data);
	}

	function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
		return Ownable.owner();
	}

	function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
		require(_exists(tokenId), "URI query for nonexistent token");

		return zuttoMamoStage.tokenURI(tokenId);
	}

	/**
	 * @dev Hook that is called after a set of serially-ordered token IDs
	 * have been transferred. This includes minting.
	 * And also called after one token has been burned.
	 * If the transferred token ID is in sleep mode, the current time is set.
	 */
	function _afterTokenTransfers(address _from, address _to, uint256 _tokenId, uint256 _quantity) internal override {
		if (tokenLocation[_tokenId] == DataType.TokenLocation.Operator) {
			if (zuttoMamoStage.getTimeGrowingUpToHighSchooler() <= block.timestamp) {
				zuttoMamoStage.setHighSchoolerLock(_tokenId);
			}
			tokenLocation[_tokenId] = DataType.TokenLocation.Other;
		}
		super._afterTokenTransfers(_from, _to, _tokenId, _quantity);
	}

	function exists(uint256 tokenId) public view virtual returns (bool) {
		return _exists(tokenId);
	}

	function nextTokenId() external view returns (uint256) {
		return _nextTokenId();
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	// =============================================================
	//   GET FUNCTION
	// =============================================================

	function getTokenLocation(uint256 _tokenId) external view returns (DataType.TokenLocation) {
		return tokenLocation[_tokenId];
	}
}