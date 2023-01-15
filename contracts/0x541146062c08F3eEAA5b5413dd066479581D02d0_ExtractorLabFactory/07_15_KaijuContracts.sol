// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "../../interfaces/IDNA.sol";
import "../../interfaces/IRWaste.sol";
import "../../interfaces/IScales.sol";
import "../../interfaces/IMutants.sol";

library KaijuContracts {
	struct Contracts {
		IDNA DNA;
		IRWaste RWaste;
		IScales Scales;
		IMutants Mutant;
	}
}