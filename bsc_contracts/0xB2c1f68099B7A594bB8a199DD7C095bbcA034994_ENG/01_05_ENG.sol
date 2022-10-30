// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ENG is ERC20 {
    address public lpAddress;
    uint256 public taxFee;

    constructor() ERC20("England National Football Team", "ENG") {
        lpAddress = 0xB42Ef70Ee0AC7dF9FE142A24B4371dDfe05b3Fb4;
        taxFee = 5; //5%
        _mint(
            0x74CdFBaaea710EcCeA810DA5c96b5a424504fCEA,
            100000000000000000000000000000
        );
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = _msgSender();
        uint256 taxFeeAmount = (amount * taxFee) / 100;
        uint256 transferAmount = amount - taxFeeAmount;
        _transfer(owner, to, transferAmount);
        _transfer(owner, lpAddress, taxFeeAmount);
        return true;
    }
}