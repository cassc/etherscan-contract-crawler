// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/ERC20.sol";

contract YZT is ERC20, Ownable {
    using SafeMath for uint256;

    address public poolAddress;
    address public pairAddress;
    mapping(address => bool) amountWhiteList;
    mapping(address => bool) feeWhiteList;
    mapping(address => bool) blackList;
    address public platForm;
    uint256 startTime = 0;
    event TradeFee(
        address indexed user,
        uint256 amount,
        uint256 rewardAmount,
        uint256 burnAmount
    );

    constructor() ERC20("YZT Token", "YZT", 18) {
        _mint(msg.sender, 99990000 * 10**uint256(decimals()));
    }

    function setPair(address _pair) public onlyOwner {
        pairAddress = _pair;
        amountWhiteList[_pair] = true;
    }

    function setPool(address _pool) public onlyOwner {
        poolAddress = _pool;
        amountWhiteList[_pool] = true;
    }

    function setAmountWhiteList(address _addr, bool _setForm) public onlyOwner {
        amountWhiteList[_addr] = _setForm;
    }

    function setFeeWhiteList(address _addr, bool _setForm) public onlyOwner {
        feeWhiteList[_addr] = _setForm;
    }

    function addBlackList(address _addr) internal {
        blackList[_addr] = true;
    }

    function setBlackList(address _addr, bool _setForm) public onlyOwner {
        blackList[_addr] = _setForm;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!blackList[sender], "Transfer error");
        if (recipient == pairAddress) {
            if (startTime == 0) {
                startTime = block.timestamp;
                platForm = sender;
                feeWhiteList[sender] = true;
            }
        }
        if (pairAddress == sender) {
            require(amount <= 10000 * 10**18, "Transfer amount exceed limit");
            if (startTime > 0 && block.timestamp - startTime < 600) {
                if (recipient != platForm) {
                    addBlackList(recipient);
                }
            }
        }

        if (!isContract(sender)) {
            require(balanceOf(sender) > 10**15, "Balance less than limit");
            if (balanceOf(sender) == amount) {
                amount = amount.sub(10**15);
            }
        }
        if (!amountWhiteList[recipient]) {
            require(
                balanceOf(recipient).add(amount) <= 100000 * 10**18,
                "balance of recipient exceed limit"
            );
        }
        if (pairAddress == recipient && !feeWhiteList[sender]) {
            _feeTransfer(sender, recipient, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function _feeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 recipientAmount = _recipientAmountSubFee(sender, amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(recipientAmount);
        emit Transfer(sender, recipient, recipientAmount);
    }

    function _recipientAmountSubFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 rewardAmount = amount.mul(20).div(1000);
        uint256 burnAmount = amount.mul(20).div(1000);
        _balances[poolAddress] = _balances[poolAddress].add(rewardAmount);
        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(sender, poolAddress, rewardAmount);
        emit Transfer(sender, address(0), burnAmount);
        emit TradeFee(sender, amount, rewardAmount, burnAmount);
        return amount.sub(rewardAmount).sub(burnAmount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}