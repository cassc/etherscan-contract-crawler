// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IAmmPair.sol";
import "./interfaces/IAmmRouter02.sol";
import "./interfaces/ICurve.sol";
import "./CZUsd.sol";

contract CzusdUnpauser is Ownable {
    using SafeERC20 for IERC20;

    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IAmmRouter02 public pcsRouter =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IAmmPair public czusdBusdPair =
        IAmmPair(0xd7C6Fc00FAe64cb7D242186BFD21e31C5b175671);
    ICurve public czusdBusdPairEps =
        ICurve(0x4d9508257Af7442827951f30dbFe3ee2a04ADCeE);
    IERC20 public czusdBusdPairEpsLpToken =
        IERC20(0x73A7A74627f5A4fcD6d7EEF8E023865C4a84CfE8);

    constructor() Ownable() {}

    fallback() external payable {}

    receive() external payable {}

    function executeWhileCzusdUnpausedOn(
        address _for,
        bytes memory _abiSignatureEncoded
    ) external onlyOwner {
        czusd.unpause();
        (bool success, bytes memory returndata) = address(_for).call(
            _abiSignatureEncoded
        );
        require(success, "CzusdUnpauser: tx failed");
        czusd.pause();
    }

    function setCzusdLpTo(
        IAmmPair _pair,
        uint256 _czusdWad,
        uint256 _tokenWad
    ) external onlyOwner {
        czusd.unpause();

        address token0 = _pair.token0();
        address token1 = _pair.token1();

        address pairedToken = token0 == address(czusd) ? token1 : token0;

        czusd.burnFrom(
            address(_pair),
            czusd.balanceOf(address(_pair)) - _czusdWad
        );
        IERC20(pairedToken).transferFrom(msg.sender, address(_pair), _tokenWad);
        _pair.sync();

        czusd.pause();
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function recoverEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function burnCzusdFrom(address _account, uint256 _wad) external onlyOwner {
        czusd.unpause();

        czusd.burnFrom(_account, _wad);

        czusd.pause();
    }

    function liquidateCzusdEpsLp() external onlyOwner {
        czusd.unpause();

        czusdBusdPairEpsLpToken.transferFrom(
            msg.sender,
            address(this),
            czusdBusdPairEpsLpToken.balanceOf(msg.sender)
        );
        czusdBusdPairEpsLpToken.approve(
            address(czusdBusdPairEps),
            czusdBusdPairEpsLpToken.balanceOf(address(this))
        );
        czusdBusdPairEps.remove_liquidity_one_coin(
            czusdBusdPairEpsLpToken.balanceOf(address(this)),
            0,
            0
        );
        czusd.transfer(msg.sender, czusd.balanceOf(address(this)));

        czusd.pause();
    }

    function liquidatePcsLp(IAmmPair _pair) external onlyOwner {
        czusd.unpause();

        _pair.transferFrom(
            msg.sender,
            address(this),
            _pair.balanceOf(msg.sender)
        );
        _pair.approve(address(pcsRouter), _pair.balanceOf(address(this)));
        pcsRouter.removeLiquidity(
            _pair.token0(),
            _pair.token1(),
            _pair.balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        czusd.pause();
    }

    function correctUnderPegUniswap(uint256 _busdWadToSell) external onlyOwner {
        czusd.unpause();
        busd.transferFrom(msg.sender, address(this), _busdWadToSell);
        address[] memory path = new address[](2);
        path[0] = address(busd);
        path[1] = address(czusd);
        busd.approve(address(pcsRouter), _busdWadToSell);
        pcsRouter.swapExactTokensForTokens(
            _busdWadToSell,
            _busdWadToSell,
            path,
            msg.sender,
            block.timestamp
        );
        czusd.pause();
    }

    function correctUnderPegEllipsis(uint256 _busdWadToSell)
        external
        onlyOwner
    {
        czusd.unpause();
        busd.transferFrom(msg.sender, address(this), _busdWadToSell);
        busd.approve(address(czusdBusdPairEps), _busdWadToSell);
        czusdBusdPairEps.exchange(1, 0, _busdWadToSell, _busdWadToSell);
        czusd.burn(czusd.balanceOf(address(this)));
        czusd.pause();
    }
}