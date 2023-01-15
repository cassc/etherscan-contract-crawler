// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// import "../interfaces/IDNA.sol";
// import "../interfaces/IRWaste.sol";
// import "../interfaces/IScales.sol";
// import "../interfaces/IMutants.sol";
import "../contracts/library/KaijuContracts.sol";

interface IExtractorLab {
	struct Contracts {
		IDNA DNA;
		IRWaste RWaste;
		IScales Scales;
		IMutants Mutant;
	}

	function setMutantOwner(address mutantOwner) external;

	function getMutantOwner() external view returns (address);

	function unstakeMutant() external;

	function stakeMutant() external;

	function initialize(Contracts calldata _contracts, uint256 mutantId, address owner) external;
}