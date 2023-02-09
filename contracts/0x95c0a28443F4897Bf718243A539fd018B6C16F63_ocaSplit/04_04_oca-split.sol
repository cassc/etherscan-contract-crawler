// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ocaSplit is Ownable {

    address private GigaLabs = 0x957356F9412830c992D465FF8CDb9b0AA023020b; 
    address private Digi = 0x07DE35AB2d22Ad4f720f25191bf19cF6222a04d9; 
    address private Chopper = 0xda27bF313dCeF0Ee3916c9506A6Ad45F306F9F3b;
    address private Kenobi = 0xa4bAa7B5dC8a4eF2c8E346F21ae641aEe73a722A; 
    address private DaoBao = 0x753e9283e7bD8Be3a74097B7186Ea9DeFFAEe071;
    address private Deezy = 0x045Ed9EF63ef20C20835f0daBc86d4eC01Db43d5;
    address private JBuck = 0x0e05FC263cB57dB89aa9f32cc3f4743244520c45;
    address private Rizzy = 0x6928693227f6A31c3B1F9E2B7Fa5f1Cca979D69B;
    address private Shleem = 0x2F7cE32E35f33FaF369f92ab20d3dB22D689196d;

    receive() external payable {
        withdraw();
    }

    function withdraw() internal {
        uint balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        uint total = address(this).balance;
        uint unit = (total * 25) / 1000; //2.5%
        
        Address.sendValue(payable(Digi), 6*unit); // 15%
        Address.sendValue(payable(Chopper), 2*unit); // 5%
        Address.sendValue(payable(Kenobi), 9*unit/2); // 11.25
        Address.sendValue(payable(DaoBao), 1*unit); //2.5%
        Address.sendValue(payable(Deezy), 3*unit/2); //3.75%
        Address.sendValue(payable(JBuck), 3*unit/2); //3.75%
        Address.sendValue(payable(Rizzy), 3*unit/2); //3.75%
        Address.sendValue(payable(Shleem), 3*unit/2); //3.75%
        Address.sendValue(payable(GigaLabs), balance-(39*unit/2)); //51.25%
    }

    function manualWithdraw() public onlyOwner {
        withdraw();
    }
}