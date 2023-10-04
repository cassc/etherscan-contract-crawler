// SPDX-License-Identifier: MIT

/*
  _    _                   _     _            _______   _          _
 | |  | |                 \ \   / /          |__   __| (_)        | |
 | |__| | __ ___   _____   \ \_/ /__  _   _     | |_ __ _  ___  __| |
 |  __  |/ _` \ \ / / _ \   \   / _ \| | | |    | | '__| |/ _ \/ _` |
 | |  | | (_| |\ V /  __/    | | (_) | |_| |    | | |  | |  __/ (_| |
 |_|  |_|\__,_| \_/ \___|    |_|\___/ \__,_|    |_|_|  |_|\___|\__,_|
  _______               _               _____ _      ____   __  __
 |__   __|             (_)             |_   _| |    / __ \ / _|/ _|
    | |_   _ _ __ _ __  _ _ __   __ _    | | | |_  | |  | | |_| |_
    | | | | | '__| '_ \| | '_ \ / _` |   | | | __| | |  | |  _|  _|
    | | |_| | |  | | | | | | | | (_| |  _| |_| |_  | |__| | | | |
    |_|\__,_|_|  |_| |_|_|_| |_|\__, | |_____|\__|  \____/|_| |_|__
                 | |  / __ \     __/ |  /\              (_)    |__ \
   __ _ _ __   __| | | |  | |_ _|___/  /  \   __ _  __ _ _ _ __   ) |
  / _` | '_ \ / _` | | |  | | '_ \    / /\ \ / _` |/ _` | | '_ \ / /
 | (_| | | | | (_| | | |__| | | | |  / ____ \ (_| | (_| | | | | |_|
  \__,_|_| |_|\__,_|  \____/|_| |_| /_/    \_\__, |\__,_|_|_| |_(_)
                                              __/ |
                                             |___/

  by steviep.eth

*/


pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./OffOnURI.sol";


contract OffOn is ERC721, Ownable {
  uint256 public latestHash;
  uint256 public lastTurnedOn;
  uint256 public lastTurnedOff;

  OffOnURI public tokenURIContract;

  uint256 public constant totalSupply = 1;
  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints = 1000;

  event MetadataUpdate(uint256 _tokenId);
  event TurnOff(uint256 timestamp);
  event TurnOn(uint256 timestamp, uint256 hash);

  constructor () ERC721('Have You Tried Turning It Off and On Again?', 'OFFON') {
    _royaltyBeneficiary = msg.sender;
    tokenURIContract = new OffOnURI();
    _mint(msg.sender, 0);
  }

  modifier stateAction {
    require(ownerOf(0) == msg.sender, 'Only token owner can turn off or on');
    _;
    emit MetadataUpdate(0);
  }

  function turnOff() external stateAction {
    require(latestHash != 0, 'Cannot turn off if not on');
    latestHash = 0;
    lastTurnedOff = block.timestamp;
    emit TurnOff(block.timestamp);
  }

  function turnOn() external stateAction {
    require(latestHash == 0, 'Cannot turn on if not off');
    latestHash = block.difficulty;
    lastTurnedOn = block.timestamp;
    emit TurnOn(block.timestamp, latestHash);
  }

  function isOn() external view returns (bool) {
    return latestHash != 0;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(tokenId == 0, "ERC721Metadata: URI query for nonexistent token");
    return tokenURIContract.tokenURI(tokenId);
  }

  function setTokenURIContract(address newContract) external onlyOwner {
    tokenURIContract = OffOnURI(newContract);
    emit MetadataUpdate(0);
  }

  function exists(uint256 tokenId) external pure returns (bool) {
    return tokenId == 0;
  }

  function setRoyaltyInfo(
    address royaltyBeneficiary,
    uint16 royaltyBasisPoints
  ) external onlyOwner {
    _royaltyBeneficiary = royaltyBeneficiary;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (_royaltyBeneficiary, _salePrice * _royaltyBasisPoints / 10000);
  }

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @return `true` if the contract implements `interfaceId` and
  ///         `interfaceId` is not 0xffffffff, `false` otherwise
  /// @dev Interface identification is specified in ERC-165. This function
  ///      uses less than 30,000 gas. See: https://eips.ethereum.org/EIPS/eip-165
  ///      See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}
