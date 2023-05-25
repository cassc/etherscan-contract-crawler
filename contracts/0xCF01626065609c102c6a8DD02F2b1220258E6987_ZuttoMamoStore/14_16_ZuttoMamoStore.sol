// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IZuttoMamo } from "./interface/IZuttoMamo.sol";

abstract contract ZuttoMamoStoreConfig {
	struct PresaleMintStruct {
		bool isDone;
		mapping(address => uint256) numberOfPresaleMintByAddress;
	}

	// =============================================================
	//   ENUM
	// =============================================================

	enum SalePhase {
		Locked,
		Presale
	}

	// =============================================================
	//   EXTERNAL CONTRACT
	// =============================================================

	IZuttoMamo public zuttoMamo;

	// =============================================================
	//   CONSTANTS
	// =============================================================

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

	// =============================================================
	//   STORAGE
	// =============================================================

	SalePhase public phase = SalePhase.Locked;

	bytes32 public merkleRoot;

	uint256 public mintCost = 0.021 ether;

	uint256 public presaleMintIndex;

	uint256 public additionalSaleLimit = 3;

	address public withdrawAddress = 0x853dac8E9115E30220857C8bDb4486e34Ba93fEa;

	bool public additionalSale = false;

	// wallet address => mint count
	mapping(address => uint256) public additionalSaleCount;

	// The presale mint struct (index => PresaleMintStruct)
	mapping(uint256 => PresaleMintStruct) public presaleMintStructs;
}

abstract contract ZuttoMamoStoreAdmin is ZuttoMamoStoreConfig, Ownable, AccessControl {
	// =============================================================
	//   ACCESS CONTROL
	// =============================================================

	function grantRole(bytes32 _role, address _account) public override onlyOwner {
		_grantRole(_role, _account);
	}

	function revokeRole(bytes32 _role, address _account) public override onlyOwner {
		_revokeRole(_role, _account);
	}

	// =============================================================
	//   EXTERNAL CONTRACT
	// =============================================================

	function setZuttoMamo(IZuttoMamo _zuttomamo) external onlyRole(ADMIN_ROLE) {
		zuttoMamo = _zuttomamo;
	}

	// =============================================================
	//   OTHER FUNCTION
	// =============================================================

	function withdraw() external onlyRole(ADMIN_ROLE) {
		(bool sent, ) = withdrawAddress.call{ value: address(this).balance }("");
		require(sent, "failed to move fund to withdrawAddress contract");
	}

	function setWithdrawAddress(address _ownerAddress) external onlyRole(ADMIN_ROLE) {
		require(_ownerAddress != address(0), "withdrawAddress shouldn't be 0");
		withdrawAddress = _ownerAddress;
	}

	function setPhase(SalePhase _phase) external onlyRole(ADMIN_ROLE) {
		phase = _phase;
	}

	function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE) {
		merkleRoot = _merkleRoot;
	}

	function setPresaleMintIndex(uint256 _index) external onlyRole(ADMIN_ROLE) {
		require(presaleMintStructs[_index].isDone != true, "this index has already been used");
		bool done = !presaleMintStructs[presaleMintIndex].isDone;
		presaleMintStructs[presaleMintIndex].isDone = done;
		presaleMintIndex = _index;
	}

	function setAdditionalSale(bool _value) external onlyRole(ADMIN_ROLE) {
		additionalSale = _value;
	}

	function setAdditionalSaleLimit(uint256 _value) external onlyRole(ADMIN_ROLE) {
		additionalSaleLimit = _value;
	}

	function setMintCost(uint256 _cost) external onlyRole(ADMIN_ROLE) {
		mintCost = _cost;
	}
}

contract ZuttoMamoStore is ZuttoMamoStoreAdmin {
	// =============================================================
	//   CONSTRUCTOR
	// =============================================================

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(ADMIN_ROLE, msg.sender);
	}

	// =============================================================
	//   MINT FUNCTION
	// =============================================================

	function presaleMint(uint256 _quantity, uint256 _allotted, bytes32[] calldata _proof) external payable {
		require(phase == SalePhase.Presale, "presale event is not active");
		require(tx.origin == msg.sender, "the caller is another controler");
		require(_quantity != 0, "the quantity is zero");
		require(mintCost * _quantity <= msg.value, "not enough eth");
		require(isValid(msg.sender, _allotted, _proof), "you don't have a whitelist");

		if (additionalSale) {
			require(additionalSaleCount[msg.sender] + _quantity <= additionalSaleLimit, "exceeds number of earned tokens");
			additionalSaleCount[msg.sender] += _quantity;
		} else {
			require(
				presaleMintStructs[presaleMintIndex].numberOfPresaleMintByAddress[msg.sender] + _quantity <= _allotted,
				"exceeds number of earned tokens"
			);
			presaleMintStructs[presaleMintIndex].numberOfPresaleMintByAddress[msg.sender] += _quantity;
		}

		zuttoMamo.birth(msg.sender, _quantity);
	}

	// =============================================================
	//   MERKLE TREE
	// =============================================================

	function _leaf(address _address, uint256 _allotted) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_address, _allotted));
	}

	function isValid(address _address, uint256 _allotted, bytes32[] calldata _proof) public view returns (bool) {
		return MerkleProof.verifyCalldata(_proof, merkleRoot, _leaf(_address, _allotted));
	}

	// =============================================================
	//   GET FUNCTION
	// =============================================================
	function getPresaleMintIsdone(uint256 _presaleMintIndex) external view returns (bool) {
		return presaleMintStructs[_presaleMintIndex].isDone;
	}

	function getPresaleMintCount(address _address) external view returns (uint256) {
		return presaleMintStructs[presaleMintIndex].numberOfPresaleMintByAddress[_address];
	}
}