// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICHYPC.sol";
import "../interfaces/IHYPC.sol";
import "../interfaces/IHYPCSwap.sol";

/**
    @title  Crowd Funded HyPC Pool
    @author Barry Rowe, David Liendo
    @notice This contract allows users to pool their HyPC together to swap for a c_HyPC that can be used to back
            a license in the HyperCycle ecosystem. Because of the initial high volume of HyPC required for
            a swap, a pooling contract is useful for users wanting to have HyPC back their license. In this
            case, a license holder creates a proposal in the pool for 1 c_HyPC to back their license. They put up
            some backing HyPC as collateral for this loan, that will be used as interest payments for the users
            that provide HyPC for the proposal.

            As an example, a manager wants to borrow a c_HyPC for 18 months (78 weeks). The manager puts up 
            50,000 HyPC as collateral to act as interest for the user that deposit to this proposal. This means
            that the yearly APR for a depositor to the proposal will be: 50,000/524,288 * (26/39) = 0.063578288
            or roughly 6.35% (26 being the number of 2 week periods in a year, and 39 the number of 2 week
            periods in the proposal's term). The depositors can then claim this interest every period (2 weeks) 
            until the end of the proposal, at which point they can then withdraw and get back their initial 
            deposit. While the proposal is active, the c_HyPC is held by the pool contract itself, though the 
            manager that created the proposal can change the assignement of the swapped for c_HyPC.
*/

contract CrowdFundHYPCPool is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IHYPC;

    struct ContractProposal {
        address owner;
        uint256 term;
        uint256 interestRateAPR;
        uint256 deadline;
        string assignmentString;
        uint256 startTime;
        uint256 depositedAmount;
        uint256 backingFunds;
        uint256 status;
        uint256 tokenId;
    }

    struct UserDeposit {
        uint256 amount;
        uint256 proposalIndex;
        uint256 interestTime;
    }

    ContractProposal[] public proposals;
    mapping(address => UserDeposit[]) public userDeposits;

    /// @notice The HyPC ERC20 contract
    IHYPC public immutable HYPCToken;

    /// @notice The c_HyPC ERC721 contract
    ICHYPC public immutable HYPCNFT;

    /// @notice The HyPC/c_HyPC swapping contract
    IHYPCSwap public immutable SwapContract;

    //Timing is done PER WEEK, with the assumption that 1 year = 52 weeks
    uint256 private constant _2_WEEKS = 60 * 60 * 24 * 14;
    uint256 private constant _1_MONTH = 60 * 60 * 24 * 7 * 4; //4 weeks
    uint256 private constant _18_MONTHS = 60 * 60 * 24 * 7 * 78; //78 weeks
    uint256 private constant _24_MONTHS = 60 * 60 * 24 * 7 * 104; //104 weeks
    uint256 private constant _36_MONTHS = 60 * 60 * 24 * 7 * 156; //156 weeks

    uint256 private constant PENDING = 0;
    uint256 private constant STARTED = 1;
    uint256 private constant CANCELLED = 2;
    uint256 private constant COMPLETED = 3;

    uint256 private constant SIX_DECIMALS = 10**6;
    uint256 private constant PERIODS_PER_YEAR = 26;

    /// @notice The amount of HyPC needed to swap for each proposal. 
    uint256 public constant REQUESTED_AMOUNT = (2**19)*SIX_DECIMALS;

    /** 
        @notice The pool fee set by the pool owner for each created proposal. This is given in HyPC with
                6 decimals.
    */
    uint256 public poolFee = 0;

    //Events
    /// @dev   The event for when a manager creates a proposal.
    /// @param proposalIndex: the proposal that was created
    /// @param owner: the proposal creator's address
    /// @param assignmentString: the assignment to give to the c_HyPC token when the proposal is filled
    /// @param deadline: the deadline in blocktime seconds for this proposal to be filled.
    event ProposalCreated(
        uint256 indexed proposalIndex,
        address indexed owner,
        string assignmentString,
        uint256 deadline
    );

    /// @dev   The event for when a proposal is canceled by its creator
    /// @param proposalIndex: the proposal that was canceled
    /// @param owner: The creator's address
    event ProposalCanceled(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for when a proposal is finished by its creator
    /// @param proposalIndex: the proposal that was finished
    /// @param owner: the creator of the proposal
    event ProposalFinished(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for when a user submits a deposit towards a proposal
    /// @param proposalIndex: the proposal this deposit was made towards
    /// @param user: the user address that submitted this deposit
    /// @param amount: the amount of HyPC the user deposited to this proposal.
    event DepositCreated(
        uint256 indexed proposalIndex,
        address indexed user,
        uint256 amount
    );

    /// @dev   The event for when a user withdraws a previously created deposit
    /// @param depositIndex: the user's deposit index that was withdrawn
    /// @param user: the user's address
    /// @param amount: the amount of HyPC that was withdrawn.
    event WithdrawDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        uint256 amount
    );

    /// @dev   The event for when a user updates their deposit and gets interest.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param interestChange: the amount of HyPC interest given to this user for this update.
    event UpdateDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        uint256 interestChange
    );

    /// @dev   The event for when a user transfers their deposit to another user.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param to: the address that this deposit was sent to
    /// @param amount: the amount of HyPC in this deposit.
    event TransferDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /// @dev   The event for when a manager changes the assigned string of a proposal.
    /// @param proposalIndex: Index of the changed proposal.
    /// @param owner: the address of the proposal's owner.
    /// @param assignment: string that the proposal's assignment was changed to
    /// @param assignmentRef: String reference to the value of assignment 
    event AssignmentChanged(
        uint256 indexed proposalIndex,
        address indexed owner,
        string indexed assignment,
        string assignmentRef
    );

    //Modifiers
    /// @dev   Checks that this proposal index has been created.
    /// @param proposalIndex: the proposal index to check
    /// @param proposalsArray: the array that stores proposals.
    modifier validIndex(uint256 proposalIndex, ContractProposal[] storage proposalsArray) {
        require(proposalIndex < proposalsArray.length, "Invalid index.");
        _;
    }

    /// @dev   Checks that the transaction sender is the proposal owner
    /// @param proposalIndex: the proposal index to check ownership of.
    modifier proposalOwner(uint256 proposalIndex) {
        require(
            msg.sender == proposals[proposalIndex].owner,
            "Must be owner of proposal."
        );
        _;
    }

    /// @dev   Checks that the transaction sender's deposit index is valid.
    /// @param depositIndex: the sender's index to check.
    modifier validDeposit(uint256 depositIndex) {
        require(
            depositIndex < userDeposits[msg.sender].length,
            "Invalid deposit."
        );
        _;
    }

    /**
        @dev   The constructor takes in the HyPC token, c_HyPC token, and Swap contract addresses to populate
               the contract interfaces.
        @param hypcTokenAddress: the address for the HyPC token contract.
        @param hypcNFTAddress: the address for the CHyPC token contract.
        @param swapContractAddress: the address of the Swap contract.
    */
    constructor(
        address hypcTokenAddress,
        address hypcNFTAddress,
        address swapContractAddress
    ) {
        require(hypcTokenAddress != address(0), "Invalid Token.");
        require(hypcNFTAddress != address(0), "Invalid NFT.");
        require(swapContractAddress != address(0), "Invalid swap contract.");

        HYPCToken = IHYPC(hypcTokenAddress);
        HYPCNFT = ICHYPC(hypcNFTAddress);
        SwapContract = IHYPCSwap(swapContractAddress);
    }

    /// @notice Allows the owner of the pool to set the fee on proposal creation.
    /// @param  fee: the fee in HyPC to charge the proposal creator on creation.
    function setPoolFee(uint256 fee) external onlyOwner {
        poolFee = fee;
    }

    /**
        @notice Allows someone to create a proposal to have HyPC pooled together to swap for a c_HyPC token and
                have that token be given a specified assignment string. The creator specifies the term length
                for this proposal and supplies an amount of HyPC to act as interest for the depositors of the
                proposal.
        @param  termNum: either 0, 1, or 2, corresponding to 18 months, 24 months or 36 months respectively.
        @param  backingFunds: the amount of HyPC that the creator puts up to create the proposal, which acts
                as the interest to give to the depositors during the course of the proposal's term.
        @param  assignmentString: the string to be assigned to the c_HyPC swapped for when this proposal is
                filled and started.
        @param  deadline: the block timestamp that this proposal must be filled by in order to be started.
        @param  specifiedFee: The fee that the creator expects to pay.
        @dev    The specifiedFee parameter is used to prevent a pool owner from front-running a transaction
                to increase the poolFee after a creator has submitted a transaction.
        @dev    The interest rate calculation for the variable interestRateAPR is described in the contract's
                comment section. The only difference here is that there is an extra term in the numerator of
                SIX_DECIMALS since we can't have floating point numbers by default in solidity.
    */
    function createProposal(
        uint256 termNum,
        uint256 backingFunds,
        string memory assignmentString,
        uint256 deadline,
        uint256 specifiedFee
    ) external nonReentrant {
        require(
            termNum < 3,
            "termNum must be 0, 1, or 2 (18 months, 24 months, or 36 months)."
        );
        require(deadline > block.timestamp, "deadline must be in the future.");
        require(backingFunds > 0, "backingFunds must be positive.");
        require(
            bytes(assignmentString).length > 0,
            "assignmentString must be non-empty."
        );
        require(specifiedFee == poolFee, "Pool fee doesn't match.");

        uint256 termLength;
        if (termNum == 0) {
            termLength = _18_MONTHS;
        } else if (termNum == 1) {
            termLength = _24_MONTHS;
        } else {
            termLength = _36_MONTHS;
        }

        uint256 requiredFunds = 524288*SIX_DECIMALS;
        uint256 periods = termLength / _2_WEEKS;

        uint256 interestRateAPR = (backingFunds * PERIODS_PER_YEAR*SIX_DECIMALS) /
            (requiredFunds * periods);

        proposals.push(
            ContractProposal({
                owner: msg.sender,
                term: termLength,
                interestRateAPR: interestRateAPR,
                deadline: deadline,
                backingFunds: backingFunds,
                tokenId: 0,
                assignmentString: assignmentString,
                startTime: 0,
                status: PENDING,
                depositedAmount: 0
            })
        );

        HYPCToken.safeTransferFrom(msg.sender, address(this), backingFunds);
        HYPCToken.safeTransferFrom(msg.sender, owner(), poolFee);
        emit ProposalCreated(
            proposals.length,
            msg.sender,
            assignmentString,
            deadline
        );
    }

    /**
        @notice Lets a user creates a deposit for a pending proposal and submit the specified amount of 
                HyPC to back it.

        @param  proposalIndex: the proposal index that the user wants to back.
        @param  amount: the amount of HyPC the user wishes to deposit towards this proposal.
    */  
    function createDeposit(
        uint256 proposalIndex,
        uint256 amount
    ) external nonReentrant validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == PENDING, "Proposal not open.");
        require(
            block.timestamp < proposalData.deadline,
            "Proposal has expired."
        );
        require(amount > 0, "HYPC amount must be positive.");
        require(proposalData.depositedAmount + amount <= REQUESTED_AMOUNT,
                "Total HyPC deposit must not exceed the requested amount.");
 
        //Register deposit into proposal's array
        proposalData.depositedAmount += amount;

        //Register user's deposit
        userDeposits[msg.sender].push(
            UserDeposit({
                proposalIndex: proposalIndex,
                amount: amount,
                interestTime: 0
            })
        );
        HYPCToken.safeTransferFrom(msg.sender, address(this), amount);
        emit DepositCreated(proposalIndex, msg.sender, amount); 
    }

    /**
        @notice Lets a user that owns a deposit for a proposal to transfer the ownership of that
                deposit to another user. This is useful for liquidity since deposit can be tied up for
                fairly long periods of time.
        @param  depositIndex: the index of this users deposits array that they wish to transfer.
        @param  to: the address of the user to send this deposit to
        @dev    Deposit objects are deleted from the deposits array after being transferred. The deposit is 
                deleted and the last entry of the array is copied to that index so the array can be decreased
                in length, so we can avoid iterating through the array.
    */
    function transferDeposit(uint256 depositIndex, address to) external validDeposit(depositIndex) {
        require(to != msg.sender, "Can not transfer deposit to yourself.");

        //Copy deposit to the new address
        userDeposits[to].push(userDeposits[msg.sender][depositIndex]);
        uint256 amount = userDeposits[msg.sender][depositIndex].amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one.         
        if (
            userDeposits[msg.sender].length > 1 &&
            depositIndex < userDeposits[msg.sender].length - 1
        ) {
            delete userDeposits[msg.sender][depositIndex];
            userDeposits[msg.sender][depositIndex] = userDeposits[msg.sender][
                userDeposits[msg.sender].length - 1
            ];
        }
        userDeposits[msg.sender].pop();
        emit TransferDeposit(depositIndex, msg.sender, to, amount);
    }

    /**
        @notice Marks a proposal as started after it has received enough HyPC. At this point the proposal swaps
                the HyPC for c_HyPC and sets the timestamp for the length of the term and interest payment
                periods.
        @param  proposalIndex: the proposal to start.
    */
    function startProposal(
        uint256 proposalIndex
    ) external nonReentrant validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == PENDING, "Proposal not open.");
        require(
            block.timestamp < proposalData.deadline,
            "Proposal has expired."
        );
        require(proposalData.depositedAmount == REQUESTED_AMOUNT,
                "Proposal's requested HyPC must be filled in order to be started.");
 
        //Start the proposal now:
        proposalData.status = STARTED;
        proposalData.startTime = block.timestamp;
        uint256 tokenId = SwapContract.nfts(0);
        proposalData.tokenId = tokenId;

        //Swap for CHYPC
        //approve first...
        HYPCToken.safeApprove(address(SwapContract), 524288*SIX_DECIMALS);
        SwapContract.swap();
        //Assign CHYPC
        HYPCNFT.assign(tokenId, proposalData.assignmentString);
    }

    /**
        @notice If a proposal hasn't been started yet, then the creator can cancel it and get back their
                backing HyPC. Users who have deposited can then withdraw their deposits with the withdrawDeposit
                function given below.
        @param  proposalIndex: the proposal index to be cancel.
    */
    function cancelProposal(
        uint256 proposalIndex
    )
        external
        nonReentrant
        validIndex(proposalIndex, proposals)
        proposalOwner(proposalIndex)
    {
        require(
            proposals[proposalIndex].status == PENDING,
            "Proposal must be pending."
        );
        uint256 amount = proposals[proposalIndex].backingFunds;
        proposals[proposalIndex].backingFunds = 0;
        proposals[proposalIndex].status = CANCELLED;
        HYPCToken.safeTransfer(msg.sender, amount);

        emit ProposalCanceled(proposalIndex, msg.sender);
    }

    /**
        @notice Allows a user to withdraw their deposit from a proposal if that proposal has been canceled,
                passed its deadline, has not been started yet, or has come to term. For the case of a proposal
                that has come to term, then the user has to update their deposit to claim any remaining 
                interest first.
        @param  depositIndex: the index of this user's deposits array that they wish to withdraw.
    */
    function withdrawDeposit(uint256 depositIndex) external validDeposit(depositIndex) {
        uint256 proposalIndex = userDeposits[msg.sender][depositIndex]
            .proposalIndex;
        ContractProposal storage proposalData = proposals[proposalIndex];
        uint256 status = proposalData.status;

        require(
            status == PENDING || status == CANCELLED || status == COMPLETED,
            "Proposal must be pending, cancelled, or completed."
        );

        if (status == COMPLETED) {
            require(
                userDeposits[msg.sender][depositIndex].interestTime ==
                    proposalData.startTime + proposalData.term,
                "Deposit must be updated before it is withdrawn."
            );
        }

        proposalData.depositedAmount -= userDeposits[msg.sender][depositIndex]
            .amount;
        uint256 amount = userDeposits[msg.sender][depositIndex].amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one. 
        if (
            userDeposits[msg.sender].length > 1 &&
            depositIndex < userDeposits[msg.sender].length - 1
        ) {
            delete userDeposits[msg.sender][depositIndex];
            userDeposits[msg.sender][depositIndex] = userDeposits[msg.sender][
                userDeposits[msg.sender].length - 1
            ];
        }
        userDeposits[msg.sender].pop();

        HYPCToken.safeTransfer(msg.sender, amount);

        emit WithdrawDeposit(depositIndex, msg.sender, amount);
    }

    /**
        @notice Updates a user's deposit and sends them the accumulated interest from the amount of two week
                periods that have passed.
        @param  depositIndex: the index of this user's deposits array that they wish to update.
        @dev    The interestChange variable takes the user's deposit amount and multiplies it by the 
                proposal's calculated interestRateAPR to get the the yearly interest for this deposit with
                6 extra decimal places. It divides this by the number of periods in a year to get the interest
                from one two-week period, and multiplies it by the number of two week periods that have passed
                since this function was called to account for periods that were previously skipped. Finally,
                it divides the result by SIX_DECIMALS to remove the extra decimal places.
    */
    function updateDeposit(uint256 depositIndex) external nonReentrant validDeposit(depositIndex) {
        //get some interest from this deposit
        UserDeposit storage deposit = userDeposits[msg.sender][depositIndex];
        ContractProposal storage proposalData = proposals[
            deposit.proposalIndex
        ];

        require(
            proposalData.status == STARTED || proposalData.status == COMPLETED,
            "Proposal not started or completed."
        );

        if (deposit.interestTime == 0) {
            deposit.interestTime = proposalData.startTime;
        }

        uint256 endTime = block.timestamp;
        if (endTime > proposalData.startTime + proposalData.term) {
            endTime = proposalData.startTime + proposalData.term;
        }

        uint256 periods = (endTime - deposit.interestTime) / _2_WEEKS;
        require(
            periods > 0,
            "Not enough time has passed since last interest period."
        );

        uint256 interestChange = (deposit.amount * periods *
            proposalData.interestRateAPR) / (PERIODS_PER_YEAR * SIX_DECIMALS);

        //send this interestChange to the user and update both the backing funds and the interest time;
        deposit.interestTime += periods * _2_WEEKS;
 
        proposalData.backingFunds -= interestChange;
        HYPCToken.safeTransfer(msg.sender, interestChange);
        emit UpdateDeposit(depositIndex, msg.sender, interestChange);
    }

    /**
        @notice This completes the proposal after it has come to term, unassigns the c_HyPC and redeems it for
                HyPC, so it can be given back to the depositors.
        @param  proposalIndex: the proposal's index to complete.
    */
    function completeProposal(uint256 proposalIndex) 
        external 
        nonReentrant
        validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == STARTED, "Proposal must be in started state.");
 
        require (block.timestamp >= proposalData.startTime + proposalData.term,
            "Proposal must have reached the end of its term." );

        proposalData.status = COMPLETED;
        //unassign token and redeem it.
        HYPCNFT.assign(proposalData.tokenId, "");
        HYPCNFT.approve(address(SwapContract), proposalData.tokenId);
        SwapContract.redeem(proposalData.tokenId);
    }

    /**
        @notice This allows the creator of a completed proposal to claim any left over backingFunds interest
                after all users have withdrawn their deposits from this proposal.
        @param  proposalIndex: the proposal's index to be finished.
    */
    function finishProposal(
        uint256 proposalIndex
    )
        external 
        nonReentrant
        validIndex(proposalIndex, proposals)
        proposalOwner(proposalIndex)
    {
        require(
            proposals[proposalIndex].status == COMPLETED,
            "Proposal must be completed."
        );
        require(
            proposals[proposalIndex].depositedAmount == 0,
            "All users must be withdrawn from proposal."
        );
        require(
            proposals[proposalIndex].backingFunds > 0,
            "Some backing funds must be left over."
        );
        uint256 amountToSend = proposals[proposalIndex].backingFunds;
        proposals[proposalIndex].backingFunds = 0;

        HYPCToken.safeTransfer(
            msg.sender,
            amountToSend
        );

        emit ProposalFinished(proposalIndex, msg.sender);
    }
 
    /**
        @notice This allows a proposal creator to change the assignment of a c_HyPC token that was swapped for
                in a fulfilled proposal.
        @param  proposalIndex: the proposal's index to have its c_HyPC assignment changed.
    */
    function changeAssignment(uint256 proposalIndex, string memory assignmentString) external validIndex(proposalIndex, proposals) proposalOwner(proposalIndex) {
        require(proposals[proposalIndex].status == STARTED, "Proposal must be in started state.");
        uint256 tokenId = proposals[proposalIndex].tokenId;
        HYPCNFT.assign(tokenId, assignmentString);

        emit AssignmentChanged(proposalIndex, msg.sender, assignmentString, assignmentString);
    }

    //Getters
    /// @notice Returns a user's deposits
    /// @param  user: the user's address.
    /// @return The UserDeposits array for this user
    function getUserDeposits(address user) external view returns(UserDeposit[] memory) {
        return userDeposits[user];
    }

    /// @notice Returns a specific deposit for a user
    /// @param user: the user's address
    /// @param depositIndex: the user's deposit index to be returned.
    /// @return The UserDeposit object at the index for this user
    function getDeposit(address user, uint256 depositIndex) external view returns(UserDeposit memory) {
        return userDeposits[user][depositIndex];
    }

    /// @notice Returns the length of a user's deposits array
    /// @param  user: the user's address
    /// @return The length of the user deposits array.
    function getDepositsLength(address user) external view returns(uint256) {
        return userDeposits[user].length;
    }

    /// @notice Returns the proposal object at the given index.
    /// @param  proposalIndex: the proposal's index to be returned
    /// @return The ContractProposal object for the given index.
    function getProposal(uint256 proposalIndex) external view returns(ContractProposal memory) {
        return proposals[proposalIndex];
    }
    
    /// @notice Returns the total number of proposals submitted to the contract so far.
    /// @return The length of the contract proposals array.
    function getProposalsLength() external view returns(uint256) {
        return proposals.length;
    }
}