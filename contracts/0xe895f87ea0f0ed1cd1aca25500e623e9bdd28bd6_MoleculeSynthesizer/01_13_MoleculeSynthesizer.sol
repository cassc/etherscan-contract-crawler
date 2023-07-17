// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./MoleculeScripter.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title ChemScripts Contract
/// @notice interface to get ElementBlocks owner addresses
interface ElementBlocksInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

/*
   ___ _  _ ___ __  __ ___  ___ ___ ___ ___ _____ ___
  / __| || | __|  \/  / __|/ __| _ \_ _| _ \_   _/ __|
 | (__| __ | _|| |\/| \__ \ (__|   /| ||  _/ | | \__ \
  \___|_||_|___|_|  |_|___/\___|_|_\___|_|   |_| |___/

  This is an ode to the scientific and technological progress humanity has made.

  It is also a reminder of the importance of freedom and the decentralization of
  power.

  The contract allows creators to store generative art scripts that
  turn chemical molecules into artworks.

  Every molecule that has been discovered so far can be minted.

  Use this experimental software at your own risk.

*/


contract MoleculeSynthesizer is MoleculeScripter, ERC721 {

  ////////////////////////////////////////////////////////////////////////////////////////
  // SETUP                                                                              //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice initiates the ElementBlocks contract
  ElementBlocksInterface elementBlocksContract;

  /// @notice sets up the token name, tracker and the ElementBlocks contract address
  constructor(address _elementsContract) ERC721("ChemScripts", "CHEMS") {
      elementBlocksContract = ElementBlocksInterface(_elementsContract);
  }

  /// @notice element short names to ElementBlocks tokenIDs
  mapping (string => uint) public elementToId;

  /// @notice allows contract owner to set the element's tokenIDs
  function setElementId (string memory _element, uint _elementId) public onlyOwner {
    elementToId[_element] = _elementId;
  }

  /// @notice gets element tokenIDs
  function getElementId (string memory _element) public view returns(uint) {
    return elementToId[_element];
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // ERC721 MAGIC                                                                       //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice apiURI stores the base URI to which the tokenID can be added for tokenURI
  string public apiURI;

  /// @notice contract owner can set and change the apiURI
  function setApiURI(string memory _apiURI) external onlyOwner {
      apiURI = _apiURI;
  }

  /// @notice returns the apiURI
  function _baseURI() internal view virtual override returns (string memory) {
    return apiURI;
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // NFT CHEMISTRY                                                                      //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice event is emitted when a new molecule gets minted
  event NewMolecule(uint indexed moleculeId, string formula, string indexed key, string name, uint16 indexed scriptId);

  /// @notice stores molecule information
  /// @param formula is in InChI (international chemical Identifier) format
  /// @param key is a unique hash for each molecule
  /// @param name must be one of the molecules official names
  /// @param scriptId links to the generative art script that visualizes the molecule
  struct Molecule {
    string formula;
    string key;
    string name;
    uint16 scriptId;
  }

  /// @notice tokenIds to molecules
  mapping (uint => Molecule) public molecules;

  /// @notice keys to tokenIDs
  mapping (string => uint) public keys;

  /// @notice ensures that each molecule can only exist once per script
  function moleculeChecker (uint16 _scriptId, string memory _key) public view {
    if (keys[_key] > 0) {
      require(molecules[keys[_key]-1].scriptId != _scriptId, "molecule already minted");
    }
  }

  /// @notice mints an ERC721 token and ties it to the molecule
  /// @param _formula requires everything after "InChI=" to at least one letter after the second slash
  function _createMolecule(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId
    ) internal mintableScript(_scriptId) returns (uint) {
          moleculeChecker(_scriptId, _key);
          uint id = _scriptId * 100000 + scripts[_scriptId].currentSupply;
          _safeMint(msg.sender, id);
          molecules[id] = Molecule(_formula, _key, _name, _scriptId);
          keys[_key] = id+1;
          scripts[_scriptId].currentSupply++;
          emit NewMolecule(id, _formula, _key, _name, _scriptId);
          return id;
      }

  /// @notice allows contract owner to re-assign wrong molecules when script not yet sealed
  function chemPolice(
    uint _moleculeId,
    string memory _formula,
    string memory _key,
    string memory _name) notSealed(molecules[_moleculeId].scriptId) onlyOwner external {
      Molecule storage wrongMolecule = molecules[_moleculeId];
      wrongMolecule.formula = _formula;
      wrongMolecule.key = _key;
      wrongMolecule.name = _name;
  }

  ////////////////////////////////////////////////////////////////////////////////////////
  // MINTING & ROYALTIES                                                                //
  ////////////////////////////////////////////////////////////////////////////////////////

  /// @notice elementPercentage percentage that gets send to ElementBlocks holders
  uint public elementPercentage = 50;

  /// @notice allows contract owner to set percentage that flows to element holders
  function elementSetup(uint _elementPercentage) external onlyOwner {
    elementPercentage = _elementPercentage;
  }

  /// @notice element that currently gets the general royalties
  uint public royaltyHoldingElement = 1;

  /// @notice increments the royaltyHoldingElement and accounts for non-existent tokens
  function _nextRoyaltyHolder() internal {
    royaltyHoldingElement++;
    if (royaltyHoldingElement == 101) {
      royaltyHoldingElement++;
    } else if (royaltyHoldingElement == 107) {
      royaltyHoldingElement ++;
    } else if (royaltyHoldingElement == 121) {
      royaltyHoldingElement = 1;
    }
  }

  /// @notice gets current price and enables dutch auctions
  function getPrice(uint _scriptId) view public returns(uint) {
    uint duration = uint256(scripts[_scriptId].saleDuration) * 1 hours;
    if (!scripts[_scriptId].publicSale && !scripts[_scriptId].whitelistSale) {
      return 0; // allows creator and owner to test mint for free before the sale starts
    } else if ((block.timestamp - startingTime[_scriptId]) >= duration) {
      return scripts[_scriptId].endPrice;
    } else {
      return ((duration - (block.timestamp - startingTime[_scriptId])) * ((scripts[_scriptId].startPrice - scripts[_scriptId].endPrice)  / duration) + scripts[_scriptId].endPrice);
    }
  }

  /// @notice distributes funds from minting to script creator and ElementBlock holders
  function _distributeFunds(uint _scriptId, string memory _formula, uint _numberOfElements) internal {
    if (msg.value > 0) {

      // script creator funds
      payable(scripts[_scriptId].creator).send(
        (msg.value - (msg.value*elementPercentage/100))
      );

      // specific elements royalties
      uint[] memory elementIds = formulaToElementIds(_formula, _numberOfElements);
      uint fundsPerElement = msg.value*elementPercentage/2/elementIds.length/100;
      for (uint i = 0; i < elementIds.length; i++) {
        payable(elementBlocksContract.ownerOf(elementIds[i])).send(fundsPerElement);
      }

      // general element royalties
      payable(elementBlocksContract.ownerOf(royaltyHoldingElement)).send(msg.value*elementPercentage/2/100);
      _nextRoyaltyHolder();

    }
  }

  /// @notice returns tokenIds from all elements in a formula
  function formulaToElementIds(string memory _formula, uint _numberOfElements) public view returns(uint[] memory) {
    uint[] memory elementIds = new uint[](_numberOfElements);
    uint slashCounter = 0;
    uint elementsFound = 0;
    bytes memory moleculeBytes = bytes(_formula);

    for (uint i=1; i<moleculeBytes.length; i++) {
      if (bytes1("/") == moleculeBytes[i-1]) {
        slashCounter++;
      }

      if (slashCounter == 2) {
        if (_numberOfElements != elementsFound) {
          revert("Wrong elements nr");
        }
        return elementIds;
      }

      if (slashCounter > 0) {
        string memory oneLetter = string(abi.encodePacked(moleculeBytes[i-1]));
        string memory twoLetters = string(abi.encodePacked(oneLetter, abi.encodePacked(moleculeBytes[i])));
        if (elementToId[twoLetters] > 0) {
          uint element = elementToId[twoLetters];
          elementIds[elementsFound] = element;
          elementsFound++;
        } else if (elementToId[oneLetter] > 0) {
          uint element = elementToId[oneLetter];
          elementIds[elementsFound] = element;
          elementsFound++;

        }
      }
    }

    revert("Wrong formula");

  }

  /// @notice mints a molecule
  /// @param _numberOfElements is the number of different elements in the formula
  /// @dev set the _numberOfElements to how often the element's letters occur in formula
  function mintMolecule(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId,
    uint _numberOfElements
    ) public payable {
      require(msg.value >= getPrice(_scriptId), "Insufficient funds");
      require(scripts[_scriptId].publicSale || msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "No public sale");
      _distributeFunds(_scriptId, _formula, _numberOfElements);
      _createMolecule(_formula, _key, _name, _scriptId);
  }

  /// @notice root for whitelist minting
  bytes32 public merkleRoot;

  /// @notice allows owner to set the merkleRoot for whitelist minting
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /// @notice counts the total amount of whitelisted mints across scripts per address
  mapping (address => uint) public mintCount;

  /// @notice mints a molecule when msg.sender is whitelisted
  /// @param _numberOfElements is the number of different elements in the formula
  /// @param _whitelisted the amount for which msg.sender is whitelisted
  /// @param _proof an array of proof hashes for the MerkleProof
  /// @dev set the _numberOfElements to how often the element's letters occur in formula
  function whitelistMint(
    string memory _formula,
    string memory _key,
    string memory _name,
    uint16 _scriptId,
    uint _numberOfElements,
    uint _whitelisted,
    bytes32[] memory _proof
    ) public payable {
      require(msg.value >= getPrice(_scriptId), "Insufficient funds");
      require(scripts[_scriptId].whitelistSale || msg.sender == scripts[_scriptId].creator || msg.sender == owner(), "No WL sale");
      require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _whitelisted))), "merkle proof failed");
      require(mintCount[msg.sender]<_whitelisted, "max reached");
      mintCount[msg.sender] += 1;

      _distributeFunds(_scriptId, _formula, _numberOfElements);
      _createMolecule(_formula, _key, _name, _scriptId);
  }


  /// @notice contract owner can withdraw ETH that was accidentally sent to this contract
  function rescueFunds() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
  }

}