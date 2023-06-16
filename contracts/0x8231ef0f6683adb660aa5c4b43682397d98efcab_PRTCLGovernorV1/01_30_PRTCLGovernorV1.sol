// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./PRTCLBaseGovernor.sol";
import "./PRTCLGovernorVotesQuorumFraction.sol";
import "./PRTCLGovernorCountingSimple.sol";
import "./PRTCLGovernorSettings.sol";
import "./PRTCLGovernorPreventLateQuorum.sol";
import "../interfaces/IPRTCLCollections721V1.sol";

/// @title Main governance contract for Particle Collection version 1
/// @author Particle Collection - valdi.eth
/// @notice Manages proposals and voting for collection buy proposals, as well as bid funds withrawal and proceeds redeeming.
/// @dev The PRTCLGovernorV1 contract contains the following privileged access for the following functions:
/// - The owner can update the late quorum vote extension through setLateQuorumVoteExtension(). 
/// - The owner can update the voting delay through setVotingDelay().
/// - The owner can update the voting period through setVotingPeriod().
/// - The owner can update the proposal threshold through setProposalThreshold().
/// - The owner can update the quorum requirement through updateQuorumNumerator().
/// - The owner can update the whitelist signer through setSigner().
/// - The owner can update the minimum price for any collection through setMinPrice().
/// - The owner can enable any currency for any collection through addAllowedCurrency().
/// - The owner can disable any currency for any collection through removeAllowedCurrency().
/// @custom:security-contact [email protected]
contract PRTCLGovernorV1 is PRTCLBaseGovernor, PRTCLGovernorPreventLateQuorum, PRTCLGovernorSettings, PRTCLGovernorCountingSimple, PRTCLGovernorVotesQuorumFraction, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @dev Emitted when a min price is updated.
     */
    event MinPriceUpdated(uint256 collectionId, address currencyAddress, uint256 minPrice);

    /**
     * @dev Emitted when the sale commission for a collection is updated.
     */
    event SaleCommissionUpdated(uint256 collectionId, uint256 minPrice);

    /**
     * @dev Emitted when the signer address is updated.
     */
    event SignerUpdated(address signer);

    /**
     * @dev Emitted when a currency is added to the allowed currencies list.
     */
    event AllowedCurrencyAdded(address currency);

    /**
     * @dev Emitted when a currency is removed from the allowed currencies list.
     */
    event AllowedCurrencyRemoved(address currency);

    /**
     * @dev Emitted when a bid is withdrawn.
     */
    event BidWithdrawn(uint256 proposalId, address proposer);

    /**
     * @dev Emitted when sale proceeds are redeemed by a user.
     */
    event SaleRedeemed(uint256 proposalId, address redeemer, uint256 amount);

    /**
     * @dev Emitted when a sale commission is redeemed.
     */
    event SaleCommissionRedeemed(uint256 proposalId);

    /**
     * @notice Used to validate whitelist addresses
     */
    address public whitelistSigner;

    uint256 private constant BID_PERCENTAGE_INCREASE = 5;

    struct Bid {
        // Bid amount in `currency` terms
        uint256 amount;
        // Proceeds per token in `currency` if sold for `amount`
        uint256 proceedsPerToken;
        bytes32 descriptionHash;
        address currency;
        address buyer;
        bool withdrawn;
        bool commissionRedeemed;
    }
    
    // Minimum price to be paid per collection in a given currency
    // allowed currency => collection id => min bid
    mapping(address => mapping(uint256 => uint256)) private _currencyMinBidPerCollection;
    
    // collection id => highest bid proposal id
    mapping(uint256 => uint256) private _highestBidProposalIdPerCollection;

    // proposal id => Bid details
    mapping(uint256 => Bid) private _bids;

    IPRTCLCollections721V1 public coreTokenData;

    /// Allowed currencies for buy proposals
    mapping(address => bool) private _allowedCurrencies;

    // collection id => sale commission %
    mapping(uint256 => uint256) private _saleCommissionPerCollection;

    modifier onlyNonZeroAddress(address _address) {
        require(_address != address(0), "Must input non-zero address");
        _;
    }

    constructor(IPRTCLVotes _tokenVotes, IPRTCLCollections721V1 _tokenData, address _signer)
        PRTCLBaseGovernor("PRTCLGovernorV1")
        PRTCLGovernorSettings(50400 /* 1 week */, 100800 /* 2 weeks */, 0)
        PRTCLGovernorVotes(_tokenVotes)
        PRTCLGovernorVotesQuorumFraction(15)
        PRTCLGovernorPreventLateQuorum(21600 /* 3 days */)
        ReentrancyGuard()
        onlyNonZeroAddress(address(_tokenVotes))
        onlyNonZeroAddress(address(_tokenData))
        onlyNonZeroAddress(_signer)
    {
        coreTokenData = _tokenData;
        whitelistSigner = _signer;
    }

    /**
     * @dev Returns true if bid is active. Reverts if non existing bid. Returns false otherwise.
     */
    function _isActiveBid(uint256 bidProposalId) internal view returns (bool) {
        ProposalState bidState = state(bidProposalId);
        return bidState == ProposalState.Active || bidState == ProposalState.Pending;
    }

    /**
     * @dev Function to validate a new buy proposal.
     * 
     * Specifies token and amount to be paid (ERC20 or ETH) for a collection `collectionId`.
     *
     * Returns true for a valid proposal, reverts otherwise.
     */
    function validateProposal(
        uint256 collectionId,
        address currencyAddress,
        uint256 price,
        bytes memory signature,
        uint256 signatureExpirationBlock
    ) public view returns (bool) {
        // Checks
        require(verifyAddressSigner(signature, signatureExpirationBlock), "Invalid signature");
        
        // Checks whether the collection is valid and can be sold
        require(coreTokenData.collectionCanBeSold(collectionId), "Collection cannot be sold");

        require(_allowedCurrencies[currencyAddress], "Currency not allowed");

        // Bid price has to be redeemable without dust for 1 token
        (,uint256 maxParticles,,,,,) = coreTokenData.collectionData(collectionId);
        uint256 commission = _saleCommissionPerCollection[collectionId];
        require((price - price * commission / 100) % maxParticles == 0, "Price minus commission must be divisible by maxParticles for the collection");

        uint256 minBidPrice = _currencyMinBidPerCollection[currencyAddress][collectionId];
        require(minBidPrice > 0 && price >= minBidPrice, "Minimum price not met or not yet set");
        
        uint256 lastHighestBidPId = _highestBidProposalIdPerCollection[collectionId];

        if (lastHighestBidPId != 0) {
            ProposalState prevBidState = state(lastHighestBidPId);
            require(prevBidState != ProposalState.Succeeded && prevBidState != ProposalState.Executed, "Existing succeeded or executed bid");

            Bid memory lastHighestBid = _bids[lastHighestBidPId];

            require(!_isActiveBid(lastHighestBidPId) || (currencyAddress == lastHighestBid.currency && price >= (lastHighestBid.amount * (BID_PERCENTAGE_INCREASE + 100) / 100)) , "Bid must match currently active bid currency and be at least 5% higher");
        }

        return true;
    }

    /**
     * @dev Function to create a new buy proposal.
     * 
     * Specifies token and amount to be paid (ERC20 or ETH) for a collection `collectionId`.
     *
     * Emits a {ProposalCreated} event.
     */
    function proposeBuy(
        uint256 collectionId,
        address currencyAddress,
        uint256 price,
        string memory description,
        bytes memory signature,
        uint256 signatureExpirationBlock
    ) public payable nonReentrant returns (uint256) {
        require(validateProposal(collectionId, currencyAddress, price, signature, signatureExpirationBlock));

        uint256 lastHighestBidPId = _highestBidProposalIdPerCollection[collectionId];

        // Effects
        if (lastHighestBidPId != 0 && _isActiveBid(lastHighestBidPId)) {
            _cancelProposal(lastHighestBidPId);
        }

        uint256 proposalId = _createBuyProposal(currencyAddress, price, collectionId, description);

        require(proposalId != 0, "Proposal id cannot be 0");

        _highestBidProposalIdPerCollection[collectionId] = proposalId;
        
        // Interactions
        // Check funds sent or approved
        if (currencyAddress != address(0)) {
            require(
                msg.value == 0,
                "Do not send ETH when the selected currency is not ETH"
            );
            require(
                IERC20(currencyAddress).allowance(msg.sender, address(this)) >=
                    price,
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(currencyAddress).balanceOf(msg.sender) >=
                    price,
                "Insufficient balance."
            );
            // Moves ERC-20 from bidder to this contract
            IERC20(currencyAddress).safeTransferFrom(
                msg.sender,
                address(this),
                price
            );
        } else {
            require(
                msg.value == price,
                "Must send exact bid value to propose"
            );
        }

        return proposalId;
    }

    /**
     * @dev Private function to create a new buy proposal.
     * Uses the buyProposalBuilder function to create the proposal.
     *
     * Emits a {ProposalCreated} event.
     */
    function _createBuyProposal(address currencyAddress, uint256 price, uint256 collectionId, string memory description) private returns(uint256) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _buyProposalBuilder(collectionId);
        // Bid price has to be redeemable for 1 token
        uint256 commission = _saleCommissionPerCollection[collectionId];
        uint256 proceedsPerToken = coreTokenData.proceeds(collectionId, price, commission, 1);
        require(proceedsPerToken > 0, "Bid price too low to be reedemable");

        uint256 proposalId = super.propose(collectionId, targets, values, calldatas, description);

        Bid storage bid = _bids[proposalId];
        bid.currency = currencyAddress;
        bid.amount = price;
        bid.proceedsPerToken = proceedsPerToken;
        bid.buyer = msg.sender;
        bid.descriptionHash = keccak256(bytes(description));

        return proposalId;
    }

    /**
     * @dev Function to execute a buy proposal.
     * 
     * Executes the buy proposal, marking the collection as sold and allowing holders to redeem their proceeds.
     *
     * Emits a {ProposalExecuted} event.
     */
    function executeBuy(uint256 collectionId) public {
        uint256 proposalId = _highestBidProposalIdPerCollection[collectionId];
        require(proposalId != 0, "No active bid");

        Bid memory bid = _bids[proposalId];

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _buyProposalBuilder(collectionId);

        super.execute(collectionId, bid.buyer, targets, values, calldatas, bid.descriptionHash);
    }

    /**
     * @dev Private function to create a new buy proposal target, value and calldata.
     */
    function _buyProposalBuilder(uint256 collectionId) private view 
        returns (
            address[] memory targets_,
            uint256[] memory values_,
            bytes[] memory calldatas_
        ) 
    {
        targets_ = new address[](1);
        targets_[0] = address(coreTokenData);

        values_ = new uint256[](1);
        values_[0] = 0;

        calldatas_ = new bytes[](1);
        calldatas_[0] = abi.encodeWithSelector(coreTokenData.markCollectionSold.selector, collectionId, msg.sender);
    }

    /**
     * @notice Returns the proposal id of the highest bid for a collection.
     * This function can return an expired highest bid for a collection, always check bid state as well.
     */
    function highestBid(uint256 collectionId) public view returns (uint256) {
        return _highestBidProposalIdPerCollection[collectionId];
    }

    /**
     * @dev Only buy proposals. Disable any other type of proposal.
     * Use proposeBuy instead.
     */
    function propose(
        uint256 /* collectionId */,
        address[] memory /* targets */,
        uint256[] memory /* values */,
        bytes[] memory /* calldatas */,
        string memory /* description */
    ) public pure override returns (uint256) {
        revert("Only buy proposals supported. Use proposeBuy instead.");
    }

    function execute(
        uint256 /* collectionId */,
        address /* proposer */,
        address[] memory /* targets */,
        uint256[] memory /* values */,
        bytes[] memory /* calldatas */,
        bytes32 /* descriptionHash */
    ) public payable override returns (uint256) {
        revert("Only buy proposals supported. Use executeBuy instead.");
    }

    /**
     * @dev See {IPRTCLBaseGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support, bytes memory signature, uint256 signatureExpirationBlock) public returns (uint256) {
        require(verifyAddressSigner(signature, signatureExpirationBlock), "Invalid whitelist signature");
        return _castVote(proposalId, msg.sender, support, "");
    }

    /**
     * @dev Only cast vote functions that include a whitelist signature.
     * Use castVote or castVoteWithReason that includes a signature instead.
     */
    function castVote(uint256 /* proposalId */, uint8 /* support */) public pure override returns (uint256) {
        revert("Function disabled. Use castVote functions that include a signature instead.");
    }

    /**
     * @dev See {IPRTCLBaseGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory signature,
        uint256 signatureExpirationBlock
    ) public returns (uint256) {
        require(verifyAddressSigner(signature, signatureExpirationBlock), "Invalid whitelist signature");
        return _castVote(proposalId, msg.sender, support, reason);
    }

    /**
     * @dev Only cast vote functions that include a whitelist signature.
     * Use castVote or castVoteWithReason that includes a signature instead.
     */
    function castVoteWithReason(
        uint256 /* proposalId */,
        uint8 /* support */,
        string calldata /* reason */
    ) public virtual override returns (uint256) {
        revert("Function disabled. Use castVote functions that include a signature instead.");
    }

    /**
     * @dev Update signer address.
     * Can only be called by owner.
     */
    function setSigner(address _signer) external onlyNonZeroAddress(_signer) onlyOwner {
        whitelistSigner = _signer;
        emit SignerUpdated(_signer);
    }

    /**
     * @notice Verify signature
     */
    function verifyAddressSigner(bytes memory _signature, uint256 _expirationBlock) public 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _expirationBlock));
        return block.number < _expirationBlock && whitelistSigner == messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @dev Update minimum price for collection.
     * 
     * Can only be called by owner.
     *
     * Emits a {MinPriceUpdated} event.
     */
    function setMinPrice(uint256 collectionId, address currencyAddress, uint256 price) external onlyOwner {
        require(_allowedCurrencies[currencyAddress], "Currency not allowed");

        // Bid price has to be redeemable without dust for 1 token
        (,uint256 maxParticles,,,,,) = coreTokenData.collectionData(collectionId);
        require(price > 0 && price % maxParticles == 0, "Price must be divisible by maxParticles for the collection and > 0");

        _currencyMinBidPerCollection[currencyAddress][collectionId] = price;

        emit MinPriceUpdated(collectionId, currencyAddress, price);
    }

    /**
     * @dev Get minimum price for a collection bid for collectionId.
     */
    function getMinPrice(uint256 collectionId, address currencyAddress) external view returns(uint256) {
        return _currencyMinBidPerCollection[currencyAddress][collectionId];
    }

    /**
     * @notice Set a sale commission (percentage) for collection with id collectionId
     */
    function setSaleCommission(uint256 collectionId, uint256 commission) external onlyOwner {
        require(commission <= 100, "Invalid commission percentage");
        (uint256 nParticles,,bool active,,,,) = coreTokenData.collectionData(collectionId);
        require(!active && nParticles == 0, "Comission can only be updated if no particles have been minted");

        _saleCommissionPerCollection[collectionId] = commission;

        emit SaleCommissionUpdated(collectionId, commission);
    }

    /**
     * @notice Get the sale commission (percentage) for collection with id collectionId
     */
    function getSaleCommission(uint256 collectionId) external view returns(uint256) {
        return _saleCommissionPerCollection[collectionId];
    }

    /**
     * @notice Set a currency as allowed to be used for bids
     */
    function addAllowedCurrency(address currency) external onlyOwner {
        _allowedCurrencies[currency] = true;
        emit AllowedCurrencyAdded(currency);
    }

    /**
     * @notice Remove a currency as allowed to be used for bids
     */
    function removeAllowedCurrency(address currency) external onlyOwner {
        _allowedCurrencies[currency] = false;
        emit AllowedCurrencyRemoved(currency);
    }

    /**
     * @notice Check if a currency is allowed to be used for bids
     */
    function isCurrencyAllowed(address currency) public view returns(bool) {
        return _allowedCurrencies[currency];
    }

    /**
     * @dev Owner can cancel a proposal in case of emergency.
     */
    function cancelProposal(uint256 proposalId) external onlyOwner {
        _cancelProposal(proposalId);
    }

    /**
     * @notice Lets the potential buyer withdraw funds if their bid failed
     */
    function withdraw(uint256 proposalId) external nonReentrant {
        Bid storage bid = _bids[proposalId];
        require(bid.buyer == msg.sender, "Only the bidder can withdraw funds");
        require(!bid.withdrawn, "Bid already withdrawn");

        ProposalState _state = state(proposalId);
        require(_state == ProposalState.Canceled || _state == ProposalState.Defeated || _state == ProposalState.Expired, "Invalid bid state for withdrawal");

        bid.withdrawn = true;

        _sendFunds(bid.buyer, bid.currency, bid.amount);

        emit BidWithdrawn(proposalId, bid.buyer);
    }

    /**
     * @notice Lets the owner redeem commission funds if the bid succeeded
     */
    function redeemCommission(uint256 proposalId) external nonReentrant onlyOwner {
        require(state(proposalId) == ProposalState.Executed, "Invalid bid state for commission redeeming");
        uint256 commission = _saleCommissionPerCollection[proposalCollection(proposalId)];
        require(commission > 0, "No commission to redeem");
        Bid storage bid = _bids[proposalId];
        require(!bid.commissionRedeemed, "Bid commission already redeemed");

        bid.commissionRedeemed = true;

        _sendFunds(owner(), bid.currency, bid.amount * commission / 100);

        emit SaleCommissionRedeemed(proposalId);
    }

    /**
     * @notice Lets the holder redeem funds for a successful sale, in exchange for burning tokensToRedeem tokens.
     */
    function redeem(uint256 proposalId, uint256 tokensToRedeem) public nonReentrant {
        require(tokensToRedeem > 0, "Must redeem at least 1 token");
        require(state(proposalId) == ProposalState.Executed, "Invalid bid state for redeeming");

        uint256 collectionId = proposalCollection(proposalId);

        // Check allowance for this contract for those tokens (or all)
        require(coreTokenData.isApprovedForAll(msg.sender, address(this)), "Contract not approved for all tokens");
        
        // Burn tokens. Checks collection balance
        coreTokenData.burn(msg.sender, collectionId, tokensToRedeem);
        
        // Send funds (ETH or ERC20)
        Bid memory bid = _bids[proposalId];
        uint256 commission = _saleCommissionPerCollection[collectionId];
        _sendFunds(msg.sender, bid.currency, coreTokenData.proceeds(collectionId, bid.amount, commission, tokensToRedeem));

        emit SaleRedeemed(proposalId, msg.sender, tokensToRedeem);
    }

    /**
     * @notice Get the bid data for a proposal
     */
    function bidData(uint256 proposalId) external view returns (Bid memory, ProposalState) {
        return (_bids[proposalId], state(proposalId));
    }

    /**
     * @dev Private function to send funds from this contract to `to`.
     * Used for withdrawing failed bids and redeeming successful ones.
     * @param to address representing the receiver of the funds
     * @param currency address for the used currency. 0x0 if Ether.
     * @param amount uint256 amount of `currency` to be sent
     */
    function _sendFunds(address to, address currency, uint256 amount) private {
        if (currency != address(0)) {
            IERC20(currency).safeTransfer(
                to,
                amount
            );
        } else {
            (bool sent, ) = to.call{value: amount}("");
            require(sent, "Failed to send Ether");
        }
    }

    // The following functions are overrides required by Solidity.

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal override(PRTCLBaseGovernor, PRTCLGovernorPreventLateQuorum) returns (uint256) {
        // Require balance > 0 for the affected collection
        require(_getVotes(account, proposalSnapshot(proposalId), proposalCollection(proposalId)) > 0, "No voting power");
        return PRTCLGovernorPreventLateQuorum._castVote(proposalId, account, support, reason);
    }

    function proposalThreshold()
        public
        view
        override(PRTCLBaseGovernor, PRTCLGovernorSettings)
        returns (uint256)
    {
        return PRTCLGovernorSettings.proposalThreshold();
    }

    function proposalDeadline(uint256 proposalId) public view virtual override(PRTCLBaseGovernor, PRTCLGovernorPreventLateQuorum) returns (uint256) {
        return PRTCLGovernorPreventLateQuorum.proposalDeadline(proposalId);
    }
}