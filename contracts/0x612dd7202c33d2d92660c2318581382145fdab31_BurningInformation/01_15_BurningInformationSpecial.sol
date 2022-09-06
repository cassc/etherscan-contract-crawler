pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./DataUnionSideChainInterface.sol";
import "./MediatorInterface.sol";
import "./AmbInterface.sol";
import "./OperatorAbility.sol";
import "./AmbInterface.sol";
import "hardhat/console.sol";

contract BurningInformation is OperatorAbility {

    enum BurnType {
        burnForUserGrowth,
        burnForEcosystemRevenue,
        burnForFutureRevenue,
        burnForDonation,
        burnForStaking,
        burnForDaoIgnition
    }

    event TokenAddressSet(address _tokenAddress);

    event TokensBurned(uint256 burnAmount, BurnType);
    event AmbContractAddressSet(address _ambContractAddress);
    event WalletOfTokensForBurnSet(address);
    event ClaimedTokens();

    struct EcosystemRevenueInfo {
        uint256 burnedToken;
        uint256 ecosystemRevenueTokens;
        uint256 maxTokenToBurn;
    }

    struct FutureRevenueInfo {
        uint256 burnedToken;
        uint256 futureRevenueTokens;
        uint256 maxTokenToBurn;
    }

    struct DonationBurningInfo {
        uint256 burnedToken;
        uint256 donatedTokens;
        uint256 maxTokenToBurn;
    }

    struct UserGrowthBurningInfo {
        uint256 burnedToken;
        uint256 target;
        uint256 maxTokenToBurn;
    }

    struct StakingBurningInfo {
        uint256 burnedToken;
        uint256 stakedTokens;
        uint256 maxTokenToBurn;
        uint256 tokenToBurnPercent;
    }

    struct DaoIgnitionBurningInfo {
        uint256 burnedToken;
        uint256 toBurn;
        uint256 maxTokenToBurn;
        uint256 tokenToBurnPercent;
    }


    address public tokenAddress;

    address public ambContractAddress;
    address public walletOfTokensForBurn;

    EcosystemRevenueInfo public ecosystemRevenueInfo;
    FutureRevenueInfo public futureRevenueInfo;
    UserGrowthBurningInfo public userGrowthBurningInfo;
    DonationBurningInfo public donationBurningInfo;
    StakingBurningInfo public stakingBurningInfo;
    DaoIgnitionBurningInfo public daoIgnitionBurningInfo;

    uint public iii;

    constructor() {
    }

    function initialize(
        address _tokenAddress,

        uint256 _userGrowthMaxTokenToBurn,
        uint256 _ecosystemRevenueMaxTokenToBurn,
        uint256 _futureRevenueMaxTokenToBurn,
        uint256 _donationMaxTokenToBurn,

        uint256 _stakingMaxTokenToBurn,
        uint256 _stakingTokenToBurnPercent,

        uint256 _daoIgnitionMaxTokenToBurn,
        uint256 _daoIgnitionTokenToBurnPercent,

        address _ambContractAddress,
        address _walletOfTokensForBurn) public initializer {

        require(_tokenAddress != address(0), "The _tokenAddress is not valid");

        require(_userGrowthMaxTokenToBurn > 0, "_userGrowthMaxTokenToBurn is not valid");
        require(_ecosystemRevenueMaxTokenToBurn > 0, "_ecosystemRevenueMaxTokenToBurn is not valid");
        require(_futureRevenueMaxTokenToBurn > 0, "_futureRevenueMaxTokenToBurn is not valid");
        require(_donationMaxTokenToBurn > 0, "_donationMaxTokenToBurn is not valid");

        require(_stakingMaxTokenToBurn > 0, "_stakingMaxTokenToBurn is not valid");
        require(_stakingTokenToBurnPercent >= 0 && _stakingTokenToBurnPercent <= 1000, "_stakingTokenToBurnPercent is not valid");

        require(_daoIgnitionMaxTokenToBurn > 0, "_daoIgnitionMaxTokenToBurn is not valid");
        require(_daoIgnitionTokenToBurnPercent >= 0 && _daoIgnitionTokenToBurnPercent <= 1000, "_daoIgnitionTokenToBurnPercent is not valid");

        require(_ambContractAddress != address(0), "The _ambContractAddress is not valid");

        require(_walletOfTokensForBurn != address(0), "The _walletOfTokensForBurn is not valid");

        __Ownable_init();
        tokenAddress = _tokenAddress;


        userGrowthBurningInfo.maxTokenToBurn = _userGrowthMaxTokenToBurn;
        ecosystemRevenueInfo.maxTokenToBurn = _ecosystemRevenueMaxTokenToBurn;
        futureRevenueInfo.maxTokenToBurn = _futureRevenueMaxTokenToBurn;
        donationBurningInfo.maxTokenToBurn = _donationMaxTokenToBurn;

        stakingBurningInfo.maxTokenToBurn = _stakingMaxTokenToBurn;
        stakingBurningInfo.tokenToBurnPercent = _stakingTokenToBurnPercent;

        daoIgnitionBurningInfo.maxTokenToBurn = _daoIgnitionMaxTokenToBurn;
        stakingBurningInfo.tokenToBurnPercent = _daoIgnitionTokenToBurnPercent;

        ambContractAddress = _ambContractAddress;

        walletOfTokensForBurn = _walletOfTokensForBurn;
    }

    // ====================================== SET METHODS =================================================
    function setEcosystemRevenueInfo(uint256 _maxTokenToBurn) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurnis not valid");

        ecosystemRevenueInfo.maxTokenToBurn = _maxTokenToBurn;
    }

    function setFutureRevenueInfo(uint256 _maxTokenToBurn) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurnis not valid");

        futureRevenueInfo.maxTokenToBurn = _maxTokenToBurn;
    }

    function setUserGrowthBurningInfo(uint256 _maxTokenToBurn) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurnis not valid");

        userGrowthBurningInfo.maxTokenToBurn = _maxTokenToBurn;
    }

    function setDonationBurningInfo(uint256 _maxTokenToBurn) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurn is not valid");

        donationBurningInfo.maxTokenToBurn = _maxTokenToBurn;
    }

    function setStakingBurningInfo(uint256 _maxTokenToBurn, uint256 _tokenToBurnPercent) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurn is not valid");
        require(_tokenToBurnPercent >= 0 && _tokenToBurnPercent <= 1000, "_tokenToBurnPercent is not valid");

        stakingBurningInfo.maxTokenToBurn = _maxTokenToBurn;
        stakingBurningInfo.tokenToBurnPercent = _tokenToBurnPercent;
    }

    function setDaoIgnitionBurningInfo(uint256 _maxTokenToBurn, uint256 _tokenToBurnPercent) public onlyOwner {
        require(_maxTokenToBurn > 0, "_maxTokenToBurn is not valid");
        require(_tokenToBurnPercent >= 0 && _tokenToBurnPercent <= 1000, "_tokenToBurnPercent is not valid");

        daoIgnitionBurningInfo.maxTokenToBurn = _maxTokenToBurn;
        daoIgnitionBurningInfo.tokenToBurnPercent = _tokenToBurnPercent;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "The _tokenAddress is not valid");

        tokenAddress = _tokenAddress;
        emit TokenAddressSet(_tokenAddress);
    }

    function setAmbContractAddress(address _ambContractAddress) public onlyOwner {
        require(_ambContractAddress != address(0), "The _ambContractAddress is not valid");
        ambContractAddress = _ambContractAddress;
        emit AmbContractAddressSet(_ambContractAddress);
    }

    function setWalletOfTokensForBurn(address _walletOfTokensForBurn) public onlyOwner {
        require(_walletOfTokensForBurn != address(0), "The _walletOfTokensForBurn is not valid");
        walletOfTokensForBurn = _walletOfTokensForBurn;
        emit WalletOfTokensForBurnSet(_walletOfTokensForBurn);
    }
    // ======================================   END OF SET METHODS =================================================

    //This method should update all information at once
    function updateInformation(uint256 donatedTokensCount, uint256 stakedTokens, uint256 joinedUserCount) external onlyOperator {
        donationBurningInfo.donatedTokens = donatedTokensCount;
        stakingBurningInfo.stakedTokens = stakedTokens;
        userGrowthBurningInfo.target = joinedUserCount;
    }

    function burnTokens(uint256 amountToBurn) private {
        ERC20Burnable(tokenAddress).burnFrom(walletOfTokensForBurn, amountToBurn);
    }

//    function burnUserGrowth() public {
//
//        uint256 amountToBurn;
//        uint256 target = userGrowthBurningInfo.target;
//
//        if (target < xxx) {
//            amountToBurn = xxx;
//        }
//        else if (target < xxx) {
//            amountToBurn = xxx;
//        }
//        else if (target < xxx) {
//            amountToBurn = xxx;
//        }
//
//        if (userGrowthBurningInfo.burnedToken + amountToBurn > userGrowthBurningInfo.maxTokenToBurn) {
//            amountToBurn = userGrowthBurningInfo.maxTokenToBurn - userGrowthBurningInfo.burnedToken;
//        }
//        else {
//            amountToBurn = amountToBurn - userGrowthBurningInfo.burnedToken;
//        }
//
//        userGrowthBurningInfo.burnedToken += amountToBurn;
//
//        emit TokensBurned(amountToBurn, BurnType.burnForUserGrowth);
//
//        if (amountToBurn > 0) {
//            burnTokens(amountToBurn);
//        }
//    }

    function burnDonation() public {

        uint256 amountToBurn = donationBurningInfo.donatedTokens - donationBurningInfo.burnedToken;
        if (donationBurningInfo.burnedToken + amountToBurn > donationBurningInfo.maxTokenToBurn) {
            amountToBurn = donationBurningInfo.maxTokenToBurn - donationBurningInfo.burnedToken;
        }
        donationBurningInfo.burnedToken += amountToBurn;

        emit TokensBurned(amountToBurn, BurnType.burnForDonation);

        if (amountToBurn > 0) {
            burnTokens(amountToBurn);
        }
    }

    function burnFutureRevenue() public {

        uint256 amountToBurn = futureRevenueInfo.futureRevenueTokens - futureRevenueInfo.burnedToken;
        if (futureRevenueInfo.burnedToken + amountToBurn > futureRevenueInfo.maxTokenToBurn) {
            amountToBurn = futureRevenueInfo.maxTokenToBurn - futureRevenueInfo.burnedToken;
        }
        futureRevenueInfo.burnedToken += amountToBurn;

        emit TokensBurned(amountToBurn, BurnType.burnForFutureRevenue);

        if (amountToBurn > 0) {
            burnTokens(amountToBurn);
        }
    }

    function burnStaking() public {

        uint256 amountToBurn = stakingBurningInfo.stakedTokens;
        amountToBurn = amountToBurn * stakingBurningInfo.tokenToBurnPercent / 1000;
        if (stakingBurningInfo.burnedToken + amountToBurn > stakingBurningInfo.maxTokenToBurn) {
            amountToBurn = stakingBurningInfo.maxTokenToBurn - stakingBurningInfo.burnedToken;
        }
        else {
            amountToBurn = amountToBurn - stakingBurningInfo.burnedToken;
        }

        stakingBurningInfo.burnedToken += amountToBurn;

        emit TokensBurned(amountToBurn, BurnType.burnForStaking);

        if (amountToBurn > 0) {
            burnTokens(amountToBurn);
        }
    }

    function burnDaoIgnition() public {

        uint256 amountToBurn = daoIgnitionBurningInfo.toBurn;
        amountToBurn = amountToBurn * daoIgnitionBurningInfo.tokenToBurnPercent / 1000;
        if (daoIgnitionBurningInfo.burnedToken + amountToBurn > daoIgnitionBurningInfo.maxTokenToBurn) {
            amountToBurn = daoIgnitionBurningInfo.maxTokenToBurn - daoIgnitionBurningInfo.burnedToken;
        }
        else {
            amountToBurn = amountToBurn - daoIgnitionBurningInfo.burnedToken;
        }

        daoIgnitionBurningInfo.burnedToken += amountToBurn;

        emit TokensBurned(amountToBurn, BurnType.burnForDaoIgnition);

        if (amountToBurn > 0) {
            burnTokens(amountToBurn);
        }
    }

    function burnEcosystemRevenue(bytes memory messageData, bytes memory signature) public {
        AmbInterface(ambContractAddress).safeExecuteSignatures(messageData, signature);
        emit ClaimedTokens();
        burnTokenInContract();
    }

    function burnTokenInContract() private {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        ERC20Burnable(tokenAddress).burn(balance);
        ecosystemRevenueInfo.burnedToken += balance;
        emit TokensBurned(balance, BurnType.burnForEcosystemRevenue);
    }

    function specialBurn(uint256 amountToBurn, BurnType burnType) public onlyOperator {

        if (burnType == BurnType.burnForEcosystemRevenue) {
            require(ecosystemRevenueInfo.maxTokenToBurn >= ecosystemRevenueInfo.burnedToken + amountToBurn, "more than max");
            emit TokensBurned(amountToBurn, BurnType.burnForEcosystemRevenue);
            ecosystemRevenueInfo.burnedToken += amountToBurn;
            ecosystemRevenueInfo.ecosystemRevenueTokens = ecosystemRevenueInfo.burnedToken;
            burnTokens(amountToBurn);
        } else if (burnType == BurnType.burnForFutureRevenue) {
            require(futureRevenueInfo.maxTokenToBurn >= futureRevenueInfo.burnedToken + amountToBurn, "more than max");
            emit TokensBurned(amountToBurn, BurnType.burnForFutureRevenue);
            futureRevenueInfo.burnedToken += amountToBurn;
            futureRevenueInfo.futureRevenueTokens = futureRevenueInfo.burnedToken;
            burnTokens(amountToBurn);
        } else if (burnType == BurnType.burnForStaking) {
            require(stakingBurningInfo.maxTokenToBurn >= stakingBurningInfo.burnedToken + amountToBurn, "more than max");
            emit TokensBurned(amountToBurn, BurnType.burnForStaking);
            stakingBurningInfo.burnedToken += amountToBurn;
            stakingBurningInfo.stakedTokens += amountToBurn * 1000 / stakingBurningInfo.tokenToBurnPercent;
            burnTokens(amountToBurn);
        }
    }

}