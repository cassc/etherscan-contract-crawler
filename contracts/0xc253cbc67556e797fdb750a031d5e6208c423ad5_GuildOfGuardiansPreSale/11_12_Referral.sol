pragma solidity >=0.8.0 <0.9.0;

contract Referral {
    uint16 referralDiscount;
    uint16 referrerBonus;
    mapping(address => uint256) public referrerBonuses;

    event WithdrawBonus(uint256 _amount, address _referrer);

    constructor(uint16 _referralDiscount, uint16 _referrerBonus) {
        referralDiscount = _referralDiscount;
        referrerBonus = _referrerBonus;
    }

    function withdrawBonus() public {
        uint256 amount = referrerBonuses[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        referrerBonuses[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawBonus(amount, msg.sender);
    }

    function _calcReferrals(uint256 _orderCost)
        internal
        view
        returns (uint256 toReferrer, uint256 discount)
    {
        toReferrer = (_orderCost * referrerBonus) / 10000;
        discount = (_orderCost * referralDiscount) / 10000;

        return (toReferrer, discount);
    }
}