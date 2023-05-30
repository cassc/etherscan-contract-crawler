// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './ITicketBooth.sol';
import './IFundingCycles.sol';
import './IYielder.sol';
import './IProjects.sol';
import './IModStore.sol';
import './ITerminal.sol';
import './IOperatorStore.sol';
import './ITreasuryExtension.sol';

struct FundingCycleMetadata2 {
  uint256 reservedRate;
  uint256 bondingCurveRate;
  uint256 reconfigurationBondingCurveRate;
  bool payIsPaused;
  bool ticketPrintingIsAllowed;
  ITreasuryExtension treasuryExtension;
}

interface ITerminalV1_1 {
  event Pay(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address indexed beneficiary,
    uint256 amount,
    uint256 beneficiaryTokens,
    uint256 totalTokens,
    string note,
    address caller
  );

  event AddToBalance(uint256 indexed projectId, uint256 value, address caller);

  event AllowMigration(ITerminal allowed);

  event Migrate(uint256 indexed projectId, ITerminal indexed to, uint256 _amount, address caller);

  event Configure(uint256 indexed fundingCycleId, uint256 indexed projectId, address caller);

  event Tap(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address indexed beneficiary,
    uint256 amount,
    uint256 currency,
    uint256 netTransferAmount,
    uint256 beneficiaryTransferAmount,
    uint256 govFeeAmount,
    address caller
  );
  event Redeem(
    address indexed holder,
    address indexed beneficiary,
    uint256 indexed _projectId,
    uint256 amount,
    uint256 returnAmount,
    address caller
  );

  event PrintReserveTickets(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    address indexed beneficiary,
    uint256 count,
    uint256 beneficiaryTicketAmount,
    address caller
  );

  event DistributeToPayoutMod(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    PayoutMod mod,
    uint256 modCut,
    address caller
  );
  event DistributeToTicketMod(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    TicketMod mod,
    uint256 modCut,
    address caller
  );

  event PrintTickets(
    uint256 indexed projectId,
    address indexed beneficiary,
    uint256 amount,
    string memo,
    address caller
  );

  event Deposit(uint256 amount);

  event EnsureTargetLocalWei(uint256 target);

  event SetYielder(IYielder newYielder);

  event SetFee(uint256 _amount);

  event SetTargetLocalWei(uint256 amount);

  function projects() external view returns (IProjects);

  function fundingCycles() external view returns (IFundingCycles);

  function ticketBooth() external view returns (ITicketBooth);

  function prices() external view returns (IPrices);

  function modStore() external view returns (IModStore);

  function reservedTicketBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function balanceOf(uint256 _projectId) external view returns (uint256);

  function currentOverflowOf(uint256 _projectId) external view returns (uint256);

  function claimableOverflowOf(
    address _account,
    uint256 _amount,
    uint256 _projectId
  ) external view returns (uint256);

  function fee() external view returns (uint256);

  function deploy(
    address _owner,
    bytes32 _handle,
    string calldata _uri,
    FundingCycleProperties calldata _properties,
    FundingCycleMetadata2 calldata _metadata,
    PayoutMod[] memory _payoutMods,
    TicketMod[] memory _ticketMods
  ) external;

  function configure(
    uint256 _projectId,
    FundingCycleProperties calldata _properties,
    FundingCycleMetadata2 calldata _metadata,
    PayoutMod[] memory _payoutMods,
    TicketMod[] memory _ticketMods
  ) external returns (uint256);

  function printTickets(
    uint256 _projectId,
    uint256 _amount,
    address _beneficiary,
    string memory _memo,
    bool _preferUnstakedTickets
  ) external;

  function tap(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedWei
  ) external returns (uint256);

  function redeem(
    address _account,
    uint256 _projectId,
    uint256 _amount,
    uint256 _minReturnedWei,
    address payable _beneficiary,
    bool _preferUnstaked
  ) external returns (uint256 returnAmount);

  function printReservedTickets(uint256 _projectId)
    external
    returns (uint256 reservedTicketsToPrint);

  function setFee(uint256 _fee) external;

  function burnFromDeadAddress(uint256 _projectId) external;
}