// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Campaign.sol";

// import hardhat console
// import "../node_modules/hardhat/console.sol";

contract CampaignFactory {
    address payable public immutable owner;
    mapping(string => address) public campaigns;

    // in US cents
    uint256 private deposit = 33300;

    // in US cents
    uint256 private fee = 0;

    constructor() {
        owner = payable(msg.sender);
    }

    event campaignCreated(address campaignContractAddress);

    function createCampaign(
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(
            campaigns[_campaignId] == address(0),
            "Campaign with this id already exists"
        );

        bytes32 message = hashMessage(
            msg.sender,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to create a campaign"
        );

        Campaign c = new Campaign(
            owner,
            msg.sender,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed,
            deposit,
            fee
        );

        campaigns[_campaignId] = address(c);
        emit campaignCreated(address(c));
    }

    function setDepositAmount(uint256 _deposit) public {
        require(msg.sender == owner, "Only owner can set deposit amount");
        deposit = _deposit;
    }

    function getDepositAmount() public view returns (uint256) {
        return deposit;
    }

    function setFeeAmount(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee amount");
        fee = _fee;
    }

    function getFeeAmount() public view returns (uint256) {
        return fee;
    }

    function hashMessage(
        address _campaignOwner,
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed
    ) public view returns (bytes32) {
        bytes memory pack = abi.encodePacked(
            this,
            _campaignOwner,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );
        return keccak256(pack);
    }

    function getCampaignContractAddress(string memory _campaignId)
        public
        view
        returns (address)
    {
        return campaigns[_campaignId];
    }
}