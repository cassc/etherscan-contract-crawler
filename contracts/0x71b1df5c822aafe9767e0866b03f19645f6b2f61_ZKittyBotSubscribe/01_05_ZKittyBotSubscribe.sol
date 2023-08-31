// SPDX-License-Identifier: Unlicense
import "./Interface/IOracle.sol";
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZKittyBotSubscribe {
    /*
     * @title Represents the shares of each recipient.
     */
    struct Share {
        uint256 recipientOne;
        uint256 recipientTwo;
    }

    /*
     * @title Details of each subscription tier.
     */

    struct Tier {
        uint256 subscriptionFee;
        uint256 walletLimit;
        string name;
        bool active;
    }

    /*
     * @title Details of a user's subscription.
     */

    struct Subscription {
        uint256 tier;
        uint256 expiry;
    }

    uint256 public constant PRECISION = 100_00;

    /*
     * @title Represents the status of a proposal.
     */

    enum ProposalStatus {
        Executed,
        Canceled,
        Pending
    }

    /*
     * @title Details of a proposal.
     */

    struct Proposal {
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32 descriptionHash;
        ProposalStatus status;
    }

    /*
     * @title Ensure the function is called by one of the recipients.
     */

    modifier onlyRecipients() {
        require(
            msg.sender == recipientOne || msg.sender == recipientTwo,
            "Not authorized"
        );
        _;
    }

    uint256 public zkittyTokenPriceInEth;
    uint256 public settingsChangeNonce;
    uint256 public minTokensForDiscount;
    uint256 public discount;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public changeConfirmations;
    Share public revSharePercent;
    address public recipientOne;
    address public recipientTwo;
    address public zkittyToken;
    address public UNISWAP_FACTORY_ADDRESS;
    address public WETH_ADDRESS;
    address public oracle;
    uint256 public currentTierCount;
    mapping(uint256 => Tier) public tiers;
    mapping(address => Subscription) public subscriptions;

    /*
     * @title Contract Constructor
     * @param _weth Address of WETH token.
     * @param _recipientOne Address of the first recipient.
     * @param _recipientTwo Address of the second recipient.
     * @param _revSharePercentOne Share percentage of the first recipient.
     * @param _revSharePercentTwo Share percentage of the second recipient.
     * @param _tierFees List of tier fees.
     * @param _names Names of tiers.
     * @param _tierWalletLimits List of tier wallet limits.
     * @dev Initialize the contract.
     */

    constructor(
        address _weth,
        address _recipientOne,
        address _recipientTwo,
        uint256 _revSharePercentOne,
        uint256 _revSharePercentTwo,
        uint256[] memory _tierFees,
        uint256[] memory _tierWalletLimits,
        string[] memory _names
    ) {
        WETH_ADDRESS = _weth;
        recipientOne = _recipientOne;
        recipientTwo = _recipientTwo;
        revSharePercent = Share(_revSharePercentOne, _revSharePercentTwo);

        for (uint256 i = 0; i < _tierFees.length; i++) {
            addTier(_tierFees[i], _tierWalletLimits[i], _names[i], true);
        }
    }

    /*
     * @title Set Discount Rate & Minimum Amount for Discount
     * @param newDiscount New discount rate.
     * @param newMinForDiscount New minimum amount.
     * @dev Sets the discount rate for users holding a certain minimum amount of tokens.
     */

    function setDiscount(
        uint256 _newDiscount,
        uint256 _newMinForDiscount
    ) external onlyRecipients {
        require(_newDiscount <= 10000, "Discount exceeds 100%");
        discount = _newDiscount;
        minTokensForDiscount = _newMinForDiscount;
        emit MinForDiscountUpdated(_newMinForDiscount);
        emit DiscountUpdated(_newDiscount);
    }

    function updateZKittyTokenPrice() public {
        IOracle(oracle).update();

        zkittyTokenPriceInEth = IOracle(oracle).consult(WETH_ADDRESS, 1 ether);
    }

    /*
     * @title Subscribe to a tier.
     * @param tierId ID of the tier to subscribe to.
     * @dev Allows a user to subscribe to a specific tier.
     */

    function subscribe(
        uint256 tierId,
        bool usingToken,
        address onBehalf,
        string calldata referredBY
    ) external payable {
        Tier memory tier = tiers[tierId];
        require(tier.active, "Tier is inactive");

        uint256 applicableSubscriptionFee = tier.subscriptionFee;

        if (zkittyToken != address(0)) {
            if (IOracle(oracle).timePassed()) {
                updateZKittyTokenPrice();
            }
            if (
                IERC20(zkittyToken).balanceOf(msg.sender) >=
                minTokensForDiscount
            ) {
                applicableSubscriptionFee =
                    (applicableSubscriptionFee * (PRECISION - discount)) /
                    PRECISION;
            }
        }

        if (usingToken && UNISWAP_FACTORY_ADDRESS != address(0)) {
            uint256 tokenAmountRequired = (zkittyTokenPriceInEth *
                applicableSubscriptionFee) / 1 ether;
            uint256 recipientOneShare = (tokenAmountRequired *
                revSharePercent.recipientOne) / PRECISION;
            uint256 recipientTwoShare = tokenAmountRequired - recipientOneShare;

            require(
                msg.value == 0 &&
                    IERC20(zkittyToken).transferFrom(
                        msg.sender,
                        recipientOne,
                        recipientOneShare
                    ) &&
                    IERC20(zkittyToken).transferFrom(
                        msg.sender,
                        recipientTwo,
                        recipientTwoShare
                    ),
                "Incorrect subscription fee in ZKittyToken or failed transfer"
            );
        } else {
            require(
                applicableSubscriptionFee > 0 &&
                    msg.value == applicableSubscriptionFee,
                "Incorrect subscription fee in ETH"
            );

            uint256 recipientOneShare = (msg.value *
                revSharePercent.recipientOne) / PRECISION;
            uint256 recipientTwoShare = msg.value - recipientOneShare;

            payable(recipientOne).transfer(recipientOneShare);
            payable(recipientTwo).transfer(recipientTwoShare);
        }
        if (onBehalf != address(0)) {
            subscriptions[onBehalf] = Subscription(
                tierId,
                block.timestamp + 30 days
            );
            emit UserSubscribed(msg.sender, tierId, usingToken, referredBY);
        } else {
            subscriptions[msg.sender] = Subscription(
                tierId,
                block.timestamp + 30 days
            );
            emit UserSubscribed(msg.sender, tierId, usingToken, referredBY);
        }
    }

    /**
     * @dev Sets the address for the UNISWAP_FACTORY_ADDRESS.
     * @param _uniswapFactoryAddress Address of the Uniswap factory.
     */
    function setUniswapFactoryAddress(
        address _uniswapFactoryAddress
    ) external onlyRecipients {
        require(_uniswapFactoryAddress != address(0), "Zero address provided");
        UNISWAP_FACTORY_ADDRESS = _uniswapFactoryAddress;
        emit UniswapFactoryAddressUpdated(_uniswapFactoryAddress);
    }

    /**
     * @dev Sets the address for the zkittyToken.
     * @param _zkittyToken Address of the ZKitty token.
     */
    function setZKittyToken(
        address _zkittyToken,
        address _Oracle
    ) external onlyRecipients {
        zkittyToken = _zkittyToken;
        oracle = _Oracle;
        emit ZKittyTokenAddressUpdated(_zkittyToken);
    }

    /**
     * @dev Allows one of the recipients to change their address.
     * @param newAddress The new address to set for the calling recipient.
     *
     * Emits either a RecipientOneChanged or RecipientTwoChanged event based on the sender.
     */
    function changeRecipient(address newAddress) public {
        if (msg.sender == recipientOne) {
            recipientOne = newAddress;
            emit RecipientOneChanged(newAddress);
        } else if (msg.sender == recipientTwo) {
            recipientTwo = newAddress;
            emit RecipientTwoChanged(newAddress);
        } else {
            revert("Not authorized");
        }
    }

    /**
     * @dev Adds a new subscription tier.
     * @param subscriptionFee The fee for the subscription tier.
     * @param walletLimit The maximum wallet limit for this tier.
     * @param name The name of the tier.
     * @param isActive Flag to indicate if the tier is active or not.
     */
    function addTier(
        uint256 subscriptionFee,
        uint256 walletLimit,
        string memory name,
        bool isActive
    ) public onlyRecipients {
        tiers[currentTierCount] = Tier({
            subscriptionFee: subscriptionFee,
            walletLimit: walletLimit,
            name: name,
            active: isActive
        });

        emit TierAdded(
            currentTierCount,
            subscriptionFee,
            walletLimit,
            isActive
        );

        currentTierCount++;
    }

    /**
     * @dev Deactivates an existing subscription tier.
     * @param tierId The ID of the tier to be deactivated.
     */

    function deactivateTier(uint256 tierId) public onlyRecipients {
        tiers[tierId].active = false;
        emit TierDeactivated(tierId);
    }

    /*
     *  @title Set Revenue Share Percentages
     *  @param Share percentage for recipient one
     *  @param Share percentage for recipient two
     *  @dev Sets the revenue share percentages for recipients
     */
    function setRevSharePercent(
        uint256 _revSharePercentOne,
        uint256 _revSharePercentTwo
    ) public {
        require(msg.sender == address(this), "Not authorized");
        require(
            _revSharePercentOne + _revSharePercentTwo == PRECISION,
            "The sum must be equal to 100%"
        );

        revSharePercent = Share(_revSharePercentOne, _revSharePercentTwo);

        emit RevSharePercentUpdated(_revSharePercentOne, _revSharePercentTwo);
    }

    /*
     * @title Create a new proposal for changing contract settings.
     * @param targets Addresses of the contracts/targets involved in the proposal.
     * @param values ETH values for the proposed actions.
     * @param calldatas Calldata for the proposed actions.
     * @param descriptionHash IPFS hash of the proposal description.
     * @dev Allows recipients to create a proposal for changes.
     */

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public onlyRecipients returns (uint256) {
        settingsChangeNonce++;

        for (uint256 i = 0; i < targets.length; i++) {
            require(targets[i] != address(0), "Zero address target");
        }

        proposals[settingsChangeNonce] = Proposal({
            targets: targets,
            values: values,
            calldatas: calldatas,
            descriptionHash: descriptionHash,
            status: ProposalStatus.Pending
        });

        emit ProposalCreated(settingsChangeNonce, descriptionHash);

        return settingsChangeNonce;
    }

    /*
     * @title Confirm a proposal.
     * @param proposalId ID of the proposal to be confirmed.
     * @dev Allows a recipient to confirm a proposal.
     */
    function confirmProposal(uint256 proposalId) public onlyRecipients {
        require(
            !changeConfirmations[proposalId][msg.sender],
            "Already confirmed"
        );
        require(
            proposals[proposalId].status == ProposalStatus.Pending,
            "Proposal not pending"
        );

        changeConfirmations[proposalId][msg.sender] = true;

        emit ProposalConfirmed(proposalId, msg.sender);
    }

    /*
     * @title Cancel a proposal.
     * @param proposalId ID of the proposal to be canceled.
     * @dev Allows a recipient to cancel a pending proposal.
     */
    function cancelProposal(uint256 proposalId) public onlyRecipients {
        require(
            proposals[proposalId].status == ProposalStatus.Pending,
            "Proposal not pending"
        );

        proposals[proposalId].status = ProposalStatus.Canceled;

        emit ProposalCanceled(proposalId);
    }

    /*
     * @title Execute a proposal.
     * @param proposalId ID of the proposal to be executed.
     * @dev Allows a recipient to execute a proposal if it's approved by both.
     */
    function executeProposal(uint256 proposalId) public onlyRecipients {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.status == ProposalStatus.Pending,
            "Proposal not pending"
        );
        require(
            changeConfirmations[proposalId][recipientOne] &&
                changeConfirmations[proposalId][recipientTwo],
            "Both recipients must confirm"
        );

        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.calldatas[i]);
            require(success, "Transaction execution failed");
        }

        proposal.status = ProposalStatus.Executed;

        emit ProposalExecuted(proposalId);
    }

    // Events
    event MinForDiscountUpdated(uint256 newMinForDiscount);
    event DiscountUpdated(uint256 newDiscount);
    event ZKittyTokenPriceUpdated(uint256 newPrice);
    event UserSubscribed(
        address indexed subscriber,
        uint256 tierId,
        bool usingToken,
        string referredBy
    );
    event RecipientOneChanged(address indexed newRecipient);
    event RecipientTwoChanged(address indexed newRecipient);
    event TierAdded(
        uint256 tierId,
        uint256 subscriptionFee,
        uint256 walletLimit,
        bool isActive
    );
    event TierDeactivated(uint256 tierId);
    event RevSharePercentUpdated(
        uint256 recipientOnePercent,
        uint256 recipientTwoPercent
    );
    event ProposalCreated(uint256 proposalId, bytes32 description);
    event ProposalConfirmed(uint256 proposalId, address indexed confirmer);
    event ProposalCanceled(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);
    event UniswapFactoryAddressUpdated(
        address indexed newUniswapFactoryAddress
    );
    event ZKittyTokenAddressUpdated(address indexed newZKittyToken);
}