/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT 
//https://api.binance.com/api/v3/ticker/price?symbol=BNBBUSD
 
pragma solidity ^0.8;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    
	function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
contract FLOKIDEXPLINKO is Claimable {

	using SafeMath for uint256;

    mapping (address => uint256) private results;

    uint256[]  rows_8 = [160,37,15,5,3,5,15,37,160];
    uint256[]  rows_12 = [220,42,30,20,14,6,3,6,14,20,30,42,220];
    uint256[]  rows_16 = [250,96,63,40,19,17,14,5,2,5,14,17,19,40,63,96,250];

    uint256 rows8Length = 9;
    uint256 rows12Length = 13;
    uint256 rows16Length = 17;

	constructor() payable{
		
	}

    function pliko_play(uint256 rowCount) public payable{
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp)))% (rowCount + 1);
        uint256 profitResult = 0;
        if (rowCount == 8){
            profitResult = rows_8[randomValue];
        }else if (rowCount == 12){
            profitResult = rows_12[randomValue];
        }else{
            profitResult = rows_16[randomValue];
        }
        uint256 refundValue = msg.value * profitResult / 10;
        payable(msg.sender).transfer (refundValue);
        results[msg.sender] = randomValue;
    }

    function getResult() public view returns (uint256){
        return results[msg.sender];
    }

    function withdrawETHs() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }

    receive() external payable {
    }

    fallback() external payable {
    }

}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}