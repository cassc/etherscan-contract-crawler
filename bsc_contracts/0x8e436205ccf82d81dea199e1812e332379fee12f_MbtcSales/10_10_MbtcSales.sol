// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IMbtcSales.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MbtcSales is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IMbtcSales {
	uint256 public constant MAX_DECIMALS = 18;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
	IERC20Upgradeable public sellToken; //mbtc's decimals is 18
	uint256 public sellPrice; 
	uint256 public startTime;
	uint256 public endTime;
	address public beneficiary;
	
	struct buyWithStruct {
		IERC20Upgradeable buyToken;
		uint256 decimals;
	}
	
	buyWithStruct[] public buyWiths;
	
    function initialize(IERC20Upgradeable _sellToken, uint256 _startTime, uint256 _endTime, IERC20Upgradeable[] calldata _buyWiths, uint256[] calldata decimals, address _beneficiary) public initializer {
        __Ownable_init();
		__ReentrancyGuard_init();
		
        require(_endTime > _startTime, "Invalid time");
		require(_buyWiths.length == decimals.length, "invalid accept buy tokens");
        
		sellToken = _sellToken;
        startTime = _startTime;
        endTime = _endTime;
        sellPrice = 0.008 ether; //to wei, this actually means 0.008 usd
		
		for(uint256 i=0; i < _buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			buyWiths.push( buyWithStruct(_buyWiths[i], decimals[i]) );
		}
		
		beneficiary = _beneficiary;
    }
	
	function buy(IERC20Upgradeable buyWith, uint256 amount) public nonReentrant {
		IERC20Upgradeable selectedToken;
		uint256 selectedDecimals;
		
		require(amount >= 1 ether /*1 mbtc*/, "min amount required");
		require(sellToken.balanceOf(address(this)) >= amount, "insufficient sell token");
		require(buyWith != IERC20Upgradeable(address(0)), "invalid buy token");
		require(block.timestamp > startTime && block.timestamp <= endTime, "sales not active");
		
		for(uint256 i=0; i < buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			if (buyWiths[i].buyToken == buyWith) {
				selectedToken = buyWiths[i].buyToken;
				selectedDecimals = buyWiths[i].decimals;
				break;
			}
		}
		
		require(selectedToken != IERC20Upgradeable(address(0)), "buy token not found");
		
		//(amount * sellPrice) / 10 ** MAX_DECIMALS = total price
		//(10 ** (MAX_DECIMALS - selectedDecimals)) = convert from 18 decimals to decimals of selectedDecimals
		uint256 reqTokenAmount = (amount * sellPrice) / 10 ** MAX_DECIMALS / (10 ** (MAX_DECIMALS - selectedDecimals));
		
		//must check because erc20 transfer accept amount is 0!
		//say usdt's decimals is 6, the lowest value would be 0.000001. 
		//if sell price is 0.0000001 then error below will be trigger
		require(reqTokenAmount > 0, "precision error");
		
		//and since compilerV8 protects us from integer overflow/underflow, so do not worry much about that!
		selectedToken.safeTransferFrom(msg.sender, beneficiary, reqTokenAmount);
		
		sellToken.safeTransfer(msg.sender, amount);
	}
	
	function setBeneficiary(address payable _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }
	
	function acceptBuyTokens(IERC20Upgradeable[] calldata _buyWiths, uint256[] calldata decimals) public onlyOwner {
		require(_buyWiths.length == decimals.length, "invalid accept buy tokens");
		
		delete buyWiths;
		
		for(uint256 i=0; i < _buyWiths.length; i++) { //is ok, buyWiths array wont bloat big
			buyWiths.push( buyWithStruct(_buyWiths[i], decimals[i]) );
		}
	}
	
	function setSalesPeriod(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_endTime > _startTime, "invalid time");
        startTime = _startTime;
        endTime = _endTime;
    }
	
	function setSellPrice(uint256 _sellPrice) public onlyOwner {
        sellPrice = _sellPrice;
    }
	
	function emergencyCollectToken(address token, uint amount) public onlyOwner {
        IERC20Upgradeable(token).transfer(owner(), amount);
    }
	
	function getSellPrice() external view returns (uint256) {
		return sellPrice;
	}
	
	function version() public pure returns (string memory) {
		return "1.0";
	}
	
	receive() external payable{
		revert();
	}
	
	fallback() external payable{
		revert();
	}

}