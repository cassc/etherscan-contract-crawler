// SPDX-License-Identifier: MIT
// BuildingIdeas.io (Breedable.sol)

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ERC721A.sol";
import "./IEDOToken.sol";
import "./IBreedManager.sol";
import "./Rewardable.sol";

abstract contract Breedable is Ownable, ERC721A, Rewardable {

  IBreedManager public breedManager;
  bool public BREEDING_ACTIVE = false;
  uint public BREED_PRICE = 150;

  function breed(uint256 _male, uint256 _female) external {
    require(address(breedManager) != address(0), 'Breading contract not set');
    require(address(yieldToken) != address(0), 'Yield Token not set');
    require(BREEDING_ACTIVE, "Breeding is not active");
    require(ownerOf(_male) == _msgSender() && ownerOf(_female) == _msgSender());
    require(breedManager.breed(_male, _female));
    yieldToken.burn(_msgSender(), BREED_PRICE);
    _safeMint(_msgSender(), 1);
  }

  function registerGender(bytes calldata signature, uint256 _tokenId, uint256 _gender) external {
	  breedManager.registerGender(signature, _tokenId, _gender);
  }

  function setBreedingManager(address _manager) external onlyOwner {
	  breedManager = IBreedManager(_manager);
  }

  function setBreedPrice(uint256 _breedPrice) external onlyOwner {
  	BREED_PRICE = _breedPrice;
  }

  function flipBreedingActive() external onlyOwner {
	  BREEDING_ACTIVE = !BREEDING_ACTIVE;
  }
}