// SPDX-License-Identifier: MIT

/*

  Coded for MakerDAO and The Keep3r Network with ♥ by
  ██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
  ██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
  ██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
  ██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
  ██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
  ╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░
  https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import {DustCollector} from './utils/DustCollector.sol';
import {Governable} from './utils/Governable.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {IMakerDAOBudgetManager} from '../interfaces/IMakerDAOBudgetManager.sol';
import {INetworkPaymentAdapter} from '../interfaces/external/INetworkPaymentAdapter.sol';
import {INetworkTreasury} from '../interfaces/external/INetworkTreasury.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IKeep3rV2} from '../interfaces/external/IKeep3rV2.sol';

contract MakerDAOBudgetManager is IMakerDAOBudgetManager, INetworkTreasury, DustCollector {
  /// @inheritdoc IMakerDAOBudgetManager
  address public constant override DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  /// @inheritdoc IMakerDAOBudgetManager
  address public override keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;

  /// @inheritdoc IMakerDAOBudgetManager
  address public override job = 0x5D469E1ef75507b0E0439667ae45e280b9D81B9C;

  /// @inheritdoc IMakerDAOBudgetManager
  address public override networkPaymentAdapter = 0xaeFed819b6657B3960A8515863abe0529Dfc444A;

  /// @inheritdoc IMakerDAOBudgetManager
  address public override keeper;

  /// @inheritdoc IMakerDAOBudgetManager
  uint256 public override daiToClaim;

  /// @inheritdoc IMakerDAOBudgetManager
  uint256 public override invoiceNonce;

  /// @inheritdoc IMakerDAOBudgetManager
  mapping(uint256 => uint256) public override invoiceAmount;

  constructor(address _governor) Governable(_governor) {
    emit Keep3rJobSet(keep3r, job);
    emit NetworkPaymentAdapterSet(networkPaymentAdapter);
  }

  // Views

  /// @inheritdoc IMakerDAOBudgetManager
  function getDaiCredits() external view returns (uint256 _daiCredits) {
    _daiCredits = _credits();
  }

  /// @inheritdoc INetworkTreasury
  function getBufferSize() external view returns (uint256 _bufferSize) {
    uint256 _daiCredits = _credits();

    // Checks dai credits greater than dai to claim, if not return 0
    _bufferSize = _daiCredits > daiToClaim ? _daiCredits - daiToClaim : 0;
  }

  // Methods

  /// @inheritdoc IMakerDAOBudgetManager
  function invoiceGas(
    uint256 _gasCostETH,
    uint256 _claimableDai,
    string memory _description
  ) external override onlyGovernor {
    daiToClaim += _claimableDai;
    invoiceAmount[++invoiceNonce] = _claimableDai;

    // emits event to be tracked in DuneAnalytics dashboard & contrast with txs
    emit InvoicedGas(invoiceNonce, _gasCostETH, _claimableDai, _description);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function deleteInvoice(uint256 _invoiceNonce) external override onlyGovernor {
    uint256 deleteAmount = invoiceAmount[_invoiceNonce];
    if (deleteAmount > daiToClaim) revert IMakerDAOBudgetManager_InvoiceClaimed();

    daiToClaim -= deleteAmount;
    delete invoiceAmount[_invoiceNonce];

    // emits event to filter out InvoicedGas events
    emit DeletedInvoice(_invoiceNonce);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function claimDai() external override onlyGovernor {
    _claimDai();
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function claimDaiUpkeep() external override onlyKeeper {
    _claimDai();
  }

  /// @notice This function handles the flow of Vested DAI
  function _claimDai() internal {
    // claims DAI
    uint256 _daiStreamed = INetworkPaymentAdapter(networkPaymentAdapter).topUp();

    // checks for DAI debt and reduces debt if applies
    uint256 _claimableDai = Math.min(daiToClaim, _daiStreamed);

    // reduces debt accountance
    daiToClaim -= _claimableDai;
    _daiStreamed -= _claimableDai;

    if (_daiStreamed > 0) {
      // refill DAI credits on Keep3rJob
      IERC20(DAI).approve(keep3r, _daiStreamed);
      IKeep3rV2(keep3r).addTokenCreditsToJob(job, DAI, _daiStreamed);
    }

    // emits event to be tracked in DuneAnalytics dashboard & tracks DAI flow
    emit ClaimedDai(_claimableDai, _daiStreamed);
  }

  function _credits() internal view returns (uint256 _daiCredits) {
    _daiCredits = IKeep3rV2(keep3r).jobTokenCredits(job, DAI);
  }

  // Parameters

  /// @inheritdoc IMakerDAOBudgetManager
  function setKeep3rJob(address _keep3r, address _job) external override onlyGovernor {
    keep3r = _keep3r;
    job = _job;

    emit Keep3rJobSet(_keep3r, _job);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function setKeeper(address _keeper) external override onlyGovernor {
    keeper = _keeper;

    emit KeeperSet(_keeper);
  }

  /// @inheritdoc IMakerDAOBudgetManager
  function setNetworkPaymentAdapter(address _networkPaymentAdapter) external onlyGovernor {
    networkPaymentAdapter = _networkPaymentAdapter;
    emit NetworkPaymentAdapterSet(_networkPaymentAdapter);
  }

  // Modifiers

  modifier onlyKeeper() {
    if (msg.sender != keeper) revert IMakerDAOBudgetManager_OnlyKeeper();
    _;
  }
}