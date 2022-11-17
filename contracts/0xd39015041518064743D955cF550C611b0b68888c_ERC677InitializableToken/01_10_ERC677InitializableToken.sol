pragma solidity 0.4.24;

import "openzeppelin-eth/contracts/token/ERC20/ERC20Burnable.sol";
//import "openzeppelin-eth/contracts/token/ERC20/ERC20Mintable.sol";
import "./ERC20Mintable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
//import "openzeppelin-eth/contracts/ownership/Ownerable.sol";
import "zos-lib/contracts/Initializable.sol";
import "./ERC677Receiver.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";

contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    function transferAndCall(address, uint, bytes) external returns (bool);


}


contract ERC677InitializableToken is
    ERC677,
    ERC20Detailed,
    ERC20Burnable,
    ERC20Mintable {

    event ContractFallbackCallFailed(address from, address to, uint value);

    address public bridgeContract;

    uint256 lastFundingPeriod = 0;
    uint256 totalPeriodFundedAmount = 0;

    FundingRules fundingRules;

    struct FundingRules {
        uint256 periodLength; // refresh period for next funding round in blocks
        uint256 maxPeriodFunds; // max amount to fund in a period
        uint256 threshold; // amount below which a funding event happens
        uint256 amount; // amount to fund
    }

    function initialize(string _name, string _symbol, uint8 _decimals, address _owner) external initializer {
        ERC20Mintable.initialize(_owner);
        ERC20Detailed.initialize(_name, _symbol, _decimals);
    }


    function () payable {}

    function setFundingRules(uint256 _periodLength, uint256 _maxPeriodFunds, uint256 _threshold, uint256 _amount) onlyOwner public {
        fundingRules.periodLength = _periodLength;
        fundingRules.maxPeriodFunds = _maxPeriodFunds;
        fundingRules.threshold = _threshold;
        fundingRules.amount = _amount;
    }

    function getFundingRules() public view returns(uint256, uint256, uint256, uint256){
        return (fundingRules.periodLength,
        fundingRules.maxPeriodFunds,
        fundingRules.threshold,
        fundingRules.amount);
    }

    function fundReceiver(address _to) internal {
        // reset funding period
        if(block.number > fundingRules.periodLength + lastFundingPeriod) {
            lastFundingPeriod = block.number;
            totalPeriodFundedAmount = 0;
        }
        // transfer receiver money only if limits are not met and they are below the threshold
        if(address(_to).balance < fundingRules.threshold && fundingRules.amount + totalPeriodFundedAmount <= fundingRules.maxPeriodFunds) {
            if(address(_to).send(fundingRules.amount)){
                totalPeriodFundedAmount += fundingRules.amount;
            }
        }
    }

    function setBridgeContract(address _bridgeContract) onlyOwner public {
        require(_bridgeContract != address(0) && isContract(_bridgeContract));
        bridgeContract = _bridgeContract;
    }

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }

    function transferAndCall(address _to, uint _value, bytes _data)
        external validRecipient(_to) returns (bool)
    {
        require(superTransfer(_to, _value));
        fundReceiver(_to);
        emit Transfer(msg.sender, _to, _value, _data);

        if (isContract(_to)) {
            require(contractFallback(_to, _value, _data));
        }
        return true;
    }

    function getTokenInterfacesVersion() public pure returns(uint64 major, uint64 minor, uint64 patch) {
        return (2, 0, 0);
    }

    function superTransfer(address _to, uint256 _value) internal returns(bool)
    {
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool)
    {
        require(superTransfer(_to, _value), "failed superTransfer");
        fundReceiver(_to);
        if (isContract(_to) && !contractFallback(_to, _value, new bytes(0))) {
            if (_to == bridgeContract) {
                revert("reverted here");
            } else {
                emit ContractFallbackCallFailed(msg.sender, _to, _value);
            }
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes _data)
        private
        returns(bool)
    {
        return _to.call(abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)",  msg.sender, _value, _data));
    }

    function isContract(address _addr)
        private
        view
        returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    function mint(
        address _to,
        uint256 _amount
    )
    public
    hasMintPermission
    returns (bool)
    {
        fundReceiver(_to);
        return super.mint(_to, _amount);
    }

    function finishMinting() public returns (bool) {
        revert();
    }

    function renounceOwnership() public onlyOwner {
        revert();
    }

    function claimTokens(address _token, address _to) public onlyOwner {
        require(_to != address(0));
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20Detailed token = ERC20Detailed(_token);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_to, balance));
    }

}