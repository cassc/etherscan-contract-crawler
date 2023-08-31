// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/ICrewToken.sol";


/**
 * @dev Allows the owner of a crew member to set a name for it that will be included in ERC721 metadata
 */
contract CrewNames is Ownable, Pausable {
  ICrewToken token;

  // Mapping from crew tokenId to name
  mapping (uint => string) private _crewNames;

  // Mapping from name to a boolean whether it's currently in use
  mapping (string => bool) private _usedNames;

  event NameChanged(uint indexed crewId, string newName);

  constructor(ICrewToken _token) {
    token = _token;
  }

  /**
   * @dev Set the name of the crew member one time only
   */
  function setName(uint _crewId, string memory _newName) external {
    require(bytes(_crewNames[_crewId]).length == 0, "CrewNames: crew name already set");
    require(_msgSender() == token.ownerOf(_crewId), "CrewNames: caller is not the owner");
    require(validateName(_newName) == true, "CrewNames: invalid name");
    require(isNameUsed(_newName) == false, "CrewNames: name already in use");

    toggleNameUsed(_newName);
    _crewNames[_crewId] = _newName;
    emit NameChanged(_crewId, _newName);
  }

  /**
   * @dev Retrieves the name of a given crew member
   * @param _crewId ERC721 tokenID for crew members
   */
  function getName(uint _crewId) public view returns (string memory) {
    return _crewNames[_crewId];
  }

  /**
   * @dev Returns if the name is in use
   * @param _nameString Name to check if is in use
   */
  function isNameUsed(string memory _nameString) public view returns (bool) {
    return _usedNames[toLower(_nameString)];
  }

  /**
   * @dev Marks the name as used
   * @param _str String to mark as used
   */
  function toggleNameUsed(string memory _str) internal {
    _usedNames[toLower(_str)] = true;
  }

  /**
   * @dev Check if the name string is valid
   * Between 1 and 32 characters (Alphanumeric and spaces without leading or trailing space)
   *
   * @param _str String to validate
   */
  function validateName(string memory _str) public pure returns (bool) {
    bytes memory b = bytes(_str);

    if(b.length < 1) return false;
    if(b.length > 32) return false; // Cannot be longer than 25 characters
    if(b[0] == 0x20) return false; // Leading space
    if (b[b.length - 1] == 0x20) return false; // Trailing space

    bytes1 lastChar = b[0];

    for (uint i; i < b.length; i++) {
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
        !(char >= 0x41 && char <= 0x5A) && //A-Z
        !(char >= 0x61 && char <= 0x7A) && //a-z
        !(char == 0x20) //space
      ) {
        return false;
      }

      lastChar = char;
    }

    return true;
  }

  /**
   * @dev Converts the string to lowercase
   * @param _str String to convert to lowercase
   */
  function toLower(string memory _str) public pure returns (string memory) {
    bytes memory bStr = bytes(_str);
    bytes memory bLower = new bytes(bStr.length);

    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }

    return string(bLower);
  }

  /**
   * @dev Pauses the contract and prevents transfers / burns
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses the contract allowing transfers / burns
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}