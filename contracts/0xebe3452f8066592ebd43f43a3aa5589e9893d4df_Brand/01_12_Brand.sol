// SPDX-License-Identifier: MIT
// Creator: leb0wski.eth

pragma solidity ^0.8.4;

import "./NFT.sol";

contract Brand is NFT {

	uint256 constant public TOTAL_SUPPLY = 5432;
	uint256 constant public GOVERNANCE_SUPPLY = 56;
	uint256 constant public BRAND_SUPPLY = 50;

	constructor(
		string memory name_,
		string memory symbol_,
		string memory baseTokenURI_,
		string memory contractURI_
	)
		NFT(name_, symbol_, TOTAL_SUPPLY, contractURI_, baseTokenURI_)
	{}

	function setCreators(address[] memory creators_, address brand_) public onlyOwner {
		require(_currentIndex <= GOVERNANCE_SUPPLY, "Governance already distributed to creators");
		for(uint256 x; x < creators_.length; x++) {
			_safeMint(creators_[x], GOVERNANCE_SUPPLY / creators_.length);
		}
		_safeMint(brand_, BRAND_SUPPLY);
	}

	function isGovernance(uint256 id_) public pure returns (bool) {
		return id_ <= GOVERNANCE_SUPPLY;
	}
}