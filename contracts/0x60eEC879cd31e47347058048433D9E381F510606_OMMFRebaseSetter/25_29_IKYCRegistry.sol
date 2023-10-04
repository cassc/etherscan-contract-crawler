/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

/**
 * @title IKYCRegistry
 * @author Ondo Finance
 * @notice The interface for Ondo's KYC Registry contract
 */
interface IKYCRegistry {
  /**
   * @notice Retrieves KYC status of an account
   *
   * @param kycRequirementGroup The KYC group for which we wish to check
   * @param account             The account we wish to retrieve KYC status for
   *
   * @return bool Whether the `account` is KYC'd
   */
  function getKYCStatus(
    uint256 kycRequirementGroup,
    address account
  ) external view returns (bool);

  /**
   * @notice View function for the public nested mapping of kycState
   *
   * @param kycRequirementGroup The KYC group to view
   * @param account             The account to check if KYC'd
   */
  function kycState(
    uint256 kycRequirementGroup,
    address account
  ) external view returns (bool);
}