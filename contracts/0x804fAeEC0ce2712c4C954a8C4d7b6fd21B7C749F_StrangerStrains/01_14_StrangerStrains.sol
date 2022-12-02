// SPDX-License-Identifier: MIT

/***
*     ____  ____  ____   __   __ _   ___  ____  ____    ____  ____  ____   __   __  __ _  ____ 
*    / ___)(_  _)(  _ \ / _\ (  ( \ / __)(  __)(  _ \  / ___)(_  _)(  _ \ / _\ (  )(  ( \/ ___)
*    \___ \  )(   )   //    \/    /( (_ \ ) _)  )   /  \___ \  )(   )   //    \ )( /    /\___ \
*    (____/ (__) (__\_)\_/\_/\_)__) \___/(____)(__\_)  (____/ (__) (__\_)\_/\_/(__)\_)__)(____/
*/

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

/** @title Stranger Strains */
contract StrangerStrains is ERC1155, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    
  string public name;
  string public symbol;

  uint public strainCount = 0;
  uint public totalSupply = 0;

  bool public paused = true;

  struct Strains {
    string name;
    string uri;
    uint id;
    uint maxSupply;
    uint supply;
    uint mintPrice;
  }
  
  mapping(uint => Strains) public strains;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC1155("") {
    name = _tokenName;
    symbol = _tokenSymbol;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
  modifier activeStrain(uint256 _id) {
    require(_exists(_id), "This strain does not exist yet, check back later!");
    _;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Mint functions ~~~~~~~~~~~~~~~~~~~~
  function mint(uint _id) public payable activeStrain(_id) {
    require(!paused, "The contract is paused!");
    require(strains[_id].supply + 1 <= strains[_id].maxSupply, "Max supply for this strain would be exceeded!");
    require(msg.value >= strains[_id].mintPrice, "Insufficient funds!");

    strains[_id].supply++;
    totalSupply++;
    _mint(_msgSender(), _id, 1, "");
  }

  // ~~~~~~~~~~~~~~~~~~~~ Burn functions ~~~~~~~~~~~~~~~~~~~~
  function burn(uint _id, uint _amount) public activeStrain(_id) {
    require(balanceOf(_msgSender(), _id) >= _amount, "Burnt amount would exceed balance");
    strains[_id].supply -= _amount;
    _burn(_msgSender(), _id, _amount);
  }

  // ~~~~~~~~~~~~~~~~~~~~ Various Checks ~~~~~~~~~~~~~~~~~~~~
  function _exists(uint _id) internal view virtual returns (bool) {
    return strains[_id].id != 0;
  }

  function uri(uint _id) public view virtual override returns (string memory) {
    require(_exists(_id), "This strain does not exist yet, check back later!");

    return strains[_id].uri;
  }

  // ~~~~~~~~~~~~~~~~~~~~ OpenSea Filtering overrides ~~~~~~~~~~~~~~~~~~~~ 
  function setApprovalForAll(address operator, bool approved) 
    public 
    override 
    onlyAllowedOperator(operator) 
  {
      super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) 
    public 
    virtual 
    override 
    onlyAllowedOperator(from) 
  {
      super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  // ~~~~~~~~~~~~~~~~~~~~ Owner functions ~~~~~~~~~~~~~~~~~~~~
  /** @notice Adds new strain with next available id. 
    * @param _name Name of token. Should match name in metadata.
    * @param _uri FULL URI link to id's metadata.
    * @param _maxSupply Max supply for this specific id. 
    * @param _mintPrice Mint price expressed in WEI.
  */
  function addStrain(string memory _name, string memory _uri, uint _maxSupply, uint _mintPrice) external onlyOwner {
    strainCount++;

    Strains memory newStrain = Strains(
      _name,
      _uri,
      strainCount,
      _maxSupply,
      0,
      _mintPrice
    );

    strains[strainCount] = newStrain;
    emit URI(_uri, strainCount);
  }

  function setURI(uint _id, string memory _newUri) external onlyOwner activeStrain(_id) {
    strains[_id].uri = _newUri;
    emit URI(_newUri, _id);
  }

  function setCost(uint _id, uint _newPrice) external onlyOwner activeStrain(_id) {
    strains[_id].mintPrice = _newPrice;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  // ~~~~~~~~~~~~~~~~~~~~ Withdraw functions ~~~~~~~~~~~~~~~~~~~~
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
/*__            __    __                     
 /\ \          /\ \__/\ \              __    
 \_\ \     __  \ \ ,_\ \ \____    ___ /\_\   
 /'_` \  /'__`\ \ \ \/\ \ '__`\  / __`\/\ \  
/\ \L\ \/\ \L\.\_\ \ \_\ \ \L\ \/\ \L\ \ \ \ 
\ \___,_\ \__/.\_\\ \__\\ \_,__/\ \____/\ \_\
 \/__,_ /\/__/\/_/ \/__/ \/___/  \/___/  \/_/
*/
}