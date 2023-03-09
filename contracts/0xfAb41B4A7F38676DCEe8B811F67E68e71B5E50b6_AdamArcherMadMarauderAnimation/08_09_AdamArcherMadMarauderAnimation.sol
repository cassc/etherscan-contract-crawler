import "Guardable/ERC721AGuardable.sol";
import "solmate/auth/Owned.sol";
import "./lib/MarauderErrors.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract AdamArcherMadMarauderAnimation is ERC721AGuardable, Owned {
    address public immutable BOX_O_BAD_GUYS_CONTRACT_ADDRESS;
    string private baseUri = "ipfs://NOT_YET_DUMMIES/";

    constructor(address _mintPassContractAddress) ERC721AGuardable("Adam Archer Mad Marauder Animation", "ARCHER") Owned(msg.sender) {
      BOX_O_BAD_GUYS_CONTRACT_ADDRESS = _mintPassContractAddress;
    }

    function mintFromBox(address recipient, uint256 amount) external {
      if (msg.sender != BOX_O_BAD_GUYS_CONTRACT_ADDRESS) revert InvalidCaller();
      _mint(recipient, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return baseUri;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
      baseUri = _uri;
    }
}