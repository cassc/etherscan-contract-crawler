// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ReturnAnyERC20Token.sol";

contract MurphyToken is ERC20Pausable, ReturnAnyERC20Token, Ownable {
    mapping(address => bool) public rejectList;
    mapping(address => bool) public liquidityList;
    bool public isLiquidityStage = true;

    constructor(address uniswap, address airdrop, address marketing, address development, address team) ERC20("MURPHY", "MURPHY") {
        setLiquidity(0x0000000000000000000000000000000000000000, true);
        // _mint(msg.sender, 231_260_000_000 * 10 ** decimals());
        setLiquidity(uniswap, true);
        setLiquidity(airdrop, true);
        setLiquidity(marketing, true);
        setLiquidity(development, true);
        setLiquidity(team, true);

        _mint(uniswap, 127_193_000_000 * 10 ** decimals()); // 55%
        _mint(airdrop, 6_937_800_000 * 10 ** decimals());   // 3%
        _mint(marketing, 2_312_600_000 * 10 ** decimals());  // 1%
        _mint(development, 92_504_000_000 * 10 ** decimals()); // 40%
        _mint(team, 2_312_600_000 * 10 ** decimals()); // 1%
    }

    function setReject(address account, bool reject) public onlyOwner {
        rejectList[account] = reject;
    }

    function setLiquidity(address account, bool allow) public onlyOwner {
        liquidityList[account] = allow;
    }

    function disableLiquidity() public onlyOwner {
        isLiquidityStage = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Pausable) {
        require(!rejectList[from], "Murphy: transfer from the reject address");
        require(!rejectList[to], "Murphy: transfer to the reject address");
        if (isLiquidityStage) {
            require(
                liquidityList[from],
                "Murphy: transfer from is not in the liquidity address"
            );
            require(
                liquidityList[to],
                "Murphy: transfer to is not in the liquidity address"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function returnAnyToken(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyOwner {
        _returnAnyToken(tokenAddress, to, amount);
    }
}