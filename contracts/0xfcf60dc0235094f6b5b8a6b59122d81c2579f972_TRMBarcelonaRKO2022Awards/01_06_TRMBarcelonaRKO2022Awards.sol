// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import 'solmate/src/tokens/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error LockedContract();
error NotTransferable();
error NotAirdropper();

/// @title TRM Barcelona RKO 2022 Awards
/// @author TrakonXYZ (https://trakon.xyz)
contract TRMBarcelonaRKO2022Awards is ERC721, Ownable {
  using Strings for uint256;

  uint256 public constant maxSupply = 11;
  bool public isLocked;

  address airdropper;
  string baseURI;

  constructor(string memory _baseURI, address _airdropper)
    ERC721('TRM Barcelona RKO 2022 Awards', 'TRMB2022')
  {
    baseURI = _baseURI;
    airdropper = _airdropper;

    for (uint256 i = 1; i <= maxSupply; ++i) {
      _mint(_airdropper, i);
    }
  }

  // Metadata
  function tokenURI(uint256 id) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, id.toString()));
  }

  function setBaseURI(string memory _baseURI) public onlyOwner isNotLocked {
    baseURI = _baseURI;
  }

  // end Metadata

  // Airdropper actions
  function airdropTo(address _to, uint256 tokenId) external {
    if (msg.sender != airdropper) {
      revert NotAirdropper();
    }
    super.transferFrom(msg.sender, _to, tokenId);
  }

  function setAirdropper(address _airdropper) external onlyOwner {
    airdropper = _airdropper;
  }

  // end Airdropper actions

  // Locking
  function lock() external onlyOwner {
    isLocked = true;
  }

  modifier isNotLocked() {
    if (isLocked) {
      revert LockedContract();
    }
    _;
  }

  // end Locking

  // Implement non-transferable token spec.
  function transferFrom(
    address,
    address,
    uint256
  ) public pure override {
    revert NotTransferable();
  }
}