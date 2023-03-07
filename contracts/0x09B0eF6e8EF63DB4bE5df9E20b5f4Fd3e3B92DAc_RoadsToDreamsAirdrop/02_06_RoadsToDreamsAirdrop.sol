// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/// @title The final contract for the roads2Dreams airdrop
contract RoadsToDreamsAirdrop is ERC721AQueryable, Ownable {

  // variables
  /// @dev The base toke URI
  string private _baseTokenURI;
  /// @dev The maximum token supply
  uint16 private _maxSupply;

  constructor(string memory name, string memory symbol, string memory baseURI, uint16 maxSupply) ERC721A(name, symbol) {
    _baseTokenURI = baseURI;
    _maxSupply = maxSupply;
  }

  function contractURI() public view returns (string memory) {
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, "contractMetadata"))
      : "";
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  /// @notice This function allows owner to change the base token uri
  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  /// @notice This function allows batch airdrop mints.
  function mintBatch(address[] calldata accounts) external onlyOwner {
    require(_totalMinted() + accounts.length <= _maxSupply, "M2");
    for (uint256 i = 0; i < accounts.length;) {
      _safeMint(accounts[i], 1);
      unchecked {
        ++i;
      }
    }
  }
}