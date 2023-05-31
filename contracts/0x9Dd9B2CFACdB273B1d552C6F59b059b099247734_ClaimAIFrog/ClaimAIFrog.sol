/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/

// SPDX-License-Identifier: MIT

/**
*   Twitter:@ai_porn_frog
*/



pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
}

contract ClaimAIFrog {
    mapping(address => bool) private whiteList;
    mapping(address=>uint) public getAmount ;
    uint public claimAmount ;
    address private admin ;
    uint public totalClaim ;
    uint private reduce ;
    address public TOKEN ;
    uint8 private decimals = 6 ;

    constructor(uint _claimAmount,uint _totalClaim,uint _reduce){
        claimAmount =_claimAmount * 10 ** decimals ;
        totalClaim = _totalClaim * 10 ** decimals ;
        reduce = _reduce * 10 ** decimals  ;
        admin = msg.sender ;
    }

    
    receive() external payable {
        require(!whiteList[msg.sender], "You have already in whitelist!");
        require(totalClaim >= claimAmount,"Finished Whitelist!!");
        whiteList[msg.sender] = true;
        getAmount[msg.sender] = claimAmount;
        totalClaim -= claimAmount ;
        if(claimAmount >reduce ) claimAmount -= reduce;
    }
    
    function IDO() public payable {
        uint _claim = _calIDO(msg.value) ;
        require(totalClaim >= _claim,"IDO Finished !!!");
        require(msg.value >= 0.01 ether,"No enough ether ....") ;
        getAmount[msg.sender] += getAmount[msg.sender] + _claim ;
        totalClaim -= _claim ;
    }

    function _calIDO(uint _value) internal view returns(uint){
        return _value / 0.01 ether * 10 * claimAmount ;
    }

    function claim() public {
        require(getAmount[msg.sender] > 0 , "You are not eligible or have already received it");
        bool success = IERC20(TOKEN).transfer(msg.sender,getAmount[msg.sender]);
        require(success,"transfer error~");
        getAmount[msg.sender] = 0 ;
    }

    modifier onlyEOA {
        require(!_isContract(msg.sender),"ONLY EOA ACCCOUNT");
        _;
    }

    function setTokenAddress(address _token) public onlyAdmin {
        TOKEN = _token ;
    }

    function setReduce(uint _reduce) public onlyAdmin {
        reduce = _reduce ;
    }

    function toPool(address _pool) public onlyAdmin{
        payable(_pool).transfer(address(this).balance);
    }

    modifier onlyAdmin {
        require(msg.sender == admin,"ONLY ADMIN ACCCOUNT");
        _;
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    } 
}