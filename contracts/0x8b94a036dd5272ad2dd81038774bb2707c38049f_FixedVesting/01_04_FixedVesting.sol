// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TransferHelper.sol";
import "./IFixedCreator.sol";

contract FixedVesting{
    address public immutable creator = msg.sender;
    address public owner = tx.origin;

    bool private initialized;
    bool public isPaused;

    uint128 public vestingLength;
    uint128 public sold;
    
    address public token;

    address[] public buyers;

    struct Detail{
        uint128 datetime;
        uint128 ratio_d2;
    }

    struct Bought{
        uint128 buyerIndex;
        uint128 purchased;
        uint128 completed_d2; // in percent (2 decimal)
        uint128 claimed;
    }
    
    mapping(address => Bought) public invoice;
    mapping(uint128 => Detail) public vesting;
    
    modifier onlyOwner{
        require(msg.sender == owner, "!owner");
        _;
    }
    
    /**
     * @dev Initialize vesting token distribution
     * @param _token Token project address
     * @param _datetime Vesting datetime in epoch
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function initialize(
        address _token,
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) external {
        require(!initialized, "Initialized");
        require(msg.sender == creator, "!creator");

        _setToken(_token);
        _newVesting(_datetime, _ratio_d2);
        
        initialized = true;
    }

    /**
     * @dev Get length of buyer
     */
    function getBuyerLength() external view returns (uint){
        return buyers.length;
    }

    /**
     * @dev Get vesting runnning
     */
    function vestingRunning() public view returns(uint128 round, uint128 totalPercent_d2){
        uint128 vestingSize = vestingLength;
        uint128 total;
        for(uint128 i=1; i<=vestingSize; i++){
            Detail memory temp = vesting[i];
            total += temp.ratio_d2;
            
            if( (temp.datetime <= block.timestamp && block.timestamp <= vesting[i+1].datetime) ||
                (i == vestingSize && block.timestamp >= temp.datetime)
            ){
                round = i;
                totalPercent_d2 = total;
                break;
            }
        }
    }

    /**
     * @dev Token claim
     */
    function claimToken() external {
        (uint128 round, uint128 totalPercent_d2) = vestingRunning();
        Bought memory temp = invoice[msg.sender];

        require(!isPaused && round > 0 && token != address(0), "!started");
        require(temp.purchased > 0, "!buyer");
        require(temp.completed_d2 < totalPercent_d2, "claimed");
        
        uint128 amountToClaim;
        if(temp.completed_d2 == 0){
            amountToClaim = (temp.purchased * totalPercent_d2) / 10000;
        } else{
            amountToClaim = ((temp.claimed * totalPercent_d2) / temp.completed_d2) - temp.claimed;
        }

        require(IERC20(token).balanceOf(address(this)) >= amountToClaim && amountToClaim > 0, "insufficient");
        
        invoice[msg.sender].completed_d2 = totalPercent_d2;
        invoice[msg.sender].claimed = temp.claimed + amountToClaim;

        TransferHelper.safeTransfer(address(token), msg.sender, amountToClaim);        
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function _setToken(address _token) private {
        token = _token;
    }

    /**
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function _newVesting(
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) private {
        require(_datetime.length == _ratio_d2.length, "!good");

        uint128 vestingSize = vestingLength;
        for(uint128 i=0; i<_datetime.length; i++){
            if(i != _datetime.length-1) require(_datetime[i] < _datetime[i+1], "!good");
            vestingSize += 1;
            vesting[vestingSize] = Detail(_datetime[i], _ratio_d2[i]);
        }

        vestingLength = vestingSize;
    }

    /**
     * @dev Insert new buyers & purchases
     * @param _buyer Buyer address
     * @param _purchased Buyer purchase
     */
    function newBuyers(address[] calldata _buyer, uint128[] calldata _purchased) external onlyOwner {
        require(_buyer.length == _purchased.length, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            if(_buyer[i] == address(0) || _purchased[i] == 0) continue;

            Bought memory temp = invoice[_buyer[i]];

            if(temp.purchased == 0){
                buyers.push(_buyer[i]);
                invoice[_buyer[i]].buyerIndex = uint128(buyers.length - 1);
            }
            
            invoice[_buyer[i]].purchased = temp.purchased + _purchased[i];
            sold += _purchased[i];
        }
    }

    /**
     * @dev Replace buyers address
     * @param _oldBuyer Old address
     * @param _newBuyer New purchase
     */
    function replaceBuyers(address[] calldata _oldBuyer, address[] calldata _newBuyer) external onlyOwner {
        require(_oldBuyer.length == _newBuyer.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_oldBuyer.length; i++){
            Bought memory temp = invoice[_oldBuyer[i]];

            if( temp.purchased == 0 ||
                _oldBuyer[i] == address(0) ||
                _newBuyer[i] == address(0)
            ) continue;

            buyers[temp.buyerIndex] = _newBuyer[i];

            invoice[_newBuyer[i]] = temp;

            delete invoice[_oldBuyer[i]];
        }
    }

    /**
     * @dev Remove buyers
     * @param _buyer Buyer address
     */
    function removeBuyers(address[] calldata _buyer) external onlyOwner {
        require(buyers.length > 0, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            Bought memory temp = invoice[_buyer[i]];

            if(temp.purchased == 0 || _buyer[i] == address(0)) continue;

            sold -= temp.purchased;

            address addressToMove = buyers[buyers.length-1];
            
            buyers[temp.buyerIndex] = addressToMove;
            invoice[addressToMove].buyerIndex = temp.buyerIndex;

            buyers.pop();
            delete invoice[_buyer[i]];
        }
    }
    
    /**
     * @dev Replace buyers purchase
     * @param _buyer Buyer address
     * @param _newPurchased new purchased
     */
    function replacePurchases(address[] calldata _buyer, uint128[] calldata _newPurchased) external onlyOwner {
        require(_buyer.length == _newPurchased.length && buyers.length > 0, "!good");

        for(uint16 i=0; i<_buyer.length; i++){
            Bought memory temp = invoice[_buyer[i]];

            if( temp.purchased == 0 ||
                temp.completed_d2 > 0 ||
                _buyer[i] == address(0) ||
                _newPurchased[i] == 0) continue;
            
            sold = sold - temp.purchased + _newPurchased[i];
            invoice[_buyer[i]].purchased = _newPurchased[i];
        }
    }

    /**
     * @dev Update vestings datetime
     * @param _vestingRound Vesting round
     * @param _newDatetime new datetime in epoch
     */
    function updateVestingDatetimes(uint128[] calldata _vestingRound, uint128[] calldata _newDatetime) external onlyOwner {
        require(_vestingRound.length == _newDatetime.length, "!good");

        (uint128 round, ) = vestingRunning();
        uint128 vestingSize = vestingLength;

        for(uint128 i=0; i<_vestingRound.length; i++){
            if( _vestingRound[i] > vestingSize ||
                round >= _vestingRound[i]) continue;

            vesting[_vestingRound[i]].datetime = _newDatetime[i];
        }
    }

    /**
     * @dev Update vestings ratio
     * @param _vestingRound Vesting round
     * @param _newRatio_d2 New ratio in percent (decimal 2)
     */
    function updateVestingRatios(uint128[] calldata _vestingRound, uint128[] calldata _newRatio_d2) external onlyOwner {
        require(_vestingRound.length == _newRatio_d2.length, "!good");

        (uint128 round, ) = vestingRunning();
        uint128 vestingSize = vestingLength;

        for(uint128 i=0; i<_vestingRound.length; i++){
            if(_vestingRound[i] > vestingSize ||
                round >= _vestingRound[i]) continue;

            vesting[_vestingRound[i]].ratio_d2 = _newRatio_d2[i];
        }
    }

    /**
     * @dev Insert new vestings
     * @param _datetime Vesting datetime
     * @param _ratio_d2 Vesting ratio in percent (decimal 2)
     */
    function newVesting(
        uint128[] calldata _datetime,
        uint128[] calldata _ratio_d2
    ) external onlyOwner {
        _newVesting(_datetime, _ratio_d2);
    }

    /**
     * @dev Remove last vesting round
     */
    function removeLastVestingRound() external onlyOwner {
        uint128 vestingSizeTarget = vestingLength-1;

        delete vesting[vestingSizeTarget];

        vestingLength = vestingSizeTarget;
    }

    /**
     * @dev Emergency condition to withdraw token
     * @param _target Target address
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address _target, uint128 _amount) external onlyOwner {
        require(_target != address(0), "!good");
        
        uint128 contractBalance = uint128(IERC20(token).balanceOf(address(this)));
        if(_amount > contractBalance) _amount = contractBalance;

        TransferHelper.safeTransfer(address(token), _target, _amount);
    }

    /**
     * @dev Set token project
     * @param _token Token project address
     */
    function setToken(address _token) external onlyOwner {
        _setToken(_token);
    }
    
    /**
     * @dev Pause vesting activity
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "!good");
        owner = _newOwner;
    }
}