// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract RewardToken is ERC20, Ownable {
    mapping(address => bool) private _allowTransfer;
    error NotAllowedToTransfer(address from);
    error NowAllowedToRecoverThisToken();
    error EtherNotAccepted();

    constructor() ERC20("Reward Token", "RWD") {}

    fallback() external payable {
        revert EtherNotAccepted();
    }
    receive() external payable {
        revert EtherNotAccepted();
    }

    function recover(address tokenAddress, address to) external onlyOwner {
        if (tokenAddress == address(this))
            revert NowAllowedToRecoverThisToken();
        IERC20(tokenAddress).transfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function otcTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyOwner {
        _transfer(from, to, amount);
    }

    function allowTransfer(address to, bool status) external onlyOwner {
        _allowTransfer[to] = status;
    }

    function _beforeTokenTransfer(
        address /*from*/,
        address /*to*/,
        uint256 /* amount*/
    ) internal view override {
        if (_allowTransfer[msg.sender] == false)
            revert NotAllowedToTransfer(msg.sender);
    }

}