// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPolygonStaking {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256);
    function sellVoucher_new(uint256 _claimAmount, uint256 _maximumSharesToBurn) external;
    function unstakeClaimTokens_new(uint256 unbondNonce) external;
    function withdrawRewards() external;
    function getLiquidRewards(address user) external view returns (uint256);
}

interface IYieldManager {
    function setAffiliate(address client, address sponsor) external;
    function getUserFactors(
        address user,
        uint typer
    ) external view returns (uint, uint, uint, uint);

    function getAffiliate(address client) external view returns (address);
}

contract PolygonStakingImplementation is ReentrancyGuard {
    event BuyVoucher(address indexed staker, uint256 amount, uint256 minSharesToMint);
    event SellVoucher(address indexed spender, uint256 _claimAmount, uint256 _maximumSharesToBurn, uint nonce);
    event ClaimTokens(address indexed spender, uint256 unbondNonce);
    event WithdrawRewards(address indexed spender, uint amount);
    event NewOwner(address indexed owner);
    event SponsorFee(address indexed sponsor, uint amount);
    event MgmtFee(address indexed factory, uint amount);
    event PerformanceFee(address indexed factory, uint amount);
    event SponsorPerformanceFee(address indexed sponsor, uint amount);
    event ERC20Recovered(address indexed owner, uint amount);

    using SafeERC20 for IERC20;
    address public owner;
    IPolygonStakingFactory public factoryAddress;

    //nonce => amount
    mapping(uint => uint) public nonces;
    uint public nonce;

    //nonce => alreadyClaimed
    mapping(uint => bool) public claimedNonces;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner || msg.sender == address(factoryAddress), "Only the contract owner may perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        owner = address(1);
    }

    function initialize(
        address owner_,
        address factoryAddress_
    ) external
    {
        require(owner == address(0), "already initialized");
        require(factoryAddress_ != address(0), "factory can not be null");
        require(owner_ != address(0), "owner cannot be null");

        owner = owner_;
        factoryAddress = IPolygonStakingFactory(factoryAddress_);

        emit NewOwner(owner);
    }

    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external onlyOwner nonReentrant {
        require(_amount > 0, "Cannot stake 0 token");

        IERC20(IPolygonStakingFactory(factoryAddress).getStakingToken()).safeTransferFrom(
            owner,
            address(this),
            _amount
        );

        IERC20(IPolygonStakingFactory(factoryAddress).getStakingToken()).approve(IPolygonStakingFactory(factoryAddress).getStakingContractStakeManager(), _amount);

        IPolygonStaking(IPolygonStakingFactory(factoryAddress).getStakingContract()).buyVoucher(_amount, _minSharesToMint);
        emit BuyVoucher(owner, _amount, _minSharesToMint);
    }

    function sellVoucher_new(uint256 _claimAmount, uint256 _maximumSharesToBurn) external onlyOwner nonReentrant {
        require(_claimAmount > 0, "Cannot stake 0 token");

        IPolygonStaking(IPolygonStakingFactory(factoryAddress).getStakingContract()).sellVoucher_new(_claimAmount, _maximumSharesToBurn);

        nonce += 1;
        nonces[nonce] = _claimAmount;
        emit SellVoucher(owner, _claimAmount, _maximumSharesToBurn, nonce);
    }

    function unstakeClaimTokens_new(uint256 unbondNonce) external onlyOwner nonReentrant {
        uint amount = nonces[unbondNonce];

        require(amount > 0, "Cannot withdraw 0");

        // get user stats
        (, , uint val3,) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint mgmtFee = (val3 * amount) / 100 / 100;
        uint sponsorFee;

        // get sponsor
        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);
        // get sponsor stats
        if (sponsor != address(0)) {
            (, uint sval2,, ) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sponsorFee = (mgmtFee * sval2) / 100 / 100;
            mgmtFee -= sponsorFee;
        }

        //withdraw
        IPolygonStaking(IPolygonStakingFactory(factoryAddress).getStakingContract()).unstakeClaimTokens_new(unbondNonce);

        // send tokens
        IERC20(IPolygonStakingFactory(factoryAddress).getStakingToken()).transfer(
            owner,
            amount - mgmtFee - sponsorFee
        );

        if (sponsor != address(0) && sponsorFee != 0) {
            IERC20(IPolygonStakingFactory(factoryAddress).getStakingToken()).transfer(sponsor, sponsorFee);
            emit SponsorFee(sponsor, sponsorFee);
        }

        if (mgmtFee != 0) {
            IERC20(IPolygonStakingFactory(factoryAddress).getStakingToken()).transfer(address(factoryAddress), mgmtFee);
            emit MgmtFee(address(factoryAddress), mgmtFee);
        }

        claimedNonces[unbondNonce] = true;

        emit ClaimTokens(owner, unbondNonce);
    }

    function withdrawRewards() external onlyOwner nonReentrant {
        uint amount = IPolygonStaking(IPolygonStakingFactory(factoryAddress).getStakingContract()).getLiquidRewards(address(this));

        (, uint val2,,) = IYieldManager(factoryAddress.getYieldManager()).getUserFactors(
            msg.sender,
            0
        );

        uint perfFee = (val2 * amount) / 100 / 100;
        uint sPerfFee;

        address sponsor = IYieldManager(factoryAddress.getYieldManager()).getAffiliate(owner);

        // get sponsor stats
        if (sponsor != address(0)) {
            (uint sval1,,,) = IYieldManager(factoryAddress.getYieldManager())
            .getUserFactors(sponsor, 1);
            sPerfFee = (perfFee * sval1)  / 100 / 100;
            perfFee -= sPerfFee;
        }

        // get reward
        IPolygonStaking(IPolygonStakingFactory(factoryAddress).getStakingContract()).withdrawRewards();

        // send tokens
        IERC20(IPolygonStakingFactory(factoryAddress).getRewardToken()).transfer(owner, amount - perfFee - sPerfFee);

        if (perfFee != 0) {
            IERC20(IPolygonStakingFactory(factoryAddress).getRewardToken()).transfer(address(factoryAddress), perfFee);
            emit PerformanceFee(address(factoryAddress), perfFee);
        }

        if (sponsor != address(0) && sPerfFee != 0) {
            IERC20(IPolygonStakingFactory(factoryAddress).getRewardToken()).transfer(sponsor, sPerfFee);
            emit SponsorPerformanceFee(sponsor, sPerfFee);
        }

        emit WithdrawRewards(owner, amount);
    }

    function getAmountPerNonce(uint _nonce) public view returns (uint) {
        return nonces[_nonce];
    }

    function getCurrentNonce() public view returns (uint) {
        return nonce;
    }

    function isNonceClaimed(uint _nonce) public view returns (bool) {
        return claimedNonces[_nonce];
    }

    function recoverERC20(address token, uint amount) public onlyOwner {
        require(factoryAddress.getRecoverOpen(), "recover not open");
        IERC20(token).transfer(owner, amount);
        emit ERC20Recovered(owner, amount);
    }
}

interface IPolygonStakingFactory {
    function getYieldManager() external view returns(address);
    function getRewardToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getStakingContract() external view returns (address);
    function getStakingContractStakeManager() external view returns (address);
    function getRecoverOpen() external view returns (bool);
}