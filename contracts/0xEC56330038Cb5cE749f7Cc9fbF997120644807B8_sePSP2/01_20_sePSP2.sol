pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./utils/TimeLockedERC20.sol";
import "./utils/Utils.sol";
import "./utils/IVault.sol";

error InsufficientAssetsReceived();

contract sePSP2 is ERC20Votes, TimeLockedERC20 {
    string constant NAME = "Social Escrowed 20WETH-80PSP BPT";
    string constant SYMBOL = "sePSP2";

    IVault public immutable BALANCER_VAULT;
    IERC20 public immutable PSP;
    IERC20 public immutable WETH;
    IERC20 public immutable BPT;
    bytes32 public immutable WETH20_PSP80_POOL_ID;

    bool public immutable isReversedBalancerPair;

    uint256 constant EXACT_BPT_IN_FOR_TOKENS_OUT = 1;
    uint256 constant EXACT_TOKENS_IN_FOR_BPT_OUT = 1;

    constructor(
        IERC20 _asset,
        uint256 _timeLockBlocks,
        uint256 _minTimeLockBlocks,
        uint256 _maxTimeLockBlocks,
        IVault balancerVault,
        IERC20 psp,
        IERC20 weth,
        bytes32 poolId
    ) TimeLockedERC20(NAME, SYMBOL, _asset, _timeLockBlocks, _minTimeLockBlocks, _maxTimeLockBlocks) {
        BALANCER_VAULT = balancerVault;
        PSP = psp;
        WETH = weth;
        BPT = _asset;
        WETH20_PSP80_POOL_ID = poolId;
        isReversedBalancerPair = address(weth) > address(psp);
    }

    function depositPSPAndEth(
        uint256 pspAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external payable {
        Utils.permit(PSP, pspPermit);

        PSP.transferFrom(msg.sender, address(this), pspAmount);

        uint256 bptAmount = _joinPool(pspAmount, msg.value, minBptOut, false);

        _deposit(bptAmount);
    }

    function depositPSPAndWeth(
        uint256 pspAmount,
        uint256 wethAmount,
        uint256 minBptOut,
        bytes memory pspPermit
    ) external {
        Utils.permit(PSP, pspPermit);

        PSP.transferFrom(msg.sender, address(this), pspAmount);
        WETH.transferFrom(msg.sender, address(this), wethAmount);

        uint256 bptAmount = _joinPool(pspAmount, wethAmount, minBptOut, true);

        _deposit(bptAmount);
    }

    function withdrawPSPAndEth(
        int256 id,
        uint256 minPspAmount,
        uint256 minEthAmount
    ) external {
        uint256 bptAmount = _withdraw(id);
        (uint256 ethAmount, uint256 pspAmount) = _exitPool(bptAmount, minPspAmount, minEthAmount, false);

        PSP.transfer(msg.sender, pspAmount);
        Utils.transferETH(payable(msg.sender), ethAmount);
    }

    function withdrawPSPAndWeth(
        int256 id,
        uint256 minPspAmount,
        uint256 minEthAmount
    ) external {
        uint256 bptAmount = _withdraw(id);
        (uint256 ethAmount, uint256 pspAmount) = _exitPool(bptAmount, minPspAmount, minEthAmount, true);

        PSP.transfer(msg.sender, pspAmount);
        WETH.transfer(msg.sender, ethAmount);
    }

    function withdrawPSPAndEthMulti(
        int256[] calldata ids,
        uint256 minPspAmount,
        uint256 minEthAmount
    ) external {
        uint256 bptAmount;
        for (uint8 i; i < ids.length; i++) {
            bptAmount += _withdraw(ids[i]);
        }

        (uint256 ethAmount, uint256 pspAmount) = _exitPool(bptAmount, minPspAmount, minEthAmount, false);

        PSP.transfer(msg.sender, pspAmount);
        Utils.transferETH(payable(msg.sender), ethAmount);
    }

    function withdrawPSPAndWethMulti(
        int256[] calldata ids,
        uint256 minPspAmount,
        uint256 minEthAmount
    ) external {
        uint256 bptAmount;
        for (uint8 i; i < ids.length; i++) {
            bptAmount += _withdraw(ids[i]);
        }

        (uint256 ethAmount, uint256 pspAmount) = _exitPool(bptAmount, minPspAmount, minEthAmount, true);

        PSP.transfer(msg.sender, pspAmount);
        WETH.transfer(msg.sender, ethAmount);
    }

    function _joinPool(
        uint256 pspAmount,
        uint256 ethAmount,
        uint256 minBptOut,
        bool isWeth
    ) internal returns (uint256 bptAmount) {
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = ethAmount;
        amountsIn[1] = pspAmount;

        address[] memory assets = new address[](2);
        assets[0] = isWeth ? address(WETH) : address(0);
        assets[1] = address(PSP);

        if (isReversedBalancerPair) {
            (assets[0], assets[1]) = (assets[1], assets[0]);
            (amountsIn[0], amountsIn[1]) = (amountsIn[1], amountsIn[0]);
        }

        bytes memory userDataEncoded = abi.encode(EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBptOut);

        IVault.JoinPoolRequest memory joinRequest = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userDataEncoded,
            fromInternalBalance: false
        });

        uint256 bptBalanceBefore = BPT.balanceOf(address(this));

        PSP.approve(address(BALANCER_VAULT), pspAmount);
        if (isWeth) {
            WETH.approve(address(BALANCER_VAULT), ethAmount);
            BALANCER_VAULT.joinPool(WETH20_PSP80_POOL_ID, address(this), address(this), joinRequest);
        } else {
            BALANCER_VAULT.joinPool{ value: ethAmount }(
                WETH20_PSP80_POOL_ID,
                address(this),
                address(this),
                joinRequest
            );
        }

        bptAmount = BPT.balanceOf(address(this)) - bptBalanceBefore;

        if (bptAmount < minBptOut) {
            revert InsufficientAssetsReceived();
        }
    }

    function _exitPool(
        uint256 bptAmount,
        uint256 minPspAmount,
        uint256 minEthAmount,
        bool isWeth
    ) internal returns (uint256 ethAmount, uint256 pspAmount) {
        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = minEthAmount;
        minAmountsOut[1] = minPspAmount;

        address[] memory assets = new address[](2);
        assets[0] = isWeth ? address(WETH) : address(0);
        assets[1] = address(PSP);

        if (isReversedBalancerPair) {
            (assets[0], assets[1]) = (assets[1], assets[0]);
            (minAmountsOut[0], minAmountsOut[1]) = (minAmountsOut[1], minAmountsOut[0]);
        }

        bytes memory userDataEncoded = abi.encode(EXACT_BPT_IN_FOR_TOKENS_OUT, bptAmount);

        IVault.ExitPoolRequest memory exitRequest = IVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: userDataEncoded,
            toInternalBalance: false
        });

        BPT.approve(address(BALANCER_VAULT), bptAmount);
        BALANCER_VAULT.exitPool(WETH20_PSP80_POOL_ID, address(this), payable(address(this)), exitRequest);

        pspAmount = PSP.balanceOf(address(this));
        ethAmount = isWeth ? WETH.balanceOf(address(this)) : address(this).balance;

        if (pspAmount < minPspAmount || ethAmount < minEthAmount) {
            revert InsufficientAssetsReceived();
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    receive() external payable {}
}