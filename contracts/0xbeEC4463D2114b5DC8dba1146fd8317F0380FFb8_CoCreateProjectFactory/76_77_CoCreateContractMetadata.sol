// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract CoCreateContractMetadata is Initializable {
  string public name;
  string public description;

  // solhint-disable-next-line
  function __CoCreateContractMetadata_init(string memory _name, string memory _description) internal onlyInitializing {
    __CoCreateContractMetadata_init_unchained(_name, _description);
  }

  // solhint-disable-next-line
  function __CoCreateContractMetadata_init_unchained(string memory _name, string memory _description)
    internal
    onlyInitializing
  {
    name = _name;
    description = _description;
  }
}