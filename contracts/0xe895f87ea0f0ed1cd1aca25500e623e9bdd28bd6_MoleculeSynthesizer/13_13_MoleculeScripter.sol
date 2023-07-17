// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @notice stores and manages generative art scripts
contract MoleculeScripter is Ownable {

  /// @notice stores script data
  /// @param name is the script's title
  /// @param scriptCode stores all generative art code on chain
  /// @param creator is the artists address
  /// @param publicSale scripts can be minted to
  /// @param locked scripts cannot be changed anymore
  /// @param isSealed scripts lock all molecule's chemical data forever
  /// @param currentSupply shows how many molecules have been minted with that script
  /// @param totalSupply is the limit of molecules that can be minted with that script
  /// @param saleDuration is the time in hours of the dutch auction
  /// @param startPrice is the price in wei the dutch auction starts with
  /// @param endPrice is the price in wei minting stays at after the saleDuration ended
  struct Script {
    string name;
    string scriptCode;
    address creator;
    bool publicSale;
    bool whitelistSale;
    bool locked;
    bool isSealed;
    uint16 currentSupply;
    uint16 totalSupply;
    uint32 saleDuration;
    uint64 startPrice;
    uint64 endPrice;

  }

  /// @notice emits when a new script is created
  event NewScript(
    uint indexed scriptId,
    string name,
    string scriptCode,
    address creator,
    bool publicSale,
    bool whitelistSale,
    bool locked,
    bool isSealed,
    uint16 currentSupply,
    uint16 totalSupply,
    uint32 saleDuration,
    uint64 startPrice,
    uint64 endPrice
  );

  /// @notice stores all scripts on chain
  Script[] public scripts;

  /// @notice number of scripts a creator can deploy
  mapping (address => uint) public allowedScripts;

  /// @notice script ids that belong to a creator
  mapping (uint => address) public scriptToCreator;

  /// @notice total number of scripts a creator has deployed
  mapping (address => uint) creatorScriptCount;

  /// @notice script IDs to timestamps of sales starts
  mapping (uint => uint) startingTime;

  /// @notice allow new creators in
  function allowCreator(address _creator, uint _scriptsAllowed) external onlyOwner {
    allowedScripts[_creator] = allowedScripts[_creator] + _scriptsAllowed;
  }

  /// @notice returns all script ids created by one creator
  function getScriptsByCreator(address _creator) external view returns(uint[] memory) {
    uint[] memory result = new uint[](creatorScriptCount[_creator]);
    uint counter = 0;
    for (uint i = 0; i < scripts.length; i++) {
      if (scriptToCreator[i] == _creator) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  /// @notice checks if the artists is allowed to publish a script
  modifier onlyCreators(address _creator) {
    require(allowedScripts[_creator] > 0 || _creator == owner(), "Creator not allowed");
    require(allowedScripts[_creator] > creatorScriptCount[_creator] || _creator == owner(), "Creator max scripts reached");
    _;
  }

  /// @notice creates a new script
  function createScript(
    string memory _name,
    string memory _scriptCode,
    uint16 _totalSupply,
    uint32 _saleDuration,
    uint64 _startPrice,
    uint64 _endPrice
    ) external onlyCreators(msg.sender) {
      scripts.push(Script(_name, _scriptCode, msg.sender, false, false, false, false, 0, _totalSupply, _saleDuration, _startPrice, _endPrice));
      uint id = scripts.length -1;
      creatorScriptCount[msg.sender]++;
      scriptToCreator[id] = msg.sender;
      emit NewScript(id, _name, _scriptCode, msg.sender, false, false, false, false, 0, _totalSupply, _saleDuration, _startPrice, _endPrice);
  }

  /// @notice allows to activate / deactivate a script and sets starting time for the sale
  function saleSwitch(uint _scriptId, bool _publicSale, bool _whitelistSale) external onlyScriptCreator(_scriptId) {
    scripts[_scriptId].publicSale = _publicSale;
    scripts[_scriptId].whitelistSale = _whitelistSale;
    if (_publicSale || _whitelistSale) {
      startingTime[_scriptId] = block.timestamp;
    }
  }

  /// @notice only script creator or owner can execute a function
  modifier onlyScriptCreator(uint _scriptId) {
    require(msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "Only script creator or owner");
    _;
  }

  /// @notice checks if the script is below its total supply
  modifier mintableScript(uint _scriptId) {
    require(scripts[_scriptId].currentSupply+1 <= scripts[_scriptId].totalSupply, "Total supply reached");
    _;
  }

  /// @notice only proceeds when the script is not locked
  modifier notLocked(uint _scriptId) {
    require(!scripts[_scriptId].locked, "Script locked");
    _;
  }

  /// @notice permanently locks a script => price, supply, and code cannot be altered
  function lockScript(uint _scriptId) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].locked = true;
  }

  /// @notice creators can update the script code when the script is not locked
  function updateScriptName(uint _scriptId, string memory _scriptName) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].name = _scriptName;
  }

  /// @notice creators can update the script code when the script is not locked
  function updateScriptCode(uint _scriptId, string memory _scriptCode) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].scriptCode = _scriptCode;
  }

  /// @notice updates total supply when the script is not locked
  function updateScriptTotalSupply(uint _scriptId, uint16 _totalSupply) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    require(scripts[_scriptId].currentSupply <= _totalSupply, "Supply already exceeded");
    scripts[_scriptId].totalSupply = _totalSupply;
  }

  /// @notice updates price per molecule when the script is not locked
  function updateScriptPrice(uint _scriptId, uint32 _saleDuration, uint64 _startPrice, uint64 _endPrice) notLocked(_scriptId) onlyScriptCreator(_scriptId) external {
    scripts[_scriptId].saleDuration = _saleDuration;
    scripts[_scriptId].startPrice = _startPrice;
    scripts[_scriptId].endPrice = _endPrice;
  }

  /// @notice only proceeds when the script is not sealed
  modifier notSealed(uint _scriptId) {
    require(!scripts[_scriptId].isSealed, "Script is sealed");
    _;
  }

  /// @notice permanently seals a script => molecules cannot be altered anymore
  function sealScript(uint _scriptId) notSealed(_scriptId) onlyOwner external {
    scripts[_scriptId].isSealed = true;
  }
}