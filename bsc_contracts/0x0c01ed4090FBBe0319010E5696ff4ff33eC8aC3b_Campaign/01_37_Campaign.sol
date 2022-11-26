// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Whitelist.sol";
import "./ERC721JumpStart.sol";
import "./EliteTokenDistributor.sol";
import "./JumpStartTicket.sol";
import "./JumpStartLib.sol";
import "./ICampaignManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Campaign is OwnableUpgradeable, Whitelist {
    using SafeMath for uint256;
    ICampaignManager campaignManager;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public softCap;
    uint256 public hardCap;
    bool public whitelistEnabled;
    bool public campaignCompleted;
    bool public refundActive;
    uint256 public totalRaised;
    uint256 public totalContributors;
    mapping(address => uint256) public userContributed;
    mapping(address => uint256) private campaignMapping;
    address[] public campaignNfts;
    address private mintToken;
    address private jumpStartFeeCollector;
    bool initialized;
    address public tokenDistributor;

    constructor() {}

    function initialize(
        // [0] = owner, [1] = mintToken, [2] = jsImplementation,
        // [3] = royaltyReceiver, [4] = campaignManager, 
        // [5] = jumpStartFeeCollector, [6] = eliteTokenDistribution
        address[7] memory _addresses,
        // [0] = startDate, [1] = endDate, [2] = softCap,
        // [3] = hardCap, [4] = priceDiscount, [5] = priceDiscountEndDate, [6] = royaltyFee
        uint256[7] memory _settings,
        bool[2] memory _boolSettings, // [0] = whitelistEnabled, [1] = createEliteTokenDistributor
        string[2] memory _stringSettings,
        JumpStartLib.MintNft[] memory _nftTiers,
        uint256 _campaignFee
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_addresses[0]);
        whitelistEnabled = _boolSettings[0];
        startDate = _settings[0];
        endDate = _settings[1];
        softCap = _settings[2];
        hardCap = _settings[3];
        mintToken = _addresses[1];
        address rreceiver = _addresses[3];
        address manager = _addresses[4];
        jumpStartFeeCollector = _addresses[5];
        campaignManager = ICampaignManager(manager);

        for (uint256 i = 0; i < _nftTiers.length; i++) {
            address nftClone = Clones.clone(_addresses[2]);
            ERC721JumpStart nft = ERC721JumpStart(nftClone);
            nft.initialize(
                [
                    _nftTiers[i].tokenName,
                    _nftTiers[i].tokenSymbol,
                    _nftTiers[i].tokenUri,
                    _stringSettings[1],
                    _nftTiers[i].nftUID,
                    _nftTiers[i].contractUri
                ],
                [
                    _nftTiers[i].quantity,
                    _nftTiers[i].mintPrice,
                    _nftTiers[i].priceDiscount,
                    _nftTiers[i].priceDiscountEndDate,
                    _nftTiers[i].mintPerAddress,
                    _nftTiers[i].mintPerTransaction,
                    _nftTiers[i].ticketsPerMint,
                    _campaignFee,
                    _settings[6]
                ],
                _nftTiers[i].enableWhitelist,
                _nftTiers[i].redeemable,
                [address(this), rreceiver, mintToken, manager]
            );
            campaignNfts.push(nftClone);
            campaignMapping[nftClone] = 1;

            if (_nftTiers[i].redeemable) {
                JumpStartTicket ticket = new JumpStartTicket(
                    _nftTiers[i].ticket.tokenName,
                    _nftTiers[i].ticket.tokenSymbol,
                    _nftTiers[i].ticket.tokenUri,
                    _nftTiers[i].ticket.quantity,
                    address(nft)
                );
                nft.setTicketContract(address(ticket));
            }

            nft.transferOwnership(owner());
        }

        if(_boolSettings[1]) {
            address distributorClone = Clones.clone(_addresses[6]);
            EliteTokenDistributor distributor = EliteTokenDistributor(distributorClone);

            uint256 distributionSplit = 10000 / _nftTiers.length;
            uint256[] memory distribution = new uint256[](_nftTiers.length);
            for(uint256 i = 0; i < _nftTiers.length; i++) {
                distribution[i] = distributionSplit;
            }
            
            distributor.initialize(
                campaignNfts,
                distribution,
                owner()
            );

            tokenDistributor = distributorClone;
        }

    }

    function completeCampaign() public onlyOwner {
        require(totalRaised >= softCap, "Soft Cap not reached");
        require(endDate <= block.timestamp, "Campaign not ended");
        require(campaignCompleted == false, "Campaign completed");

        campaignCompleted = true;
        uint256 balance = IERC20(mintToken).balanceOf(address(this));
 
        // take fee
        (uint256 createFee, uint256 campaignFee) = campaignManager
            .calculateFees(softCap, hardCap, mintToken, false);

        uint256 fee = balance.mul(campaignFee).div(1e18 * 100);

        IERC20(mintToken).transfer(jumpStartFeeCollector, fee);
        IERC20(mintToken).transfer(owner(), balance - fee);
    }

    function refundActivate() public onlyOwner {
        refundActive = true;
    }

    function isRefundActive() public view returns (bool) {
        if(refundActive)
            return true;
        else {
            if(totalRaised < softCap && endDate <= block.timestamp)
                return true; // automatic refund if softcap not met and campaign ended
            else
                return false;
        }
        
        return  false;
    }

    function updateUserContributed(address _user, uint256 _amount) public {
        require(campaignMapping[msg.sender] == 1, "Not valid campaign");

        if (userContributed[_user] == 0) {
            totalContributors++;
        }

        userContributed[_user] += _amount;

        totalRaised += _amount;
    }

    function claimRefund() public {
        require(isRefundActive(), "Not active");
        require(block.timestamp >= endDate, "Not available");
        require(userContributed[msg.sender] > 0, "No refund");
        uint256 contribution = userContributed[msg.sender];
        userContributed[msg.sender] = 0;
        IERC20(mintToken).transfer(msg.sender, contribution);
    }

    function getNfts() public view returns (address[] memory) {
        return campaignNfts;
    }

    function getDates()
        public
        view
        returns (
            uint256 _startDate,
            uint256 _endDate,
            bool _refundActive
        )
    {
        return (startDate, endDate, refundActive);
    }

    function extendCampaign(uint256 _newEndDate) public onlyOwner {
        require(endDate < _newEndDate, "New date must be greater than current");
        endDate = _newEndDate;
    }
}