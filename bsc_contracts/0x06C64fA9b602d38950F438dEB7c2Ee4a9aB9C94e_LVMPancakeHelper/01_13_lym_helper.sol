// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interface/IPancake.sol";
import "contracts/other/divestor.sol";
import "hardhat/console.sol";

interface ITRS {
    function pair() external view returns (address);

    function addLiquidity() external returns (uint256);

    function removeLiquidity(address wallet_) external returns (uint256 amountA, uint256 amountB);
}

contract LVMPancakeHelper is Ownable, Divestor {
    // IPancakeRouter02 public router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeRouter02 public router;
    IPancakePair public pair;
    address public banker;
    address[] public path;
    mapping(address => bool) public admin;

    event RemoveLiquidity(uint256 indexed liquidity, uint256 indexed amountA, uint256 indexed amountB);

    constructor(address router_, address banker_) {
        router = IPancakeRouter02(router_);
        banker = banker_;
        // banker = 0xfc471E838C09Ad4fcf6DFD002f5eF69e7e0d2C4C;
    }

    modifier onlyAdmin() {
        require(admin[_msgSender()], "not admin");
        _;
    }
    modifier initPath() {
        require(path.length >= 2, "wrong path");
        _;
    }

    function setBanker(address newBanker_) public onlyOwner {
        banker = newBanker_;
    }

    function pathSize() public view returns (uint256) {
        return path.length;
    }

    function getLiquidity(address account_) public view initPath returns (uint256) {
        return pair.balanceOf(account_);
    }

    function setRouter(address router_) public onlyOwner {
        router = IPancakeRouter02(router_);
    }

    function setPath(address[] calldata path_) public onlyOwner {
        path = new address[](path_.length);
        for (uint256 i = 0; i < path_.length; i++) {
            path[i] = path_[i];
        }
        // pair = IPancakePair(pair_);
        // pair = IPancakePair(factory.getPair(path_[0], path_[path_.length - 1]));
        swapAprove();
    }

    function setAdmin(address addr_, bool com_) public onlyOwner {
        admin[addr_] = com_;
    }

    function swapAprove() public onlyOwner initPath {
        address tokenA = path[0];
        address tokenB = path[path.length - 1];
        address routerAddr = address(router);
        IERC20(tokenA).approve(routerAddr, 1e28);
        IERC20(tokenB).approve(routerAddr, 1e28);
        // pair.approve(routerAddr, 1e28);
    }

    function addLiquidity() public onlyAdmin returns (uint256) {
        uint256 amount = IERC20(path[0]).balanceOf(address(this));
        uint256 _half = amount / 2;
        uint256 amountA = amount - _half;
        uint256 _oldBalance = IERC20(path[1]).balanceOf(address(this));

        // router.swapExactTokensForTokens(_half, 0, path, address(this), block.timestamp + 720);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_half, 0, path, address(this), block.timestamp + 720);
        // router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_half, 0, path, address(this), block.timestamp + 720);

        uint256 amountB = IERC20(path[1]).balanceOf(address(this)) - _oldBalance;
        router.addLiquidity(path[0], path[1], amountA, amountB, 0, 0, banker, block.timestamp + 720);
        return 0;
    }

    function removeLiquidity(address wallet_) public onlyAdmin initPath returns (uint256 amountA, uint256 amountB) {
        address tokenA = path[0];
        address tokenB = path[path.length - 1];

        uint256 liquidity = getLiquidity(address(this));

        (amountA, amountB) = router.removeLiquidity(tokenA, tokenB, liquidity, 0, 0, wallet_, block.timestamp + 720);
        emit RemoveLiquidity(liquidity, amountA, amountB);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}