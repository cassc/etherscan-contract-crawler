/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: ERC2981Collection.sol
 * @author: Max Flow O2 -> @MaxFlowO2 on bird app/GitHub
 * @notice: Use case for EIP 2981, steered more towards NFT Collections as a whole
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IMAX2981.sol";
import "../../access/MaxAccess.sol";

abstract contract ERC2981Collection is MaxAccess, IMAX2981 {

  address private royaltyAddress;
  uint256 private royaltyPermille;

  event royalatiesSet(
          uint value
        , address recipient
        );

  // the internals to do logic flows later

  // @dev to set roaylties on contract via EIP 2891
  // @param _receiver, address of recipient
  // @param _permille, permille xx.x -> xxx value
  function _setRoyalties(
    address _receiver
  , uint256 _permille
  ) internal {
  if (_permille >= 1000 || _permille == 0) {
    revert MaxSplaining({
      reason: string(
                abi.encodePacked(
                  "ERC2981Collection: ",
                  Strings.toHexString(uint160(msg.sender), 20),
                  " submitted ",
                  Strings.toString(_permille),
                  " and that is out of bounds!"
                )
              )
    });
  }
    royaltyAddress = _receiver;
    royaltyPermille = _permille;
    emit royalatiesSet(royaltyPermille, royaltyAddress);
  }

  // @dev to remove royalties from contract
  function _removeRoyalties()
    internal {
    delete royaltyAddress;
    delete royaltyPermille;
    emit royalatiesSet(royaltyPermille, royaltyAddress);
  }

  // Logic for this contract (abstract)

  // @notice: This sets the contract as royalty reciever (useful with abstract PaymentSplitter)
  // @param permille: Percentage you want so 3.5% -> 35
  function setRoyaltiesThis (
    uint permille
  ) external
    virtual
    override
    onlyOwner() {
    _setRoyalties(address(this), permille);
  }

  // @notice: This sets royalties per EIP-2981
  // @param newAddress: Sets the address for royalties
  // @param permille: Percentage you want so 3.5% -> 35
  function setRoyalties (
    address newAddress
  , uint256 permille
  ) external
    virtual
    override
    onlyOwner() {
    _setRoyalties(newAddress, permille);
  }

  // @notice: This clears all EIP-2981 royalties (address(0) and 0%)
  function clearRoyalties()
    external
    virtual
    override
    onlyOwner() {
    _removeRoyalties();
  }

  // @dev Override for royaltyInfo(uint256, uint256)
  // @param _tokenId, uint of token ID to be checked
  // @param _salePrice, uint of amount of sale
  // @return receiver, address of recipient
  // @return royaltyAmount, amount royalties recieved
  function royaltyInfo(
    uint256 _tokenId
  , uint256 _salePrice
  ) external
    view
    virtual
    override
    returns (
    address receiver
  , uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;
    royaltyAmount = _salePrice * royaltyPermille / 1000;
  }
}