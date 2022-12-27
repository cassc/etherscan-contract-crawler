// SPDX-License-Identifier: CNU

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

pragma solidity ^0.8.0;

/**
 * @title IComplianceRegistry
 * @dev IComplianceRegistry interface
 **/
interface IComplianceRegistry {
  event AddressAttached(
    address indexed trustedIntermediary,
    uint256 indexed userId,
    address indexed address_
  );
  event AddressDetached(
    address indexed trustedIntermediary,
    uint256 indexed userId,
    address indexed address_
  );

  function userId(address[] calldata _trustedIntermediaries, address _address)
    external
    view
    returns (uint256, address);

  function validUntil(address _trustedIntermediary, uint256 _userId)
    external
    view
    returns (uint256);

  function attribute(
    address _trustedIntermediary,
    uint256 _userId,
    uint256 _key
  ) external view returns (uint256);

  function attributes(
    address _trustedIntermediary,
    uint256 _userId,
    uint256[] calldata _keys
  ) external view returns (uint256[] memory);

  function isAddressValid(
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (bool);

  function isValid(address _trustedIntermediary, uint256 _userId)
    external
    view
    returns (bool);

  function registerUser(
    address _address,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function registerUsers(
    address[] calldata _addresses,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function attachAddress(uint256 _userId, address _address) external;

  function attachAddresses(
    uint256[] calldata _userIds,
    address[] calldata _addresses
  ) external;

  function detachAddress(address _address) external;

  function detachAddresses(address[] calldata _addresses) external;

  function updateUserAttributes(
    uint256 _userId,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function updateUsersAttributes(
    uint256[] calldata _userIds,
    uint256[] calldata _attributeKeys,
    uint256[] calldata _attributeValues
  ) external;

  function updateTransfers(
    address _realm,
    address _from,
    address _to,
    uint256 _value
  ) external;

  function monthlyTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function monthlyInTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyInTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function monthlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function yearlyOutTransfers(
    address _realm,
    address[] calldata _trustedIntermediaries,
    address _address
  ) external view returns (uint256);

  function addOnHoldTransfer(
    address trustedIntermediary,
    address token,
    address from,
    address to,
    uint256 amount
  ) external;

  function getOnHoldTransfers(address trustedIntermediary)
    external
    view
    returns (
      uint256 length,
      uint256[] memory id,
      address[] memory token,
      address[] memory from,
      address[] memory to,
      uint256[] memory amount
    );

  function processOnHoldTransfers(
    uint256[] calldata transfers,
    uint8[] calldata transferDecisions,
    bool skipMinBoundaryUpdate
  ) external;

  function updateOnHoldMinBoundary(uint256 maxIterations) external;

  event TransferOnHold(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferApproved(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferRejected(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
  event TransferCancelled(
    address indexed trustedIntermediary,
    address indexed token,
    address indexed from,
    address to,
    uint256 amount
  );
}