// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract OnchainGateway {
    address public immutable onchainSwap;

    modifier onlyOnchainSwap() {
        require(onchainSwap == msg.sender, "Symb: caller is not the onchainSwap");
        _;
    }

    constructor(address _onchainSwap) {
        onchainSwap = _onchainSwap;
    }

    function claimTokens(
        address _token,
        address _from,
        uint256 _amount
    ) external onlyOnchainSwap {
        IERC20(_token).transferFrom(_from, onchainSwap, _amount );
    }
}