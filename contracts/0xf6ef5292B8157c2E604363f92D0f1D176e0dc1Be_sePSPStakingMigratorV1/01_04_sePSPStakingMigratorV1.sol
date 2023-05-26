pragma solidity 0.8.19;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./utils/Utils.sol";

interface I_sePSP2 is IERC20 {
    function depositPSPAndEth(
        uint256 pspAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external payable;

    function depositPSPAndWeth(
        uint256 pspAmount,
        uint256 wethAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external;
}

contract sePSPStakingMigratorV1 {
    IERC20 public immutable PSP;
    IERC20 public immutable WETH;

    IERC20 public immutable sePSP;
    I_sePSP2 public immutable sePSP2;

    address public immutable PSP_Supplier;

    constructor(
        IERC20 _PSP,
        IERC20 _WETH,
        IERC20 _sePSP,
        I_sePSP2 _sePSP2,
        address _PSP_Supplier
    ) {
        PSP = _PSP;
        WETH = _WETH;

        sePSP = _sePSP;
        sePSP2 = _sePSP2;

        PSP_Supplier = _PSP_Supplier;

        // pre-approve
        PSP.approve(address(sePSP2), type(uint).max);
        WETH.approve(address(sePSP2), type(uint).max);
    }

    function migrateSePSP1AndWETHtoSePSP2(
        uint256 sePSP1Amount,
        uint256 wethAmount,
        uint256 minBptOut,
        bytes calldata sePSPPermit
    ) external {
        /**
        0.1 Migrator contract has allowance from PSP_Supplier for some amount of PSP
        0.2 Migrator contract has allowance from user for some amount of WETH
        1. User gives allowance or permit for sePSP1 to Migrator contract
        2. sePSP1 is transferred to PSP_Supplier
        3. equivalent PSP is transferred from PSP_Supplier, and WETH from user
        4. PSP + WETH (from user) is deposited into Balancer Pool through sePSP2
        5. resulting sePSP2 is transferred to user
         */

        if (sePSP.allowance(msg.sender, address(this)) < sePSP1Amount) {
            Utils.permit(sePSP, sePSPPermit);
        }

        sePSP.transferFrom(msg.sender, PSP_Supplier, sePSP1Amount);

        WETH.transferFrom(msg.sender, address(this), wethAmount);
        PSP.transferFrom(PSP_Supplier, address(this), sePSP1Amount);

        sePSP2.depositPSPAndWeth(sePSP1Amount, wethAmount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }

    function migrateSePSP1AndETHtoSePSP2(
        uint256 sePSP1Amount,
        uint256 minBptOut,
        bytes calldata sePSPPermit
    ) external payable {
        /**
        0. Migrator contract has allowance from PSP_Supplier for some amount of PSP
        1. User gives allowance or permit for sePSP1 to Migrator contract
        2. sePSP1 is transferred to PSP_Supplier
        3. equivalent PSP is transferred from PSP_Supplier
        4. PSP + ETH (from user) is deposited into Balancer Pool through sePSP2
        5. resulting sePSP2 is transferred to user
         */

        if (sePSP.allowance(msg.sender, address(this)) < sePSP1Amount) {
            Utils.permit(sePSP, sePSPPermit);
        }


        sePSP.transferFrom(msg.sender, PSP_Supplier, sePSP1Amount);

        PSP.transferFrom(PSP_Supplier, address(this), sePSP1Amount);

        sePSP2.depositPSPAndEth{ value: msg.value }(sePSP1Amount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }
}