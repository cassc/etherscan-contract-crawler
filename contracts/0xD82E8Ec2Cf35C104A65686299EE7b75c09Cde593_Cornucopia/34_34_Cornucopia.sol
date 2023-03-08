// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/protocol/packages/core/contracts/optimistic-oracle/interfaces/SkinnyOptimisticOracleInterface.sol";
import "lib/protocol/packages/core/contracts/optimistic-oracle/previous-versions/SkinnyOptimisticOracle.sol";
import "lib/protocol/packages/core/contracts/data-verification-mechanism/implementation/Constants.sol";
import "lib/protocol/packages/core/contracts/optimistic-oracle/interfaces/OptimisticOracleInterface.sol";
import "lib/protocol/packages/core/contracts/data-verification-mechanism/interfaces/StoreInterface.sol";
import "lib/protocol/packages/core/contracts/data-verification-mechanism/interfaces/FinderInterface.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

/// @title Cornucopia contract
/// @notice Cornucopia bounty protocol
contract Cornucopia is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20 for IERC20;

    mapping(bytes32 => uint) public bountyAmounts;
    mapping(bytes32 => Status) public progress;
    mapping(bytes32 => uint) public expiration;
    mapping(bytes32 => uint) public payoutExpiration;
    mapping(bytes32 => address) public bountyToken;
    mapping(bytes32 => bytes32) public bountyAncillaryData;

    SkinnyOptimisticOracleInterface public oracleInterface;
    address public constant ORACLE_ADDRESS = 0xeE3Afe347D5C74317041E2618C49534dAf887c24;
    address public constant ORACLE_STORE_ADDRESS = 0x54f44eA3D2e7aA0ac089c4d8F7C93C27844057BF;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    enum Status {
        NoBounty,
        Submitted, 
        DisputeInitiated,
        DisputeRespondedTo,
        Resolved
    }

    event Escrowed(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);
    event Submitted(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);
    event Disputed(address indexed creator, address indexed hunter, string indexed bountyAppId, uint32 timestamp, string message);
    event DisputeRespondedTo(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);
    event Resolved(address indexed creator, address indexed hunter, string indexed bountyAppId, address winner, string message); 
    event FundsSent(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);
    event FundsWithdrawnToCreator(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);
    event FundsForceSentToHunter(address indexed creator, address indexed hunter, string indexed bountyAppId, string message);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // Only the owner can upgrade the implementation.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice Escrows creator's ERC-20 or ETH for a given bounty and hunter
    /// @dev Check if creator using ETH via msg.value and explicitly checks progress and _amount to prevent creator setting bountyAmounts twice
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _hunter The hunter's address
    /// @param _expiration How long the hunter has to submit their work before the creator can refund themselves
    /// @param _token The token's address (zero address if ETH)
    /// @param _amount The token amount (zero if ETH)
    function escrow(string memory _bountyAppId, address _hunter, uint _expiration, address _token, uint _amount) external payable nonReentrant {
        require(bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] == 0, "Funds already escrowed");
        require(progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] == Status.NoBounty, "State must be No Bounty");
 
        if (msg.value > 0) { // User sends ETH
            bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = msg.value; 
        } else { // Creator escrows ERC20 
            require(_amount > 0, "Amount must be non-zero");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = _amount;
            bountyToken[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = _token;
        }
        
        expiration[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = block.timestamp + _expiration; 
        emit Escrowed(msg.sender, _hunter, _bountyAppId, "Escrowed!"); 
    }

    /// @notice Hunter submits work for a given bounty and creator 
    /// @dev Sets payoutExpiration to be 2 weeks, giving creator two weeks to pay or dispute the hunter's work
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _creator The creator's address
    function submit(string memory _bountyAppId, address _creator) external nonReentrant {
        require(bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] != 0, "Funds not escrowed");
        require(progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] == Status.NoBounty, "Work already submitted");
        progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] = Status.Submitted;
        payoutExpiration[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] = block.timestamp + 2 weeks; // Creator has 2 weeks to pay. 
        emit Submitted(_creator, msg.sender, _bountyAppId, "Submitted!"); 
    }

    /// @notice Creator initiates dispute for a given bounty and hunter
    /// @dev Currency can only be WETH, DAI, or USDC 
    /// @dev Creator is the proposer but Cornucopia contract is the requester
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _hunter The hunter's address
    /// @param _bondAmt The UMA bond the creator posts to initiate the dispute
    /// @param _ancillaryData The dispute data UMA holders use to judge the dispute
    /// @param _currency The currency the creator wants to use for the bond 
    /// @return creatorBondAmt The creator's bond plus UMA's finalFee
    function initiateDispute(
        string memory _bountyAppId, 
        address _hunter,
        uint _bondAmt, 
        string memory _ancillaryData,
        IERC20 _currency
    ) external nonReentrant returns (uint) {
        require(progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] == Status.Submitted, "Work not Submitted");
        require(address(_currency) == WETH_ADDRESS || address(_currency) == DAI_ADDRESS || address(_currency) == USDC_ADDRESS, "Bond can only be in WETH, DAI, or USDC");
        bytes memory ancillaryData = bytes(_ancillaryData);
        
        uint256 finalFee = StoreInterface(ORACLE_STORE_ADDRESS).computeFinalFee(address(_currency)).rawValue;
        _currency.safeTransferFrom(msg.sender, address(this), _bondAmt + finalFee); // Transfer bond token from creator to contract to then send to OO.
        _currency.safeIncreaseAllowance(ORACLE_ADDRESS, _bondAmt + finalFee); // Need to approve OO contract to transfer tokens from here to OO of bondAmt + finalFee.

        oracleInterface = SkinnyOptimisticOracleInterface(ORACLE_ADDRESS);
        uint creatorBondAmt = oracleInterface.requestAndProposePriceFor(
            bytes32("YES_OR_NO_QUERY"), // bytes32, identifier 
            uint32(block.timestamp), // uint32, timestamp
            ancillaryData, // bytes memory, github link
            _currency, // ERC-20, WETH, DAI, or USDC 
            0, // uint256, reward 
            _bondAmt, // uint256, bounty creator determines bond
            1 weeks, // uint256, customLiveness
            msg.sender, // address, bounty creator = proposer
            0 // int256, p1:0 = no
        ); 
    
        bountyAncillaryData[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = keccak256(abi.encode(ancillaryData, block.timestamp));
        progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = Status.DisputeInitiated; 
        emit Disputed(msg.sender, _hunter, _bountyAppId, uint32(block.timestamp), "Disputed!");
        return creatorBondAmt; 
    }

    /// @notice Hunter responds to dispute for a given bounty and creator
    /// @dev Checks that bounty has been disputed 
    /// @dev Request can be found from events emitted when initiateDispute is called
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _creator The creator's address
    /// @param _timestamp The timestamp when the creator called initiateDispute and the dispute was created in UMA
    /// @param _ancillaryData The dispute data UMA holders use to judge the dispute
    /// @param _request The UMA request struct representing the dispute
    /// @return hunterBondAmt The hunter's bond plus UMA's finalFee
    function hunterDisputeResponse(
        string memory _bountyAppId, 
        address _creator, 
        uint32 _timestamp, 
        bytes memory _ancillaryData,
        SkinnyOptimisticOracleInterface.Request memory _request
    ) external nonReentrant returns (uint) {
        require(progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] == Status.DisputeInitiated, "Bounty creator has not disputed");
        require(bountyAncillaryData[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] == keccak256(abi.encode(_ancillaryData, _timestamp)), "Incorrect ancillaryData/timestamp");
        
        uint256 finalFee = StoreInterface(ORACLE_STORE_ADDRESS).computeFinalFee(address(_request.currency)).rawValue;
        _request.currency.safeTransferFrom(msg.sender, address(this), _request.bond + finalFee); // Transfer bond token from hunter to contract to then send to OO.
        _request.currency.safeIncreaseAllowance(address(oracleInterface), _request.bond + finalFee); // Need to approve OO contract to transfer tokens from here to OO of bondAmt + finalFee.

        uint hunterBondAmt = oracleInterface.disputePriceFor(
            bytes32("YES_OR_NO_QUERY"),
            _timestamp,
            _ancillaryData,
            _request,
            msg.sender, // Setting hunter to disputer
            address(this) // EscrowContract is actually the requester not the creator as EscrowContract calls UMA contract.
        ); 

        progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] = Status.DisputeRespondedTo;
        emit DisputeRespondedTo(_creator, msg.sender, _bountyAppId, "Dispute Responded To!");
        return hunterBondAmt;  
    }
    
    /// @notice Hunter forces the payout of escrowed funds for a given bounty and creator if creator ignores work submission
    /// @dev Checks that hunter has submitted their work
    /// @dev Checks that creator can still pay or dispute the bounty
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _creator The creator's address
    function forceHunterPayout(string memory _bountyAppId, address _creator) external nonReentrant {
        // Bounty creator did not pay or dispute within 2 weeks following hunter submitting work.
        require(progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] == Status.Submitted, "Work not Submitted");
        require(payoutExpiration[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] <= block.timestamp, "Creator can still pay or dispute");
        
        uint value = bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))];
        bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] -= value;

        address token = bountyToken[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))];

        if (token != address(0)) { // If ERC-20 token
            IERC20(token).safeTransfer(msg.sender, value);
        } else {
            (bool sent, ) = payable(msg.sender).call{value: value}("");
            require(sent, "Failed to send Ether");
        }

        emit FundsForceSentToHunter(_creator, msg.sender, _bountyAppId, "Funds force sent to hunter!");
        progress[keccak256(abi.encodePacked(_bountyAppId, _creator, msg.sender))] = Status.Resolved;
    }

    /// @notice Creator or hunter settles an outstanding UMA dispute 
    /// @dev Checks that caller is either the creator or hunter to ensure correct payout data
    /// @dev Checks that the bounty was disputed in Cornucopia 
    /// @dev Handles the cases where dispute is settled, still live, expired, or hunter hasn't responded to the dispute
    /// @dev Handles the cases where the creator wins the dispute, hunter wins the dispute, or they tie. 
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _creator The creator's address
    /// @param _hunter The hunter's address
    /// @param _timestamp The timestamp when the creator called initiateDispute and the dispute was created in UMA
    /// @param _ancillaryData The dispute data UMA holders use to judge the dispute
    /// @param _request The UMA request struct representing the dispute
    function payoutIfDispute(
        string memory _bountyAppId, 
        address _creator,
        address _hunter,
        uint32 _timestamp, 
        bytes memory _ancillaryData,
        SkinnyOptimisticOracleInterface.Request memory _request
    ) external nonReentrant {
        require(msg.sender == _creator || msg.sender == _hunter, "Caller must be creator or hunter");
        require(bountyAncillaryData[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))] == keccak256(abi.encode(_ancillaryData, _timestamp)), "Incorrect ancillaryData/timestamp");

        Status status = progress[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))];
        require(status == Status.DisputeInitiated || status == Status.DisputeRespondedTo, "Bounty must be disputed");

        OptimisticOracleInterface.State state = oracleInterface.getState(address(this), bytes32("YES_OR_NO_QUERY"), _timestamp, _ancillaryData, _request); // Note: EscrowContract is actually the requester not the creator

        uint value = bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))];
        address token = bountyToken[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))];

        if (status != Status.Resolved && 
            (state == OptimisticOracleInterface.State.Resolved || state == OptimisticOracleInterface.State.Expired)) {
            // Hunter disputes and it's resolved by DVM or Hunter doesn't dispute and it expires after 1 week.
            // Settle returns how much dvm pays winner and "price" (0, 1, 2).
   
            if (state == OptimisticOracleInterface.State.Resolved) { // Check here b/c expired state has no disputer field set in request. This prevents creator from submitting a request for a different creator and/or hunter, forcing an incorrect payout. 
                require(_request.proposer == _creator && _request.disputer == _hunter, "Incorrect request data");
            } else if (state == OptimisticOracleInterface.State.Expired) { // Prevents creator from submitting request and ancillary data for an expired dispute for a given hunter with an active/resolved dispute.
                require(status == Status.DisputeInitiated, "Incorrect hunter specified");
            }

            (, int256 winner) = oracleInterface.settle(address(this), bytes32("YES_OR_NO_QUERY"), _timestamp, _ancillaryData, _request); // EscrowContract is actually the requester not the creator.
            if (winner == 0) { // Send funds to creator
                bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))] -= value;
                if (token != address(0)) { // If ERC-20 token
                    IERC20(token).safeTransfer(_creator, value);
                } else {
                    (bool sent, ) = payable(_creator).call{value: value}("");
                    require(sent, "Failed to send Ether");
                }
                emit FundsSent(_creator, _hunter, _bountyAppId, "Funds sent back to creator!");
            } else if (winner == 1) { // Send funds to hunter
                bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))] -= value;
                if (token != address(0)) { // If ERC-20 token
                    IERC20(token).safeTransfer(_hunter, value);
                } else {
                    (bool sent, ) = payable(_hunter).call{value: value}("");
                    require(sent, "Failed to send Ether");
                }
                emit FundsSent(_creator, _hunter, _bountyAppId, "Funds sent to hunter!");
            } else if (winner == 2) { // Send half funds to creator and half to hunter
                bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))] -= value;
                if (token != address(0)) { // If ERC-20 token
                    IERC20(token).safeTransfer(_hunter, value / 2);
                    IERC20(token).safeTransfer(_creator, value / 2);
                } else {
                    (bool sent, ) = payable(_hunter).call{value: value / 2 }("");
                    require(sent, "Failed to send Ether");
                    (bool sent2, ) = payable(_creator).call{value: value / 2 }("");
                    require(sent2, "Failed to send Ether");
                }
                emit FundsSent(_creator, _hunter, _bountyAppId, "Half of funds sent back to creator and then to hunter!");
            }
            progress[keccak256(abi.encodePacked(_bountyAppId, _creator, _hunter))] = Status.Resolved;
        } else if (status != Status.Resolved && 
            (state == OptimisticOracleInterface.State.Proposed || state == OptimisticOracleInterface.State.Disputed)) {
            // Creator dispute still live: Hunter hasn't disputed yet or hunter dispute hasn't been settled by DVM yet
            revert("Dispute still live");
        } 
    }

    /// @notice Creator pays out a bounty for a given hunter 
    /// @dev Handles the case where the bounty hunter doesn't submit work in time so creator can get a refund
    /// @dev Handles cases where bounty was disputed or hunter didn't submit their work yet
    /// @dev Handles both ERC-20 and ETH bounties   
    /// @param _bountyAppId The bountyId for the given bounty
    /// @param _hunter The hunter's address
    function payout(string memory _bountyAppId, address _hunter) external nonReentrant {
        uint value = bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))];
        address token = bountyToken[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))];

        // Bounty Hunter doesn't submit work within specified time
        if(progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] == Status.NoBounty 
            && expiration[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] <= block.timestamp) {
                bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] -= value;
                if (token != address(0)) { // If ERC-20 token
                    IERC20(token).safeTransfer(msg.sender, value);
                } else {
                    (bool sent, ) = payable(msg.sender).call{value: value}("");
                    require(sent, "Failed to send Ether");
                }
                emit FundsWithdrawnToCreator(msg.sender, _hunter, _bountyAppId, "Funds withdrawn to creator!");
                progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = Status.Resolved; 
        } 

        Status status = progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))];
        // Bounty creator doesn't dispute and pays out normal amount
        if (status == Status.Submitted) {
            bountyAmounts[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] -= value;
            if (token != address(0)) { // If ERC-20 token
                    IERC20(token).safeTransfer(_hunter, value);
            } else {
                (bool sent, ) = payable(_hunter).call{value: value}("");
                require(sent, "Failed to send Ether");
            }
            emit FundsSent(msg.sender, _hunter, _bountyAppId, "Funds sent to hunter!");
            progress[keccak256(abi.encodePacked(_bountyAppId, msg.sender, _hunter))] = Status.Resolved;
        } else if (status == Status.NoBounty && value > 0) {
            revert("Hunter hasn't submitted work yet");
        } else if (status == Status.DisputeInitiated || status == Status.DisputeRespondedTo){
            revert("Bounty is disputed");
        }  
    }
}