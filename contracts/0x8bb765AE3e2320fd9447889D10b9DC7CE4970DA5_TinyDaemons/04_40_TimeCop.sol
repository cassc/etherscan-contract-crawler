/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: TimeCop.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Time based mechanism for Solidity
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ITimeCop.sol";
import "../access/MaxAccess.sol";

abstract contract TimeCop is MaxAccess
                           , ITimeCop {

   uint private startPresale;
   uint private presaleDuration;

   event PresaleSet(uint start, uint length);

  function setPresale(
    uint time
  , uint duration
  ) external
    onlyDev() {
    startPresale = time;
    presaleDuration = duration;
    emit PresaleSet(time, duration);
  }

  function showPresaleStart()
    external
    view
    virtual
    override (ITimeCop)
    returns (uint) {
    return startPresale;
  }

  function showStart()
    external
    view
    virtual
    override (ITimeCop)
    returns (uint) {
    return startPresale + presaleDuration;
  }

  function showPresaleTimes()
    external
    view
    virtual
    override (ITimeCop)
    returns (uint, uint) {
    return (
      startPresale
    , startPresale + presaleDuration
    );
  }

    modifier onlyPresale() {
    if (block.timestamp < startPresale) {
      revert TooSoonJunior({
        yourTime: block.timestamp
      , hitTime: startPresale
      });
    }
    if (block.timestamp >= startPresale + presaleDuration) {
      revert TooLateBoomer({
        yourTime: block.timestamp
      , hitTime: startPresale + presaleDuration
      });
    }
    _;
  }

    modifier onlySale() {
    if (block.timestamp < startPresale + presaleDuration) {
      revert TooSoonJunior({
        yourTime: block.timestamp
      , hitTime: startPresale + presaleDuration
      });
    }
    if (startPresale == 0) {
      revert MaxSplaining({
        reason: "TimeCop: You've been Time Copped. NGL onlyDev() hasn't set the time"
      });
    }
    _;
  }
}