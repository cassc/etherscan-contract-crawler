pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

contract SwapperPCS is
    Initializable,
    OwnableUpgradeable,
    ManageableUpgradeable
{
    address public TOKEN;
    IUniswapV2Router02 public ROUTER;

    address public GROWTH;
    address public BANK;

    function initialize(
        address token,
        address router,
        address growth,
        address bank
    ) public initializer {
        __Ownable_init();
        TOKEN = token;
        ROUTER = IUniswapV2Router02(router);
        GROWTH = growth;
        BANK = bank;

        IERC20Upgradeable(token).approve(router, type(uint256).max);
        IERC20Upgradeable(ROUTER.WETH()).approve(router, type(uint256).max);
    }

    function executeSwaps(
        uint256 toLiq,
        uint256 toGrowth,
        uint256 toBank,
        uint256 total
    ) public onlyManager {
        total -= toLiq / 2;

        address[] memory path = new address[](2);
        path[0] = TOKEN;
        path[1] = ROUTER.WETH();

        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            total,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbBalance = IERC20Upgradeable(ROUTER.WETH()).balanceOf(
            address(this)
        );

        ROUTER.addLiquidity(
            TOKEN,
            ROUTER.WETH(),
            toLiq / 2,
            ((bnbBalance * toLiq) / 2) / total,
            0,
            0,
            GROWTH,
            block.timestamp
        );

        IERC20Upgradeable(ROUTER.WETH()).transfer(
            GROWTH,
            (bnbBalance * toGrowth) / total
        );

        IERC20Upgradeable(ROUTER.WETH()).transfer(
            BANK,
            (bnbBalance * toBank) / total
        );
        IBank(BANK).addRewards(ROUTER.WETH(), (bnbBalance * toBank) / total);
    }

    receive() external payable {}

    fallback() external payable {}
}