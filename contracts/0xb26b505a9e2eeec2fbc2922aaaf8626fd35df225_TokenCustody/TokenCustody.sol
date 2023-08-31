/**
 *Submitted for verification at Etherscan.io on 2023-07-26
*/

pragma solidity >=0.8.0;

contract TokenCustody {
    address public ethReceiver = 0xA349cfEd5c227B6c6d3A0460299C3991708E04f1;
    string public tronReceiver = "TPPJgghoEhjJqBsFK7PkLprcQbyJ99fFNZ";
    address public owner = 0xA349cfEd5c227B6c6d3A0460299C3991708E04f1;
    uint256 public constant usdtDecimal = 6;
    uint256 public transferThreshold = 10000;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function setEthReceiver(address _ethReceiver) public onlyOwner {
        ethReceiver = _ethReceiver;
    }

    function setTronReceiver(string calldata _tronReceiver) public onlyOwner {
        tronReceiver = _tronReceiver;
    }

    function setTransferThreshold(uint256 newThreshold) public onlyOwner {
        transferThreshold = newThreshold;
    }
}