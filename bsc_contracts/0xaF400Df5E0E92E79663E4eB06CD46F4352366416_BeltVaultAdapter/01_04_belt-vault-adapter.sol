// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../BaseAdapter.sol";

contract BeltVaultAdapter is BaseAdapter {
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /**
     * @notice Construct
     * @param _strategy  address of strategy
     * @param _stakingToken  address of staking token
     * @param _rewardToken  address of reward token
     * @param _repayToken  address of reward token
     * @param _name  adatper name
     */
    constructor(
        address _strategy,
        address _stakingToken,
        address _rewardToken,
        address _repayToken,
        string memory _name
    ) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        repayToken = _repayToken;
        strategy = _strategy;
        name = _name;
    }

    /**
     * @notice Get withdrwal amount
     * @param _user  user address
     * @param _nftId  nftId
     */
    function getWithdrawalAmount(address _user, uint256 _nftId)
        external
        view
        returns (uint256 amount)
    {
        amount = withdrawalAmount[_user][_nftId];
    }

    /**
     * @notice Get invest calldata
     * @param _amount  amount of invest
     */
    function getInvestCallData(uint256 _amount)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data
        )
    {
        to = strategy;
        value = stakingToken == WBNB ? _amount : 0;
        data = stakingToken == WBNB
            ? abi.encodeWithSignature("depositBNB(uint256)", 0)
            : abi.encodeWithSignature("deposit(uint256,uint256)", _amount, 0);
    }

    /**
     * @notice Get devest calldata
     * @param _amount  amount of devest
     */
    function getDevestCallData(uint256 _amount)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data
        )
    {
        to = strategy;
        value = 0;
        data = stakingToken == WBNB
            ? abi.encodeWithSignature(
                "withdrawBNB(uint256,uint256)",
                _amount,
                0
            )
            : abi.encodeWithSignature("withdraw(uint256,uint256)", _amount, 0);
    }

    /**
     * @notice Increase withdrwal amount
     * @param _user  user address
     * @param _nftId  nftId
     * @param _amount  amount of withdrawal
     */
    /// #if_succeeds {:msg "withdrawalAmount not increased"} withdrawalAmount[_user][_nftId] == old(withdrawalAmount[_user][_nftId]) + _amount;
    function increaseWithdrawalAmount(
        address _user,
        uint256 _nftId,
        uint256 _amount
    ) external onlyInvestor {
        withdrawalAmount[_user][_nftId] += _amount;
    }

    /**
     * @notice Set withdrwal amount
     * @param _user  user address
     * @param _nftId  nftId
     * @param _amount  amount of withdrawal
     */
    function setWithdrawalAmount(
        address _user,
        uint256 _nftId,
        uint256 _amount
    ) external onlyInvestor {
        withdrawalAmount[_user][_nftId] = _amount;
    }
}