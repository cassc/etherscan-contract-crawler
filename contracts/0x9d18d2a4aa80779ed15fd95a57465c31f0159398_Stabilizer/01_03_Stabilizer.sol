pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./ERC20.sol";

interface IStrat {
    function invest() external; // underlying amount must be sent from vault to strat address before
    function divest(uint amount) external; // should send requested amount to vault directly, not less or more
    function calcTotalValue() external returns (uint);
    function underlying() external view returns (address);
}

contract Stabilizer {
    using SafeMath for uint;

    uint public constant MAX_FEE = 1000; // 10%
    uint public constant FEE_DENOMINATOR = 10000;
    uint public buyFee;
    uint public sellFee;
    uint public supplyCap;
    uint public supply;
    ERC20 public synth;
    ERC20 public reserve;
    address public operator;
    IStrat public strat;
    address public governance;

    constructor(ERC20 synth_, ERC20 reserve_, address gov_, uint buyFee_, uint sellFee_, uint supplyCap_) public {
        require(buyFee_ <= MAX_FEE, "STABILIZER:BUYFEE_TOO_HIGH");
        require(sellFee_ <= MAX_FEE, "STABILIZER:SELLFEE_TOO_HIGH");
        synth = synth_;
        reserve = reserve_;
        governance = gov_;
        buyFee = buyFee_;
        sellFee = sellFee_;
        operator = msg.sender;
        supplyCap = supplyCap_;
    }

    modifier onlyOperator {
        require(msg.sender == operator || msg.sender == governance, "STABILIZER:ONLY_OPERATOR_OR_GOV");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "STABILIZER:ONLY_GOV");
        _;
    }

    function setOperator(address operator_) public {
        require(msg.sender == governance || msg.sender == operator, "STABILIZER:ONLY_GOV_OR_OPERATOR");
        require(operator_ != address(0), "STABILIZER:NO_ADDRESS_ZERO");
        operator = operator_;
    }

    function setBuyFee(uint amount) public onlyGovernance {
        require(amount <= MAX_FEE, "STABILIZER:AMOUNT_TOO_HIGH");
        buyFee = amount;
    }

    function setSellFee(uint amount) public onlyGovernance {
        require(amount <= MAX_FEE, "STABILIZER:AMOUNT_TOO_HIGH");
        sellFee = amount;
    }
    
    function setCap(uint amount) public onlyOperator {
        supplyCap = amount;
    }

    function setGovernance(address gov_) public onlyGovernance {
        require(gov_ != address(0), "STABILIZER:NO_ADDRESS_ZERO");
        governance = gov_;
    }

    function setStrat(IStrat newStrat) public onlyGovernance {
        require(newStrat.underlying() == address(reserve), "STABILIZER:INVALID_STRAT");
        if(address(strat) != address(0)) {
            uint prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
        }
        reserve.transfer(address(newStrat), reserve.balanceOf(address(this)));
        newStrat.invest();
        strat = newStrat;
    }

    function removeStrat() public onlyGovernance {
        uint prevTotalValue = strat.calcTotalValue();
        strat.divest(prevTotalValue);

        strat = IStrat(address(0));
    }

    function takeProfit() public {
        uint totalReserves = getTotalReserves();
        if(totalReserves > supply) {
            uint profit = totalReserves - supply; // underflow prevented by if condition
            if(address(strat) != address(0)) {
                uint bal = reserve.balanceOf(address(this));
                if(bal < profit) {
                    strat.divest(profit - bal); // underflow prevented by if condition
                }
            }
            reserve.transfer(governance, profit);
        }
    }

    function buy(uint amount) public {
        require(supply.add(amount) <= supplyCap, "STABILIZER:SUPPLY_EXCEEDED_CAP");
        if(address(strat) != address(0)) {
            reserve.transferFrom(msg.sender, address(strat), amount);
            strat.invest();
        } else {
            reserve.transferFrom(msg.sender, address(this), amount);
        }

        if(buyFee > 0) {
            uint fee = amount.mul(buyFee).div(FEE_DENOMINATOR);
            reserve.transferFrom(msg.sender, governance, fee);
            emit Buy(msg.sender, amount, amount.add(fee));
        } else {
            emit Buy(msg.sender, amount, amount);
        }

        synth.mint(msg.sender, amount);
        supply = supply.add(amount);
    }

    function sell(uint amount) public {
        synth.transferFrom(msg.sender, address(this), amount);
        synth.burn(amount);

        uint reserveBal = reserve.balanceOf(address(this));
        if(address(strat) != address(0) && reserveBal < amount) {
            strat.divest(amount - reserveBal); // underflow prevented by if condition
        }

        uint afterFee;
        if(sellFee > 0) {
            uint fee = amount.mul(sellFee).div(FEE_DENOMINATOR);
            afterFee = amount.sub(fee);
            reserve.transfer(governance, fee);
        } else {
            afterFee = amount;
        }
        
        reserve.transfer(msg.sender, afterFee);
        supply = supply.sub(amount);
        emit Sell(msg.sender, amount, afterFee);
    }

    function rescue(ERC20 token) public onlyGovernance {
        require(token != reserve, "STABILIZER:RESERVE_NOT_RESCUED");
        token.transfer(governance, token.balanceOf(address(this)));
    }

    function getTotalReserves() internal returns (uint256 bal) { // new view function because strat.calcTotalValue() is not view function
        bal = reserve.balanceOf(address(this));
        if(address(strat) != address(0)) {
            bal = bal.add(strat.calcTotalValue());
        }
    }

    event Buy(address indexed user, uint purchased, uint spent);
    event Sell(address indexed user, uint sold, uint received);
}