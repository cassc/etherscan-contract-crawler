// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BLBIOAdministration is Ownable {

    uint256 public publicBLBsPerUSD;  //how much BLBs is earned for 1 USD in retail purchase.
    uint256 public privateBLBsPerUSD; //how much BLBs is earned for 1 USD in bulk purchase.
    uint256 public retailLimit;       //amount of USD paid in which the token amount increases from retail to bulk.
    uint256 public minUSDLimit;       //amount of USD paid in which the token amount increases from retail to bulk.
    uint256 public claimableFraction; //fraction of purchased token that users can claim for now.
    uint256 public TotalClaimable;    //amount of token that users purchased in total and sould be awailable in contract to be claimed.

    IERC20 public BLB;  // the contract address of blb token.
    IERC20 public BUSD; // the contract address of BUSD token.

    /**
     * @dev emits when the owner sets new prices for private and public blb sale.
     */
    event SetBLBsPerUSD(uint256 indexed publicBLBsAmount, uint256 indexed privateBLBsAmount);

    /**
     * @dev emits when the owner sets a new retail limit.
     */
    event SetRetailLimit(uint256 indexed _retailLimit);

    /**
     * @dev emits when the owner sets a new min USD limit.
     */
    event SetMinUSDLimit(uint256 indexed _minAmountUSD);

    /**
     * @dev emits when the owner withdraws any amount of BNB or ERC20 token.
     */
    event Withdraw(string indexed tokenName, uint256 amount);

    /**
     * @return balance BLB in this contract.
     */
    function blbBalance() public view returns(uint256) {
        return BLB.balanceOf(address(this));
    }

    /**
     * @return balance BUSD in this contract.
     */
    function busdBalance() public view returns(uint256) {
        return BUSD.balanceOf(address(this));
    }

    /**
     * @return balance BNB in this contract.
     */
    function bnbBalance() public view returns(uint256) {
        return address(this).balance;
    }


//------------------------------------------------------------------------------------

    /**
     * @dev increase the fraction of BLB tokens which users can claim now;
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *   - the maximum fraction can be 1,000,000 which means 100% of the tokens 
     *      user puchased.
     */
    function increaseClaimableFraction(uint256 fraction) public onlyOwner {
        claimableFraction += fraction;

        require(
            claimableFraction <= 1000000, 
            "BLBIOAdministration: fraction exceeds 10^6"
        );
    }

    /**
     * @dev set minimum USD limit;
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetMinUSDLimit event
     */
    function setMinUSDLimit(uint256 amountUSD) public onlyOwner {
        minUSDLimit = amountUSD;
        emit SetMinUSDLimit(amountUSD);
    }

    /**
     * @dev set retail limit;
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetRetailLimit event
     */
    function setRetailLimit(uint256 amountUSD) public onlyOwner {
        retailLimit = amountUSD;
        emit SetRetailLimit(amountUSD);
    }

    /**
     * @dev set ticket price in USD for public sale and private sale;
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a SetBLBsPerUSD event
     */
    function setBLBsPerUSD(
        uint256 publiceBLBsAmount,
        uint256 privateBLBsAmount
    ) public onlyOwner {
        require(
            publiceBLBsAmount <= privateBLBsAmount, 
            "BLBIOAdministration: private amount must be greater than or equal to public amount"
        );
        publicBLBsPerUSD = publiceBLBsAmount;
        privateBLBsPerUSD = privateBLBsAmount;
        emit SetBLBsPerUSD(publiceBLBsAmount, privateBLBsAmount);
    }

//------------------------------------------------------------------------------------

    /**
     * @dev withdraw BLB tokens from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdrawBLB(uint256 amount) public onlyOwner {
        BLB.transfer(owner(), amount);
        emit Withdraw("BLB", amount);
    }

    /**
     * @dev withdraw BUSD tokens from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdrawBUSD(uint256 amount) public onlyOwner {
        BUSD.transfer(owner(), amount);
        emit Withdraw("BUSD", amount);
    }

    /**
     * @dev withdraw BNB from the contract.
     *
     * @notice requirement:
     *   - only owner of the contract can call this function.
     *
     * @notice emits a Withdraw event
     */
    function withdrawBNB(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
        emit Withdraw("BNB", amount);
    }
}