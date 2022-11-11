// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./external/gelato/OpsReady.sol";
import "./interfaces/ISweepersAuctionHouse.sol";

contract SweepersSettler is Ownable, OpsReady {

	ISweepersAuctionHouse public AuctionHouse;
	bytes32 public currentTaskId;
	uint256 public currentFee;
    uint256 public maxGWEI;
    bool public automating;

	constructor (address payable _ops, ISweepersAuctionHouse _auctionHouse, uint256 _gas) OpsReady(_ops) {
		AuctionHouse = _auctionHouse;
        maxGWEI = _gas;
	}

    function setMaxGWEI(uint256 _gas) external onlyOwner {
        maxGWEI = _gas;
    }

    function setAuctionHouse(ISweepersAuctionHouse _auctionHouse) external onlyOwner {
        AuctionHouse = _auctionHouse;
    }

	function enableAutoSettlement() external onlyOwner {
		currentTaskId = IOps(ops).createTaskNoPrepayment(
            address(this), 
            this.settleAuction.selector,
            address(this),
            abi.encodeWithSelector(this.canSettleAuction.selector),
            ETH
        );
        automating = true;
	}

	function disableAutoSettlement() external onlyOwner {
		IOps(ops).cancelTask(currentTaskId);
		automating = false;
	}

    function canSettleAuction() external view returns (bool canExec, bytes memory execPayload) {
        (uint256 _startTime, uint256 _endTime, address _bidder, bool _settled) = AuctionHouse.auctionInfo();

        if(_bidder == address(0)) return (false, bytes("No bidder"));
        if(_startTime == 0) return (false, bytes("Auction has not started"));
        if(_settled) return (false, bytes("Auction already settled"));
        if(block.timestamp < _endTime) return (false, bytes("Auction has not ended"));

        
        execPayload = abi.encodeWithSelector(
            this.settleAuction.selector
        );
        return(true, execPayload);
    }

    function settleAuction() external onlyOps {
        require(tx.gasprice < maxGWEI, "Current gas too high");
		(uint256 fee, address feeToken) = IOps(ops).getFeeDetails();
		currentFee = fee;
		AuctionHouse.settleCurrentAndCreateNewAuction();
		_transfer(fee, feeToken);
	}

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}