//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
contract CANCCToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("CANADIAN CRYPTO CURRENCY", "CANCC") {
        _mint(0xD5b192a854a54Fa0b5E5405DE32Be8AC63c8DFe2, 21000000000e18);
        transferOwnership(0xBA3Fb2de4997De2434934b04232db7BF7dBf5B82);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner() {
        _mint(to, amount);
    }
}