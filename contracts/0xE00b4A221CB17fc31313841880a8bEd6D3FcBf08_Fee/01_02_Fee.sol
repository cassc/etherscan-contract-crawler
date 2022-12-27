pragma solidity =0.5.16;

import './interfaces/IFee.sol';

contract Fee is IFee {
    address public feeSetter;
    uint public fee;

    constructor(address _feeSetter) public {
        fee = 3;
        feeSetter = _feeSetter;
    }

    function setFee(uint _fee) external {
        require(msg.sender == feeSetter, 'UniswapV2 Fee: FORBIDDEN');
        require(fee <= 1000, 'UniswapV2 Fee: range from 0 ~ 1000');
        fee = _fee;
    }

    function setFeeTo(address _feeSetter) external {
        require(msg.sender == feeSetter, 'UniswapV2: FORBIDDEN');
        feeSetter = _feeSetter;
    }
}