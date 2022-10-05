pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Interface based on 
   https://github.com/balancer-labs/balancer-v2-monorepo/blob/6cca6c74e26d9e78b8e086fbdcf90075f99d8e76/pkg/vault/contracts/interfaces/IVault.sol
*/
interface IVault {
    function WETH() external view returns (address);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

contract Swapper {
    address public TOKEN;
    address public WETH;
    IVault public VAULT;
    bytes32 public POOL_ID;

    address public GROWTH;
    address public BANK;

    constructor(
        address token,
        address weth,
        address vault,
        bytes32 poolId,
        address growth,
        address bank
    ) {
        TOKEN = token;
        WETH = weth;
        VAULT = IVault(vault);
        POOL_ID = poolId;
        GROWTH = growth;
        BANK = bank;

        IERC20(token).approve(vault, type(uint256).max);
        IERC20(weth).approve(vault, type(uint256).max);
    }

    function executeSwaps(
        uint256 toLiq,
        uint256 toGrowth,
        uint256 toBank,
        uint256 total
    ) public {
        total -= toLiq / 2;
        bytes memory temp;
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
            POOL_ID,
            IVault.SwapKind.GIVEN_IN,
            TOKEN,
            WETH,
            total - toLiq / 2,
            temp
        );

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );

        VAULT.swap(singleSwap, funds, 0, block.timestamp + 100000);

        uint256 bnbBalance = IERC20(WETH).balanceOf(address(this));

        address[] memory assets = new address[](2);
        assets[0] = WETH;
        assets[1] = TOKEN;

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = ((bnbBalance * toLiq) / 2) / total;
        amountsIn[1] = toLiq / 2;

        bytes memory data = abi.encode(
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn
        );

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(
            assets,
            amountsIn,
            data,
            false
        );

        VAULT.joinPool(POOL_ID, address(this), payable(GROWTH), request);

        IERC20(WETH).transfer(GROWTH, (bnbBalance * toGrowth) / total);

        IERC20(WETH).transfer(BANK, (bnbBalance * toBank) / total);
        IBank(BANK).addRewards(WETH, (bnbBalance * toBank) / total);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}