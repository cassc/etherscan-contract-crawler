/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: lzLlamas.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Solidity for Llama/BAYC Mint engine, does Provenance for Metadata/Images, for lzModules
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./lzILlamas.sol";
import "../lib/PsuedoRand.sol";
import "../lib/CountersV2.sol";

abstract contract lzLlamas is lzILlamas {

  using PsuedoRand for PsuedoRand.Engine;
  using CountersV2 for CountersV2.Counter;

  PsuedoRand.Engine private llamas;
  CountersV2.Counter private tokensOnChain;
  uint private tokenStartNumber;

  event SetStartNumbers(uint numberToMint, uint startingID, uint endingID);

  // @dev this is for any team mint that happens, must be included in mint...
  function _oneTeamMint()
    internal {
    llamas.battersUp();
    llamas.battersUpTeam();
    tokensOnChain.increment();
  }

  // @dev this is for any mint outside of a team mint, must be included in mint...
  function _oneRegularMint()
    internal {
    llamas.battersUp();
    tokensOnChain.increment();
  }

  // @dev this is to add one to on chain minted
  function _addOne()
    internal {
    tokensOnChain.increment();
  }

  // @dev this is to substract one to on chain minted
  function _subOne()
    internal {
    tokensOnChain.decrement();
  }

  // @dev this will set the boolean for minter status
  // @param toggle: bool for enabled or not
  function _setStatus(
    bool toggle
  ) internal {
    llamas.setStatus(toggle);
  }

  // @dev this will set the minter fees
  // @param number: uint for fees in wei.
  function _setMintFees(
    uint number
  ) internal {
    llamas.setFees(number);
  }

  // @dev this will set the mint engine
  // @param _startID: uint for startingID number (say 2000)
  // @param _mintingCap: uint for publicMint() capacity of this chain
  // @param _teamMints: uint for maximum teamMints() capacity on this chain
  function _setLZLlamasEngine(
    uint _startID
  , uint _mintingCap
  , uint _teamMints
  ) internal {
    tokenStartNumber = _startID;
    llamas.setMaxCap(_mintingCap);
    llamas.setMaxTeam(_teamMints);

    emit SetStartNumbers( _mintingCap
                        , _startID
                        , _mintingCap + _startID);
  }

  // @dev this will set the Provenance Hashes
  // @param string memory img - Provenance Hash of images in sequence
  // @param string memory json - Provenance Hash of metadata in sequence
  // @notice: This will set the start number as well, make sure to set MaxCap
  //  also can be a hyperlink... sha3... ipfs.. whatever.
  function _setProvenance(
    string memory img
  , string memory json
  ) internal {
    llamas.setProvJSON(json);
    llamas.setProvIMG(img);
    llamas.setStartNumber();
  }

  function _nextUp()
    internal
    view
    returns (uint) {
    return tokenStartNumber + llamas.mintID();
  }

  // @dev will return status of Minter
  // @return - bool of active or not
  function minterStatus()
    external
    view
    virtual
    override
    returns (bool) {
    return llamas.status;
  }

  // @dev will return minting fees
  // @return - uint of mint costs in wei
  function minterFees()
    external
    view
    virtual
    override
    returns (uint) {
    return llamas.mintFee;
  }

  // @dev will return maximum mint capacity
  // @return - uint of maximum mints allowed
  function minterMaximumCapacity()
    external
    view
    virtual
    override
    returns (uint) {
    return llamas.maxCapacity;
  }

  // @dev will return maximum mint capacity
  // @return - uint of maximum mints allowed
  function minterMintsRemaining()
    external
    view
    virtual
    returns (uint) {
    return llamas.maxCapacity - llamas.showMinted();
  }

  // @dev will return maximum mint capacity
  // @return - uint of maximum mints allowed
  function minterCurrentMints()
    external
    view
    virtual
    returns (uint) {
    return llamas.showMinted();
  }

  // @dev will return maximum "team minting" capacity
  // @return - uint of maximum airdrops or team mints allowed
  function minterMaximumTeamMints()
    external
    view
    virtual
    override
    returns (uint) {
    return llamas.maxTeamMints;
  }

  // @dev will return "team mints" left
  // @return - uint of remaing airdrops or team mints
  function minterTeamMintsRemaining()
    external
    view
    virtual
    override
    returns (uint) {
    return llamas.maxTeamMints - llamas.showTeam();
  }

  // @dev will return "team mints" count
  // @return - uint of airdrops or team mints done
  function minterTeamMintsCount()
    external
    view
    virtual
    override
    returns (uint) {
    return llamas.showTeam();
  }

  // @dev: will return total supply for mint
  // @return: uint for this mint
  function totalSupply()
    external
    view
    virtual
    override
    returns (uint256) {
    return tokensOnChain.current();
  }

  // @dev: will return Provenance hash of images
  // @return: string memory of the Images Hash (sha256)
  function RevealProvenanceImages() 
    external 
    view 
    virtual
    override 
    returns (string memory) {
    return llamas.ProvenanceIMG;
  }

  // @dev: will return Provenance hash of metadata
  // @return: string memory of the Metadata Hash (sha256)
  function RevealProvenanceJSON()
    external
    view
    virtual
    override
    returns (string memory) {
    return llamas.ProvenanceJSON;
  }

  // @dev: will return starting number for mint
  // @return: uint of the start number
  function RevealStartNumber()
    external
    view
    virtual
    override
    returns (uint256) {
    return llamas.startNumber;
  }

  // @dev: this is will show the start number for this chain's start number
  // @return: uint of start number
  function lzStartNumber()
    external
    view
    virtual
    override
    returns (uint256) {
    return tokenStartNumber;
  }
}