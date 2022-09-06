/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IValidator {
    function getLoyalKeyRank(address user) external view returns (uint256);
    function getMarketplaceFee(address user) external view returns (uint256);
    function hasKeyCard(address user) external view returns (bool);
    function keyCardBalance(address user) external view returns (uint256);
    function keysBalance(address user) external view returns (uint256);
}

contract LoyalKeyDatabase is Ownable {

    address public LoyalKeyValidator = 0xBd6b115a483aE608fd710edD9EFAE6b2D819EB2c;

    function setLoyalKeyValidator(address newLoyalKeyValidator) external onlyOwner {
        require(
            newLoyalKeyValidator != address(0),
            'Zero Address'
        );

        // set state
        LoyalKeyValidator = newLoyalKeyValidator;
    }

    function keysBalance(address user) public view returns (uint256) {
        return IValidator(LoyalKeyValidator).keysBalance(user);
    }

    function keyCardBalance(address user) public view returns (uint256) {
        return IValidator(LoyalKeyValidator).keyCardBalance(user);
    }

    function hasKeyCard(address user) public view returns (bool) {
        return IValidator(LoyalKeyValidator).hasKeyCard(user);
    }

    function getLoyalKeyRank(address user) external view returns (uint256) {
        return IValidator(LoyalKeyValidator).getLoyalKeyRank(user);
    }

    function getMarketplaceFee(address user) external view returns (uint256) {
        return IValidator(LoyalKeyValidator).getMarketplaceFee(user);
    }
}