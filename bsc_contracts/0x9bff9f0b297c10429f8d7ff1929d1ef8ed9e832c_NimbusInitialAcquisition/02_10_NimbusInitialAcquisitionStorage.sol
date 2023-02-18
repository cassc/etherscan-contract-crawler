// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

interface IBEP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IBEP165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBEP165).interfaceId;
    }
}

interface IBEP721 is IBEP165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface ISmartLP is IBEP721 {
    function buySmartLPforBNB() payable external;
    function buySmartLPforWBNB(uint256 amount) external;
    function buySmartLPforToken(uint256 amount) external;
    function withdrawUserRewards(uint tokenId) external;
    function tokenCount() external view returns(uint);
    function getUserTokens(address user) external view returns (uint[] memory);
    function WBNB() external view returns(address);
}

interface IStakingMain is IBEP721 {
    function buySmartStaker(uint256 _setNum, uint _amount) external payable;
    function withdrawReward(uint256 _id) external;
    function tokenCount() external view returns(uint);
    function getUserTokens(address user) external view returns (uint[] memory);
}

interface IVestingNFT is IBEP721 {
    function safeMint(address to, string memory uri, uint nominal, address token) external;
    function totalSupply() external view returns (uint256);
    function lastTokenId() external view returns (uint256);
    function burn(uint256 tokenId) external;
    struct Denomination {
        address token;
        uint256 value;
    }
    function denominations(uint256 tokenId) external returns (Denomination memory denomination);
}

interface INimbusReferralProgram {
    function lastUserId() external view returns (uint);
    function userSponsorByAddress(address user)  external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

interface INimbusStakingPool {
    struct StakeNonceInfo {
        uint256 unlockTime;
        uint256 stakeTime;
        uint256 stakingTokenAmount;
        uint256 rewardsTokenAmount;
        uint256 rewardRate;
    }
    function stakeFor(uint amount, address user) external;
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns (IERC20Upgradeable);
    function rewardsToken() external view returns (IERC20Upgradeable);
    function getRewardForUser(address user) external;
    function stakeNonceInfos(address user, uint256 nonce) external view returns (StakeNonceInfo memory);
    function stakeNonces(address user) external view returns (uint256);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint value) external returns (bool);
}

interface INimbusRouter {
    function NBU_WBNB() external view returns(address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function pairFor(address tokenA, address tokenB) external view returns (INimbusPair);
}

interface INimbusPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IPancakeRouter {
    function WETH() external view returns(address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface INimbProxy {
    function mint(address receiver, uint256 amount) external;
}

interface INimbusReferralProgramMarketing {
    function registerUser(address user, uint sponsorId) external returns(uint userId);
    function updateReferralProfitAmount(address user, uint amount) external;
    function registerUserBySponsorId(address user, uint sponsorId, uint category) external returns (uint);
    function userPersonalTurnover(address user) external returns(uint);
}

interface IPriceFeed {
    function queryRate(address sourceTokenAddress, address destTokenAddress) external view returns (uint256 rate, uint256 precision);
    function wbnbToken() external returns(address);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

contract NimbusInitialAcquisitionStorage is OwnableUpgradeable, PausableUpgradeable {
    IERC20Upgradeable public SYSTEM_TOKEN;
    address public NBU_WBNB;
    INimbusReferralProgram public referralProgram;
    INimbusReferralProgramMarketing public referralProgramMarketing;
    IPriceFeed public priceFeed;

    IVestingNFT public nftVesting;
    ISmartLP public nftCashback;
    IStakingMain public nftSmartStaker;

    string public nftVestingUri;

    bool public allowAccuralMarketingReward;

    mapping(uint => INimbusStakingPool) public stakingPools;
    mapping(address => uint) public userPurchases;
    mapping(address => uint) public userPurchasesEquivalent;

    address public recipient;                      

    INimbusRouter public swapRouter;                
    mapping (address => bool) public allowedTokens;
    address public swapToken;                       
    
    uint public sponsorBonus;
    uint public swapTokenAmountForSponsorBonusThreshold;  
    mapping(address => uint) public unclaimedSponsorBonus;
    mapping(address => uint) public unclaimedSponsorBonusEquivalent;

    bool public usePriceFeeds;

    uint public cashbackBonus;
    uint public swapTokenAmountForCashbackBonusThreshold;  

    bool public vestingRedeemingAllowed;

    event BuySystemTokenForToken(address indexed token, uint indexed stakingPool, uint tokenAmount, uint systemTokenAmount, uint swapTokenAmount, address indexed systemTokenRecipient);
    event Restake(uint indexed stakingPoolIdSrc, uint indexed stakingPoolIdDst, uint currentStakingNonce, uint systemTokenAmount, address indexed systemTokenRecipient);
    event ProcessSponsorBonus(address indexed user, address indexed nftContract, uint nftTokenId, uint amount, uint indexed timestamp);
    event AddUnclaimedSponsorBonus(address indexed sponsor, address indexed user, uint systemTokenAmount, uint swapTokenAmount);
    event SwapPriceImpact(uint systemTokenAddPart, uint tokenAmount, uint swapPartBnb);

    event VestingNFTRedeemed(address indexed nftVesting, uint indexed tokenId, address user, address token, uint value);

    event UpdateTokenSystemTokenWeightedExchangeRate(address indexed token, uint indexed newRate);
    event ToggleUsePriceFeeds(bool indexed usePriceFeeds);
    event ToggleVestingRedeemingAllowed(bool indexed vestingRedeemingAllowed);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed token, address indexed to, uint amount);

    event AllowedTokenUpdated(address indexed token, bool allowance);
    event SwapTokenUpdated(address indexed swapToken);
    event SwapTokenAmountForSponsorBonusThresholdUpdated(uint indexed amount);
    event SwapTokenAmountForCashbackBonusThresholdUpdated(uint indexed amount);

    event ProcessCashbackBonus(address indexed to, address indexed nftContract, uint nftTokenId, address purchaseToken, uint amount, uint indexed timestamp);
    event UpdateCashbackBonus(uint indexed cashbackBonus);
    event UpdateNFTVestingContract(address indexed nftVestingAddress, string nftVestingUri);
    event UpdateNFTCashbackContract(address indexed nftCashbackAddress);
    event UpdateNFTSmartStakerContract(address indexed nftSmartStakerAddress);
    event UpdateVestingParams(uint vestingFirstPeriod, uint vestingSecondPeriod);
    event ImportUserPurchases(address indexed user, uint amount, bool indexed isEquivalent, bool indexed addToExistent);
    event ImportSponsorBonuses(address indexed user, uint amount, bool indexed isEquivalent, bool indexed addToExistent);

}