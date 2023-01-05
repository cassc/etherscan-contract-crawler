// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Campaign.sol";
import "./CampaignManager.sol";
import "./JumpStartLib.sol";

contract CampaignFactory is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event CampaignCreated(address campaign, string campaignId);

    CampaignManager public _manager;
    address _jumpStartFeeCollector;
    mapping(string => bool) public isExisting;

    constructor() {
        _jumpStartFeeCollector = msg.sender;
    }

    function setManager(address _newManager) external onlyOwner {
        _manager = CampaignManager(_newManager);
    }

    function setManagerValues(
        uint256 _feeDiscount1, // hc discount
        uint256 _feeDiscount2, // softCap 75% discount
        uint256 _feeDiscount3, // softCap 50% discount
        uint256 _sidekickDiscount, // token raised in sidekick discount
        uint256 _campaignFee,
        uint256 _createFee,
        address payable _newFeecollector
    ) external onlyOwner {
        _manager.setValues(
            _feeDiscount1,
            _feeDiscount2,
            _feeDiscount3,
            _sidekickDiscount,
            _campaignFee,
            _createFee,
            _newFeecollector
        );
    }

    function setJumpStartFeeCollector(address _newFeeCollector)
        external
        onlyOwner
    {
        _jumpStartFeeCollector = _newFeeCollector;
    }

    function createCampaign(
        // [0] = startDate, [1] = endDate, [2] = softCap,
        // [3] = hardCap, [4] = priceDiscount, [5] = priceDiscountEndDate, [6] = royaltyFee
        uint256[7] memory _settings,
        // [0] = campaignId, [1] = mintType
        string[2] memory _stringSettings,
        // [0] = mintToken, [1] = implementation, [2] = jsImplementation, [3] = royaltyReceiver,
        // [4] = payToken [5] = eliteTokenDistributorImplementation
        address[6] memory _addresses,
        bool[2] memory _boolSettings, // [0] = whitelistEnabled, [1] = createEliteTokenDistributor
        JumpStartLib.MintNft[] memory _nftTiers
    ) external {
        require(
            isExisting[_stringSettings[0]] == false,
            "Campaign already exists"
        );

        for(uint256 i = 0; i < _nftTiers.length; i++){
            if(_nftTiers[i].ticket.quantity > 0){
                require(_nftTiers[i].ticketsPerMint > 0, "Ticket found, ticketsPerMint must be > 0");
            }
        }
        

        (uint256 actualCreationFee, uint256 actualCampaignFee) = _manager
            .calculateFees(_settings[2], _settings[3], _addresses[0], _boolSettings[1]);
        
        require(_manager._pay(msg.sender, actualCreationFee, _addresses[4]), "Must pay fee");

        address campaignClone = Clones.clone(_addresses[1]);
        _manager.pushCampaign(campaignClone);

        Campaign campaignContract = Campaign(campaignClone);

        campaignContract.initialize(
            [
                msg.sender,
                _addresses[0],
                _addresses[2],
                _addresses[3],
                address(_manager),
                _jumpStartFeeCollector,
                _addresses[5] // eliteTokenDistributorImplementation
            ],
            _settings,
            [
                _boolSettings[0], // whitelistEnabled
                _boolSettings[1] // createEliteTokenDistributor
            ],            
            _stringSettings,
            _nftTiers,
            actualCampaignFee
        );

        isExisting[_stringSettings[0]] = true;

        emit CampaignCreated(campaignClone, _stringSettings[0]);
    }

    function loadCampaigns(address[] memory _campaigns) external onlyOwner {
        for (uint256 i = 0; i < _campaigns.length; i++) {
            _manager.pushCampaign(_campaigns[i]);
        }
    }

    function transferManagerOwnership(address _newOwner) external onlyOwner {
        _manager.transferOwnership(_newOwner);
    }

    function setCampaignCreationToken(address _newToken, bool _active) external onlyOwner {
        _manager.setCampaignCreationToken(_newToken, _active);
    }
}