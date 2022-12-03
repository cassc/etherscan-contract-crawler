// SPDX-License-Identifier: Unliscensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";  

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./CosmeticERC721A/ICosmeticERC721A.sol";


contract CosmeticsRegistry is 
  Initializable, 
  OwnableUpgradeable, 
  ReentrancyGuardUpgradeable, 
  UUPSUpgradeable
{

  /**
   * @notice the current cosmetic ID.
   * 
   * @dev incremented when a new cosmetic is added to the registry.
   */
  uint256 currentCosmeticId;

  /**
   * @notice mapping from an address to a list of the cosmetic IDs they own.
   * 
   * @dev used in the front-end to allow a user to select a cosmetic to use.
   */
  address[] cosmeticContracts;

  

  /**
   * @notice mapping from a cosmetic ID to a cosmetic name.
   * 
   * @dev used in { addCosmetic } when adding a new cosmetic to the registry.
   */
  mapping (uint256 => string) public cosmetics;


  /**
   * @notice mapping from a cosmetic ID to its { CosmeticERC721A } contract address.
   * 
   * @dev used in { claimCosmetic } to see if the user is eligible for the ERC721,
   * and so that they can claim it.
   */
  mapping (uint256 => address) public cosmeticContractOf;


  /**
   * @notice initialize function sets the { currentCosmeticId } to 1.
   */
  function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        currentCosmeticId = 1;
  }

  function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}


  /**
   * @notice function to claim a new cosmetic.
   * 
   * @dev calls the contract of the { _cosmeticId } to check for elibility and claim.
   * @param _cosmeticId the cosmetic to claim.
   */
  function claimCosmetic(uint256 _cosmeticId) public onlyProxy nonReentrant {
    // instantiate the cosmetic contract using { ICosmeticERC721A } //
    ICosmeticERC721A cosmetic = ICosmeticERC721A(cosmeticContractOf[_cosmeticId]);

    // check for elibility //
    require(cosmetic.isEligible(msg.sender), "You are not eligible for this cosmetic.");

    // if eligible call { claim } on the cosmetic contract and push the ID to their { ownedCosmetics }.
    cosmetic.claim(msg.sender);
  }

  /**
   * @notice function allowing the owner to add new cosmetics to the registry.
   * 
   * @dev updates the { cosmetics } and { cosmeticContractOf } mappings to be used
   * in { claimCosmetic } in future.
   * @param _cosmetic the name of the new cosmetic.
   * @param _cosmeticContract the contract address of the new cosmetic ERC721A.
   */
  function addCosmetic(string memory _cosmetic, address _cosmeticContract) public onlyOwner {
    cosmeticContracts.push(_cosmeticContract);
    cosmetics[currentCosmeticId] = _cosmetic;
    cosmeticContractOf[currentCosmeticId] = _cosmeticContract;
    currentCosmeticId += 1;
  }
  
  /**
   * @notice function returning available cosmetic contract addresses
   */
  function getCosmeticContracts() public view returns (address[] memory) {
    return cosmeticContracts;
  }
}