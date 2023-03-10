// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./libraries/CloneLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YFLOW Team
/// @title PolygonStakingFactory
/// @notice Factory contract to create new instances
contract PolygonStakingFactory {
    using CloneLibrary for address;

    event NewPolygonStaking(address polygonStaking, address client);
    event FactoryOwnerChanged(address newowner);
    event NewYieldManager(address newYieldManager);
    event NewPolygonStakingImplementation(address newPolygonStakingImplementation);
    event NewRewardToken(address rewardToken);
    event NewStakingToken(address stakingToken);
    event NewStakingContract(address stakingContract);
    event NewStakingContractStakeManager(address stakingContractStakeManger);
    event FeesWithdrawn(uint amount, address withdrawer);
    event NewSponsor(address sponsor, address client);

    address public factoryOwner;
    address public polygonImplementation;
    address public yieldManager;
    address public rewardToken;
    address public stakingToken;
    address public stakingContract;
    address public stakingContractStakeManager;

    mapping(address => address) public stakingContractLookup;

    constructor(
        address _polygonImplementation,
        address _yieldManager,
        address _rewardToken,
        address _stakingToken,
        address _stakingContract,
        address _stakingContractStakeManager
    )
    {
        require(_polygonImplementation != address(0), "No zero address for _polygonImplementation");
        require(_yieldManager != address(0), "No zero address for _yieldManager");

        factoryOwner = msg.sender;
        polygonImplementation = _polygonImplementation;
        yieldManager = _yieldManager;
        rewardToken = _rewardToken;
        stakingToken = _stakingToken;
        stakingContract = _stakingContract;
        stakingContractStakeManager = _stakingContractStakeManager;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewPolygonStakingImplementation(polygonImplementation);
        emit NewYieldManager(yieldManager);
        emit NewRewardToken(rewardToken);
        emit NewStakingToken(stakingToken);
        emit NewStakingContract(stakingContract);
    }

    function polygonStakingMint(address sponsor)
    external
    returns(address polygon)
    {
        polygon = polygonImplementation.createClone();

        emit NewPolygonStaking(polygon, msg.sender);
        stakingContractLookup[msg.sender] = polygon;

        IPolygonStakingImplementation(polygon).initialize(
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

    function getRewardToken() external view returns (address) {
        return rewardToken;
    }

    function getStakingToken() external view returns (address) {
        return stakingToken;
    }

    function getStakingContract() external view returns (address) {
        return stakingContract;
    }

    function getStakingContractStakeManager() external view returns (address) {
        return stakingContractStakeManager;
    }

    /**
     * @dev lets the owner change the current polygon implementation
     *
     * @param polygonImplementation_ the address of the new implementation
    */
    function newPolygonStakingImplementation(address polygonImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(polygonImplementation_ != address(0), "No zero address for polygonImplementation_");

        polygonImplementation = polygonImplementation_;
        emit NewPolygonStakingImplementation(polygonImplementation);
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

    function newRewardToken(address rewardToken_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(rewardToken_ != address(0), "No zero address for rewardToken_");

        rewardToken = rewardToken_;
        emit NewRewardToken(rewardToken);
    }

    function newStakingToken(address stakingToken_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingToken_ != address(0), "No zero address for stakingToken_");

        stakingToken = stakingToken_;
        emit NewStakingToken(stakingToken);
    }

    function newStakingContract(address stakingContract_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingContract_ != address(0), "No zero address for stakingContract_");

        stakingContract = stakingContract_;
        emit NewStakingContract(stakingContract);
    }

    function newStakingContractStakeManager(address stakingContractStakeManager_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(stakingContractStakeManager_ != address(0), "No zero address for stakingContract_");

        stakingContractStakeManager = stakingContractStakeManager_;
        emit NewStakingContractStakeManager(stakingContractStakeManager);
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
            amount <= IERC20(rewardToken).balanceOf(address(this)),
            "Cannot withdraw more than fees in the contract"
        );
        IERC20(rewardToken).transfer(receiver, amount);
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

interface IPolygonStakingImplementation {
    function initialize(
        address owner_,
        address factoryAddress_
    ) external;
}
interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getAffiliate(address client) external view returns (address);
}