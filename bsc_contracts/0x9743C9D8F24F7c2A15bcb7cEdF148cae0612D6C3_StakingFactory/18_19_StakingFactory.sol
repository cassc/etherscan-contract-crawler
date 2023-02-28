// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../staking/MyStaking.sol";
import "../token/MyShare.sol";
import "../wrapper/MyWrapper.sol";


/**
 * @title The magical StakingFactory contract.
 * @author int(200/0), slidingpanda
 */
contract StakingFactory is Ownable {
    using SafeERC20 for IERC20;

    MyShare myShare;

    mapping(address => address) public pool;

    // bsc mainnet
    address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // bsc testnet
    // address constant public WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    constructor(address myShareAddr) {
        myShare = MyShare(myShareAddr);
    }

    /**
     * Creates a new staking pool if there is no "old" pool behind the lp token hash.
	 *
     * @param lpAddr address of the pair token (UniV2/V1)
     * @param owner_ address of the owner of the contract
     * @return stakingContract address of the new staking contract
     */
    function createNewStaking(address lpAddr, address owner_) external onlyOwner returns (address stakingContract) {
        require(pool[lpAddr] == address(0), "LP token already has a staking contract");

        stakingContract = _createStaking(lpAddr, owner_);
    }

    /**
     * Changes an existing staking contract to a new one and removes the old as a staker from the pool hashtable.
	 *
     * @notice - Should never be used because it also removes the possibility for stakers to withdraw claimable amounts (rather just deactivate the minter)
     *         - But if something went wrong at creating and no stakers are there, it possibly is a helpful function
	 *         - Also can be used if there is an old staking contract which is not used anymore
	 *
     * @param newLpAddr address of the old pair token (UniV2/V1)
     * @param oldLpAddr address of the new pair token (UniV2/V1)
     * @param owner_ address of the set owner of the contract
     * @return stakingContract address of the new staking contract
     */
    function changeStaking(address newLpAddr, address oldLpAddr, address owner_) external onlyOwner returns (address stakingContract) {
        myShare.removeMinter(pool[oldLpAddr]);
        _deleteStaking(oldLpAddr);

        stakingContract = _createStaking(newLpAddr, owner_);
    }

    /**
     * Creates a new staking pool.
     */
    function _createStaking(address lpAddr, address owner_) internal returns (address stakingContract) {
        MyStaking newPool = new MyStaking(address(myShare), lpAddr, owner_);

        address newPoolAddr = address(newPool);

        pool[lpAddr] = newPoolAddr;
        myShare.addMinter(newPoolAddr);
        stakingContract = newPoolAddr;
    }

    /**
     * Deletes a pool from the pool hashtable.
	 *
     * @param lpAddr address of the old pair token (UniV2/V1)
     */
    function _deleteStaking(address lpAddr) internal {
        pool[lpAddr] = address(0);
    }

    /**
     * Adds a minter.
	 *
     * @param newMinter address of the new minter (should be a staking contract)
     */
    function addMinter(address newMinter) external onlyOwner {
        myShare.addMinter(newMinter);
    }

    /**
     * Removing a minter.
	 *
     * @notice - If a minter is removed, it is losing the possibility to mint and every unminted emission
     *         - If it should not lose unminted emission (old staking pool which has stakers), deactivate the minter and remove it after all stakers left
	 *
     * @param toRemove address of the minter
     */
    function removeMinter(address toRemove) external onlyOwner {
        myShare.removeMinter(toRemove);
    }

    /**
     * Withdraws ERC20 tokens from the contract.
	 * This contract should not be the owner of any other token.
	 *
     * @param tokenAddr address of the IERC20 token
     * @param to address of the recipient
     */
    function withdrawERC(address tokenAddr, address to) external onlyOwner {
        IERC20(tokenAddr).safeTransfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {
        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }

}