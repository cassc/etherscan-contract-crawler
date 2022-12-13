// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;


import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/ICampaignFactory.sol";


contract CampaignFactory is OwnableUpgradeable {
    event CampaignImplementationUpdated(address newImplementation);
    event FeeUpdated(uint16 new_fee);
    event RouterUpdated(ICampaign.Dex dex, address new_router);
    event NewCampaign(uint256 indexed id, address indexed creator, address indexed campaign);

    address public campaignImplementation;
    mapping (uint256 => address) public campaigns;
    mapping (ICampaign.Dex => address) public routers;
    uint16 constant MAX_PERCENT = 10000;
    uint16 public fee; // 5%, 10000 = 100%

    function initialize(address _owner, address _campaignImplementation, uint16 _fee) external initializer {
        _transferOwnership(_owner);
        _updateCampaignImplementation(_campaignImplementation);
        fee = _fee;
    }

    function updateCampaignImplementation(address newImplementation) external onlyOwner {
        _updateCampaignImplementation(newImplementation);
    }

    function _updateCampaignImplementation(address newImplementation) internal {
        campaignImplementation = newImplementation;
        emit CampaignImplementationUpdated(newImplementation);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setFee(uint16 new_fee) external onlyOwner {
        require (new_fee <= MAX_PERCENT, "CampaignFactory::setFee: bad fee");

        fee = new_fee;
        emit FeeUpdated(new_fee);
    }

    function setRouter(ICampaign.Dex dex, address new_router) external onlyOwner {
        routers[dex] = new_router;
        emit RouterUpdated(dex, new_router);
    }

    function getCampaignList(uint256[] memory ids) public view returns (
        address[] memory _campaigns, uint256[] memory _raised
    ) {
        _campaigns = new address[](ids.length);
        _raised = new uint256[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            _campaigns[i] = campaigns[ids[i]];
            if (_campaigns[i] != address(0)) {
                _raised[i] = ICampaign(_campaigns[i]).raised();
            }
        }
    }

    function _initCampaign(uint256 id, address _owner, ICampaign.Config calldata config) internal {
        require (campaigns[id] == address(0), "CampaignFactory::createCampaign: id is already used");
        require (config.start > block.timestamp, "CampaignFactory::createCampaign: start should be in future");
        require (config.start < config.end, "CampaignFactory::createCampaign: start stime should be less than end time");
        require (config.minPurchaseBnb < config.maxPurchaseBnb, "CampaignFactory::createCampaign: minPurchase should be less than maxPurchase");
        require (config.liquidityTokens > 0 && config.presaleTokens > 0, "CampaignFactory::createCampaign: token amounts should be positive");
        require (config.tokensPerBnb > 0, "CampaignFactory::createCampaign: rate should be positive");
        require (config.liquidityPercent < MAX_PERCENT, "CampaignFactory::createCampaign: liquidityPercent should be less than 10000");
        require (config.softCap < (config.presaleTokens * 10**18) / config.tokensPerBnb, "CampaignFactory::createCampaign: softCap should be less then hardCap");
        require (routers[config.dex] != address(0), "CampaignFactory::createCampaign: router not set for dex");

        address new_campaign = ClonesUpgradeable.clone(campaignImplementation);
        ICampaign(new_campaign).initialize(_owner, fee, routers[config.dex], config);

        campaigns[id] = new_campaign;

        emit NewCampaign(id, _owner, new_campaign);
    }

    function createCampaign(uint256 id, ICampaign.Config calldata config) external {
        _initCampaign(id, msg.sender, config);
    }

    function createCampaignWithOwner(uint256 id, address _owner, ICampaign.Config calldata config) external {
        _initCampaign(id, _owner, config);
    }

    receive() external payable {}
}