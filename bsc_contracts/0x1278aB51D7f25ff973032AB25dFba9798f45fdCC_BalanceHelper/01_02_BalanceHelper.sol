// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BalanceHelper {

    IERC20 public CREAMPYE = IERC20(0xAaD87f47CDEa777FAF87e7602E91e3a6AFbe4D57);
    IERC20 public PYE1 = IERC20(0x853FCf1e9CAd2FAE2150621D583c98dc5f8748f3);
    IERC20 public PYE2 = IERC20(0x4d542De559D9696cbC15a3937Bf5c89fEdb5b9c7);
    IERC20 public APPLE1 = IERC20(0x390deb8148397F04f59d99a224Da0e9365D5CB19);
    IERC20 public APPLE2 = IERC20(0x5a83d81daCDcd3f5a5A712823FA4e92275d8ae9F);
    IERC20 public APPLE3 = IERC20(0xF65Ae63D580EDe49589992b6E772b48E61EaDed2);
    IERC20 public CHERRY1 = IERC20(0xa98a6B0d9ddb2C036ea38079C0ADdeC7Bd8959E3);
    IERC20 public CHERRY2 = IERC20(0xc1D6A3ef07C6731DA7FDE4C54C058cD6e371dA04);
    IERC20 public PEACH = IERC20(0xdB3aBa37F0F0C0e8233FFB862FbaD2F725cdE989);
    IERC20 public FORCE1 = IERC20(0xcD9bc85C6b675DA994F172Debb6Db9BDD6727FE7);
    IERC20 public FORCE2 = IERC20(0xEcE3D017A62b8723F3648a9Fa7cD92f603E88a0E);
    IERC20 public FUEL = IERC20(0xc4a21f59628c82Ff916F2267ad97f250A572DB4b);
    IERC20 public GRAVITY = IERC20(0x8B9386354C6244232e44E03932f2484b37fB94E2);
    IERC20 public MINIDOGE = IERC20(0xBa07EED3d09055d60CAEf2bDfCa1c05792f2dFad);
    IERC20 public TREASURE = IERC20(0xC0b943b63e605cf8a75c7832C2baF46629f7F762);
    IERC20 public TRICK = IERC20(0xE5F8Ea8A9081f7CaBb9D155Fb12B599E30c32AFE);
    IERC20 public TREAT = IERC20(0x4c091d0cbdCaF7eA2Bdd3beD7b0E787A95B9b483);
    IERC20 public SYMBULL1 = IERC20(0xA176fa55bef56D18ab671251957aCB0Db630539b);
    IERC20 public SYMBULL2 = IERC20(0xA354F2185f8240b04f3f3C7b56A8Cd66F00b58db);
    IERC20 public RIDE = IERC20(0x10A0ddd99ff720BE0f247995d0E43CbaBd14D466);
    IERC20 public CHARGE = IERC20(0xA0340e9261C120708FD74b644A9Ff2D339B3eaee);
    



    function getBalances(
        address[] calldata accounts
    ) external view returns (
        address[] memory holdsCREAMPYE,
        uint256[] memory balanceCREAMPYE,
        address[] memory holdsPYE1,
        uint256[] memory balancePYE1,
        address[] memory holdsPYE2,
        uint256[] memory balancePYE2,
        address[] memory holdsAPPLE1,
        uint256[] memory balanceAPPLE1,
        address[] memory holdsAPPLE2,
        uint256[] memory balanceAPPLE2,
        address[] memory holdsAPPLE3,
        uint256[] memory balanceAPPLE3,
        address[] memory holdsCHERRY1,
        uint256[] memory balanceCHERRY1,
        address[] memory holdsCHERRY2,
        uint256[] memory balanceCHERRY2,
        address[] memory holdsPEACH,
        uint256[] memory balancePEACH,
        address[] memory holdsFORCE1,
        uint256[] memory balanceFORCE1,
        address[] memory holdsFORCE2,
        uint256[] memory balanceFORCE2,
        address[] memory holdsFUEL,
        uint256[] memory balanceFUEL,
        address[] memory holdsGRAVITY,
        uint256[] memory balanceGRAVITY,
        address[] memory holdsMINIDOGE,
        uint256[] memory balanceMINIDOGE,
        address[] memory holdsTREASURE,
        uint256[] memory balanceTREASURE,
        address[] memory holdsTRICK,
        uint256[] memory balanceTRICK,
        address[] memory holdsTREAT,
        uint256[] memory balanceTREAT,
        address[] memory holdsSYMBULL1,
        uint256[] memory balanceSYMBULL1,
        address[] memory holdsSYMBULL2,
        uint256[] memory balanceSYMBULL2,
        address[] memory holdsRIDE,
        uint256[] memory balanceRIDE,
        address[] memory holdsCHARGE,
        uint256[] memory balanceCHARGE
    ) {
        (holdsCREAMPYE, balanceCREAMPYE) = getBalance(accounts, CREAMPYE);
        (holdsPYE1, balancePYE1) = getBalance(accounts, PYE1);
        (holdsPYE2, balancePYE2) = getBalance(accounts, PYE2);
        (holdsAPPLE1, balanceAPPLE1) = getBalance(accounts, APPLE1);
        (holdsAPPLE2, balanceAPPLE2) = getBalance(accounts, APPLE2);
        (holdsAPPLE3, balanceAPPLE3) = getBalance(accounts, APPLE3);
        (holdsCHERRY1, balanceCHERRY1) = getBalance(accounts, CHERRY1);
        (holdsCHERRY2, balanceCHERRY2) = getBalance(accounts, CHERRY2);
        (holdsPEACH, balancePEACH) = getBalance(accounts, PEACH);
        (holdsFORCE1, balanceFORCE1) = getBalance(accounts, FORCE1);
        (holdsFORCE2, balanceFORCE2) = getBalance(accounts, FORCE2);
        (holdsFUEL, balanceFUEL) = getBalance(accounts, FUEL);
        (holdsGRAVITY, balanceGRAVITY) = getBalance(accounts, GRAVITY);
        (holdsMINIDOGE, balanceMINIDOGE) = getBalance(accounts, MINIDOGE);
        (holdsTREASURE, balanceTREASURE) = getBalance(accounts, TREASURE);
        (holdsTRICK, balanceTRICK) = getBalance(accounts, TRICK);
        (holdsTREAT, balanceTREAT) = getBalance(accounts, TREAT);
        (holdsSYMBULL1, balanceSYMBULL1) = getBalance(accounts, SYMBULL1);
        (holdsSYMBULL2, balanceSYMBULL2) = getBalance(accounts, SYMBULL2);
        (holdsRIDE, balanceRIDE) = getBalance(accounts, RIDE);
        (holdsCHARGE, balanceCHARGE) = getBalance(accounts, CHARGE);
    }

    function getBalance(
        address[] calldata accounts, 
        IERC20 token
    ) internal view returns (
        address[] memory, 
        uint256[] memory
    ) {
        uint256 length = accounts.length;
        address[] memory acct = new address[](length);
        uint256[] memory bal = new uint256[](length);
        uint256 _bal;
        uint z;
        for (uint i = 0; i < length; i++) {
            _bal = token.balanceOf(accounts[i]);
            if (_bal > 0) {
                acct[z] = accounts[i];
                bal[z] = _bal;
                z++;
            }
        }
        address[] memory acct2 = new address[](z);
        uint256[] memory bal2 = new uint256[](z);
        for (uint j = 0; j < z; j++) {
            acct2[j] = acct[j];
            bal2[j] = bal[j];
        }
        if (acct[0] == address(0)) {
            return (new address[](0), new uint256[](0));
        } else {
            return (acct2, bal2);
        }
    }
    
}