// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IOKGScholarship.sol";
import "./interfaces/IOKGManagement.sol";
import "./interfaces/IRestrictionV2.sol";

contract OKGScholarship is Initializable, IOKGScholarship {
	IOKGManagement public gov;
	IRestrictionV2 public restrict;
	IERC721 public heroes;

	mapping(bytes32 => Scholarship) createdScholarship;
	mapping(uint256 => bool) public lockedHeroes;
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	struct Scholarship {
		bool active;
		uint256[] heroIds;
		address owner;
		address assignee;
	}

	modifier onlyManager() {
		require(gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager");
		_;
	}

	function init(
		IOKGManagement _gov,
		IRestrictionV2 _restrict,
		IERC721 _heroes
	) external initializer {
		gov = _gov;
		restrict = _restrict;
		heroes = _heroes;
	}

	function setGovernance(IOKGManagement _gov) external onlyManager {
		gov = _gov;
	}

	function setRestriction(IRestrictionV2 _restrict) external onlyManager {
		restrict = _restrict;
	}

	function setHeroes(IERC721 _heroes) external onlyManager {
		heroes = _heroes;
	}

	function getScolarship(string calldata _id) external view returns (Scholarship memory) {
		bytes32 id = keccak256(abi.encodePacked(_id));
		return createdScholarship[id];
	}

	function scholarship(
		uint256[] calldata _heroIds,
		string calldata _scholarshipId,
		address _assignee,
		bytes calldata _signature
	) external override {
		bytes32 id = keccak256(abi.encodePacked(_scholarshipId));
		require(createdScholarship[id].owner == address(0), "Scholarship already existed");

		bytes32 _msgHash = ECDSAUpgradeable.toEthSignedMessageHash(
			keccak256(abi.encodePacked(_heroIds, msg.sender, _assignee, _scholarshipId))
		);
		require(
			gov.hasRole(MANAGER_ROLE, ECDSAUpgradeable.recover(_msgHash, _signature)),
			"Invalid params or signature"
		);
		createdScholarship[id] = Scholarship(true, _heroIds, msg.sender, _assignee);

		for (uint256 i; i < _heroIds.length; i++) {
			require(
				msg.sender == heroes.ownerOf(_heroIds[i]),
				"Transaction must be sent by heroes owner"
			);
			require(
				!lockedHeroes[_heroIds[i]],
				"Heroes must not be locked"
			);

			lockedHeroes[_heroIds[i]] = true;
			restrict.untradeable(address(heroes), _heroIds[i]);
		}

		emit NewScholarship(_heroIds, msg.sender, _assignee, _scholarshipId);
	}

	function cancelScholarship(
		string calldata _scholarshipId,
		bytes calldata _signature
	) external override {
		bytes32 scholarshipId = keccak256(abi.encodePacked(_scholarshipId));

		bytes32 _msgHash = ECDSAUpgradeable.toEthSignedMessageHash(scholarshipId);

		require(
			gov.hasRole(MANAGER_ROLE, ECDSAUpgradeable.recover(_msgHash, _signature)),
			"Invalid params or signature"
		);

		Scholarship memory scholar = createdScholarship[scholarshipId];
		require(scholar.active, "Scholarship not existed");
		require(scholar.owner == msg.sender, "Transaction must be sent by owner");

		for (uint256 i = 0; i < scholar.heroIds.length; i++) {
			restrict.unrestrict(address(heroes), scholar.heroIds[i]);
			delete lockedHeroes[scholar.heroIds[i]];
		}
		createdScholarship[scholarshipId].active = false;

		emit CancelScholarship(scholar.heroIds, scholar.owner, scholar.assignee, _scholarshipId);
	}
}