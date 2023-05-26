pragma solidity 0.5.17;

import "./lib/CloneFactory.sol";
import "./tokens/minime/MiniMeToken.sol";
import "./PeakDeFiFund.sol";
import "./PeakDeFiProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PeakDeFiFactory is CloneFactory {
    using Address for address;

    event CreateFund(address fund);
    event InitFund(address fund, address proxy);

    address public usdcAddr;
    address payable public kyberAddr;
    address payable public oneInchAddr;
    address payable public peakdefiFund;
    address public peakdefiLogic;
    address public peakdefiLogic2;
    address public peakdefiLogic3;
    address public peakRewardAddr;
    address public peakStakingAddr;
    MiniMeTokenFactory public minimeFactory;
    mapping(address => address) public fundCreator;

    constructor(
        address _usdcAddr,
        address payable _kyberAddr,
        address payable _oneInchAddr,
        address payable _peakdefiFund,
        address _peakdefiLogic,
        address _peakdefiLogic2,
        address _peakdefiLogic3,
        address _peakRewardAddr,
        address _peakStakingAddr,
        address _minimeFactoryAddr
    ) public {
        usdcAddr = _usdcAddr;
        kyberAddr = _kyberAddr;
        oneInchAddr = _oneInchAddr;
        peakdefiFund = _peakdefiFund;
        peakdefiLogic = _peakdefiLogic;
        peakdefiLogic2 = _peakdefiLogic2;
        peakdefiLogic3 = _peakdefiLogic3;
        peakRewardAddr = _peakRewardAddr;
        peakStakingAddr = _peakStakingAddr;
        minimeFactory = MiniMeTokenFactory(_minimeFactoryAddr);
    }

    function createFund() external returns (PeakDeFiFund) {
        // create fund
        PeakDeFiFund fund = PeakDeFiFund(createClone(peakdefiFund).toPayable());
        fund.initOwner();

        // give PeakReward signer rights to fund
        PeakReward peakReward = PeakReward(peakRewardAddr);
        peakReward.addSigner(address(fund));

        fundCreator[address(fund)] = msg.sender;

        emit CreateFund(address(fund));

        return fund;
    }

    function initFund1(
        PeakDeFiFund fund,
        string calldata reptokenName,
        string calldata reptokenSymbol,
        string calldata sharesName,
        string calldata sharesSymbol
    ) external {
        require(
            fundCreator[address(fund)] == msg.sender,
            "PeakDeFiFactory: not creator"
        );

        // create tokens
        MiniMeToken reptoken = minimeFactory.createCloneToken(
            address(0),
            0,
            reptokenName,
            18,
            reptokenSymbol,
            false
        );
        MiniMeToken shares = minimeFactory.createCloneToken(
            address(0),
            0,
            sharesName,
            18,
            sharesSymbol,
            true
        );
        MiniMeToken peakReferralToken = minimeFactory.createCloneToken(
            address(0),
            0,
            "Peak Referral Token",
            18,
            "PRT",
            false
        );

        // transfer token ownerships to fund
        reptoken.transferOwnership(address(fund));
        shares.transferOwnership(address(fund));
        peakReferralToken.transferOwnership(address(fund));

        fund.initInternalTokens(
            address(reptoken),
            address(shares),
            address(peakReferralToken)
        );
    }

    function initFund2(
        PeakDeFiFund fund,
        address payable _devFundingAccount,
        uint256 _devFundingRate,
        uint256[2] calldata _phaseLengths,
        address _compoundFactoryAddr
    ) external {
        require(
            fundCreator[address(fund)] == msg.sender,
            "PeakDeFiFactory: not creator"
        );
        fund.initParams(
            _devFundingAccount,
            _phaseLengths,
            _devFundingRate,
            address(0),
            usdcAddr,
            kyberAddr,
            _compoundFactoryAddr,
            peakdefiLogic,
            peakdefiLogic2,
            peakdefiLogic3,
            1,
            oneInchAddr,
            peakRewardAddr,
            peakStakingAddr
        );
    }

    function initFund3(
        PeakDeFiFund fund,
        uint256 _newManagerRepToken,
        uint256 _maxNewManagersPerCycle,
        uint256 _reptokenPrice,
        uint256 _peakManagerStakeRequired,
        bool _isPermissioned
    ) external {
        require(
            fundCreator[address(fund)] == msg.sender,
            "PeakDeFiFactory: not creator"
        );
        fund.initRegistration(
            _newManagerRepToken,
            _maxNewManagersPerCycle,
            _reptokenPrice,
            _peakManagerStakeRequired,
            _isPermissioned
        );
    }

    function initFund4(
        PeakDeFiFund fund,
        address[] calldata _kyberTokens,
        address[] calldata _compoundTokens
    ) external {
        require(
            fundCreator[address(fund)] == msg.sender,
            "PeakDeFiFactory: not creator"
        );
        fund.initTokenListings(_kyberTokens, _compoundTokens);

        // deploy and set PeakDeFiProxy
        PeakDeFiProxy proxy = new PeakDeFiProxy(address(fund));
        fund.setProxy(address(proxy).toPayable());

        // transfer fund ownership to msg.sender
        fund.transferOwnership(msg.sender);

        emit InitFund(address(fund), address(proxy));
    }
}