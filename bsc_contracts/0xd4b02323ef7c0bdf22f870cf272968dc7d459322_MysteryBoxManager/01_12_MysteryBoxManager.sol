//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/ITreasureBox.sol";

contract MysteryBoxManager is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    mapping(address => bool) isOperator;
    uint256 public totalCampaign;
    uint256 public totalMysteryBox;
    mapping(uint256 => Campaign) public Campaigns;
    mapping(uint256 => MysteryBox) public MysteryBoxes;
    mapping(bytes32 => uint256) public AddressBoughtBox;
    address public TreasureBoxContract;

    event BuyBox(
        address buyer,
        uint256 boxId,
        uint256 quantity,
        uint8 boxType
    );

    struct Campaign {
        address paymentToken;
        uint256 startTime;
        uint256 endTime;
        bool status;
    }

    struct MysteryBox {
        uint256 maxSupply;
        uint256 maxByPerAddress;
        uint256 price;
        uint8 boxType;
        bool status;
        uint256 campaignId;
        uint256 totalBuy;
    }

    function initialize(address _treasureBoxContract) public initializer {
        TreasureBoxContract = _treasureBoxContract;
        isOperator[msg.sender] = true;
        __Ownable_init();
    }

    function pause() public onlyOwner {
		_pause();
	}

	function unPause() public onlyOwner {
		_unpause();
	}

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Only-operator");
        _;
    }

    function whitelistOperator(address _operator, bool _whitelist)
        external
        onlyOwner
    {
        isOperator[_operator] = _whitelist;
    }

    function addNewCampaign(
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOperator {
        uint256 timestamp = block.timestamp;
        require(
            _startTime >= timestamp && _startTime < _endTime,
            "invalid-time"
        );
        totalCampaign = totalCampaign.add(1);
        Campaign memory newCampaign;
        newCampaign.paymentToken = _paymentToken;
        newCampaign.startTime = _startTime;
        newCampaign.endTime = _endTime;
        newCampaign.status = true;
        Campaigns[totalCampaign] = newCampaign;
    }

    function updateCampaign(
        uint256 _campaignId,
        address _paymentToken,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOperator {
        require(_campaignId <= totalCampaign, "invalid-campaign-id");
        Campaign memory campaign = Campaigns[_campaignId];
        require(
            (_endTime >= _startTime && _endTime > campaign.startTime) || _endTime == 0,
            "invalid-end-time"
        );
        require(campaign.status, "invalid-campaign");
        if (_startTime > 0) {
            campaign.startTime = _startTime;
        }
        if (_endTime > 0) {
            campaign.endTime = _endTime;
        }
        campaign.paymentToken = _paymentToken;
        Campaigns[_campaignId] = campaign;
    }

    function cancelCampaign(uint256 _campaignId) external onlyOperator {
        uint256 timestamp = block.timestamp;
        require(_campaignId <= totalCampaign, "invalid-campaign-id");
        Campaign memory campaign = Campaigns[_campaignId];
        require(
            campaign.startTime > timestamp,
            "can-not-cancel"
        );
        require(campaign.status, "invalid-campaign");
        campaign.status = false;
        Campaigns[_campaignId] = campaign;
    }

    function newMysteryBoxCampaign(
        uint256 _campaignId,
        uint256 _maxSupply,
        uint256 _maxBuyPerAddress,
        uint256 _price,
        uint8 _boxType
    ) external onlyOperator {
        uint256 timestamp = block.timestamp;
        require(_campaignId <= totalCampaign, "invalid-campaign-id");
        Campaign memory campaign = Campaigns[_campaignId];
        require(
            campaign.startTime > timestamp,
            "campaign-started"
        );
        require(campaign.status, "invalid-campaign");
        require(_price > 0, "invalid-price");
        require(
            _maxSupply > 0 &&
                _maxBuyPerAddress > 0 &&
                _maxSupply >= _maxBuyPerAddress,
            "invalid-input"
        );
        MysteryBox memory newMysteryBox;
        newMysteryBox.maxSupply = _maxSupply;
        newMysteryBox.maxByPerAddress = _maxBuyPerAddress;
        newMysteryBox.price = _price;
        newMysteryBox.campaignId = _campaignId;
        newMysteryBox.boxType = _boxType;
        newMysteryBox.status = true;
        totalMysteryBox = totalMysteryBox.add(1);
        MysteryBoxes[totalMysteryBox] = newMysteryBox;
    }

    function updateMysteryBoxCampaign(
        uint256 _boxId,
        uint256 _maxSupply,
        uint256 _maxBuyPerAddress,
        uint256 _price,
        uint8 _boxType,
        bool _status
    ) external onlyOperator {
        uint256 timestamp = block.timestamp;
        require(_boxId <= totalMysteryBox, "invalid-box-id");
        MysteryBox memory mysteryBox = MysteryBoxes[_boxId];
        Campaign memory campaign = Campaigns[mysteryBox.campaignId];
        require(campaign.startTime > timestamp, "campaign-started");
        require(campaign.status, "invalid-campaign");
        require(_price > 0, "invalid-price");
        require(
            _maxSupply > 0 &&
                _maxBuyPerAddress > 0 &&
                _maxSupply >= _maxBuyPerAddress,
            "invalid-input"
        );
        mysteryBox.maxSupply = _maxSupply;
        mysteryBox.maxByPerAddress = _maxBuyPerAddress;
        mysteryBox.price = _price;
        mysteryBox.boxType = _boxType;
        mysteryBox.status = _status;
        MysteryBoxes[_boxId] = mysteryBox;
    }

    function buyMysteryBox(uint256 _boxId, uint256 _quantity)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 timestamp = block.timestamp;
        require(_boxId <= totalMysteryBox, "invalid-box-id");
        require(_quantity > 0, "invalid-quantity");
        MysteryBox memory mysteryBox = MysteryBoxes[_boxId];
        require(mysteryBox.status, "box-canceled");
        require(
            mysteryBox.totalBuy + _quantity <= mysteryBox.maxSupply,
            "over-max-supply"
        );
        bytes32 _id = keccak256(abi.encodePacked(_boxId, msg.sender));
        require(
            AddressBoughtBox[_id] + _quantity <= mysteryBox.maxByPerAddress,
            "over-box-can-buy"
        );
        Campaign memory campaign = Campaigns[mysteryBox.campaignId];
        require(
            campaign.startTime <= timestamp && campaign.endTime >= timestamp,
            "can-not-buy"
        );
        require(campaign.status, "invalid-campaign");
        uint256 amount = mysteryBox.price.mul(_quantity);
        if (campaign.paymentToken == address(0)) {
            require(amount <= msg.value, "Insufficient-balance");
        } else {
            IERC20Upgradeable(campaign.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        ITreasureBox(TreasureBoxContract).mint(
            msg.sender,
            mysteryBox.boxType,
            _quantity
        );
        mysteryBox.totalBuy = mysteryBox.totalBuy.add(_quantity);
        MysteryBoxes[_boxId] = mysteryBox;
        AddressBoughtBox[_id] = AddressBoughtBox[_id].add(_quantity);
        emit BuyBox(msg.sender, _boxId, _quantity, mysteryBox.boxType);
    }

    function setTreasureBoxContract(address _treasureBoxContract)
        external
        onlyOperator
    {
        require(_treasureBoxContract != address(0), "invalid-address");
        TreasureBoxContract = _treasureBoxContract;
    }

    function remainingBoxCanBuy(address _address, uint256 _boxId)
        external
        view
        returns (uint256)
    {
        MysteryBox memory mysteryBox = MysteryBoxes[_boxId];
        bytes32 _id = keccak256(abi.encodePacked(_boxId, _address));
        return mysteryBox.maxByPerAddress.sub(AddressBoughtBox[_id]);
    }

    function withdrawFunds(address payable _beneficiary, address _tokenAddress)
        external
        onlyOwner
        whenPaused
    {
        require(_beneficiary != address(0), "invalid-address");
        uint256 _withdrawAmount;
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
        } else {
            _withdrawAmount = IERC20Upgradeable(_tokenAddress).balanceOf(
                address(this)
            );
            IERC20Upgradeable(_tokenAddress).transfer(
                _beneficiary,
                _withdrawAmount
            );
        }
    }
}