// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract MTGToken is ERC20Burnable, Ownable {
    uint32 private constant HUNDRED_PERCENT = 1e6;
    uint32 private constant MAX_FEE_PERCENTAGE = 2e5;

    address public transferCallbackAddress;
    address public lotteryWallet;
    uint32 public burnPercentage;
    uint32 public lotteryPercentage;

    mapping(address => bool) public isExcludedFromFees;

    event TakeFee(address indexed sender, uint256 burnAmount, uint256 lotteryAmount);

    constructor(
        string memory _name, 
        string memory _symbol,
        uint32 _burnPercentage,
        uint32 _lotteryPercentage,
        address _lotteryWallet,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        require(_burnPercentage <= MAX_FEE_PERCENTAGE && _lotteryPercentage <= MAX_FEE_PERCENTAGE);
        require(_lotteryWallet != address(0));

        burnPercentage = _burnPercentage;
        lotteryPercentage = _lotteryPercentage;
        lotteryWallet = _lotteryWallet;

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(0)] = true;
        isExcludedFromFees[_lotteryWallet] = true;

        _mint(msg.sender, _totalSupply);
    }

    // ================ OWNER FUNCTIONS ================ //

    function setTransferCallbackAddress(address newTransferCallbackAddress) external onlyOwner {
        transferCallbackAddress = newTransferCallbackAddress;
    }

    function setBurnPercentage(uint32 newBurnPercentage) external onlyOwner {
        require(newBurnPercentage <= MAX_FEE_PERCENTAGE);
        burnPercentage = newBurnPercentage;
    }

    function setLotteryPercentage(uint32 newLotteryPercentage) external onlyOwner {
        require(newLotteryPercentage <= MAX_FEE_PERCENTAGE);
        lotteryPercentage = newLotteryPercentage;
    }
    
    function setLotteryWallet(address newLotteryWallet) external onlyOwner {
        require(newLotteryWallet != address(0));
        lotteryWallet = newLotteryWallet;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        isExcludedFromFees[owner()] = false;
        super.transferOwnership(newOwner);
        isExcludedFromFees[newOwner] = true;
    }

    // ================ INTERNAl FUNCTIONS ================ //

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (address(transferCallbackAddress) != address(0)) {
            // to enable onchain lottery later
            transferCallbackAddress.call{gas: 200000}(abi.encodeWithSignature("callback(address,address,uint256)", sender, recipient, amount));
        }

        amount -= _takeFee(sender, recipient, amount);
        super._transfer(sender, recipient, amount);
    }

    function _takeFee(address sender, address recipient, uint256 amount) internal returns (uint256 totalFee) {
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            return 0;
        }

        uint256 burnAmount;
        uint256 lotteryAmount;

        burnAmount = amount * burnPercentage / HUNDRED_PERCENT;
        totalFee += burnAmount;
        if (burnAmount > 0) {
            _burn(sender, burnAmount);
        }

        lotteryAmount = amount * lotteryPercentage / HUNDRED_PERCENT;
        totalFee += lotteryAmount;
        if (lotteryAmount > 0) {
            super._transfer(sender, lotteryWallet, lotteryAmount);
        }

        emit TakeFee(sender, burnAmount, lotteryAmount);
    }
}