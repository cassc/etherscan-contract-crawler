// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/IBankroll.sol";
import "../../interfaces/IGasStation.sol";
import "../../interfaces/IReferralVault.sol";
import "../../interfaces/VRFCoordinatorV2InterfaceExtended.sol";

error InvalidPriceFeed();
error InvalidVRFCost();
error FailedVRFHarvest();

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

abstract contract BaseGameEvents {
    event UpdateChainlinkSettings(
        address coordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint256 vrfPremium,
        uint256 callbackGasLimit
    );

    event UpdateGameSettings(uint256 houseEdge, uint256 bankrollShare);
    event UpdateBankroll(address newBankrollAddress);
    event UpdateVRFHarvester(address newHarvester);
    event UpdateReferral(address newReferral);
    /*  */
    event RequestRandomness(uint256 requestId, uint32 randomValues);
    event ReceiveRandomness(uint256 requestId, uint256[] randomValues);
    /*  */
    event DeductVRFFee(uint256 paid, uint256 est);
    event HarvestVRFFees(uint256 amount);
}

abstract contract BaseGameWLEvent is BaseGameEvents {
    event UpdatePartnerBoostNft(address nft, uint256 boostHouseEdge);
    event UpdateAllowedToken(address token, bool state);
    event PartnerAdminChanged(address newPartnerAdmin);
    event UpdateBoost(address nftContract, uint256 houseEdge);
}

abstract contract BaseGameWL is BaseGameWLEvent, Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    /* Chainlink Settings */
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2InterfaceExtended vrfCoordinator;

    struct ChainlinkConfig {
        uint64 subscriptionId;
        bytes32 keyHash;
        uint256 vrfPremium;
        uint32 callbackGasLimit;
    }
    ChainlinkConfig public chainlinkConfig =
        ChainlinkConfig(0, 0, 10_200, 500_000);

    struct SettingStruct {
        uint256 houseEdge;
        uint256 bankrollShare;
    }
    SettingStruct public settings = SettingStruct(250, 8000);

    IBankroll public bank;
    IReferralVault public referral;

    AggregatorV3Interface public linkPriceFeed;
    address public vrfHarvester;

	
    mapping(address => bool) public allowedTokens;
    address partnerAdmin = address(0);

    uint256 public boostedNftEdge = 240;
    address public boostNftContract = address(0);

    constructor(
        uint64 _subId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        address _linkPriceFeed,
        address bankAddress
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        chainlinkConfig.subscriptionId = _subId;
        chainlinkConfig.keyHash = _keyHash;
        chainlinkConfig.callbackGasLimit = _callbackGasLimit;
        vrfCoordinator = VRFCoordinatorV2InterfaceExtended(_vrfCoordinator);

        bank = IBankroll(bankAddress);
        linkPriceFeed = AggregatorV3Interface(_linkPriceFeed);
    }

    /* Partner Tokens & Settings */
    modifier isTokenAllowed(address token) {
        require(allowedTokens[token], "token not whitelisted");
        _;
    }

	function hasPartnerNFT(address user) public view returns (bool) {
		if (address(boostNftContract) != address(0)) {
			(bool success,bytes memory result) = boostNftContract.staticcall(abi.encodeWithSignature("balanceOf(address)", user));
            require(success, "partner nft check failed");
			return abi.decode(result,(uint256)) > 0;
		}
		return false;
	}

    function setPartnerAdmin(address _partnerAdmin) external onlyOwner {
        partnerAdmin = _partnerAdmin;
        emit PartnerAdminChanged(partnerAdmin);
    }

    function setTokenAllowed(address token, bool state) external onlyOwner {
        allowedTokens[token] = state;
        emit UpdateAllowedToken(token, state);
    }

    function setBoost(address nftContract, uint256 houseEdge) external {
        require(msg.sender == partnerAdmin, "not partner");
        boostedNftEdge = houseEdge;
        boostNftContract = nftContract;
        emit UpdateBoost(nftContract, houseEdge);
    }
    /* Partner Tokens & Settings */

    /* Owner */
    function setChainlinkSettings(
        address _vrfCoordinator,
        uint64 _subId,
        bytes32 _keyHash,
        uint256 _vrfPremium,
        uint32 _callbackGasLimit
    ) external onlyOwner {
        vrfCoordinator = VRFCoordinatorV2InterfaceExtended(_vrfCoordinator);
        chainlinkConfig.subscriptionId = _subId;
        chainlinkConfig.keyHash = _keyHash;
        chainlinkConfig.vrfPremium = _vrfPremium;
        chainlinkConfig.callbackGasLimit = _callbackGasLimit;

        emit UpdateChainlinkSettings(
            _vrfCoordinator,
            chainlinkConfig.subscriptionId,
            chainlinkConfig.keyHash,
            chainlinkConfig.vrfPremium,
            chainlinkConfig.callbackGasLimit
        );
    }

    function setGameSettings(uint256 _edge, uint256 _share) external onlyOwner {
        settings.houseEdge = _edge;
        settings.bankrollShare = _share;

        emit UpdateGameSettings(settings.houseEdge, settings.bankrollShare);
    }

    function changeBank(address newBank) external onlyOwner {
        bank = IBankroll(newBank);

        emit UpdateBankroll(newBank);
    }

    function changeVRFHarvester(address newHarvester) external onlyOwner {
        vrfHarvester = newHarvester;
        emit UpdateVRFHarvester(newHarvester);
    }

    function changeReferral(address newReferral) external onlyOwner {
        referral = IReferralVault(newReferral);
        emit UpdateReferral(newReferral);
    }

    function recoverTokens(address token) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    /* Owner */

    /* VRF */
    function harvestVRFCost() external {
        require(vrfHarvester != address(0), "No Harvester");
        uint256 balance = address(this).balance;
        IGasStation(vrfHarvester).topUp{value: balance}(
            address(vrfCoordinator),
            chainlinkConfig.subscriptionId,
            msg.sender
        );
        emit HarvestVRFFees(balance);
    }

    function _deductVRFCost(uint256 sentVRFGas) internal {
        uint256 VRFCost = getVRFCost();
        if (sentVRFGas < (VRFCost - ((VRFCost * 10) / 100))) {
            revert InvalidVRFCost();
        }

        emit DeductVRFFee(sentVRFGas, VRFCost);
    }

    function _requestRandomValues(uint32 randomValues)
        internal
        returns (uint256 requestId)
    {
        (uint16 minimumRequestConfirmations, , , ) = vrfCoordinator.getConfig();
        requestId = vrfCoordinator.requestRandomWords(
            chainlinkConfig.keyHash,
            chainlinkConfig.subscriptionId,
            minimumRequestConfirmations,
            chainlinkConfig.callbackGasLimit,
            randomValues
        );
        emit RequestRandomness(requestId, randomValues);

        return requestId;
    }

    /* function getVRFCost(uint256) public view returns (uint256) {

	}*/
    function getVRFCost() public view returns (uint256) {
        (, int256 unitsPerLink, , , ) = linkPriceFeed.latestRoundData();
        if (unitsPerLink == 0) revert InvalidPriceFeed();
        (uint32 fulfillmentFlatFeeLinkPPMTier1, , , , , , , , ) = vrfCoordinator
            .getFeeConfig();
        (, , , uint32 gasAfterPaymentCalculation) = vrfCoordinator.getConfig();

        uint256 callGasCost = tx.gasprice *
            (gasAfterPaymentCalculation + chainlinkConfig.callbackGasLimit);
        uint256 vrfCost = (1e12 *
            uint256(fulfillmentFlatFeeLinkPPMTier1) *
            uint256(unitsPerLink)) / 1e18;

        return
            ((callGasCost + vrfCost) * (chainlinkConfig.vrfPremium)) / 10_000;
    }

    /* VRF */
    function _getReferralId(string memory code, address player)
        internal
        view
        returns (uint256)
    {
        return (address(referral) != address(0)) ? referral.getCodeId(code, player) : 0;
    }

    /* Gas Token */
    fallback() external payable {}

    receive() external payable {}
}