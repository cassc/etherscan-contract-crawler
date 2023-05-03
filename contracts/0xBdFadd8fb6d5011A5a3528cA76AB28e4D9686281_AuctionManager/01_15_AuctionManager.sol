// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IAuctionManager.sol";
import "./interfaces/INodeOperatorManager.sol";
import "./interfaces/IProtocolRevenueManager.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract AuctionManager is
    Initializable,
    IAuctionManager,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    uint128 public whitelistBidAmount;
    uint64 public minBidAmount;
    uint64 public maxBidAmount;
    uint256 public numberOfBids;
    uint256 public numberOfActiveBids;

    INodeOperatorManager public nodeOperatorManagerInterface;
    IProtocolRevenueManager public protocolRevenueManager;

    address public stakingManagerContractAddress;
    bool public whitelistEnabled;

    mapping(uint256 => Bid) public bids;

    uint256[43] public __gap;

    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event BidCreated(
        address indexed bidder,
        uint256 amountPerBid,
        uint256[] bidIdArray,
        uint64[] ipfsIndexArray
    );
    event BidCancelled(uint256 indexed bidId);
    event BidReEnteredAuction(uint256 indexed bidId);
    event Received(address indexed sender, uint256 value);
    event WhitelistDisabled(bool whitelistStatus);
    event WhitelistEnabled(bool whitelistStatus);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice initialize to set variables on deployment
    function initialize(
        address _nodeOperatorManagerContract
    ) external initializer {
        require(_nodeOperatorManagerContract != address(0), "No Zero Addresses");
        
        whitelistBidAmount = 0.001 ether;
        minBidAmount = 0.01 ether;
        maxBidAmount = 5 ether;
        numberOfBids = 1;
        whitelistEnabled = true;

        nodeOperatorManagerInterface = INodeOperatorManager(
            _nodeOperatorManagerContract
        );

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Creates bid(s) for the right to run a validator node when ETH is deposited
    /// @param _bidSize the number of bids that the node operator would like to create
    /// @param _bidAmountPerBid the ether value of each bid that is created
    /// @return bidIdArray array of the bidIDs that were created
    function createBid(
        uint256 _bidSize,
        uint256 _bidAmountPerBid
    ) external payable whenNotPaused nonReentrant returns (uint256[] memory) {
        require(_bidSize > 0, "Bid size is too small");
        if (whitelistEnabled) {
            require(
                nodeOperatorManagerInterface.isWhitelisted(msg.sender),
                "Only whitelisted addresses"
            );
            require(
                msg.value == _bidSize * _bidAmountPerBid &&
                    _bidAmountPerBid >= whitelistBidAmount &&
                    _bidAmountPerBid <= maxBidAmount,
                "Incorrect bid value"
            );
        } else {
            if (
                nodeOperatorManagerInterface.isWhitelisted(msg.sender)
            ) {
                require(
                    msg.value == _bidSize * _bidAmountPerBid &&
                        _bidAmountPerBid >= whitelistBidAmount &&
                        _bidAmountPerBid <= maxBidAmount,
                    "Incorrect bid value"
                );
            } else {
                require(
                    msg.value == _bidSize * _bidAmountPerBid &&
                        _bidAmountPerBid >= minBidAmount &&
                        _bidAmountPerBid <= maxBidAmount,
                    "Incorrect bid value"
                );
            }
        }

        uint64 keysRemaining = nodeOperatorManagerInterface.getNumKeysRemaining(
            msg.sender
        );
        require(_bidSize <= keysRemaining, "Insufficient public keys");

        uint256[] memory bidIdArray = new uint256[](_bidSize);
        uint64[] memory ipfsIndexArray = new uint64[](_bidSize);

        for (uint256 i = 0; i < _bidSize; i++) {
            uint64 ipfsIndex = nodeOperatorManagerInterface.fetchNextKeyIndex(
                msg.sender
            );

            uint256 bidId = numberOfBids;

            bidIdArray[i] = bidId;
            ipfsIndexArray[i] = ipfsIndex;

            //Creates a bid object for storage and lookup in future
            bids[bidId] = Bid({
                amount: _bidAmountPerBid,
                bidderPubKeyIndex: ipfsIndex,
                bidderAddress: msg.sender,
                isActive: true
            });

            numberOfBids++;
        }

        numberOfActiveBids += _bidSize;
        emit BidCreated(
            msg.sender,
            _bidAmountPerBid,
            bidIdArray,
            ipfsIndexArray
        );
        return bidIdArray;
    }

    function cancelBidBatch(uint256[] calldata _bidIds) external whenNotPaused {
        for (uint256 i = 0; i < _bidIds.length; i++) {
            _cancelBid(_bidIds[i]);
        }
    }

    /// @notice Cancels a specified bid by de-activating it
    /// @dev Require the bid to exist and be active
    /// @param _bidId the ID of the bid to cancel
    function cancelBid(uint256 _bidId) public whenNotPaused {
        _cancelBid(_bidId);
    }

    /// @notice Updates a bid winning bids details
    /// @dev Called by batchDepositWithBidIds() in StakingManager.sol
    /// @param _bidId the ID of the bid being removed from the auction (since it has been selected)
    function updateSelectedBidInformation(
        uint256 _bidId
    ) public onlyStakingManagerContract {
        require(bids[_bidId].isActive, "The bid is not active");

        bids[_bidId].isActive = false;
        numberOfActiveBids--;
    }

    /// @notice Lets a bid that was matched to a cancelled stake re-enter the auction
    /// @param _bidId the ID of the bid which was matched to the cancelled stake.
    function reEnterAuction(
        uint256 _bidId
    ) external onlyStakingManagerContract {
        require(!bids[_bidId].isActive, "Bid already active");
        //Reactivate the bid
        bids[_bidId].isActive = true;
        numberOfActiveBids++;
        emit BidReEnteredAuction(_bidId);
    }

    /// @notice Transfer the auction fee received from the node operator to the protocol revenue manager
    /// @dev Called by registerValidator() in StakingManager.sol
    /// @param _bidId the ID of the validator
    function processAuctionFeeTransfer(
        uint256 _bidId
    ) external onlyStakingManagerContract {
        uint256 amount = bids[_bidId].amount;
        protocolRevenueManager.addAuctionRevenue{value: amount}(_bidId);
    }

    /// @notice Disables the bid whitelist
    /// @dev Allows both regular users and whitelisted users to bid
    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
        emit WhitelistDisabled(whitelistEnabled);
    }

    /// @notice Enables the bid whitelist
    /// @dev Only users who are on a whitelist can bid
    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
        emit WhitelistEnabled(whitelistEnabled);
    }

    //Pauses the contract
    function pauseContract() external onlyOwner {
        _pause();
    }

    //Unpauses the contract
    function unPauseContract() external onlyOwner {
        _unpause();
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    function _cancelBid(uint256 _bidId) internal {

        Bid storage bid = bids[_bidId];

        require(bid.bidderAddress == msg.sender, "Invalid bid");
        require(bid.isActive, "Bid already cancelled");

        // Cancel the bid by de-activating it
        bid.isActive = false;
        numberOfActiveBids--;

        // Refund the user with their bid amount
        (bool sent, ) = msg.sender.call{value: bid.amount}("");
        require(sent, "Failed to send Ether");

        emit BidCancelled(_bidId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //--------------------------------------  GETTER  --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Fetches the address of the user who placed a bid for a specific bid ID
    /// @dev Needed for registerValidator() function in Staking Contract
    /// @return the user who placed the bid
    function getBidOwner(uint256 _bidId) external view returns (address) {
        return bids[_bidId].bidderAddress;
    }

    /// @notice Fetches if a selected bid is currently active
    /// @dev Needed for batchDepositWithBidIds() function in Staking Contract
    /// @return the boolean value of the active flag in bids
    function isBidActive(uint256 _bidId) external view returns (bool) {
        return bids[_bidId].isActive;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    //--------------------------------------------------------------------------------------
    //--------------------------------------  SETTER  --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Sets an instance of the protocol revenue manager
    /// @dev Needed to process an auction fee
    /// @param _protocolRevenueManager the addres of the protocol manager
    /// @notice Performed this way due to circular dependencies
    function setProtocolRevenueManager(
        address _protocolRevenueManager
    ) external onlyOwner {
        require(address(protocolRevenueManager) == address(0), "Address already set");
        require(_protocolRevenueManager != address(0), "No zero addresses");
        protocolRevenueManager = IProtocolRevenueManager(
            _protocolRevenueManager
        );
    }

    /// @notice Sets the stakingManagerContractAddress address in the current contract
    /// @param _stakingManagerContractAddress new stakingManagerContract address
    function setStakingManagerContractAddress(
        address _stakingManagerContractAddress
    ) external onlyOwner {
        require(address(stakingManagerContractAddress) == address(0), "Address already set");
        require(_stakingManagerContractAddress != address(0), "No zero addresses");
        stakingManagerContractAddress = _stakingManagerContractAddress;
    }

    /// @notice Updates the minimum bid price
    /// @param _newMinBidAmount the new amount to set the minimum bid price as
    function setMinBidPrice(uint64 _newMinBidAmount) external onlyOwner {
        require(_newMinBidAmount < maxBidAmount, "Min bid exceeds max bid");
        require(_newMinBidAmount > whitelistBidAmount, "Min bid less than whitelist bid amount");
        minBidAmount = _newMinBidAmount;
    }

    /// @notice Updates the maximum bid price
    /// @param _newMaxBidAmount the new amount to set the maximum bid price as
    function setMaxBidPrice(uint64 _newMaxBidAmount) external onlyOwner {
        require(_newMaxBidAmount > minBidAmount, "Min bid exceeds max bid");
        maxBidAmount = _newMaxBidAmount;
    }

    /// @notice Updates the minimum bid price for a whitelisted address
    /// @param _newAmount the new amount to set the minimum bid price as
    function updateWhitelistMinBidAmount(
        uint128 _newAmount
    ) external onlyOwner {
        require(_newAmount < minBidAmount && _newAmount > 0, "Invalid Amount");
        whitelistBidAmount = _newAmount;
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyStakingManagerContract() {
        require(
            msg.sender == stakingManagerContractAddress,
            "Only staking manager contract function"
        );
        _;
    }

    modifier onlyNodeOperatorManagerContract() {
        require(
            msg.sender == address(nodeOperatorManagerInterface),
            "Only node operator key manager contract function"
        );
        _;
    }
}