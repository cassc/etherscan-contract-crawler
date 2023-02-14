// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Lambda is ERC20 {

    address private constant address1 = 0x999F380680F810dc2AB6a380e3093074E6F8B1e2;
    address private constant address2 = 0xE9973eb4F8125D008042cC24B7C9de43Fd729957;
    address private constant address3 = 0x2Da1DAe51Add94CA07CeF449e128219F3Aa73DDe;
    address private constant address4 = 0x1B50C7addbEd3DaA8c3B683aDE0B9a6be89AD789;
    address private constant address5 = 0x460271CEcd0CE07fc89794E616D3383775330F44;
    address private constant address6 = 0x4BBC7159c6Be53CeFAA6fd9B619414b26654BcD2;
    address private constant address7 = 0xb12691675580cc5c3638d1560aBC56d0d6a94a04;
    address private constant address8 = 0x96A6ee95C170A06817a0F5456C1De9Cab21664F8;
    address private constant address9 = 0x3435F469721fe167CF353ffED2d335766eC40b33;

    uint256 private constant amount1 = 1_000_000_000 * 10**18;
    uint256 private constant amount2 = 500_000_000 * 10**18;
    uint256 private constant amount3 = 300_000_000 * 10**18;
    uint256 private constant amount4 = 200_000_000 * 10**18;


    constructor() ERC20("Lambda", "LAMB") {
        _mint(address1, amount1);
        _mint(address2, amount1);
        _mint(address3, amount1);
        _mint(address4, amount1);
        _mint(address5, amount2);
        _mint(address6, amount2);
        _mint(address7, amount2);
        _mint(address8, amount4);
        _mint(address9, amount3);
    }
}