// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {IBorrower} from "../../interfaces/IBorrower.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {UcuProxy} from "./proxy/UcuProxy.sol";

/**
 * @title GoldfinchFactory
 * @notice Contract that allows us to create other contracts, such as CreditLines and BorrowerContracts
 *  Note GoldfinchFactory is a legacy name. More properly this can be considered simply the GoldfinchFactory
 * @author Goldfinch
 */

contract GoldfinchFactory is BaseUpgradeablePausable {
  GoldfinchConfig public config;

  /// Role to allow for pool creation
  bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

  using ConfigHelper for GoldfinchConfig;

  event BorrowerCreated(address indexed borrower, address indexed owner);
  event PoolCreated(ITranchedPool indexed pool, address indexed borrower);
  event CreditLineCreated(IV2CreditLine indexed creditLine);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
    _setRoleAdmin(BORROWER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice Allows anyone to create a CreditLine contract instance
   * @dev There is no value to calling this function directly. It is only meant to be called
   *  by a TranchedPool during it's creation process.
   */
  function createCreditLine() external returns (IV2CreditLine) {
    IV2CreditLine creditLine = IV2CreditLine(
      _deployMinimal(config.creditLineImplementationAddress())
    );
    emit CreditLineCreated(creditLine);
    return creditLine;
  }

  /**
   * @notice Allows anyone to create a Borrower contract instance
   * @param owner The address that will own the new Borrower instance
   */
  function createBorrower(address owner) external returns (address) {
    address _borrower = _deployMinimal(config.borrowerImplementationAddress());
    IBorrower borrower = IBorrower(_borrower);
    borrower.initialize(owner, address(config));
    emit BorrowerCreated(address(borrower), owner);
    return address(borrower);
  }

  /**
   * @notice Allows anyone to create a new TranchedPool for a single borrower
   * @param _borrower The borrower for whom the CreditLine will be created
   * @param _juniorFeePercent The percent of senior interest allocated to junior investors, expressed as
   *  integer percents. eg. 20% is simply 20
   * @param _limit The maximum amount a borrower can drawdown from this CreditLine
   * @param _interestApr The interest amount, on an annualized basis (APR, so non-compounding), expressed as an integer.
   *  We assume 18 digits of precision. For example, to submit 15.34%, you would pass up 153400000000000000,
   *  and 5.34% would be 53400000000000000
   * @param _paymentPeriodInDays How many days in each payment period.
   *  ie. the frequency with which they need to make payments.
   * @param _termInDays Number of days in the credit term. It is used to set the `termEndTime` upon first drawdown.
   *  ie. The credit line should be fully paid off {_termIndays} days after the first drawdown.
   * @param _lateFeeApr The additional interest you will pay if you are late. For example, if this is 3%, and your
   *  normal rate is 15%, then you will pay 18% while you are late. Also expressed as an 18 decimal precision integer
   *
   * Requirements:
   *  You are the admin
   */
  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external onlyAdminOrBorrower returns (ITranchedPool) {
    ITranchedPool pool;
    // need to enclose in a scope to avoid overflowing stack
    {
      ImplementationRepository repo = config.getTranchedPoolImplementationRepository();
      UcuProxy poolProxy = new UcuProxy(repo, _borrower);
      pool = ITranchedPool(address(poolProxy));
    }

    pool.initialize(
      address(config),
      _borrower,
      _juniorFeePercent,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays,
      _fundableAt,
      _allowedUIDTypes
    );
    emit PoolCreated(pool, _borrower);
    config.getPoolTokens().onPoolCreated(address(pool));
    return pool;
  }

  // Stolen from:
  // https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
  function _deployMinimal(address _logic) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(_logic);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }
    return proxy;
  }

  function isBorrower() public view returns (bool) {
    return hasRole(BORROWER_ROLE, _msgSender());
  }

  modifier onlyAdminOrBorrower() {
    require(isAdmin() || isBorrower(), "Must have admin or borrower role to perform this action");
    _;
  }
}