import "./CErc20.sol";
import "./SafeMath.sol";
import "./Synth.sol";

pragma solidity ^0.5.16;

contract Fed {
    using SafeMath for uint;

    CErc20 public ctoken;
    Synth public underlying;
    address public chair; // Fed Chair
    address public gov;
    uint public supply;
    address public feeDist;

    event Expansion(uint amount);
    event Contraction(uint amount);

    constructor(CErc20 ctoken_, address feeDist_) public {
        ctoken = ctoken_;
        feeDist = feeDist_;
        underlying = Synth(ctoken_.underlying());
        underlying.approve(address(ctoken), uint(-1));
        chair = tx.origin;
        gov = tx.origin;
    }

    function changeGov(address newGov_) public {
        require(msg.sender == gov, "ONLY GOV");
        gov = newGov_;
    }

    function changeChair(address newChair_) public {
        require(msg.sender == gov, "ONLY GOV");
        chair = newChair_;
    }

    function changeFeeDistribution(address newFee_) public {
        require(msg.sender == gov, "ONLY GOV");
        feeDist = newFee_;
    }

    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    function expansion(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        underlying.mint(address(this), amount);
        require(ctoken.mint(amount, false) == 0, 'Supplying failed');
        supply = supply.add(amount);
        emit Expansion(amount);
    }

    function contraction(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        require(amount <= supply, "AMOUNT TOO BIG"); // can't burn profits
        require(ctoken.redeemUnderlying(amount) == 0, "Redeem failed");
        underlying.burn(amount);
        supply = supply.sub(amount);
        emit Contraction(amount);
    }

    function takeProfit() public {
        uint underlyingBalance = ctoken.balanceOfUnderlying(address(this));
        uint profit = underlyingBalance.sub(supply);
        if(profit > 0) {
            require(ctoken.redeemUnderlying(profit) == 0, "Redeem failed");
            underlying.transfer(gov, profit);
        }
    }

    function takeProfitFeeDist() public {
        uint underlyingBalance = ctoken.balanceOfUnderlying(address(this));
        uint feeProfit = underlyingBalance.sub(supply);
        if(feeProfit > 0) {
            require(ctoken.redeemUnderlying(feeProfit) == 0, "Redeem failed");
            underlying.transfer(feeDist, feeProfit);
        }
    }
}