// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";
import "solady/utils/LibString.sol";

/// @title GobDrops
/// @author EtDu

contract GobDrops is ERC721, Owned {
  using LibString for uint256;

  uint256 public totalSupply = 0;
  string public baseURI;
  address public admin;

  modifier onlyAdmin() {
    require(msg.sender == admin, "Must be admin!");
    _;
  }

  constructor(address adminAddress) ERC721("GOB DROPS", "DROP") Owned(msg.sender) {
    admin = adminAddress;
  }

  /// @notice Mint new trait. Only callable by ETH Gobblers contract on trait unlock.
  /// @param user User address to claim the NFT trait.
  function mint(address user) external onlyOwner {
    _mint(user, totalSupply);
    unchecked {
      totalSupply++;
    }
  }

  function tokenURI(uint tokenID) public view override returns (string memory) {
    require(tokenID < totalSupply, "This token does not exist");
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
  }

  function changeBaseURI(string calldata newBaseURI) external onlyAdmin {
    baseURI = newBaseURI;
  }

  function changeAdmin(address newAdmin) external onlyAdmin {
    admin = newAdmin;
  }

  function withdraw() external onlyAdmin {
    assembly {
        let result := call(0, caller(), selfbalance(), 0, 0, 0, 0)
        switch result
        case 0 { revert(0, 0) }
        default { return(0, 0) }
    }
  }
}