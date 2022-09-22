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

/**
 * @title IProcessor
 * @dev IProcessor interface
 **/

 
interface IProcessor {
  
  /* Register */
  function register(string calldata _name, string calldata _symbol, uint8 _decimals) external;
  /* Rulable */
  function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool, uint256, uint256);
  /* ERC20 */
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) 
    external returns (bool, address, uint256);
  function approve(address _owner, address _spender, uint256 _value) external;
  function allowance(address _owner, address _spender) external view returns (uint256);
  function increaseApproval(address _owner, address _spender, uint _addedValue) external;
  function decreaseApproval(address _owner, address _spender, uint _subtractedValue) external;
  /* Seizable */
  function seize(address _caller, address _account, uint256 _value) external;
  /* Mintable */
  function mint(address _caller, address _to, uint256 _amount) external;
  function burn(address _caller, address _from, uint256 _amount) external;
}