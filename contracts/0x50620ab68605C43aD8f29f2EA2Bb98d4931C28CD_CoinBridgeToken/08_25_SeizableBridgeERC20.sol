/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity 0.6.2;

import "../../access/Roles.sol";
import "./BridgeERC20.sol";
import "../../interfaces/ISeizable.sol";
import "../../interfaces/IProcessor.sol";

/**
 * @title SeizableBridgeERC20
 * @dev SeizableBridgeERC20 contract
 *
 * Error messages
 * SE02: Caller is not seizer
**/


contract SeizableBridgeERC20 is Initializable, ISeizable, BridgeERC20 {
  using Roles for Roles.Role;
  
  Roles.Role internal _seizers;

  function initialize(
    address owner, 
    IProcessor processor
  ) 
    public override initializer 
  {
    BridgeERC20.initialize(owner, processor);
  }

  modifier onlySeizer() {
    require(isSeizer(_msgSender()), "SE02");
    _;
  }

  function isSeizer(address _seizer) public override view returns (bool) {
    return _seizers.has(_seizer);
  }

  function addSeizer(address _seizer) public override onlyAdministrator {
    _seizers.add(_seizer);
    emit SeizerAdded(_seizer);
  }

  function removeSeizer(address _seizer) public override onlyAdministrator {
    _seizers.remove(_seizer);
    emit SeizerRemoved(_seizer);
  }

  /**
   * @dev called by the owner to seize value from the account
   */
  function seize(address _account, uint256 _value)
    public override onlySeizer hasProcessor
  {
    _processor.seize(_msgSender(), _account, _value);
    emit Seize(_account, _value);
    emit Transfer(_account, _msgSender(), _value); 
  }

  /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
  uint256[49] private ______gap;
}