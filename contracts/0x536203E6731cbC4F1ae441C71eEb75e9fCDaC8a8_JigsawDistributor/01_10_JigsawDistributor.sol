// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

/**
 * @author Brewlabs
 * This treasury contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IJigsawToken {
    function getNumberOfTokenHolders() external view returns(uint256);
    function getTokenHolderAtIndex(uint256 accountIndex) external view returns(address);
    function balanceOf(address account) external view returns (uint256);
}
interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

contract JigsawDistributor is ReentrancyGuard, VRFConsumerBaseV2, Ownable {
    using SafeERC20 for IERC20;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    bool public initialized = false;
    IJigsawToken public jigsawToken;

    uint64 public s_subscriptionId;

    bytes32 keyHash;
    uint32 callbackGasLimit = 150000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  3;

    uint256 public s_requestId;
    uint256 public r_requestId;
    uint256[] public s_randomWords;

    struct TheOfferingResult {
        address[3] winner;
        uint256[3] amount;
    }
    uint256 public theOfferingID;
    uint256 public theOfferingRate = 2500;
    uint256[3] public theOfferingHolderRates = [6000, 2500, 1000];
    mapping(uint256 => TheOfferingResult) private theOfferingResults;
    uint256 public winnerBalanceLimit = 20000 * 1 ether;

    mapping(address => bool) private isWinner;
    address[] private winnerList;
    uint256 public oneTimeResetCount = 1000;

    address[3] public wallets;
    uint256[3] public rates = [2500, 2000, 2500];
    
    // BSC Mainnet ERC20_LINK_ADDRESS
    address public constant ERC20_LINK_ADDRESS = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address public constant PEGSWAP_ADDRESS = 0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD;

    event SetDistributors(address walletA, address walletB, address walletC);
    event SetDistributorRates(uint256 rateA, uint256 rateB, uint256 rateC);
    event SetTheOfferingRate(uint256 rate);
    event SetTheOfferingHolderRates(uint256 rateA, uint256 rateB, uint256 rateC);
    event SetWinnerBalanceLimit(uint256 amount);
    event Distributed(uint256 amountA, uint256 amountB, uint256 amountC);
    event HolderDistributed(uint256 triadID, address[3] winners, uint256[3] amounts);
    event SetOneTimeResetCount(uint256 num);
    event ResetWinnerList();

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
    function initialize(address _token, address[3] memory _wallets) external onlyOwner {
        require(!initialized, "Contract already initialized");
        initialized = true;

        jigsawToken = IJigsawToken(_token);
        wallets = _wallets;
    }

    /**
     * @notice Distribute the ETH to the three distributors
     * @dev This function must be called by the owner of the contract.
     */
    function callDistributor() external onlyOwner {
        require(initialized, "Contract not initialized");

        uint256 amount = address(this).balance;
        require(amount > 3, "Not enough ETH to distribute");

        uint256 amountA = amount * rates[0] / 10000;
        uint256 amountB = amount * rates[1] / 10000;
        uint256 amountC = amount * rates[2] / 10000;
        payable(wallets[0]).transfer(amountA);
        payable(wallets[1]).transfer(amountB);
        payable(wallets[2]).transfer(amountC);

        emit Distributed(amountA, amountB, amountC);
    }

    /**
     * @notice Distribute the prizes to the three winners
     * @dev This function must be called by the owner of the contract.
     */
    function callTheOffering() external onlyOwner {
        require(initialized, "Contract not initialized");
        require(s_requestId == r_requestId, "Request IDs do not match");
        require(s_randomWords.length == numWords, "Number of words does not match");

        uint256 numHolders = jigsawToken.getNumberOfTokenHolders();
        require(numHolders > 3, "Not enough token holders");

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

        theOfferingID = theOfferingID + 1;        
        TheOfferingResult storage triadResult = theOfferingResults[theOfferingID];

        uint256 amount = address(this).balance;
        amount = amount * theOfferingRate / 10000;
        for(uint i = 0; i < 3; i++) {
            address winnerA = jigsawToken.getTokenHolderAtIndex(idx[i]);
            triadResult.winner[i] = winnerA;

            if(isWinner[winnerA]) continue;
            isWinner[winnerA] = true;
            winnerList.push(winnerA);

            if(isContract(winnerA)) continue;
            if(jigsawToken.balanceOf(winnerA) < winnerBalanceLimit) continue;

            uint256 amountA = amount * theOfferingHolderRates[i] / 10000;
            triadResult.amount[i] = amountA;
            payable(winnerA).transfer(amountA);
        }

        emit HolderDistributed(theOfferingID, triadResult.winner, triadResult.amount);
    }

    function offeringResult(uint256 _id) external view returns(address[3] memory, uint256[3] memory) {
        return (theOfferingResults[_id].winner, theOfferingResults[_id].amount);
    }

    function totalWinners() external view returns(uint256) {
        return winnerList.length;
    }

    function resetWinnerList() external onlyOwner {
        uint count = winnerList.length;
        for(uint i = 0; i < count; i++) {
            if(i >= oneTimeResetCount) break;
            
            address winner = winnerList[winnerList.length - 1];
            isWinner[winner] = false;
            winnerList.pop();
        }

        emit ResetWinnerList();
    }

    function setOneTimeResetCount(uint256 num) external onlyOwner {
        oneTimeResetCount = num;
        emit SetOneTimeResetCount(num);
    }

    /**
     * @notice Set the distribution rates for the three wallets
     * @dev This function must be called by the owner of the contract.
     */
    function setDistributorRates(uint256 _rateA, uint256 _rateB, uint256 _rateC) external onlyOwner {        
        require(_rateA > 0, "Rate A must be greater than 0");
        require(_rateB > 0, "Rate B must be greater than 0");
        require(_rateC > 0, "Rate C must be greater than 0");
        require(_rateA + _rateB + _rateC < 10000, "Total rate must be less than 10000");

        rates = [_rateA, _rateB, _rateC];
        emit SetDistributorRates(_rateA, _rateB, _rateC);
    }

    /**
     * @notice Set the three wallets for the distribution
     * @dev This function must be called by the owner of the contract.
     */
    function setWallets(address[3] memory _wallets) external onlyOwner {
        require(initialized, "Contract not initialized");

        require(_wallets[0] != address(0), "Wallet A must be set");
        require(_wallets[1] != address(0), "Wallet B must be set");
        require(_wallets[2] != address(0), "Wallet C must be set");
        require(_wallets[0] != _wallets[1], "Wallet A and B must be different");
        require(_wallets[0] != _wallets[2], "Wallet A and C must be different");
        require(_wallets[1] != _wallets[2], "Wallet B and C must be different");

        wallets = _wallets;
        emit SetDistributors(wallets[0], wallets[1], wallets[2]);
    }

    /**
     * @notice Set the distribution rate for the three wallets
     * @dev This function must be called by the owner of the contract.
     */
    function setTheOfferingRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate must be greater than 0");
        theOfferingRate = _rate;
        emit SetTheOfferingRate(_rate);
    }
    
    /**
     * @notice Set the minimum balance to receive ETH from call offering
     * @dev This function must be called by the owner of the contract.
     */
    function setWinnerBalanceLimit(uint256 _min) external onlyOwner {
        winnerBalanceLimit = _min * 1 ether;
        emit SetWinnerBalanceLimit(winnerBalanceLimit);
    }

    /**
     * @notice Set the distribution rates for three winners
     * @dev This function must be called by the owner of the contract.
     */
    function setTheOfferingHolderRates(uint256 _rateA, uint256 _rateB, uint256 _rateC) external onlyOwner {
        require(_rateA > 0, "Rate A must be greater than 0");
        require(_rateB > 0, "Rate B must be greater than 0");
        require(_rateC > 0, "Rate C must be greater than 0");
        require(_rateA + _rateB + _rateC < 10000, "Total rate must be less than 10000");

        theOfferingHolderRates = [_rateA, _rateB, _rateC];
        emit SetTheOfferingHolderRates(_rateA, _rateB, _rateC);
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