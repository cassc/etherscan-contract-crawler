// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/INFT.sol";
import "./NFTConstants.sol";

contract NFTPool2 is Ownable {
    using SafeERC20 for IERC20;

    address public signer;

    IUniswapV2Router02 public immutable router;
    IExchange public immutable exchange;
    IERC20 public immutable goe;
    IERC20 public immutable vegoe;
    address public immutable usdt;
    INFT public immutable nft;

    uint256 public luckyReward = 400 * 1e18;

    mapping(uint256 => bool) public used;
    mapping(address => bool) public blacklist;

    event Harvest(uint256 indexed id);

    constructor(
        address _router,
        address _exchange,
        address _goe,
        address _vegoe,
        address _usdt,
        address _nft
    ) {
        signer = msg.sender;

        router = IUniswapV2Router02(_router);
        exchange = IExchange(_exchange);
        goe = IERC20(_goe);
        vegoe = IERC20(_vegoe);
        usdt = _usdt;
        nft = INFT(_nft);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBlacklist(address account, bool state) external onlyOwner {
        blacklist[account] = state;
    }

    function setLuckyReward(uint256 amount) external onlyOwner {
        luckyReward = amount;
    }

    function lucky(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            nft.burn(msg.sender, LUCKY, 1);
            goe.transfer(msg.sender, luckyReward);
        }
    }

    function harvest(bytes memory payload, bytes memory signature) external {
        string memory message = string(payload);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();

        uint256 id;
        address account;
        uint256 kind;
        uint256 amount;
        uint256 deadline;
        (id, account, kind, amount, deadline) = abi.decode(payload, (uint256, address, uint256, uint256, uint256));

        if (block.timestamp > deadline) revert();
        if (used[id] == true) revert();
        used[id] = true;

        // 0-principal
        if (kind == 0) {
            goe.transfer(account, amount);
        }
        // 1-interest
        if (kind == 1) {
            amount = (amount * exchange.price()) / 1e18;
            vegoe.safeTransfer(account, quote(amount));
        }
        // 2-reward
        if (kind == 2) {
            if (blacklist[account] == true) revert();
            amount = (amount * exchange.price()) / 1e18;
            vegoe.safeTransfer(account, quote(amount));
        }

        emit Harvest(id);
    }

    function quote(uint256 amount) public view returns (uint256) {
        address pair = IUniswapV2Factory(router.factory()).getPair(address(usdt), address(vegoe));
        (uint256 amount0, uint256 amount1, ) = IUniswapV2Pair(pair).getReserves();
        if (address(usdt) < address(vegoe)) {
            // usdt: amount0 vegoe: amount1
            return (amount * amount1) / amount0;
        } else {
            // usdt: amount1 vegoe: amount0
            return (amount * amount0) / amount1;
        }
    }

    function claim(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}