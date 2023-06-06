// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HasProxyAdmin.sol";
import "../../interfaces/collections/IHasRoninTrustedOrganizationContract.sol";
import "../../interfaces/IRoninTrustedOrganization.sol";

contract HasRoninTrustedOrganizationContract is IHasRoninTrustedOrganizationContract, HasProxyAdmin {
  IRoninTrustedOrganization internal _roninTrustedOrganizationContract;

  modifier onlyRoninTrustedOrganizationContract() {
    if (roninTrustedOrganizationContract() != msg.sender) revert ErrCallerMustBeRoninTrustedOrgContract();
    _;
  }

  /**
   * @inheritdoc IHasRoninTrustedOrganizationContract
   */
  function roninTrustedOrganizationContract() public view override returns (address) {
    return address(_roninTrustedOrganizationContract);
  }

  /**
   * @inheritdoc IHasRoninTrustedOrganizationContract
   */
  function setRoninTrustedOrganizationContract(address _addr) external virtual override onlyAdmin {
    if (_addr.code.length == 0) revert ErrZeroCodeContract();
    _setRoninTrustedOrganizationContract(_addr);
  }

  /**
   * @dev Sets the ronin trusted organization contract.
   *
   * Emits the event `RoninTrustedOrganizationContractUpdated`.
   *
   */
  function _setRoninTrustedOrganizationContract(address _addr) internal {
    _roninTrustedOrganizationContract = IRoninTrustedOrganization(_addr);
    emit RoninTrustedOrganizationContractUpdated(_addr);
  }
}