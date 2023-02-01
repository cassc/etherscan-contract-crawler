// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uma/core/contracts/oracle/implementation/Constants.sol";
import "@uma/core/contracts/oracle/interfaces/FinderInterface.sol";
import "@uma/core/contracts/common/implementation/AncillaryData.sol";
import "@uma/core/contracts/oracle/interfaces/StoreInterface.sol";
import "@uma/core/contracts/oracle/interfaces/OptimisticOracleV2Interface.sol";

contract Decentralist is Initializable, Ownable {
    using SafeERC20 for IERC20;

    event RevisionProposed(
        uint256 indexed revisionId,
        RevisionType revisionType,
        address[] proposedAddresses
    );
    event RevisionApproved(
        uint256 indexed revisionId,
        RevisionType revisionType
    );
    event RevisionRejected(
        uint256 indexed revisionId,
        RevisionType revisionType
    );
    event RevisionExecuted(
        uint256 indexed revisionId,
        RevisionType revisionType,
        address[] revisedAddresses
    );

    event RewardsSet(uint256 additionReward, uint256 removalReward);
    event LivenessSet(uint64 liveness);
    event BondSet(uint256 bondAmount);

    OptimisticOracleV2Interface public oracle;
    StoreInterface public store;

    FinderInterface public finder;
    bytes public fixedAncillaryData;
    string public title;
    uint256 public bondAmount;
    IERC20 public token;
    uint256 public additionReward;
    uint256 public removalReward;
    uint64 public liveness;
    uint64 public minimumLiveness;
    uint256 private revisionCounter;
    uint256 private finalFee;

    int256 internal constant PROPOSAL_YES_RESPONSE = int256(1e18);
    bytes32 internal constant IDENTIFIER = "DECENTRA-LIST";

    enum RevisionType {
        Remove,
        Add
    }

    enum Status {
        Invalid,
        Proposed,
        Approved,
        Rejected,
        Executed
    }

    struct Revision {
        address proposer;
        bytes32 addressesHash;
        RevisionType revisionType;
        Status status;
    }

    // maps hash of oracle revision data to revisionId
    mapping(bytes32 => uint256) private revisionIds;
    // maps revisionId to Revision
    mapping(uint256 => Revision) public revisions;
    // maps addresses to bool for inclusion on list
    mapping(address => bool) public onList;

    /**
     * @notice Initializes the contract.
     * @param _finder The address of UMA Finder contract. This is set in the DecentralistProxyFactory constructor.
     * @param _listCriteria Criteria for what addresses should be included on the list. Can be on-chain text or a link to IPFS.
     * @param _title Short title for the list.
     * @param _token The address of the token currency used for this contract. Must be on UMA's collateral whitelist.
     * @param _bondAmount Additional bond required, beyond the final fee.
     * @param _additionReward Reward per address successfully added to the list, paid by the contract to the proposer.
     * @param _removalReward Reward per address successfully removed from the list, paid by the contract to the proposer.
     * @param _liveness The period, in seconds, in which a proposal can be disputed.
     * @param _minimumLiveness The minimum allowable liveness period, in seconds.
     * @param _owner Owner of the contract can remove funds from the contract and adjust reward rates. Set to the 0 address to make the contract 'public'.
     */
    function initialize(
        address _finder,
        bytes memory _listCriteria,
        string memory _title,
        address _token,
        uint256 _bondAmount,
        uint256 _additionReward,
        uint256 _removalReward,
        uint64 _liveness,
        uint64 _minimumLiveness,
        address _owner
    ) external initializer {
        finder = FinderInterface(_finder);
        syncContracts();
        token = IERC20(_token);

        finalFee = store.computeFinalFee(address(token)).rawValue;

        require(
            _bondAmount >= store.computeFinalFee(address(token)).rawValue,
            "bond must be >= final fee"
        );
        require(
            _liveness >= _minimumLiveness,
            "liveness must be >= minimumLiveness"
        );
        require(_liveness < 5200 weeks, "liveness must be < 5200 weeks");

        // add boilerplate directions for verification to _listCriteria
        fixedAncillaryData = bytes.concat(
            "meet the List Criteria at the time of the price request? List Criteria: ",
            _listCriteria,
            ". Decentra-List Revision ID = "
        );
        title = _title;
        token = IERC20(_token);
        bondAmount = _bondAmount;
        additionReward = _additionReward;
        removalReward = _removalReward;
        liveness = _liveness;
        minimumLiveness = _minimumLiveness;
        _transferOwnership(_owner);

        revisionCounter = 1;
    }

    /**
     * @notice Proposes addresses to add or remove from the list.
     * @param _revisionType Enum indicatting if the proposed revision is adding or removing addresses. 0 = Remove, 1 = Add.
     * @param _addresses Array of addresses for the proposed revision.
     * @dev Caller must have approved this contract to spend the total bond amount of the contract's token before calling.
     */
    function proposeRevision(
        RevisionType _revisionType,
        address[] calldata _addresses
    ) external {
        require(
            _addresses.length < 100,
            "addresses array length must be < 100"
        );

        // prepare oracle request data
        bytes memory ancillaryData = "Do all Proposed Addresses ";
        if (_revisionType == RevisionType.Remove) {
            ancillaryData = bytes.concat(ancillaryData, "fail to ");
        }
        ancillaryData = bytes.concat(
            ancillaryData,
            fixedAncillaryData,
            AncillaryData.toUtf8BytesUint(revisionCounter),
            ". For directions to find the Proposed Addresses, see Implementation section of UMIP-169."
        );
        uint256 currentTime = block.timestamp;

        // prepare data for storage in Revision
        bytes32 oracleRequestHash = keccak256(
            abi.encodePacked(ancillaryData, currentTime)
        );
        bytes32 addressesHash = keccak256(abi.encodePacked(_addresses));

        // map oracleRequestHash to the current revisionCounter
        revisionIds[oracleRequestHash] = revisionCounter;

        // store Revision data in revisions mapping under the revisionCounter
        revisions[revisionCounter].proposer = msg.sender;
        revisions[revisionCounter].addressesHash = addressesHash;
        revisions[revisionCounter].revisionType = _revisionType;
        revisions[revisionCounter].status = Status.Proposed;

        // request data from oracle and configure request settings
        oracle.requestPrice(IDENTIFIER, currentTime, ancillaryData, token, 0);
        oracle.setCallbacks(
            IDENTIFIER,
            currentTime,
            ancillaryData,
            false,
            false,
            true
        );
        oracle.setCustomLiveness(
            IDENTIFIER,
            currentTime,
            ancillaryData,
            liveness
        );
        uint256 totalBond = oracle.setBond(
            IDENTIFIER,
            currentTime,
            ancillaryData,
            bondAmount
        );

        // transfer totalBond from proposer to contract for forwarding to Oracle
        token.safeTransferFrom(msg.sender, address(this), totalBond);

        // approve oracle to transfer total bond amount from list contract
        token.safeApprove(address(oracle), totalBond);

        // propose value to oracle
        oracle.proposePriceFor(
            msg.sender,
            address(this),
            IDENTIFIER,
            currentTime,
            ancillaryData,
            PROPOSAL_YES_RESPONSE
        );

        emit RevisionProposed(revisionCounter, _revisionType, _addresses);
        revisionCounter++;
    }

    /**
     * @notice Callback function called upon oracle data settlement to update the Revision status to Approved or Rejected.
     * @param timestamp Timestamp to identify the existing request.
     * @param ancillaryData Ancillary data of the data being requested.
     * @param value Value returned from the oracle.
     */
    function priceSettled(
        bytes32, /* identifier */
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 value
    ) external {
        // restrict function access to oracle
        require(
            msg.sender == address(oracle),
            "only oracle can call this function"
        );

        // get revisionId from oracleRequestHash
        bytes32 oracleRequestHash = keccak256(
            abi.encodePacked(ancillaryData, timestamp)
        );
        uint256 revisionId = revisionIds[oracleRequestHash];

        // set status to Approved or Rejected
        if (value == PROPOSAL_YES_RESPONSE) {
            revisions[revisionId].status = Status.Approved;
            emit RevisionApproved(
                revisionId,
                revisions[revisionId].revisionType
            );
        } else {
            revisions[revisionId].status = Status.Rejected;
            emit RevisionRejected(
                revisionId,
                revisions[revisionId].revisionType
            );
        }
    }

    /**
     * @notice Executes approved revisions by revising the list and paying out rewards to the proposer.
     * @param _revisionId ID of revision to be executed. If Revision submitted does not have status Approved, tx will revert.
     * @param _addresses Address array that matches the array logged in the RevisionProposed event for the provided _revisionId.
     */
    function executeRevision(uint256 _revisionId, address[] calldata _addresses)
        external
    {
        require(
            revisions[_revisionId].status == Status.Approved,
            "revisionId is not approved"
        );
        require(
            revisions[_revisionId].addressesHash ==
                keccak256(abi.encodePacked(_addresses)),
            "hash of addresses != revisionId's addressesHash"
        );

        // update Revision status
        revisions[_revisionId].status = Status.Executed;

        // set helper variables based on revisionType = Remove or Add
        bool setOnListTo;
        uint256 rewardRate;

        if (revisions[_revisionId].revisionType == RevisionType.Remove) {
            setOnListTo = false;
            rewardRate = removalReward;
        } else if (revisions[_revisionId].revisionType == RevisionType.Add) {
            setOnListTo = true;
            rewardRate = additionReward;
        }

        // add or remove address from the list, increment rewardCounter for calculating rewards and record revised Addresses
        uint256 rewardCounter;
        address[] memory revisedAddresses = new address[](_addresses.length);

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (onList[_addresses[i]] != setOnListTo) {
                onList[_addresses[i]] = setOnListTo;
                revisedAddresses[i] = _addresses[i];
                rewardCounter++;
            }
        }

        // calculate & pay out rewards to proposer
        uint256 reward = rewardRate * rewardCounter;
        if (reward > 0) {
            if (token.balanceOf(address(this)) < reward) {
                token.safeTransfer(
                    revisions[_revisionId].proposer,
                    token.balanceOf(address(this))
                );
            } else {
                token.safeTransfer(revisions[_revisionId].proposer, reward);
            }
        }
        emit RevisionExecuted(
            _revisionId,
            revisions[_revisionId].revisionType,
            revisedAddresses
        );
    }

    /**
     * @notice Allows owner to withdraw the default tokens from the contract.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to to send.
     */
    function withdraw(address recipient, uint256 amount) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    /**
     * @notice Allows owner to rescue tokens sent accidentally to the contract.
     * @param recipient The recipient of the tokens.
     * @param amount The amount of tokens to to send.
     * @param _token The contract address of the token to send.
     */
    function rescue(
        address recipient,
        uint256 amount,
        address _token
    ) external onlyOwner {
        IERC20(_token).safeTransfer(recipient, amount);
    }

    /**
     * @notice Sets the rewards for successful revisions.
     * @param _additionReward Reward to proposer per address successfully added to the list.
     * @param _removalReward Reward to proposer per address successfully removed from the list.
     */
    function setRewards(uint256 _additionReward, uint256 _removalReward)
        external
        onlyOwner
    {
        additionReward = _additionReward;
        removalReward = _removalReward;
        emit RewardsSet(_additionReward, _removalReward);
    }

    /**
     * @notice Sets the bond amount for revisions.
     * @param _bondAmount Amount of the bond token that will need to be paid for future proposals.
     */
    function setBond(uint256 _bondAmount) external onlyOwner {
        // Value of the bond required for proposing revisions, in addition to the final fee. Bond must be
        // greater or equal to the final fee
        require(
            _bondAmount >= store.computeFinalFee(address(token)).rawValue,
            "bond must be >= final fee"
        );

        bondAmount = _bondAmount;
        emit BondSet(_bondAmount);
    }

    /**
     * @notice Sets the liveness for future revisions. This is the amount of delay before a proposal is approved by
     * default.
     * @param _liveness Liveness to set in seconds.
     */
    function setLiveness(uint64 _liveness) external onlyOwner {
        require(
            _liveness >= minimumLiveness,
            "liveness must be >= minimumLiveness"
        );
        require(_liveness < 1 weeks, "liveness must be < than 1 week");
        liveness = _liveness;
        emit LivenessSet(_liveness);
    }

    /**
     * @notice This pulls in the most up-to-date Optimistic Oracle contract.
     * @dev If a new OptimisticOracle is added and this is run between a revision's introduction and execution, the
     * proposal will become unexecutable.
     */
    function syncContracts() public {
        oracle = OptimisticOracleV2Interface(
            finder.getImplementationAddress(OracleInterfaces.OptimisticOracleV2)
        );
        store = StoreInterface(
            finder.getImplementationAddress(OracleInterfaces.Store)
        );
    }
}