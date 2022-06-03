// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// stores daily trades
// is minter of token, first interaction mints tokens and distributes tokens
// gives prorata tokens to traders and exchange daily

import '@openzeppelin/contracts/access/Ownable.sol';

interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);
}

contract DummyRewardDistributor is Ownable {
    address public trader;

    /// _time to start rewards
    constructor(address _trader, address _governance) {
        trader = _trader;
        _transferOwnership(_governance);
    }

    modifier onlyTrader() {
        require(msg.sender == trader);
        _;
    }

    // dummy function will be replaced with the correct contract once audits are done , refer here--> https://github.com/golom-protocol/contracts
    function addFee(address[2] memory addr, uint256 fee) public onlyTrader {}

    function withdrawTokens(address _token, address _to) external onlyOwner {
        ERC20(_token).transfer(_to, ERC20(_token).balanceOf(address(this)));
    }

    function withdrawEth(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}
}