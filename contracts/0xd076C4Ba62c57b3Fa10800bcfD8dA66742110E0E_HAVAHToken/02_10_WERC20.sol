// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract WERC20 is ERC20Burnable, IERC165, Ownable {

    uint16 public originChain;
    string public originToken;
    uint8 private _decimals;

    address public minter;

    constructor(uint16 originChain_, string memory originToken_, string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        originChain = originChain_;
        originToken = originToken_;
        _decimals = decimals_;
        minter = _msgSender();
    }

    modifier onlyMinter() {
        require(minter == _msgSender(), "caller is not the minter");
        _;
    }

    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId;
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

}