// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {
  ChainlinkClient,
  Chainlink
} from '@chainlink/contracts/src/v0.7/ChainlinkClient.sol';

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IMerkleDistributorV1 } from '../../../interfaces/IMerkleDistributorV1.sol';
import { IRewardsOracle } from '../../../interfaces/IRewardsOracle.sol';
import { MD1Types } from '../lib/MD1Types.sol';

/**
 * @title MD1ChainlinkAdapter
 * @author dYdX
 *
 * @notice Chainlink oracle adapter to be read by the MerkleDistributorV1 contract.
 */
contract MD1ChainlinkAdapter is
  ChainlinkClient,
  IRewardsOracle
{
  using Chainlink for Chainlink.Request;
  using SafeERC20 for IERC20;

  // ============ Events ============

  /// @notice Emitted when the oracle data is updated.
  event OracleRootUpdated(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes ipfsCid
  );

  // ============ Constants ============

  /// @notice Address of the LINK token, used to pay for requests for oracle data.
  IERC20 public immutable CHAINLINK_TOKEN;

  /// @notice The address of the Merkle distributor contract, which determines rewards parameters.
  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;

  /// @notice The address to which the Chainlink request is sent.
  address public immutable ORACLE_CONTRACT;

  /// @notice The address which will call writeOracleData().
  address public immutable ORACLE_EXTERNAL_ADAPTER;

  /// @notice Chainlink ID for the job.
  bytes32 public immutable JOB_ID;

  // ============ Storage ============

  /// @dev Mapping from Chainlink request ID to the address that initated the request.
  mapping(bytes32 => address) internal _OPEN_REQUESTS_;

  /// @dev The latest oracle data.
  MD1Types.MerkleRoot internal _ORACLE_ROOT_;

  // ============ Constructor ============

  constructor(
    address chainlinkToken,
    address merkleDistributor,
    address oracleContract,
    address oracleExternalAdapter,
    bytes32 jobId
  ) {
    setChainlinkToken(chainlinkToken);
    CHAINLINK_TOKEN = IERC20(chainlinkToken);
    MERKLE_DISTRIBUTOR = IMerkleDistributorV1(merkleDistributor);
    ORACLE_CONTRACT = oracleContract;
    ORACLE_EXTERNAL_ADAPTER = oracleExternalAdapter;
    JOB_ID = jobId;
  }

  // ============ External Functions ============

  /**
   * @notice Helper function which transfers the fee and makes a request in a single transaction.
   *
   * @param  fee  The LINK amount to pay for the request.
   */
  function transferAndRequestOracleData(
    uint256 fee
  )
    external
  {
    CHAINLINK_TOKEN.safeTransferFrom(msg.sender, address(this), fee);
    requestOracleData(fee);
  }

  /**
   * @notice Called by the oracle external adapter to write data in response to a request.
   *
   *  This should be called before fulfillRequest() is called.
   *
   * @param  merkleRoot  Root hash of the Merkle tree for this epoch's rewards distribution.
   * @param  epoch       The epoch number for this rewards distribution.
   * @param  ipfsCid     The IPFS CID with the full Merkle tree data.
   */
  function writeOracleData(
    bytes32 merkleRoot,
    uint256 epoch,
    bytes calldata ipfsCid
  )
    external
  {
    require(
      msg.sender == ORACLE_EXTERNAL_ADAPTER,
      'MD1ChainlinkAdapter: Sender must be the oracle external adapter'
    );

    _ORACLE_ROOT_ = MD1Types.MerkleRoot({
      merkleRoot: merkleRoot,
      epoch: epoch,
      ipfsCid: ipfsCid
    });

    emit OracleRootUpdated(merkleRoot, epoch, ipfsCid);
  }

  /**
   * @notice Callback function for the oracle to record fulfillment of a request.
   */
  function fulfillRequest(
    bytes32 requestId
  )
    external
    recordChainlinkFulfillment(requestId)
  {
    delete _OPEN_REQUESTS_[requestId];
  }

  /**
   * @notice Allow the initiator of a request to cancel that request. The request must have expired.
   *
   *  The LINK fee for the request will be refunded back to this contract.
   */
  function cancelRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    external
  {
    require(
      msg.sender == _OPEN_REQUESTS_[requestId],
      'Request is not open or sender was not the initiator'
    );
    cancelChainlinkRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Read the latest data written by the oracle. This will be called by MerkleDistributorV1.
   *
   * @return  merkleRoot  The Merkle root for the next Merkle distributor update.
   * @return  epoch       The epoch number corresponding to the new Merkle root.
   * @return  ipfsCid     An IPFS CID pointing to the Merkle tree data.
   */
  function read()
    external
    override
    view
    returns (bytes32 merkleRoot, uint256 epoch, bytes memory ipfsCid)
  {
    merkleRoot = _ORACLE_ROOT_.merkleRoot;
    epoch = _ORACLE_ROOT_.epoch;
    ipfsCid = _ORACLE_ROOT_.ipfsCid;
  }

  /**
   * @notice If a request with the specified ID is open, returns the address that initiated it.
   *
   * @param  requestId  The Chainlink request ID.
   *
   * @return The address that initiated request, or the zero address if the request is not open.
   */
  function getOpenRequest(
    bytes32 requestId
  )
    external
    view
    returns (address)
  {
    return _OPEN_REQUESTS_[requestId];
  }

  // ============ Public Functions ============

  /**
   * @notice Request the latest oracle data.
   *
   *  In response to this request, if sufficient fee is provided, the Chainlink node is expected to
   *  call the writeOracleData() function, followed by the fulfillRequest() function.
   *
   *  Reverts if this contract does not have LINK to pay the fee.
   *
   *  If the fee is less than the amount agreed to by the external (off-chain) oracle adapter, then
   *  the external adapter may ignore the request.
   *
   * @param  fee  The LINK amount to pay for the request.
   */
  function requestOracleData(
    uint256 fee
  )
    public
  {
    // Read parameters from the Merkle distributor contract.
    string memory ipnsName = MERKLE_DISTRIBUTOR.getIpnsName();
    (
      uint256 marketMakerRewardsAmount,
      uint256 traderRewardsAmount,
      uint256 traderScoreAlpha
    ) = MERKLE_DISTRIBUTOR.getRewardsParameters();
    (, , bytes memory activeRootIpfsCid) = MERKLE_DISTRIBUTOR.getActiveRoot();
    uint256 newEpoch = MERKLE_DISTRIBUTOR.getNextRootEpoch();

    // Build the Chainlink request.
    Chainlink.Request memory req = buildChainlinkRequest(
      JOB_ID,
      address(this),
      this.fulfillRequest.selector
    );
    req.addBytes('callbackAddress', abi.encodePacked(address(this)));
    req.add('ipnsName', ipnsName);
    req.addUint('marketMakerRewardsAmount', marketMakerRewardsAmount);
    req.addUint('traderRewardsAmount', traderRewardsAmount);
    req.addUint('traderScoreAlpha', traderScoreAlpha);
    req.addBytes('activeRootIpfsCid', activeRootIpfsCid);
    req.addUint('newEpoch', newEpoch);

    // Send the Chainlink request.
    //
    // Note: This emits ChainlinkRequested(bytes32 indexed id);
    bytes32 requestId = sendChainlinkRequestTo(ORACLE_CONTRACT, req, fee);

    // Store the address that initiated the request. This address may cancel the request.
    _OPEN_REQUESTS_[requestId] = msg.sender;
  }
}