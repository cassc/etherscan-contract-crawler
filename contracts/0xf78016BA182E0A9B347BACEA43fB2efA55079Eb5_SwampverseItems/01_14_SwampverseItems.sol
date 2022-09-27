// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICroak.sol";

/// @title Swampverse: Items
/// @author @ryeshrimp

contract SwampverseItems is ERC1155Supply, Pausable, Ownable {

    mapping(address => bool) controllers;

    uint256 public constant SWAMP_PILE = 1;
    uint256 public constant WOOD = 2;
    uint256 public constant METAL = 3;
    uint256 public constant CANOE = 4;
    uint256 public constant TOOL_KIT = 5;
    uint256 public constant BOAT = 6;
    uint256 public constant PASS = 7;

    ICroak public croakAddress;
    
    string public beginning_uri;
    string public ending_uri;

    uint256 public swampPileCostForMetal;
    uint256 public swampPileCostForWood;

    uint256 public woodCostForCanoe;
    uint256 public metalCostForToolKit;

    uint public metalCostForBoat;
    uint public woodCostForBoat;

    uint256 public maxSwampBoats;
    uint256 public refineryCost;

    constructor(
      uint256 _swampPileCostForMetal,
      uint256 _swampPileCostForWood,
      uint256 _woodCostForCanoe,
      uint256 _metalCostForToolKit,
      uint256 _metalCostForBoat,
      uint256 _woodCostForBoat,
      uint256 _maxSwampBoats,
      uint256 _refineryCost,
      address _croakAddress
    ) ERC1155("") {

      swampPileCostForMetal = _swampPileCostForMetal;
      swampPileCostForWood = _swampPileCostForWood;

      woodCostForCanoe = _woodCostForCanoe;
      metalCostForToolKit = _metalCostForToolKit;

      metalCostForBoat = _metalCostForBoat;
      woodCostForBoat = _woodCostForBoat;

      maxSwampBoats = _maxSwampBoats;
      refineryCost = _refineryCost;

      croakAddress = ICroak(_croakAddress);

      controllers[msg.sender] = true;
    }

    function mint(address minterAddress, uint256 itemId, uint256 amount) external {
      require(controllers[msg.sender], "Only controllers can mint");
      _mint(minterAddress, itemId, amount, "");
    }

    function burn(address burnerAddress, uint256 itemId, uint256 amount) external {
      require(controllers[msg.sender], "Only controllers can burn");
      _burn(burnerAddress, itemId, amount);
    }

    function mintSwampPile(address minterAddress, uint256 amount) external {
      require(controllers[msg.sender], "Only controllers can mint");
      _mint(minterAddress, SWAMP_PILE, amount, "");
    }

    function mintMetal(uint256 amount) external whenNotPaused {
      _burn(msg.sender, SWAMP_PILE, swampPileCostForMetal*amount);
      croakAddress.burn(msg.sender, refineryCost * amount * 1 ether);
      _mint(msg.sender, METAL, amount, "");
    }

    function mintWood(uint256 amount) external whenNotPaused {
      _burn(msg.sender, SWAMP_PILE, swampPileCostForWood*amount);
      croakAddress.burn(msg.sender, refineryCost * amount * 1 ether);
      _mint(msg.sender, WOOD, amount, "");
    }

    function mintToolkit(uint256 amount) external whenNotPaused {
      _burn(msg.sender, METAL, metalCostForToolKit*amount);
      croakAddress.burn(msg.sender, refineryCost * amount * 1 ether);
      _mint(msg.sender, TOOL_KIT, amount, "");
    }

    function mintCanoe(uint256 amount) external whenNotPaused {
      _burn(msg.sender, WOOD, woodCostForCanoe*amount);
      croakAddress.burn(msg.sender, refineryCost * amount * 1 ether);
      _mint(msg.sender, CANOE, amount, "");
    }

    function mintBoat(uint256 amount) external whenNotPaused {
      require(totalSupply(BOAT)+amount < maxSwampBoats+1, "Swampboat limit reached");
      require(totalSupply(TOOL_KIT) > 0, "Toolkit required");

      _burn(msg.sender, METAL, metalCostForBoat*amount);
      _burn(msg.sender, WOOD, woodCostForBoat*amount);
      _burn(msg.sender, CANOE, amount);
      croakAddress.burn(msg.sender, refineryCost * amount * 1 ether);

      _mint(msg.sender, BOAT, amount, "");
    }
    
    /**
      @param _mode: 
      1) swampPileCostForMetal;
      2) swampPileCostForWood;
      3) woodCostForCanoe;
      4) metalCostForToolKit;
      5) metalCostForBoat;
      6) woodCostForBoat;
      7) maxSwampBoats;
      8) refineryCost;
      anything else - will result in revert()
      @param _value: corresponding value
    */
    function setValues(uint256 _mode, uint256 _value) external onlyOwner {
      if(_mode == 1) swampPileCostForMetal = _value;
      else if(_mode == 2) swampPileCostForWood = _value;
      else if(_mode == 3) woodCostForCanoe = _value;
      else if(_mode == 4) metalCostForToolKit = _value;
      else if(_mode == 5) metalCostForBoat = _value;
      else if(_mode == 6) woodCostForBoat = _value;
      else if(_mode == 7) maxSwampBoats = _value;
      else if(_mode == 8) refineryCost = _value;
      else revert("WRONG_MODE");
    }

    function setCroakAddress(address _croakAddress) external onlyOwner {
      croakAddress = ICroak(_croakAddress);
    }

    /**
        @param _mode: 
        1 - replace beinning of URI
        2 - replce ending of URI
        anything else - will result in revert()
        @param _new_uri: corresponding value
     */
    function setURI(uint256 _mode, string memory _new_uri) external onlyOwner {
        if (_mode == 1) beginning_uri = _new_uri;
        else if (_mode == 2) ending_uri = _new_uri;
        else revert("SwampverseItems.setURI: WRONG_MODE");
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
      require(exists(_tokenId), "id does not exist");
      return string(
        abi.encodePacked(beginning_uri, Strings.toString(_tokenId), ending_uri)
      );
    }

  /**
   * allows another contract to burn tokens
   * @param _from the holder of the tokens to burn
   * @param _ids [1, 2, 3, 4]
   * @param _amounts amount to burn of each id
   */
  function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burnBatch(_from, _ids, _amounts);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

}