/*     +%%#-                           ##.        =+.    .+#%#+:       *%%#:    .**+-      =+
 *   .%@@*#*:                          @@: *%-   #%*=  .*@@=.  =%.   .%@@*%*   [email protected]@=+=%   .%##
 *  .%@@- -=+                         *@% :@@-  #@=#  [email protected]@*     [email protected]  :@@@: ==* -%%. ***   #@=*
 *  %@@:  -.*  :.                    [email protected]@-.#@#  [email protected]%#.   :.     [email protected]*  :@@@.  -:# .%. *@#   *@#*
 * *%@-   +++ [email protected]#.-- .*%*. .#@@*@#  %@@%*#@@: [email protected]@=-.         -%-   #%@:   +*-   =*@*   [email protected]%=:
 * @@%   =##  [email protected]@#-..%%:%[email protected]@[email protected]@+  ..   [email protected]%  #@#*[email protected]:      .*=     @@%   =#*   -*. +#. %@#+*@
 * @@#  [email protected]*   #@#  [email protected]@. [email protected]@+#*@% =#:    #@= :@@-.%#      -=.  :   @@# .*@*  [email protected]=  :*@:[email protected]@-:@+
 * -#%[email protected]#-  :@#@@+%[email protected]*@*:=%+..%%#=      *@  *@++##.    =%@%@%%#-  =#%[email protected]#-   :*+**+=: %%++%*
 *
 * @title: [EIP1822/1967] UUPS Proxy Factory
 * @author: cryptogenics on medium, r4881t on GitHub
 * @notice source at https://r48b1t.medium.com/universal-upgrade-proxy-proxyfactory-a-modern-walkthrough-22d293e369cb
 * @custom:change-log readability, comments added
 * @custom:change-log UUPS 1822 added for LZ 1822/1967 ERC20 factory
 */

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright waived under CC0                                                 *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./eip/20/IERC20.sol";
import "./modules/access/IRoles.sol";
import "./lib/Roles.sol";

contract WrapperFactory is IRoles {

  using Roles for Roles.Role;

  event WrapperCreated(address proxy);
  event UpdatedImp(address _src, address _dest);
  error Unauthorized();

  address[] internal proxies;
  address internal source;
  address internal destination;
  Roles.Role internal contractRoles;
  bytes4 constant internal DEVS = 0xca4b208b;
  bytes4 constant internal OWNERS = 0x8da5cb5b;
  bytes4 constant internal ADMIN = 0xf851a440;

  constructor (address _admin, address _source, address _destination) {
    contractRoles.add(ADMIN, _admin);
    contractRoles.setAdmin(_admin);
    contractRoles.add(DEVS, _admin);
    contractRoles.setDeveloper(_admin);
    contractRoles.add(OWNERS, _admin);
    contractRoles.setOwner(_admin);
    source = _source;
    destination = _destination;
    emit UpdatedImp(source, destination);
  }

  modifier onlyRole(bytes4 role) {
    if (contractRoles.has(role, msg.sender) || contractRoles.has(ADMIN, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  modifier onlyDev() {
    if (contractRoles.has(DEVS, msg.sender)) {
      _;
    } else {
    revert Unauthorized();
    }
  }

  function payload(
    string memory _name
  , string memory _symbol
  , uint8 _deci
  , address _token
  , address _admin
  , address _endpoint
  , uint256 _gas
  ) internal
    pure
    returns (bytes memory) {
    return abi.encodeWithSignature(
      "initialize(string,string,uint8,address,address,address,uint256)"
    , _name
    , _symbol
    , _deci
    , _token
    , _admin
    , _endpoint
    , _gas
    );
  }

  function payloadDest(
    string memory _name
  , string memory _symbol
  , uint8 _deci
  , address _admin
  , address _endpoint
  , uint256 _gas
  ) internal
    pure
    returns (bytes memory) {
    return abi.encodeWithSignature(
      "initialize(string,string,uint8,address,address,uint256)"
    , _name
    , _symbol
    , _deci
    , _admin
    , _endpoint
    , _gas
    );
  }

  function createWrapperSource(
    string memory _name
  , string memory _symbol
  , address _token
  , address _endpoint
  , uint256 _gas
  ) external
    onlyRole(ADMIN)
    returns (address) {
    uint8 _deci = IERC20(_token).decimals();
    address _admin = this.developer();
    ERC1967Proxy proxy = new ERC1967Proxy(source, payload(_name, _symbol, _deci, _token, _admin, _endpoint, _gas));
    emit WrapperCreated(address(proxy));
    proxies.push(address(proxy));
    return address(proxy);
  }

  function createWrapperDestination(
    string memory _name
  , string memory _symbol
  , uint8 _deci
  , address _endpoint
  , uint256 _gas
  ) external
    onlyRole(ADMIN)
    returns (address) {
    address _admin = this.developer();
    ERC1967Proxy proxy = new ERC1967Proxy(destination, payloadDest(_name, _symbol, _deci, _admin, _endpoint, _gas));
    emit WrapperCreated(address(proxy));
    proxies.push(address(proxy));
    return address(proxy);
  }

  function deployedWrappers()
    external
    view
    returns (address[] memory) {
    return proxies;
  }

  function currentImplementation()
    external
    view
    returns (address _source, address _destination) {
    _source = source;
    _destination = destination;
  }

  function updateImplementation(
    address _source
  , address _destination
  ) external
    onlyRole(ADMIN) {
    source = _source;
    destination = _destination;
    emit UpdatedImp(source, destination);
  }

  /////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard
  /////////////////////////////////////////

  /// @notice Get the address of the owner
  /// @return The address of the owner.
  function owner()
    external
    view
    virtual
    returns(address) {
    return contractRoles.getOwner();
  }

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(
    address _newOwner
  ) external
    virtual
    onlyRole(OWNERS) {
    contractRoles.add(OWNERS, _newOwner);
    contractRoles.setOwner(_newOwner);
    contractRoles.remove(OWNERS, msg.sender);
  }

  ////////////////////////////////////////////////////////////////
  /// EIP-173: Contract Ownership Standard, MaxFlowO2's extension
  ////////////////////////////////////////////////////////////////

  /// @dev This is the classic "EIP-173" method of renouncing onlyOwner()
  function renounceOwnership()
    external
    virtual
    onlyRole(OWNERS) {
    contractRoles.setOwner(address(0));
    contractRoles.remove(OWNERS, msg.sender);
  }

  //////////////////////////////////////////////
  /// [Not an EIP]: Contract Developer Standard
  //////////////////////////////////////////////

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @return Developer of contract
  function developer()
    external
    view
    virtual
    returns (address) {
    return contractRoles.getDeveloper();
  }

  /// @dev This renounces your role as onlyDev()
  function renounceDeveloper()
    external
    virtual
    onlyRole(DEVS) {
    contractRoles.setDeveloper(address(0));
    contractRoles.remove(DEVS, msg.sender);
  }

  /// @dev Classic "EIP-173" but for onlyDev()
  /// @param newDeveloper: addres of new pending Developer role
  function transferDeveloper(
    address newDeveloper
  ) external
    virtual
    onlyRole(DEVS) {
    contractRoles.add(DEVS, newDeveloper);
    contractRoles.setDeveloper(newDeveloper);
    contractRoles.remove(DEVS, msg.sender);
  }

  //////////////////////////////////////////
  /// [Not an EIP]: Contract Roles Standard
  //////////////////////////////////////////

  /// @dev Returns `true` if `account` has been granted `role`.
  /// @param role: Bytes4 of a role
  /// @param account: Address to check
  /// @return bool true/false if account has role
  function hasRole(
    bytes4 role
  , address account
  ) external
    view
    virtual
    override
    returns (bool) {
    return contractRoles.has(role, account);
  }

  /// @dev Returns the admin role that controls a role
  /// @param role: Role to check
  /// @return admin role
  function getRoleAdmin(
    bytes4 role
  ) external
    view
    virtual
    override
    returns (bytes4) {
    return ADMIN;
  }

  /// @dev Grants `role` to `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to give role to
  function grantRole(
    bytes4 role
  , address account
  ) external
    virtual
    override
    onlyRole(role) {
    contractRoles.add(role, account);
  }

  /// @dev Revokes `role` from `account`
  /// @param role: Bytes4 of a role
  /// @param account: account to revoke role from
  function revokeRole(
    bytes4 role
  , address account
  ) external
    virtual
    override
    onlyRole(role) {
    contractRoles.remove(role, account);
  }

  /// @dev Renounces `role` from `account`
  /// @param role: Bytes4 of a role
  function renounceRole(
    bytes4 role
  ) external
    virtual
    override
    onlyRole(role) {
    contractRoles.remove(role, msg.sender);
  }

  //////////////////////////////////////////
  /// EIP-165: Standard Interface Detection
  //////////////////////////////////////////

  /// @dev Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @notice Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(
    bytes4 interfaceID
  ) external
    view
    virtual
    override
    returns (bool) {
    return (
      interfaceID == type(IERC165).interfaceId
    );
  }
}