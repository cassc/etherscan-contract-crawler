// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PGalaDistribution is Ownable{

    IERC20  public immutable PGala;


    uint public immutable galaOnPair; //BalanceOf(pair)
    uint public immutable lpOnPair; //lp token supply

    mapping (address=>uint) public distribution; //user => lp token (wallet with Masterchef)
    mapping (address=>bool) public withdrawn;

    uint public totalDistribution;
    uint public totalWithdrawn;

    event Withdrawn(address user, uint lpAmount);

    constructor(IERC20 _PGala, uint _galaOnPair, uint _lpOnPair){
        PGala = _PGala;
        galaOnPair = _galaOnPair;
        lpOnPair = _lpOnPair;

        require(lpOnPair > 0, "must be gt 0");
    }

    function galaValueOf(address user) public view returns(uint galaBalance, uint lpTokenBalance){
        galaBalance = galaOnPair * distribution[user] / lpOnPair;
        lpTokenBalance = distribution[user];
    }

    struct User {
        address userAddress;
        uint balance;
    }

    function bulkImportBalances(User[] calldata users) public onlyOwner{
        uint totalAddedDistributionValue;

        for (uint i = 0; i < users.length; i++){
            require(users[i].userAddress != address(0)  && users[i].balance > 0, "Wrong parameters");
            distribution[users[i].userAddress] =  users[i].balance;
            totalAddedDistributionValue += users[i].balance;
        }

        totalDistribution += totalAddedDistributionValue;
        require(totalDistribution <= galaOnPair, "Distributed more than available");
    }

    function withdraw() public {
        require(!withdrawn[msg.sender], "Already withdrawn");
        require(distribution[msg.sender] != 0, "Not distributed");
        withdrawn[msg.sender] = true;

        uint userBalance = distribution[msg.sender];
        distribution[msg.sender] = 0;

        uint galaValue = galaOnPair * userBalance / lpOnPair;

        totalWithdrawn += userBalance;

        PGala.transfer(msg.sender, galaValue);
        emit Withdrawn(msg.sender, userBalance);
    }

    function withdrawERC20(IERC20 token, uint amount) public onlyOwner{
        token.transfer(owner(), amount);
    }
}