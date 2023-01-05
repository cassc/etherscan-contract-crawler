// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract CampaignManager is Ownable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address[] public campaigns;
    uint256[4] public fees;
    uint256 public createFee;
    uint256 public campaignFee;
    address payable feeCollector;
    address[] public campaignCreationTokenArray;

    // todo- creationToken mapped to fee amount uint256
    mapping(address => bool) private campaignCreationTokens;
    

    constructor(address owner) {
        transferOwnership(owner);
        fees[0] = 15; // sk token raise discount
        fees[1] = 15;
        fees[2] = 10;
        fees[3] = 5;

        // todo - account for decimals on createFee, otherwise all creationTokens must use same decimals
        // createFee = 200000000000000000000; // 6500 sk bsc
        createFee = 200000000; // 200 usdc 6 decimals eth cro
        campaignFee = 5000; // 5 * 1000 to account for decimals

        // feesplitter mainnet
        feeCollector = payable(0x170f96b6A5aCcCEC8FF1D8a74D8dD5a5DCaf90F5);

        // campaignCreationTokenArray.push(0xB5473067681d79d822bD4314893827eE5A8198A4); // mumbai busd
        // campaignCreationTokens[0xB5473067681d79d822bD4314893827eE5A8198A4] = true; // mumbai busd

        //campaignCreationTokenArray.push(0xfCeBe3A758352FF904C96cC84eA214A93ec95d57); // testnet busd
        //campaignCreationTokens[0xfCeBe3A758352FF904C96cC84eA214A93ec95d57] = true; //testnet busd

        // campaignCreationTokenArray.push(0x5755E18D86c8a6d7a6E25296782cb84661E6c106); // mainnet busd
        // campaignCreationTokens[0x5755E18D86c8a6d7a6E25296782cb84661E6c106] = true; //mainnet busd

        // campaignCreationTokenArray.push(0xacbDc2b7a577299718309Ed5C4B703fb5ed7af90); // mainnet sign
        // campaignCreationTokens[0xacbDc2b7a577299718309Ed5C4B703fb5ed7af90] = true; //mainnet sign

        //campaignCreationTokenArray.push(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // mainnet eth usdc
        //campaignCreationTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //mainnet eth usdc

        campaignCreationTokenArray.push(0xc21223249CA28397B4B6541dfFaEcC539BfF0c59); // mainnet cro usdc
        campaignCreationTokens[0xc21223249CA28397B4B6541dfFaEcC539BfF0c59] = true; //mainnet cro usdc

    }

    function getFeeCollector() public view returns (address payable) {
        return feeCollector;
    }

    function getCampaignCreationTokens() public view returns (address[] memory) {
        return campaignCreationTokenArray;
    }

    function getCampaigns() public view returns (address[] memory a) {
        return campaigns;
    }

    function getFees() public view returns (uint256[4] memory a) {
        return fees;
    }

    function getCreateFee() public view returns (uint256) {
        return createFee;
    }

    function calculateFees(
        uint256 softCap,
        uint256 hardCap,
        address mintToken,
        bool createDistributorContract 
    )
        public
        view
        returns (uint256 actualCreationFee, uint256 actualCampaignFee)
    {
        if (softCap == hardCap) {
            // 100% hardcap discount
            if (campaignCreationTokens[mintToken]) {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[1] ))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[1]))
                    .div(100);
            } else {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100, fees[1]))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100, fees[1]))
                    .div(100);
            }
        } else if (softCap.mul(100).div(hardCap) > 75) {
            // 75% hc discount
           if (campaignCreationTokens[mintToken]) {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[2] ))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[2]))
                    .div(100);
            } else {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100, fees[2]))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100, fees[2]))
                    .div(100);
            }
        } else if (softCap.mul(100).div(hardCap) > 50) {
            // 50% hc discount
           if (campaignCreationTokens[mintToken]) {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[3] ))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100,fees[0] + fees[3]))
                    .div(100);
            } else {
                actualCreationFee = createFee
                    .mul(SafeMathUpgradeable.sub(100, fees[3]))
                    .div(100);
                actualCampaignFee = campaignFee
                    .mul(SafeMathUpgradeable.sub(100, fees[3]))
                    .div(100);
            }
        } else {
            if(campaignCreationTokens[mintToken]) {
                actualCreationFee = createFee.mul(SafeMathUpgradeable.sub(100,fees[0])).div(100);
                actualCampaignFee = campaignFee.mul(SafeMathUpgradeable.sub(100,fees[0])).div(100);
            } else {
                actualCreationFee = createFee;
                actualCampaignFee = campaignFee;
            }
        }

        if(createDistributorContract){
            actualCreationFee = actualCreationFee.mul(150).div(100);
        }

        return (actualCreationFee, actualCampaignFee);
    }

    function pushCampaign(address _campaign) external onlyOwner {
        campaigns.push(_campaign);
    }

    function setCampaignCreationToken(address _token, bool active) external onlyOwner {
        campaignCreationTokens[_token] = active;

        if(active) {
            campaignCreationTokenArray.push(_token);
        }else {
            for(uint i = 0; i < campaignCreationTokenArray.length; i++) {
                if(campaignCreationTokenArray[i] == _token) {
                    campaignCreationTokenArray[i] = campaignCreationTokenArray[campaignCreationTokenArray.length - 1];
                    campaignCreationTokenArray.pop();
                    break;
                }
            }
        }
    }

    function setValues(
        uint256 _feeDiscount1, // hc discount
        uint256 _feeDiscount2, // softCap 75% discount
        uint256 _feeDiscount3, // softCap 50% discount
        uint256 _sidekickDiscount, // token raised in sidekick discount
        uint256 _campaignFee,
        uint256 _createFee,
        address payable _newFeecollector
    ) external onlyOwner {
        fees[0] = _sidekickDiscount;
        fees[1] = _feeDiscount1;
        fees[2] = _feeDiscount2;
        fees[3] = _feeDiscount3;
        campaignFee = _campaignFee;
        createFee = _createFee;
        feeCollector = _newFeecollector;
    }

    function _pay(address payee, uint256 fee, address payToken) public virtual returns (bool) {
        require(payee != address(0), "payee is the zero address");
        require(fee > 0, "fee is 0");
        require(campaignCreationTokens[payToken], "token not allowed");
        require(IERC20Upgradeable(payToken).transferFrom(payee, feeCollector, fee), "transfer failed");
        
        return true;
    }

    // need metrics
    // current amount raised
    // number of unique contributors
}