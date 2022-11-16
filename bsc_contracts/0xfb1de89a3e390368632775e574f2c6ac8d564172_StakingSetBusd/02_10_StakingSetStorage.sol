// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

interface IRouter {
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountsOut(
        uint amountIn, 
        address[] memory path
    ) external view returns (uint[] memory amounts);

}

interface IPancakeRouter {
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
}

interface IStaking {
    function stake(uint256 amount) external;
    function stakeNonces (address) external view returns (uint256);
    function stakeFor(uint256 amount, address user) external;
    function getEquivalentAmount(uint amount) external view returns (uint);
    function balanceOf(address account) external view returns (uint256);
    function getReward() external;
    function withdraw(uint256 nonce) external;
    function rewardDuration() external returns (uint256);
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint value) external returns (bool);
}

interface IlpBnbCake {
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function harvestFromMasterChef() external;
    function getBoostMultiplier(address _user, uint256 _pid) external view returns (uint256);
    struct PoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory); 
    function totalRegularAllocPoint() external view returns (uint256);
    function totalSpecialAllocPoint() external view returns (uint256);
    function cakePerBlock(bool _isRegular) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
    function CAKE() external view returns(address);
}

interface IPriceFeed {
    function queryRate(address sourceTokenAddress, address destTokenAddress) external view returns (uint256 rate, uint256 precision);
    function wbnbToken() external view returns(address);
}


contract StakingSetStorage is ContextUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC165 {    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IWBNB public nimbusBNB;
    IWBNB public binanceBNB;
    IRouter public nimbusRouter;
    IPancakeRouter public pancakeRouter;
    IStaking public NbuStaking;
    IStaking public GnbuStaking;
    IMasterChef public CakeStaking;
    IlpBnbCake public lpBnbCake;
    IERC20Upgradeable public nbuToken;
    IERC20Upgradeable public gnbuToken;
    IERC20Upgradeable public cakeToken;
    IERC20Upgradeable public busdToken;
    address public purchaseToken;
    address public hubRouting;
    uint256 public minPurchaseAmount;
    uint256 public rewardDuration;
    uint256 public counter;
    uint256 public lockTime;
    uint256 public cakePID;
    uint256 public POOLS_NUMBER;

    mapping(uint256 => uint256) public providedAmount;

    struct NFTFields {
	  address pool;
	  address rewardToken;
	  uint256 rewardAmount;
	  uint256 percentage;
      uint256 stakedAmount;
    }  
    
    struct UserSupply { 
      uint NbuStakingAmount;
      uint GnbuStakingAmount;
      uint CakeBnbAmount;
      uint CakeShares;
      uint CurrentRewardDebt;
      uint CurrentCakeShares;
      uint NbuStakeNonce;
      uint GnbuStakeNonce;
      uint SupplyTime;
      uint BurnTime;
      uint TokenId;
      bool IsActive;
    }

    
    mapping(uint => uint256) internal _balancesRewardEquivalentNbu;
    mapping(uint => uint256) internal _balancesRewardEquivalentGnbu;
    mapping(uint => UserSupply) public tikSupplies;
    mapping(uint => uint256) public weightedStakeDate;

    event BuyStakingSet(uint indexed tokenId, address indexed purchaseToken, uint providedAmount, uint supplyTime);
    event WithdrawRewards(address indexed user, uint indexed tokenId, uint totalNbuReward, uint totalCakeReward);
    event BalanceNBURewardsNotEnough(address indexed user, uint indexed tokenId, uint totalNbuReward);
    event BurnStakingSet(uint indexed tokenId, uint nbuStakedAmount, uint gnbuStakedAmount, uint lpCakeBnbStakedAmount);
    event UpdateNimbusRouter(address indexed newNimbusRouterContract);
    event UpdateNbuStaking(address indexed newNbuStakingContract);
    event UpdateGnbuStaking(address indexed newGnbuStakingContract);
    event UpdateCakeStaking(address indexed newCakeStakingContract);
    event UpdateTokenNbu(address indexed newToken);
    event UpdateTokenGnbu(address indexed newToken);
    event UpdateTokenCake(address indexed newToken);
    event UpdateMinPurchaseAmount(uint newAmount);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed to, address indexed token, uint amount);
    event UpdateLockTime(uint indexed newlockTime);
    event UpdateCakePID(uint indexed newCakePID);
}