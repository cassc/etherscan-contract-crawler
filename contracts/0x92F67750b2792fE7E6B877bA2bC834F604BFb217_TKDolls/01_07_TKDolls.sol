// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AQueryable.sol";

contract TKDolls is ERC721AQueryable, Ownable {
 
    string private _baseTokenURI;

		address public claimContract;
		bool public active;

		mapping(uint256 => bool) public claims;

    constructor(address _claimContract
    ) ERC721A("TKDolls", "DOLLS") {
				claimContract = _claimContract;
    }

		function claim(address _recipient, uint256[] memory _claimIds) external {
				require(msg.sender == claimContract, "Not allowed");
				uint256 amount = _claimIds.length;
				uint i;
				for (i; i < amount; ){
					claims[_claimIds[i]] = true;
					unchecked { ++i; }
				}
				_safeMint(_recipient, amount);
		}
    
    function setBaseURI(string calldata newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

}