// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "../libs/IPriceOracle.sol";

interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

contract LuckyRooAirdrop is ReentrancyGuard, VRFConsumerBaseV2, Ownable {
    using SafeERC20 for IERC20;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    bool public initialized = false;
    IERC20 public token;
    IPriceOracle private oracle;

    uint64 public s_subscriptionId;

    bytes32 keyHash;
    uint32 callbackGasLimit = 150000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  3;

    uint256 public s_requestId;
    uint256 public r_requestId;
    uint256[] public s_randomWords;

    struct AirdropResult {
        address[3] winner;
        uint256[3] amount;
    }
    uint256 public currentID = 1;
    uint256 public distributeRate = 9500;
    uint256 public distributorLimit = 500 ether;
    uint256[3] public airdropRates = [6000, 2500, 1000];
    mapping(uint256 => AirdropResult) private results;
    uint256 public lastAirdropTime;

    struct DistributorInfo {
        uint256 amount;
        uint256 regAirdropID;
    }
    mapping(address => DistributorInfo) public userInfo;
    address[] public distributors;
    
    address public treasury = 0xE64812272f989c63907B002843973b302E85c023;
    uint256 public performanceFee = 0.0008 ether;
    
    // BSC Mainnet ERC20_LINK_ADDRESS
    address public constant ERC20_LINK_ADDRESS = 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD;
    address public constant PEGSWAP_ADDRESS = 0x1FCc3B22955e76Ca48bF025f1A6993685975Bb9e;

    event AddDistributor(address user, uint256 amount);
    event Claim(address user, uint256 amount);
    event HolderDistributed(uint256 id, address[3] winners, uint256[3] amounts);
    event SetDistributorLimit(uint256 limit);
    event SetDistributorRates(uint256[3] rates);
    event ServiceInfoUpadted(address addr, uint256 fee);

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     */
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = COORDINATOR.createSubscription();
        keyHash = _keyHash;

        COORDINATOR.addConsumer(s_subscriptionId, address(this));
        LINKTOKEN = LinkTokenInterface(_link);
    }

    /**
     * @notice Initialize the contract
     * @dev This function must be called by the owner of the contract.
     */
    function initialize(address _token, address _oracle) external onlyOwner {
        require(!initialized, "Contract already initialized");
        initialized = true;

        token = IERC20(_token);
        oracle = IPriceOracle(_oracle);
    }

    function addDistributor() external payable nonReentrant {
        require(initialized, "Contract not initialized");
        require(!isContract(msg.sender), "contract cannot be distributor");

        DistributorInfo storage user = userInfo[msg.sender];
        require(user.regAirdropID < currentID, "already added");
        require(user.amount == 0, "claim previous stake first");

        _transferPerformanceFee();
        
        uint256 tokenPrice = oracle.getTokenPrice(address(token));
        uint256 tokenBal = token.balanceOf(msg.sender);
        uint256 amount = distributorLimit * 1 ether / tokenPrice;
        require(tokenPrice > 0, "LUCKY ROO price is missing");
        require(tokenBal >= amount, "insufficient holder balance");
        
        uint256 beforeAmt = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 realAmt = token.balanceOf(address(this)) - beforeAmt;
        if(realAmt > amount) realAmt = amount;

        user.amount = realAmt;
        user.regAirdropID = currentID;
        distributors.push(msg.sender);

        emit AddDistributor(msg.sender, realAmt);
    }

    function claim() external {
        DistributorInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "not registered");
        require(user.regAirdropID < currentID, "can claim after this round is finished");

        token.safeTransfer(msg.sender, user.amount);
        user.amount = 0;
    }

    function _transferPerformanceFee() internal {
        require(msg.value >= performanceFee, 'should pay small gas to add as a distributor');

        payable(treasury).transfer(performanceFee);
        if(msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    function numDistributors() external view returns (uint256) {
        return distributors.length;
    }

    /**
     * @notice Distribute the prizes to the three winners
     * @dev This function must be called by the owner of the contract.
     */
    function callAirdrop() external onlyOwner {
        require(initialized, "Contract not initialized");
        require(s_requestId == r_requestId, "Request IDs do not match");
        require(s_randomWords.length == numWords, "Number of words does not match");

        uint256 numHolders = distributors.length;
        require(numHolders > 3, "Not enough distributors");

        s_requestId = 0;
        
        uint256[3] memory idx;
        uint256[3] memory sortedIdx;
        for(uint i = 0; i < 3; i++) {
            idx[i] = s_randomWords[i] % (numHolders - i);
            for(uint j = 0; j < i; j++) {
                if (idx[i] >= sortedIdx[j]) {
                    idx[i] = idx[i] + 1;
                } else {
                    break;
                }
            }

            idx[i] = idx[i] % numHolders;
            sortedIdx[i] = idx[i];
            if(i > 0 && sortedIdx[i] < sortedIdx[i - 1]) {
                uint256 t = sortedIdx[i];
                sortedIdx[i] = sortedIdx[i - 1];
                sortedIdx[i - 1] = t;
            }
        }

        AirdropResult storage airdropResult = results[currentID];

        uint256 amount = address(this).balance;
        amount = amount * distributeRate / 10000;
        for(uint i = 0; i < 3; i++) {
            address winnerA = distributors[idx[i]];
            airdropResult.winner[i] = winnerA;

            uint256 amountA = amount * airdropRates[i] / 10000;
            airdropResult.amount[i] = amountA;
            payable(winnerA).transfer(amountA);
        }
        emit HolderDistributed(currentID, airdropResult.winner, airdropResult.amount);

        currentID = currentID + 1;
        lastAirdropTime = block.timestamp;
        distributors = new address[](0);
    }

    function getAirdropResult(uint256 _id) external view returns(address[3] memory, uint256[3] memory) {
        return (results[_id].winner, results[_id].amount);
    }

    /**
     * @notice Set the distribution rates for the three wallets
     * @dev This function must be called by the owner of the contract.
     */
    function setAirdropRates(uint256 _rateA, uint256 _rateB, uint256 _rateC) external onlyOwner {        
        require(_rateA > 0, "Rate A must be greater than 0");
        require(_rateB > 0, "Rate B must be greater than 0");
        require(_rateC > 0, "Rate C must be greater than 0");
        require(_rateA + _rateB + _rateC < 10000, "Total rate must be less than 10000");

        airdropRates = [_rateA, _rateB, _rateC];
        emit SetDistributorRates(airdropRates);
    }
    
    /**
     * @notice Set the minimum holding tokens to add distributor in usd
     * @dev This function must be called by the owner of the contract.
     */
    function setDistributorBalanceLimit(uint256 _min) external onlyOwner {
        distributorLimit = _min * 1 ether;
        emit SetDistributorLimit(_min);
    }

    function setServiceInfo(address _treasury, uint256 _fee) external {
        require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
        require(_treasury != address(0x0), "Invalid address");

        treasury = _treasury;
        performanceFee = _fee;

        emit ServiceInfoUpadted(_treasury, _fee);
    }

    function setCoordiatorConfig(bytes32 _keyHash, uint32 _gasLimit, uint32 _numWords ) external onlyOwner {
        keyHash = _keyHash;
        callbackGasLimit = _gasLimit;
        numWords = _numWords;
    }

    /**
     * @notice fetch subscription information from the VRF coordinator
     */
    function getSubscriptionInfo() external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) {
        return COORDINATOR.getSubscription(s_subscriptionId);
    }

    /**
     * @notice cancle subscription from the VRF coordinator
     * @dev This function must be called by the owner of the contract.
     */
    function cancelSubscription() external onlyOwner {
        COORDINATOR.cancelSubscription(s_subscriptionId, msg.sender);
        s_subscriptionId = 0;
    }

    /**
     * @notice subscribe to the VRF coordinator
     * @dev This function must be called by the owner of the contract.
     */
    function startSubscription(address _vrfCoordinator) external onlyOwner {
        require(s_subscriptionId == 0, "Subscription already started");

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    /**
     * @notice Fund link token from the VRF coordinator for subscription
     * @dev This function must be called by the owner of the contract.
     */
    function fundToCoordiator(uint96 _amount) external onlyOwner {
        LINKTOKEN.transferFrom(msg.sender, address(this), _amount);
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(s_subscriptionId)
        );
    }

    /**
     * @notice Fund link token from the VRF coordinator for subscription
     * @dev This function must be called by the owner of the contract.
     */
    function fundPeggedLinkToCoordiator(uint256 _amount) external onlyOwner {
        IERC20(ERC20_LINK_ADDRESS).transferFrom(msg.sender, address(this), _amount);
        IERC20(ERC20_LINK_ADDRESS).approve(PEGSWAP_ADDRESS, _amount);
        IPegSwap(PEGSWAP_ADDRESS).swap(_amount, ERC20_LINK_ADDRESS, address(LINKTOKEN));
        
        uint256 tokenBal = LINKTOKEN.balanceOf(address(this));
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            tokenBal,
            abi.encode(s_subscriptionId)
        );
    }

    /**
     * @notice Request random words from the VRF coordinator
     * @dev This function must be called by the owner of the contract.
     */
    function requestRandomWords() external onlyOwner {
        r_requestId = 0;
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        r_requestId = requestId;
        s_randomWords = randomWords;
    }
    
    function emergencyWithdrawETH() external onlyOwner {
        uint256 _tokenAmount = address(this).balance;
        payable(msg.sender).transfer(_tokenAmount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function emergencyWithdrawToken(address _token) external onlyOwner {
        uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

    receive() external payable {}
}