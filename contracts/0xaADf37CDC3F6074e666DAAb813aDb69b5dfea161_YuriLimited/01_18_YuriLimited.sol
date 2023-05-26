// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Releasable.sol";

contract YuriLimited is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    Ownable,
    Pausable,
    Releasable
{
    using Address for address;

    constructor() ERC20("Yuri Limited", "YLC") {
        _mint(msg.sender, 0);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function releaseAllETH(address payable account) public onlyOwner {
        _releaseAllETH(account);
    }

    function releaseETH(address payable account, uint256 amount)
        public
        onlyOwner
    {
        _releaseETH(account, amount);
    }

    function releaseAllERC20(IERC20 token, address account) public onlyOwner {
        _releaseAllERC20(token, account);
    }

    function releaseERC20(
        IERC20 token,
        address account,
        uint256 amount
    ) public onlyOwner {
        _releaseERC20(token, account, amount);
    }

    function releaseERC721(
        IERC721 token,
        address account,
        uint256 tokenId
    ) public onlyOwner {
        _releaseERC721(token, account, tokenId);
    }
}