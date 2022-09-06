// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeesCollector is Ownable {
    address public marketplace;

    enum COLLECTORTYPES {
        BUYBURN,
        BUYDISTRIBUTE,
        HEXMARKET,
        HEDRONFLOW,
        BONUS
    }

    struct FeesCollectors {
        address payable feeAddress;
        uint256 share;
        uint256 amount;
        uint256 enumId;
    }
    mapping(uint256 => FeesCollectors) public feeMap;

    /*
     *@notice Set Marketplace address.
     *@param _marketplace address
     */
    function setMarketAddress(address _marketplace) public onlyOwner {
        require(_marketplace != address(0), "Zero address is not allowed.");
        require(
            _marketplace != marketplace,
            "Cannot add the same address as marketplace"
        );

        marketplace = _marketplace;
    }

    /*
     *@notice Set Fee collector wallet details
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function setFees(
        COLLECTORTYPES feeType,
        address payable wallet,
        uint256 share
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");

        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            amount: 0,
            enumId: uint256(feeType)
        });
    }

    /*
     *@notice Update Fee collector wallet address and share
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function updateFees(
        COLLECTORTYPES feeType,
        address payable wallet,
        uint256 share
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");

        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            amount: feeMap[uint256(feeType)].amount,
            enumId: uint256(feeType)
        });
    }

    /*
     *@notice Assigns fees amount to fee collector structs
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function manageFees(uint256 value, uint256 addShare) external {
        require(msg.sender == marketplace, "Only marketplace are allowed");

        for (uint256 i = 0; i < 5; i++) {
            uint256 shareAmount = updateAmount(i, value, addShare);
            addShare = addShare - shareAmount;
        }
    }

    /*
     *@notice Update amount to fee collector structs used by manageFees function
     *@param  uint256 id, Index of COLLECTORTYPES
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function updateAmount(
        uint256 id,
        uint256 value,
        uint256 addShare
    ) internal returns (uint256) {
        uint256 shareAmount = (value * feeMap[id].share) / 1000000;
        if (shareAmount <= addShare) {
            feeMap[id].amount = feeMap[id].amount + shareAmount;
        } else {
            feeMap[id].amount = feeMap[id].amount + addShare;
        }

        return shareAmount;
    }

    /*
     @notice Claim Balance for the type of COLLECTORTYPES
     *@param  uint256 id, Index of COLLECTORTYPES
    */
    function claimBalances(uint256 id) internal {
        uint256 totalAmount = (feeMap[id].amount);
        require(
            totalAmount <= getBalance() && totalAmount > 0,
            "Not enough balance to claim"
        );

        feeMap[id].feeAddress.transfer(feeMap[id].amount);
        feeMap[id].amount = 0;
    }

    /*
     *@notice Claim Hexmarket amount
     */
    function claimHexmarket() external {
        uint256 id = uint256(COLLECTORTYPES.HEXMARKET);
        claimBalances(id);
        claimHedronFlow();
    }

    /*
     *@notice Claim Bonus amount
     */
    function claimBonus() external {
        uint256 id = uint256(COLLECTORTYPES.BONUS);
        claimBalances(id);
    }

    /*
     *@notice Claim HedronFlow amount
     */
    function claimHedronFlow() public {
        uint256 id = uint256(COLLECTORTYPES.HEDRONFLOW);
        claimBalances(id);
    }

    /*
     *@notice Claim Buy and Burn amount
     */
    function claimBuyBurn() external {
        uint256 id = uint256(COLLECTORTYPES.BUYBURN);
        claimBalances(id);
    }

    /*
     *@notice Claim Buy and distribute  amount.
     */
    function claimBuyDistribute() external {
        uint256 id = uint256(COLLECTORTYPES.BUYDISTRIBUTE);
        claimBalances(id);
    }

    /*
     *@notice  Get balance of this contract.
     *@return uint
     */
    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /*
     *  @notice Withdraw the extra eth available after distribution.
     */
    function withdrawDust() external onlyOwner {
        uint256 nonwithdrawableAmount;
        for (uint256 i = 0; i < 5; i++) {
            nonwithdrawableAmount += feeMap[i].amount;
        }

        uint256 withdrawableAmount = address(this).balance -
            nonwithdrawableAmount;
        require(withdrawableAmount > 0, "No extra ETH is available");
        payable(msg.sender).transfer(withdrawableAmount);
    }

    receive() external payable {}
}