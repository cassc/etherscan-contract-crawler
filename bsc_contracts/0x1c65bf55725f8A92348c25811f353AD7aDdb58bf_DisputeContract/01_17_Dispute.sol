// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IterableArbiters.sol";

/// @title LPY Dispute Contract
/// @author Leisure Pay
/// @notice Dispute Contract for the Leisure Pay Ecosystem
contract DisputeContract is AccessControlEnumerable, ReentrancyGuard {
    using IterableArbiters for IterableArbiters.Map;
    using ECDSA for bytes32;
    using Strings for uint256;

    enum State {
        Open,
        Closed,
        Canceled
    }

    enum PARTIES {
        NULL,
        A,
        B
    }

    struct NFT {
        address _nft;
        uint256 _id;
    }

    struct Dispute {
        uint256 disputeIndex;
        NFT _nft;
        uint256 usdValue;
        uint256 tokenValue;
        address sideA;
        address sideB;
        bool hasClaim;
        uint256 voteCount;
        uint256 support;
        uint256 against;
        IterableArbiters.Map arbiters;
        bool claimed;
        PARTIES winner;
        State state;
    }

    struct DisputeView {
        uint256 disputeIndex;
        NFT _nft;
        uint256 usdValue;
        uint256 tokenValue;
        address sideA;
        address sideB;
        bool hasClaim;
        uint256 voteCount;
        uint256 support;
        uint256 against;
        IterableArbiters.UserVote[] arbiters;
        bool claimed;
        PARTIES winner;
        State state;
    }

    /// @notice Total number of disputes on chain
    /// @dev This includes cancelled disputes as well
    uint256 public numOfdisputes;

    /// @notice mapping to get dispute by ID where `uint256` key is the dispute ID
    mapping(uint256 => Dispute) private disputes;

    /// @notice Easily get a user's created disputes IDs
    mapping(address => uint256[]) public disputeIndexesAsSideA;

    /// @notice Easily get a user's attached disputes iDs
    mapping(address => uint256[]) public disputeIndexesAsSideB;

    /// @notice Address that points to the LPY contract - used for settling disputes
    IERC20 private lpy;

    // ROLES
    /// @notice SERVER_ROLE LPY Dispute Automation Server
    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");

    // CONSTRUCTOR

    /// @notice Default initializer for the dispute contract
    /// @param _lpy Address of the LPY contract
    /// @param _server Address of the Server
    constructor(
        IERC20 _lpy,
        address _server
    ) {
        require(address(_lpy) != address(0) && _server != address(0), "Addresses must be set");
        
        lpy = _lpy;
        _grantRole(SERVER_ROLE, _server);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // EVENTS
    /// @notice Event emitted when a dispute is created
    /// @param disputeIndex Created dispute ID
    /// @param _nft A struct containing the NFT address and its ID
    /// @param hasClaim Initial value to determine if dispute is claimable
    /// @param usdValue Dispute's USD at stake (1000000 == 1 USD; 6 decimals)
    /// @param sideA Creator of the dispute
    /// @param sideB Attached user to the dispute
    /// @param arbiters An array of users responsible for voting
    event DisputeCreated(
        uint256 indexed disputeIndex,
        NFT _nft,
        bool hasClaim,
        uint256 usdValue,
        address indexed sideA,
        address indexed sideB,
        address[] arbiters
    );

    /// @notice Event emitted when an arbiter votes on a dispute
    /// @param disputeIndex Dispute ID
    /// @param voter The Voter
    /// @param agree If user votes YES or NO to the dispute
    event DisputeVoted(
        uint256 indexed disputeIndex,
        address indexed voter,
        bool agree
    );

    /// @notice Event emitted when a dispute is closed
    /// @param disputeIndex Dispute ID
    /// @param usdValue Dispute's USD at stake (1000000 == 1 USD; 6 decimals)
    /// @param tokenValue LPY Token worth `usdValue`
    /// @param rate The present lpy rate per usd
    /// @param sideAVotes Total Votes `sideA` received
    /// @param sideBVotes Total Votes `sideB` received
    /// @param winner Winner of the dispute
    event DisputeClosed(
        uint256 indexed disputeIndex,
        uint256 usdValue,
        uint256 tokenValue,
        uint256 rate,
        uint256 sideAVotes,
        uint256 sideBVotes,
        PARTIES winner
    );

    /// @notice Event emitted when a dispute is caqncelled
    /// @param disputeIndex Dispute ID
    event DisputeCanceled(uint256 indexed disputeIndex);

    /// @notice Event emitted when a dispute fund is claimed
    /// @param disputeIndex Dispute ID
    /// @param tokenValue Amount of LPY claimed
    /// @param claimer Receiver of the funds
    event DisputeFundClaimed(
        uint256 indexed disputeIndex,
        uint256 tokenValue,
        address indexed claimer
    );

    /// @notice Event emitted when a sideA is modified
    /// @param disputeIndex Dispute ID
    /// @param oldSideA Previous SideA Address
    /// @param newSideA New SideA Address
    event SideAUpdated(
        uint256 indexed disputeIndex,
        address indexed oldSideA,
        address indexed newSideA
    );

    /// @notice Event emitted when a sideB is modified
    /// @param disputeIndex Dispute ID
    /// @param oldSideB Previous SideB Address
    /// @param newSideB New SideB Address
    event SideBUpdated(
        uint256 indexed disputeIndex,
        address indexed oldSideB,
        address indexed newSideB
    );

    /// @notice Event emitted when an arbiter is added to dispute
    /// @param disputeIndex Dispute ID
    /// @param arbiter Arbiter added
    event ArbiterAdded(
        uint256 indexed disputeIndex,
        address indexed arbiter
    );

    /// @notice Event emitted when an arbiter is removed to dispute
    /// @param disputeIndex Dispute ID
    /// @param arbiter Arbiter removed
    event ArbiterRemoved(
        uint256 indexed disputeIndex,
        address indexed arbiter
    );

    /// @notice Event emitted when hasClaim gets toggled
    /// @param disputeIndex Dispute ID
    /// @param value Value of hasClaim
    event ToggledHasClaim(
        uint256 indexed disputeIndex,
        bool value
    );

    // INTERNAL FUNCTIONS

    /// @notice Internal function that does the actual casting of vote, and emits `DisputeVoted` event
    /// @dev Can only be called by public/external functions that have done necessary checks <br/>1. dispute is opened<br/> 2. user must be an arbiter<br/>3. user should not have already voted
    /// @param disputeIndex ID of the dispute to vote on
    /// @param signer The user that's voting
    /// @param agree The vote's direction where `true==YES and false==NO`
    /// @return UserVote struct containing the vote details
    function _castVote(
        uint256 disputeIndex,
        address signer,
        bool agree
    ) internal returns (IterableArbiters.UserVote memory) {
        IterableArbiters.UserVote memory vote = IterableArbiters.UserVote(signer, agree, true);

        emit DisputeVoted(disputeIndex, signer, agree);

        return vote;
    }

    /// @notice Internal function that gets signer of a vote from a message `(id+msg)` and signature bytes
    /// @dev Concatenate the dispute ID and MSG to get the message to sign, and uses ECDSA to get the signer of the message
    /// @param id ID of the dispute the message was signed on
    /// @param _msg The original message signed
    /// @param _sig The signed message signature
    /// @return signer of the message, if valid, otherwise `0x0`
    /// @return vote direction of the signature, if valid, otherwise `false`
    function _getSignerAddress(uint256 id, string memory _msg, bytes memory _sig)
        internal
        pure
        returns (address, bool)
    {
        bytes32 voteA = keccak256(abi.encodePacked(id.toString(),"A"));
        bytes32 voteB = keccak256(abi.encodePacked(id.toString(),"B"));

        bytes32 hashMsg = keccak256(bytes(_msg));

        if(hashMsg != voteA && hashMsg != voteB) return (address(0), false);

        return (
            hashMsg.toEthSignedMessageHash().recover(_sig),
            hashMsg == voteA
        );


    }

    // PUBLIC AND EXTERNAL FUNCTIONS

    /// @notice Changes the `hasClaim` field of a dispute to the opposite
    /// @dev Function can only be called by a user with the `DEFAULT_ADMIN_ROLE` or `SERVER_ROLE` role
    /// @param disputeIndex the id or disputeIndex of the dispute in memory
    function toggleHasClaim(uint disputeIndex) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(SERVER_ROLE, msg.sender), "Only Admin or Server Allowed");

        Dispute storage dispute = disputes[disputeIndex];
        dispute.hasClaim = !dispute.hasClaim;
        emit ToggledHasClaim(dispute.disputeIndex, dispute.hasClaim);
    }

    /// @notice Adds a new dispute
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles, <br/>all fields can be changed post function call except the `_nftAddr` and `txID`
    /// @param _sideA Is the creator of the dispute
    /// @param _sideB Is the user the dispute is against
    /// @param _hasClaim A field to know if settlement occurs on chain
    /// @param _nftAddr The LPY NFT contract address
    /// @param txID The LPY NFT ID to confirm it's a valid transaction
    /// @param usdValue Dispute's USD at stake (1000000 == 1 USD; 6 decimals)
    /// @param _arbiters List of users that can vote on this dispute
    /// @return if creation was successful or not
    function createDisputeByServer(
        address _sideA,
        address _sideB,
        bool _hasClaim,
        address _nftAddr,
        uint256 txID,
        uint256 usdValue,
        address[] memory _arbiters
    ) external onlyRole(SERVER_ROLE) returns (bool) {
        require(_sideA != _sideB, "sideA == sideB");
        require(_sideA != address(0), "sideA has to be set");
        require(_nftAddr != address(0), "NFTAddr has to be set");
        require(usdValue > 0, "usdValue has to be > 0");

        if(_sideB == address(0)){
            _sideB = address(this);
        }

        uint256 disputeIndex = numOfdisputes++;

        Dispute storage dispute = disputes[disputeIndex];

        // Non altering call to confirm tokenID is already minted
        IERC721Extended(_nftAddr).tokenURI(txID);

        dispute.disputeIndex = disputeIndex;
        dispute._nft = NFT(_nftAddr, txID);
        dispute.sideA = _sideA;
        dispute.sideB = _sideB;
        dispute.hasClaim = _hasClaim;

        for (uint256 i = 0; i < _arbiters.length; i++) {
            require(_arbiters[i] != address(0), "Arbiter is not valid");
            require(!dispute.arbiters.contains(_arbiters[i]), "Duplicate Keys");
            dispute.arbiters.set(_arbiters[i], IterableArbiters.UserVote(_arbiters[i], false, false));
        }
        dispute.state = State.Open;
        dispute.usdValue = usdValue;

        disputeIndexesAsSideA[_sideA].push(disputeIndex);
        disputeIndexesAsSideB[_sideB].push(disputeIndex);

        emit DisputeCreated(
            disputeIndex,
            dispute._nft,
            dispute.hasClaim,
            usdValue,
            _sideA,
            _sideB,
            dispute.arbiters.keysAsArray()
        );

        return true;
    }

    /// @notice Function to let a user directly vote on a dispute
    /// @dev  Can only be called if; <br/> 1. dispute state is `OPEN` <br/> 2. the user is an arbiter of that very dispute<br/>3. the user has not already voted on that dispute<br/>This function calls @_castVote
    /// @param disputeIndex ID of the dispute to vote on
    /// @param _agree The vote's direction where `true==support for sideA and false==support for sideB`
    /// @return if vote was successful or not
    function castVote(uint256 disputeIndex, bool _agree) external returns (bool) {
        Dispute storage dispute = disputes[disputeIndex];

        require(dispute.state == State.Open, "dispute is closed");
        require(dispute.arbiters.contains(msg.sender), "Not an arbiter");
        require(!dispute.arbiters.get(msg.sender).voted, "Already Voted");

        // cast vote and emit an event
        IterableArbiters.UserVote memory vote = _castVote(disputeIndex, msg.sender, _agree);

        dispute.voteCount += 1;
        dispute.support += _agree ? 1 : 0;
        dispute.against += _agree ? 0 : 1;

        dispute.arbiters.set(msg.sender, vote); // Save vote casted

        return true;
    }

    /// @notice Function to render a dispute cancelled and not interactable anymore
    /// @dev  Can only be called if dispute state is `OPEN` and the user the `SERVER_ROLE` role and it emits a `DisputeCanceled` event
    /// @param disputeIndex ID of the dispute to cancel
    function cancelDispute(uint256 disputeIndex) external onlyRole(SERVER_ROLE){
        Dispute storage dispute = disputes[disputeIndex];

        require(dispute.state == State.Open, "dispute is closed");
        dispute.state = State.Canceled;

        emit DisputeCanceled(disputeIndex);
    }

    /// @notice Submits signed votes to contract
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles<br/>This function calls @_castVote
    /// @param disputeIndex ID of the dispute
    /// @param _sigs _sigs is an array of signatures`
    /// @param _msgs _msgs is an array of the raw messages that was signed`
    /// @return if vote casting was successful
    function castVotesWithSignatures(
        uint256 disputeIndex,
        bytes[] memory _sigs,
        string[] memory _msgs
    ) external onlyRole(SERVER_ROLE) returns (bool) {
        Dispute storage dispute = disputes[disputeIndex];

        require(_sigs.length == _msgs.length, "sigs and msg != same length");
        require(dispute.state == State.Open, "dispute is closed");
        bool voteCasted;
        for (uint256 i = 0; i < _sigs.length; i++) {
            (address signer, bool agree) = _getSignerAddress(
                disputeIndex,
                _msgs[i],
                _sigs[i]
            );

            if (!dispute.arbiters.contains(signer)) {
                continue;
            }
            require(!dispute.arbiters.get(signer).voted, "Already Voted");

            // cast vote and emit an event
            IterableArbiters.UserVote memory vote = _castVote(disputeIndex, signer, agree);

            dispute.voteCount += 1;
            dispute.support += agree ? 1 : 0;
            dispute.against += agree ? 0 : 1;

            dispute.arbiters.set(signer, vote); // Save vote casted
            if(!voteCasted)
                voteCasted = true;
        }
        require(voteCasted, "No votes to cast");
        return true;
    }

    /// @notice Finalizes and closes dispute
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles<br/>The server has the final say by passing `sideAWins` to `true|false`, and emits a `DisputeClosed` event
    /// @param disputeIndex ID of the dispute
    /// @param sideAWins Final say of the server on the dispute votes
    /// @param ratio This is the rate of LPY per USD
    /// @return if vote finalize was succesful
    function finalizeDispute(
        uint256 disputeIndex,
        bool sideAWins,
        uint256 ratio // tokens per dollar
    ) external onlyRole(SERVER_ROLE) returns (bool) {
        require(ratio > 0, "Ratio has to be > 0");
        
        Dispute storage dispute = disputes[disputeIndex];
        require(dispute.state == State.Open, "dispute is closed");
        require(dispute.voteCount == dispute.arbiters.size(), "Votes not completed");

        dispute.tokenValue = (dispute.usdValue * ratio) / 1e6; // divide by 1e6 (6 decimals)

        dispute.winner = sideAWins ? PARTIES.A : PARTIES.B;

        dispute.state = State.Closed;

        if(!dispute.hasClaim)
            dispute.claimed = true;

        emit DisputeClosed(
            disputeIndex,
            dispute.usdValue,
            dispute.tokenValue,
            ratio,
            dispute.support,
            dispute.against,
            dispute.winner
        );

        return true;
    }

    /// @notice Adds a user as an arbiter to a dispute
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles
    /// @param disputeIndex ID of the dispute
    /// @param _arbiter User to add to list of dispute arbiters
    function addArbiter(uint256 disputeIndex, address _arbiter)
        external
        onlyRole(SERVER_ROLE)
    {
        Dispute storage _dispute = disputes[disputeIndex];

        require(_dispute.state == State.Open, "dispute is closed");
        require(!_dispute.arbiters.contains(_arbiter), "Already an Arbiter");

        _dispute.arbiters.set(_arbiter, IterableArbiters.UserVote(_arbiter, false, false));
        emit ArbiterAdded(_dispute.disputeIndex, _arbiter);
    }

    /// @notice Removes a user as an arbiter to a dispute
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles
    /// @param disputeIndex ID of the dispute
    /// @param _arbiter User to remove from list of dispute arbiters
    function removeArbiter(uint256 disputeIndex, address _arbiter)
        external
        onlyRole(SERVER_ROLE)
    {
        Dispute storage _dispute = disputes[disputeIndex];
        
        require(_dispute.state == State.Open, "dispute is closed");
        require(_dispute.arbiters.contains(_arbiter), "Not an arbiter");


        IterableArbiters.UserVote memory vote = _dispute.arbiters.get(_arbiter);

        if (vote.voted) {
            _dispute.support -= vote.agree ? 1 : 0;
            _dispute.against -= vote.agree ? 0 : 1;
            _dispute.voteCount -= 1;
        }
        _dispute.arbiters.remove(_arbiter);
        emit ArbiterRemoved(_dispute.disputeIndex, _arbiter);
    }

    /// @notice Change sideA address (in the unlikely case of an error)
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles
    /// @param disputeIndex ID of the dispute
    /// @param _sideA The address of the new sideA
    function updateSideA(uint256 disputeIndex, address _sideA)
        external
        onlyRole(SERVER_ROLE)
    {
        // Server would be able to update incase owner loses key
        Dispute storage _dispute = disputes[disputeIndex];
        emit SideAUpdated(disputeIndex, _dispute.sideA, _sideA);
        _dispute.sideA = _sideA;
    }

    /// @notice Change sideB address (in the unlikely case of an error)
    /// @dev Function can only be called by a user with the `SERVER_ROLE` roles
    /// @param disputeIndex ID of the dispute
    /// @param _sideB The address of the new sideB
    function updateSideB(uint256 disputeIndex, address _sideB)
        external
        onlyRole(SERVER_ROLE)
    {
        // Server would be able to update incase owner loses key
        Dispute storage _dispute = disputes[disputeIndex];
        emit SideBUpdated(disputeIndex, _dispute.sideB, _sideB);
        _dispute.sideB = _sideB;
    }

    /// @notice Function for user to claim the tokens
    /// @dev Function can only be called by just a user with the `SERVER_ROLE` and the winner of the dispute, emits a `DisputeFundClaimed` event
    /// @param disputeIndex ID of the dispute
    function claim(uint256 disputeIndex) external nonReentrant returns (bool) {
        Dispute storage _dispute = disputes[disputeIndex];
        require(_dispute.state == State.Closed, "dispute is not closed");
        require(_dispute.claimed != true, "Already Claimed");

        if (_dispute.winner == PARTIES.A) {
            require(
                hasRole(SERVER_ROLE, msg.sender) ||
                    msg.sender == _dispute.sideA,
                "Only SideA or Server can claim"
            );
        } else {
            require(
                hasRole(SERVER_ROLE, msg.sender) ||
                    msg.sender == _dispute.sideB,
                "Only SideB or Server can claim"
            );
        }

        _dispute.claimed = true;

        emit DisputeFundClaimed(_dispute.disputeIndex, _dispute.tokenValue, msg.sender);
        uint cBal = lpy.balanceOf(address(this));
        require(cBal >= _dispute.tokenValue, "transfer failed: insufficient balance");

        lpy.transfer(msg.sender, _dispute.tokenValue);
        return true;
    }

    // READ ONLY FUNCTIONS

    /// @notice Internal function to convert type @Dispute to type @DisputeView
    /// @param disputeIndex ID of the dispute
    /// @return DisputeView object
    function serializeDispute(uint disputeIndex) internal view returns (DisputeView memory) {
        Dispute storage _dispute = disputes[disputeIndex];

        return DisputeView(
            _dispute.disputeIndex,
            _dispute._nft,
            _dispute.usdValue,
            _dispute.tokenValue,
            _dispute.sideA,
            _dispute.sideB,
            _dispute.hasClaim,
            _dispute.voteCount,
            _dispute.support,
            _dispute.against,
            _dispute.arbiters.asArray(),
            _dispute.claimed,
            _dispute.winner,
            _dispute.state
        );
    }

    /// @notice Get all Disputes in the contract
    /// @return Array of DisputeView object
    function getAllDisputes()
        external
        view
        returns (DisputeView[] memory)
    {
        uint256 count = numOfdisputes;
        DisputeView[] memory _disputes = new DisputeView[](count);

        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            _disputes[i] = dispute;
        }

        return _disputes;
    }

    /// @notice Get all Open Dispute
    /// @return Array of DisputeView object
    function getAllOpenDisputes()
        external
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Open) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Open) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Closed Dispute
    /// @return Array of DisputeView object
    function getAllClosedDisputes()
        external
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Closed) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Closed) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Canceled Dispute
    /// @return Array of DisputeView object
    function getAllCanceledDisputes()
        external
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Canceled) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < numOfdisputes; i++) {
            DisputeView memory dispute = serializeDispute(i);
            if (dispute.state == State.Canceled) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }
    /// @notice Get a specific dispute based on `disputeIndex`
    /// @param disputeIndex ID of the dispute
    /// @return _dispute DisputeView object
    function getDisputeByIndex(uint256 disputeIndex)
        external
        view
        returns (DisputeView memory _dispute)
    {
        _dispute = serializeDispute(disputeIndex);
    }

    /// @notice Get all Open Dispute where sideA is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideAOpenDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Open) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Open) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Closed Dispute where sideA is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideAClosedDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Closed) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Closed) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Canceled Dispute where sideA is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideACanceledDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Canceled) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideA[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideA[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Canceled) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Open Dispute where sideB is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideBOpenDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Open) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Open) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Closed Dispute where sideB is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideBClosedDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Closed) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Closed) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Canceled Dispute where sideB is `_user`
    /// @param _user User to get disputes for
    /// @return Array of DisputeView object
    function getSideBCanceledDisputes(address _user)
        public
        view
        returns (DisputeView[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Canceled) {
                count++;
            }
        }

        DisputeView[] memory _disputes = new DisputeView[](count);

        uint256 outterIndex;
        for (uint256 i = 0; i < disputeIndexesAsSideB[_user].length; i++) {
            uint256 disputeIndex = disputeIndexesAsSideB[_user][i];
            DisputeView memory dispute = serializeDispute(disputeIndex);
            if (dispute.state == State.Canceled) {
                _disputes[outterIndex] = dispute;
                outterIndex++;
            }
        }

        return _disputes;
    }

    /// @notice Get all Open Dispute where sideA is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyOpenDisputesAsSideA()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideAOpenDisputes(msg.sender);
    }

    /// @notice Get all Close Dispute where sideA is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyClosedDisputesAsSideA()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideAClosedDisputes(msg.sender);
    }

    /// @notice Get all Canceled Dispute where sideA is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyCanceledDisputesAsSideA()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideAClosedDisputes(msg.sender);
    }

    /// @notice Get all Open Dispute where sideB is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyOpenDisputesAsSideB()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideBOpenDisputes(msg.sender);
    }

    /// @notice Get all Closed Dispute where sideB is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyClosedDisputesAsSideB()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideBClosedDisputes(msg.sender);
    }

    /// @notice Get all Canceled Dispute where sideB is the one calling the function
    /// @return _disputes Array of DisputeView object
    function getMyCanceledDisputesAsSideB()
        external
        view
        returns (DisputeView[] memory _disputes)
    {
        _disputes = getSideBCanceledDisputes(msg.sender);
    }
}