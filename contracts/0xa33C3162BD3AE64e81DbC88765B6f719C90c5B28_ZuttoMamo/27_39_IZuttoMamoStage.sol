// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { DataType } from "../lib/type/DataType.sol";

interface IZuttoMamoStage {
	function tokenURI(uint256 tokenId) external view returns (string memory);

	function isHighSchooler(uint256 _tokenId) external view returns (bool);

	function isWorkingAdult(uint256 _tokenId) external view returns (bool);

	function isElapsedTimeWorkingAdult(uint256 _tokenId) external view returns (bool);

	function isMarriage(uint256 _tokenId) external view returns (bool);

	function isElapsedTimeMarriage(uint256 _tokenId) external view returns (bool);

	function isFamily(uint256 _tokenId) external view returns (bool);

	function isOldAge(uint256 _tokenId) external view returns (bool);

	function isTomb(uint256 _tokenId) external view returns (bool);

	function setHighSchoolerLock(uint256 _tokenId) external;

	function setFamilyLock(uint256 _tokenId) external;

	function setOldAgeLock(uint256 _tokenId) external;

	function setTombLock(uint256 _tokenId) external;

	function getTimeGrowingUpToHighSchooler() external view returns (uint256);

	function getTimeGrowingUpToFamily() external view returns (uint256);

	function getTimeGrowingUpToOldAge() external view returns (uint256);

	function getTimeGrowingUpToTomb() external view returns (uint256);
}