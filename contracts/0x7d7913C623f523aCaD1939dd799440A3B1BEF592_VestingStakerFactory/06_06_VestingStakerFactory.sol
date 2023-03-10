// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./libraries/CloneLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author YFLOW Team
/// @title VestingStakerFactory
/// @notice Factory contract to create new instances
contract VestingStakerFactory {
    using CloneLibrary for address;

    event NewVesting(address vesting);
    event FactoryOwnerChanged(address newowner);
    event NewVestingImplementation(address newVesting);

    address public factoryOwner;
    address public vestingImplementation;

    mapping(address => address) public stakingContractLookup;

    constructor(
        address _vestingImplementation
    )
    {
        require(_vestingImplementation != address(0), "No zero address for _polygonImplementation");

        factoryOwner = msg.sender;
        vestingImplementation = _vestingImplementation;

        emit FactoryOwnerChanged(factoryOwner);
        emit NewVestingImplementation(vestingImplementation);
    }

    function vestingMint(address receiver, address staking, address token)
    external
    returns(address vesting)
    {
        vesting = vestingImplementation.createClone();
        stakingContractLookup[receiver] = vesting;
        emit NewVesting(vesting);

        IVestingImplementation(vesting).initialize(
            token,
            staking,
            receiver
        );
    }

    /**
     * @dev lets the owner change the current polygon implementation
     *
     * @param vesting_ the address of the new implementation
    */
    function newVestingImplementation(address vesting_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(vesting_ != address(0), "No zero address for vesting_");

        vestingImplementation = vesting_;
        emit NewVestingImplementation(vesting_);
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

    /**
     * receive function to receive funds
    */
    receive() external payable {}

    function getUserStakingContract(address staker) external view returns(address) {
        return stakingContractLookup[staker];
    }
}

interface IVestingImplementation {
    function initialize(address _token, address _stakingContract, address _recipient) external;
}