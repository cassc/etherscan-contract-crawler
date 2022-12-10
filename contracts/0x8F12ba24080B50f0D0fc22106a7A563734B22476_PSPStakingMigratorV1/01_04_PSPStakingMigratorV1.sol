pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./utils/Utils.sol";

error IndexOutOfRange(uint8 index);

interface I_sPSP is IERC20 {
    function leave(uint256 _stakedAmount) external;

    function withdraw(int256 id) external;

    function userVsNextID(address owner) external returns (int256);
}

interface I_stkPSPBpt is IERC20 {
    function redeem(address to, uint256 amount) external;

    function cooldown() external;
}

interface I_sePSP is IERC20 {
    function deposit(uint256 amount) external;
}

interface I_sePSP2 is I_sePSP {
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

contract PSPStakingMigratorV1 {
    IERC20 public immutable PSP;
    IERC20 public immutable WETH;

    I_sePSP public immutable sePSP;
    I_sePSP2 public immutable sePSP2;

    I_stkPSPBpt public immutable stkPSPBpt;
    IERC20 public immutable BPT;

    I_sPSP[] public SPSPs;

    struct RequestSPSP {
        uint8 index;
        uint256 amount;
        bytes permitData;
    }

    constructor(
        IERC20 _PSP,
        IERC20 _WETH,
        IERC20 _bpt,
        I_sePSP _sePSP,
        I_sePSP2 _sePSP2,
        I_stkPSPBpt _stkPSPBpt,
        I_sPSP[] memory _SPSPs
    ) {
        PSP = _PSP;
        WETH = _WETH;
        BPT = _bpt;

        sePSP = _sePSP;
        sePSP2 = _sePSP2;

        stkPSPBpt = _stkPSPBpt;
        SPSPs = _SPSPs;
    }

    function depositSPSPsForSePSP(RequestSPSP[] calldata reqs) external {
        _unstakeSPSPsAndGetPSP(reqs);

        uint256 pspBalance = PSP.balanceOf(address(this));

        PSP.approve(address(sePSP), pspBalance);
        sePSP.deposit(pspBalance);

        sePSP.transfer(msg.sender, pspBalance); // 1:1 between sePSP and PSP
    }

    function depositStkPSPBptForSePSP2(uint256 bptAmount, bytes calldata stkPSPBptPermit) external {
        Utils.permit(stkPSPBpt, stkPSPBptPermit);

        stkPSPBpt.transferFrom(msg.sender, address(this), bptAmount);
        stkPSPBpt.cooldown();
        stkPSPBpt.redeem(address(this), bptAmount);

        BPT.approve(address(sePSP2), bptAmount);
        sePSP2.deposit(bptAmount);

        sePSP2.transfer(msg.sender, bptAmount); // 1:1 between stkPSPBpt, BPT and sePSP2
    }

    function depositSPSPsAndETHForSePSP2(RequestSPSP[] calldata reqs, uint256 minBptOut) external payable {
        _unstakeSPSPsAndGetPSP(reqs);

        uint256 pspAmount = PSP.balanceOf(address(this));
        PSP.approve(address(sePSP2), pspAmount);
        sePSP2.depositPSPAndEth{ value: msg.value }(pspAmount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }

    function depositSPSPsAndWETHForSePSP2(
        RequestSPSP[] calldata reqs,
        uint256 wethAmount,
        uint256 minBptOut
    ) external {
        _unstakeSPSPsAndGetPSP(reqs);
        WETH.transferFrom(msg.sender, address(this), wethAmount);

        uint256 pspAmount = PSP.balanceOf(address(this));

        PSP.approve(address(sePSP2), pspAmount);
        WETH.approve(address(sePSP2), wethAmount);
        sePSP2.depositPSPAndWeth(pspAmount, wethAmount, minBptOut, "");

        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2Balance);
    }

    function _unstakeSPSPsAndGetPSP(RequestSPSP[] calldata reqs) internal {
        for (uint8 i; i < reqs.length; i++) {
            RequestSPSP memory req = reqs[i];

            if (req.index >= SPSPs.length) {
                revert IndexOutOfRange(req.index);
            }

            I_sPSP sPSP = SPSPs[req.index];

            Utils.permit(sPSP, req.permitData);

            sPSP.transferFrom(msg.sender, address(this), req.amount);

            int256 id = sPSP.userVsNextID(address(this));
            sPSP.leave(req.amount);
            sPSP.withdraw(id);
        }
    }
}