// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../router.sol";
import "./INode.sol";

contract OPTC is ERC20, Ownable {
    using Address for address;
    address public pair;
    IPancakeRouter02 public router;
    INode public node;
    address public fund;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public usdt;
    mapping(address => bool) public wContract;
    uint[]  FeeRate;
    mapping(address => address) public invitor;
    mapping(address => bool) public W;
    //    uint public lastPrice;
    uint public maxSellPercent;
    mapping(address => uint) public lastSell;
    uint public lastPriceChange;
    uint public sellFuse;
    bool public whiteStatus;
    address public setter;

    struct PriceInfo {
        uint startTime;
        uint endTime;
        uint total;
        uint length;
    }

    mapping(uint => PriceInfo) public priceInfo;
    bool public whiteLock;
    constructor() ERC20('Farming Games Association', 'OPTC'){
        _mint(msg.sender, 3300000 ether);
        FeeRate = [4, 3, 2];
        maxSellPercent = 30;
        sellFuse = 9;
        W[msg.sender] = true;
        fund = msg.sender;
        whiteStatus = true;
        setter = msg.sender;
        whiteLock = true;
        //burn,fund,node
    }

    function setFund(address addr) external onlyOwner {
        fund = addr;
    }

    function setWhiteLock(bool b) external onlyOwner {
        whiteLock = b;
    }

    function setRouter(address addr) public onlyOwner {
        router = IPancakeRouter02(addr);
        pair = IPancakeFactory(router.factory()).createPair(address(this), usdt);
        wContract[address(router)] = true;
        wContract[address(this)] = true;
        wContract[pair] = true;
    }


    function setUsdt(address addr) public onlyOwner {
        usdt = addr;
    }

    function setNode(address addr) external onlyOwner {
        node = INode(addr);
        wContract[addr];
    }

    function setW(address[] memory addr, bool b) external onlyOwner {
        for (uint i = 0; i < addr.length; i ++) {
            W[addr[i]] = b;
        }
    }

    function setWContract(address[] memory addr, bool b) external onlyOwner {
        for (uint i = 0; i < addr.length; i ++) {
            wContract[addr[i]] = b;
        }
    }

    function setSetter(address addr) external onlyOwner {
        setter = addr;
    }

    function getPrice() public view returns (uint) {
        if (pair == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
        if (reserve0 == 0) {
            return 0;
        }
        if (IPancakePair(pair).token0() == address(this)) {
            return reserve1 * 1e18 / reserve0;
        } else {
            return reserve0 * 1e18 / reserve1;
        }
    }

    function setPair(address addr) external onlyOwner {
        pair = addr;
    }

    function setStatus(bool b) external onlyOwner {
        whiteStatus = b;
    }

    //    function changeLastPrice(uint _price) external onlyOwner {
    //        lastPrice = _price;
    //    }

    function updatePrice(uint price) internal {
        if (price == 0) {
            return;
        }
        lastPriceChange = block.timestamp - ((block.timestamp - 3600 * 16) % 86400);
        PriceInfo storage info = priceInfo[lastPriceChange];
        if (info.startTime != 0 && block.timestamp > info.endTime) {
            return;
        } else if (info.startTime == 0) {
            info.startTime = lastPriceChange;
            info.endTime = lastPriceChange + 3600 * 3;
            info.length = 1;
            info.total = price;
        } else if (block.timestamp >= info.startTime && block.timestamp < info.endTime) {
            info.total += price;
            info.length++;
        }

    }

    function lastPrice() public view returns (uint){
        if (priceInfo[lastPriceChange].length == 0) {
            return 0;
        }
        return priceInfo[lastPriceChange].total / priceInfo[lastPriceChange].length;
    }

    function _processFee(address sender, address recipient, uint amount, bool isSell) internal {
        uint burnAmount;
        uint fundAmount;
        uint nodeAmount;
        if (isSell) {
            require(block.timestamp - lastSell[sender] >= 86400, 'too fast');
            require(amount <= balanceOf(sender) * maxSellPercent / 100, 'too much');
            uint price = getPrice();
            lastSell[sender] = block.timestamp;
            if (price <= lastPrice() * (100 - sellFuse) / 100) {
                uint temp = 100 - (price * 100 / lastPrice());
                uint rates = temp / 9;
                if (rates > 5) {
                    rates = 5;
                }
                burnAmount = amount * FeeRate[0] * rates / 100;
                fundAmount = amount * FeeRate[1] * rates / 100;
                nodeAmount = amount * FeeRate[2] * rates / 100;
            } else {
                burnAmount = amount * FeeRate[0] / 100;
                fundAmount = amount * FeeRate[1] / 100;
                nodeAmount = amount * FeeRate[2] / 100;
            }
        } else {
            burnAmount = amount * FeeRate[0] / 100;
            fundAmount = amount * FeeRate[1] / 100;
            nodeAmount = amount * FeeRate[2] / 100;
        }
        _transfer(sender, burnAddress, burnAmount);
        _transfer(sender, fund, fundAmount);
        _transfer(sender, address(node), nodeAmount);
        node.syncDebt(nodeAmount);
        uint _amount = amount - burnAmount - fundAmount - nodeAmount;
        _transfer(sender, recipient, _amount);

    }


    function _processTransfer(address sender, address recipient, uint amount) internal {

        if (balanceOf(burnAddress) >= 99 * totalSupply() / 100) {
            _transfer(sender, recipient, amount);
            return;
        }
        if (sender == setter) {
            _transfer(sender, recipient, amount);
            return;
        }
        if (recipient.isContract() && whiteStatus && sender != setter) {
            require(wContract[recipient], 'not white contract');
        }

        if ((sender != pair && recipient != pair) || W[sender] || W[recipient]) {
            _transfer(sender, recipient, amount);
            return;
        }
        if (sender == pair) {
            require(!whiteLock, 'white lock');
            _processFee(sender, recipient, amount, false);
            uint price = getPrice();
            updatePrice(price);

        } else {
            require(!whiteLock, 'white lock');
            _processFee(sender, recipient, amount, true);
            uint price = getPrice();
            updatePrice(price);
        }

    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _processTransfer(sender, recipient, amount);
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }
        return true;
    }

    function safePull(address token, address recipient, uint amount) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _processTransfer(msg.sender, recipient, amount);
        return true;
    }


}