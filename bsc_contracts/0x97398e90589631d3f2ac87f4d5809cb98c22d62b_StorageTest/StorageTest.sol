/**
 *Submitted for verification at BscScan.com on 2023-01-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract StorageTest {

    uint256 number;
	
	
	event Add(uint256 _num);
	event Sub(uint256 _num);
	event Mul(uint256 _num);

    function store(uint256 num) public {
        number = num;
    }

    function add(uint256 num) public {
        number += num;
		emit Add(num);
    }

    function sub(uint256 num) public {
        number -= num;
		emit Sub(num);
    }

    function mul(uint256 num) public {
        number *= num;
		emit Mul(num);
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}