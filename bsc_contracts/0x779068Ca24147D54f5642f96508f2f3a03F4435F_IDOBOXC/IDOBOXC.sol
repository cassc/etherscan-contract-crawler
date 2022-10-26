/**
 *Submitted for verification at BscScan.com on 2022-10-25
*/

pragma solidity ^0.4.18;

contract IDOBOXC {
    address public team=0xA9035E491cC1af6f9c0F71c0Fb9d72Fe1812ed24;
    address public project=0xD034D00790F72a46EcE08581e05Aa7dF30bbC069;
    function() public payable {
        require(msg.value == 2 ether,"Must be 2BNB");
        distribution();
    }
    function distribution() public {
        uint256 _bnb=address(this).balance;
        uint256 senBnb=_bnb / 2;
        team.transfer(senBnb);
        project.transfer(senBnb);    
    }
}