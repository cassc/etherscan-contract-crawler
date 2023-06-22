// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./libraries/CloneLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YFLOW Team
/// @title UniV2LPETHFactory
/// @notice Factory contract to create new instances
contract UniV2LPETHFactory {
    using CloneLibrary for address;
    using SafeERC20 for IERC20;

    event NewUniV2LPETH(address uinv2LPETH, address client);
    event FactoryOwnerChanged(address newowner);
    event NewYieldManager(address newYieldManager);
    event NewUniV2LPETHImplementation(address newUniV2LPETHImplementation);
    event NewLPToken(address lptoken);
    event NewStakingTokenA(address stakingtokenA);
    event NewStakingContract(address stakingContract);
    event FeesWithdrawn(uint amount, address withdrawer);
    event NewSponsor(address sponsor, address client);
    event NewRewardStakingContract(address rewardStakingContract);
    event NewRewardStakingToken(address rewardStakingToken);
    event RecoverOpen(bool recover);

    address public factoryOwner;
    address public uniV2LPETHImplementation;
    address public yieldManager;
    address public lpToken;
    address public stakingTokenA;
    address public stakingContract;
    bool public recoverOpen;

    mapping(address => address) public stakingContractLookup;
    address public rewardStakingContract;
    address public rewardStakingToken;

    constructor(
        address _uniV2LPETHImplementation,
        address _yieldManager,
        address _lpToken,
        address _stakingTokenA,
        address _stakingContract
    )
    {
        require(_uniV2LPETHImplementation != address(0), "No zero address for _uniV2LPETHImplementation");
        require(_yieldManager != address(0), "No zero address for _yieldManager");

        factoryOwner = msg.sender;
        uniV2LPETHImplementation = _uniV2LPETHImplementation;
        yieldManager = _yieldManager;
        lpToken = _lpToken;
        stakingTokenA = _stakingTokenA;
        stakingContract = _stakingContract;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewUniV2LPETHImplementation(uniV2LPETHImplementation);
        emit NewYieldManager(yieldManager);
        emit NewLPToken(lpToken);
        emit NewStakingTokenA(stakingTokenA);
        emit NewStakingContract(stakingContract);
    }

    function uniV2LPETHMint(address sponsor)
    external
    returns(address uniV2)
    {
        uniV2 = uniV2LPETHImplementation.createClone();

        emit NewUniV2LPETH(uniV2, msg.sender);
        stakingContractLookup[msg.sender] = uniV2;

        IUinV2LPETHImplementation(uniV2).initialize(
            msg.sender,
            address(this)
        );

        if (sponsor != address(0) && sponsor != msg.sender && IYieldManager(yieldManager).getAffiliate(msg.sender) == address(0)) {
            IYieldManager(yieldManager).setAffiliate(msg.sender, sponsor);
            emit NewSponsor(sponsor, msg.sender);
        }
    }

    /**
     * @dev gets the address of the yield manager
     *
     * @return the address of the yield manager
    */
    function getYieldManager() external view returns (address) {
        return yieldManager;
    }

    function getLPToken() external view returns (address) {
        return lpToken;
    }

    function getStakingTokenA() external view returns (address) {
        return stakingTokenA;
    }

    function getStakingContract() external view returns (address) {
        return stakingContract;
    }

    function getRewardStakingContract() external view returns (address) {
        return rewardStakingContract;
    }

    function getRewardStakingToken() external view returns (address) {
        return rewardStakingToken;
    }

    function getRecoverOpen() external view returns (bool) {
        return recoverOpen;
    }

    /**
     * @dev lets the owner change the current uniV2LPETHImplementation_ implementation
     *
     * @param uniV2LPETHImplementation_ the address of the new implementation
    */
    function newUniV2LPETHImplementation(address uniV2LPETHImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(uniV2LPETHImplementation_ != address(0), "No zero address for uniV2LPETHImplementation_");

        uniV2LPETHImplementation = uniV2LPETHImplementation_;
        emit NewUniV2LPETHImplementation(uniV2LPETHImplementation);
    }

    /**
     * @dev lets the owner change the current yieldManager_
     *
     * @param yieldManager_ the address of the new router
    */
    function newYieldManager(address yieldManager_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(yieldManager_ != address(0), "No zero address for yieldManager_");

        yieldManager = yieldManager_;
        emit NewYieldManager(yieldManager);
    }

    function newLPToken(address lpToken_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(lpToken_ != address(0), "No zero address for lpToken_");

        lpToken = lpToken_;
        emit NewLPToken(lpToken);
    }

    function newStakingTokenA(address stakingTokenA_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingTokenA_ != address(0), "No zero address for stakingTokenA_");

        stakingTokenA = stakingTokenA_;
        emit NewStakingTokenA(stakingTokenA);
    }

    function newStakingContract(address stakingContract_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingContract_ != address(0), "No zero address for stakingContract_");

        stakingContract = stakingContract_;
        emit NewStakingContract(stakingContract);
    }

    function newRewardStakingContract(address stakingContract_) external {
        require(msg.sender == factoryOwner, "Only factory owner");

        rewardStakingContract = stakingContract_;
        emit NewRewardStakingContract(stakingContract);
    }

    function newRewardStakingToken(address stakingToken_) external {
        require(msg.sender == factoryOwner, "Only factory owner");

        rewardStakingToken = stakingToken_;
        emit NewRewardStakingToken(stakingToken_);
    }

    function newRecoverOpen(bool recoverOpen_) external {
        require(msg.sender == factoryOwner, "Only factory owner");

        recoverOpen = recoverOpen_;
        emit RecoverOpen(recoverOpen_);
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");

        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }

    function getUserStakingContract(address staker) external view returns(address) {
        return stakingContractLookup[staker];
    }

    function withdrawRewardFees(
        address receiver,
        uint amount
    ) external  {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(amount > 0, "Cannot withdraw 0");
        require(
            amount <= IERC20(lpToken).balanceOf(address(this)),
            "Cannot withdraw more than fees in the contract"
        );
        IERC20(lpToken).safeTransfer(receiver, amount);
        emit FeesWithdrawn(amount, receiver);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public payable returns (bytes memory) {
        require(
            msg.sender == factoryOwner,
            "executeTransaction: Call must come from owner"
        );

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(
            success,
            "executeTransaction: Transaction execution reverted."
        );

        return returnData;
    }

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IUinV2LPETHImplementation {
    function initialize(
        address owner_,
        address factoryAddress_
    ) external;
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getAffiliate(address client) external view returns (address);
}