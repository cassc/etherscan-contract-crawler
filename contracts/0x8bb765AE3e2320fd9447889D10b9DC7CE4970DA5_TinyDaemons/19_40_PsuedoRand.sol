/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: PsuedoRand.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Library for Llama/BAYC Mint engine...
 *  basically a random start point and a bookends mint to start
 *  i.e. 0-2999 start at 500 -> 2999, then 0 -> 499.
 *
 *  Covers IMAX721.sol and Illamas.sol
 *
 * Include with 'using PsuedoRand for PsuedoRand.Engine;'
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./CountersV2.sol";

library PsuedoRand {
  using CountersV2 for CountersV2.Counter;

  event SetProvenanceIMG(string _new, string _old);
  event SetProvenanceJSON(string _new, string _old);
  event SetStartNumber(uint _new);
  event SetMaxCapacity(uint _new, uint _old);
  event SetMaxTeamMint(uint _new, uint _old);
  event SetMintFees(uint _new, uint _old);
  event SetStatus(bool _new);

  // @dev: this is MaxSplaining(), giving you a reason, aka require(param, "reason")
  // @param reason: Use the "Contract name: error"
  // @notice: 0x0661b792 bytes4 of this
  error MaxSplaining(
    string reason
  );

  struct Engine {
    uint256 mintFee;
    uint256 startNumber;
    uint256 maxCapacity;
    uint256 maxTeamMints;
    string ProvenanceIMG;
    string ProvenanceJSON;
    CountersV2.Counter currentMinted;
    CountersV2.Counter currentTeam;
    bool status;
  }

  function setProvJSON(
    Engine storage engine
  , string memory provJSON
  ) internal {
    string memory old = engine.ProvenanceJSON;
    engine.ProvenanceJSON = provJSON;
    emit SetProvenanceJSON(provJSON, old);
  }
 
  function setProvIMG(
    Engine storage engine
  , string memory provIMG
  ) internal {
    string memory old = engine.ProvenanceIMG;
    engine.ProvenanceIMG = provIMG;
    emit SetProvenanceIMG(provIMG, old);
  }

  function setStartNumber(
    Engine storage engine
  ) internal {
    if (engine.maxCapacity == 0) {
      revert MaxSplaining({
        reason : "PsuedoRandom Lib: Maximum Capacity not set!"
      });
    }
    engine.startNumber = uint(
                           keccak256(
                             abi.encodePacked(
                               block.timestamp
                             , msg.sender
                             , engine.ProvenanceIMG
                             , engine.ProvenanceJSON
                             , block.difficulty))) 
                         % engine.maxCapacity;
    emit SetStartNumber(engine.startNumber);
  }

  function setMaxCap(
    Engine storage engine
  , uint256 max
  ) internal {
    uint old = engine.maxCapacity;
    engine.maxCapacity = max;
    emit SetMaxCapacity(max, old);
  }

  function setMaxTeam(
    Engine storage engine
  , uint256 max
  ) internal {
    uint old = engine.maxTeamMints;
    engine.maxTeamMints = max;
    emit SetMaxTeamMint(max, old);
  }

  function setFees(
    Engine storage engine
  , uint256 max
  ) internal {
    uint old = engine.mintFee;
    engine.mintFee = max;
    emit SetMintFees(max, old);
  }

  function setStatus(
    Engine storage engine
  , bool change
  ) internal {
    engine.status = change;
    emit SetStatus(change);
  }

  function mintID(
    Engine storage engine
  ) internal
    view
    returns (uint256) {
    return (engine.startNumber + engine.currentMinted.current()) % engine.maxCapacity;
  }

  function showTeam(
    Engine storage engine
  ) internal 
    view
    returns (uint256) {
    return engine.currentTeam.current();
  }

  function showMinted(
    Engine storage engine
  ) internal
    view
    returns (uint256) {
    return engine.currentMinted.current();
  }

  function battersUpTeam(
    Engine storage engine
  ) internal {
    engine.currentTeam.increment();
  }

  function battersUp(
    Engine storage engine
  ) internal {
    engine.currentMinted.increment();
  }
}