// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./Owned.sol";

contract AvnNftListingsFactory is Owned {
  event LogNewClient(address indexed clientAddress, string clientName);

  address immutable beacon;
  bytes4 private constant INIT_SELECTOR = 0x7ab4339d;
  mapping (address => bool) public isAuthority;
  address[] private authorities;

  constructor(address _beacon) {
    beacon = _beacon;
    isAuthority[msg.sender] = true;
    authorities.push(msg.sender);
  }

  function setAuthority(address _authority, bool _isAuthorised)
    external
    onlyOwner
  {
    require(_authority != address(0), "Cannot be zero address");

    if (_isAuthorised == isAuthority[_authority])
      return;
    else if (_isAuthorised) {
      isAuthority[_authority] = true;
      authorities.push(_authority);
    } else {
      isAuthority[_authority] = false;
      uint256 endAuthority = authorities.length - 1;
      for (uint256 i; i < endAuthority;) {
        if (authorities[i] == _authority) {
          authorities[i] = authorities[endAuthority];
          break;
        }
        unchecked { i++; }
      }
      authorities.pop();
    }
  }

  function getAuthorities()
    external
    view
    returns(address[] memory)
  {
    return authorities;
  }

  function addNewClient(string calldata _clientName, address _initialAuthority)
    external
    returns(address)
  {
    require(isAuthority[msg.sender], "Only authority");
    BeaconProxy proxy = new BeaconProxy(beacon, abi.encodeWithSelector(INIT_SELECTOR, _clientName, _initialAuthority));
    emit LogNewClient(address(proxy), _clientName);
    return address(proxy);
  }
}