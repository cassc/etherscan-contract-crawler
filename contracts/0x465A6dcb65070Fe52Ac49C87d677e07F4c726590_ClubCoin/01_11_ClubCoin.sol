// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClubCoin is ERC20, ERC20Burnable, Pausable, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _lock;

    string private _name;

    constructor(
        address _ownerAddress,
        address payable _mintWalletAddress,
        uint256 _mintWholeTokens
    ) ERC20("CLUB Coin", "CLUB") {
        _mint(_mintWalletAddress, _mintWholeTokens * 10**decimals());

        transferOwnership(_ownerAddress);
    }

    function transferBulk(address[] memory _tos, uint256[] memory _values)
        external
    {
        require(
            _tos.length == _values.length,
            "Count Recipients/values don't match"
        );
        require(_tos.length < 100, "Too many recipients");

        for (uint256 i = 0; i < _tos.length; ++i) {
            _transfer(msg.sender, _tos[i], _values[i]);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function lockAddress(address payable addr) external onlyOwner {
        _lock[addr] = true;
    }

    function unlockAddress(address payable addr) external onlyOwner {
        delete _lock[addr];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Recover ERC20 tokens
     * @param tokenAddress The token contract address
     */
    function recover(address tokenAddress) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);

        if (tokenContract == IERC20(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(address(this).balance);
        } else {
            tokenContract.safeTransfer(
                owner(),
                tokenContract.balanceOf(address(this))
            );
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        require(_lock[from] != true, "Transfer Locked");
    }
}