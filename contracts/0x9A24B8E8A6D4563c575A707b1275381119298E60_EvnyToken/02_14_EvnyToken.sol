pragma solidity >=0.6.0 <0.8.0;

import "../token/reshape/ConstantRatioReshapableERC20.sol";
import "../token/reshape/SweepToOwner.sol";

contract EvnyToken is Ownable, ConstantRatioReshapableERC20, SweepToOwner {
    address public liquidityAdder;

    constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    public { }

    function setLiquidityAdder(address _liquidityAdder) external onlyOwner() {
        liquidityAdder = _liquidityAdder;
    }

    function deposit(address token, uint256 amount) external virtual override returns(uint256) {
        require(msg.sender == liquidityAdder || msg.sender == owner(), "EvnyToken: Not allowed");
        return _deposit(msg.sender, msg.sender, token, amount);
    }
}