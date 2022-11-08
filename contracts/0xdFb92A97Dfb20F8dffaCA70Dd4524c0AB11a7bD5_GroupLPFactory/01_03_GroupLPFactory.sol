pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IGroupLP {
  function initialize(address _pair, address _tokenSupplier, uint256 _goalDate, uint256 _withdrawalsLockedUntilTimestamp, uint256 _commitment) external payable;
}

contract GroupLPFactory {
    event GroupLPCampaignCreated(address indexed campaign);
    address lpCampaignContract;
    address owner;

    constructor(address _lpCampaignContractAddress) {
        lpCampaignContract = _lpCampaignContractAddress;
        owner = msg.sender;
    }

    function createLPCampaign(address _tokenSupplier, address _pair, uint256 _goalDate, uint256 _withdrawalsLockedDuration, uint256 _commitment) public payable returns (address new_lpCampaign) {
        require(msg.sender == owner);
        new_lpCampaign = Clones.clone(lpCampaignContract);
        IGroupLP(new_lpCampaign).initialize{value: msg.value}(_pair, _tokenSupplier, _goalDate, _withdrawalsLockedDuration, _commitment);
        emit GroupLPCampaignCreated(new_lpCampaign);
    }
}