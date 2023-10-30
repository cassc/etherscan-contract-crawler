// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./NBC721Collection.sol";
import "./NBCStructsAndEnums.sol";

contract NBCBeaconFactory is AccessControl {
  address public NBCPayableAddress = address(0x61566435CFf27FfbF813BD0E15b70428E3AF38e4);
  uint256 public NBCPrimarySaleShare = 5;
  address public immutable beaconAddress;

  event ContractCreated(address creator, address contractAddress);

  constructor(address _beaconAddress) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    beaconAddress = _beaconAddress;
  }

  function createContract(
    string memory _name,
    string memory _symbol,
    Init721Params memory _initParams,
    address[] memory _psAddresses,
    uint256[] memory _psShares
  ) external returns (address) {
    uint256 sharesTotal = 0;
    uint256 psLength = _psAddresses.length + 1;
    address[] memory psAddresses = new address[](psLength);
    uint256[] memory psShares = new uint256[](psLength);
    for (uint256 i = 0; i < psLength; ) { 
      if (i == psLength - 1) {
        psAddresses[i] = NBCPayableAddress;
        psShares[i] = NBCPrimarySaleShare;
        sharesTotal += NBCPrimarySaleShare;
      } else {
        psAddresses[i] = _psAddresses[i];
        psShares[i] = _psShares[i];
        sharesTotal += _psShares[i];
      }
      
      unchecked {
        ++i;
      }
    }

    if (sharesTotal > 100) {
      revert InvalidPaymentSplitterSettings();
    }

    BeaconProxy proxy = new BeaconProxy(
        beaconAddress,
        abi.encodeWithSelector(
            NBC721Collection.initialize.selector,
            _name,
            _symbol,
            _initParams,
            psAddresses,
            psShares,
            msg.sender
        )
    );

    emit ContractCreated(msg.sender, address(proxy));
    return address(proxy);
  }

  function updatePaymentSettings(address _address, uint256 _share) external onlyRole(DEFAULT_ADMIN_ROLE) {
    NBCPayableAddress = _address;
    NBCPrimarySaleShare = _share;
  }
}