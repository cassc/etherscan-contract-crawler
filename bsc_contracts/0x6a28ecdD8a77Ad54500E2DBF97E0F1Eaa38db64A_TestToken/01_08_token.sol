// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
// contract ExampleToken is ERC20, ERC20Detailed {
//   constructor () public
//   ERC20Detailed("CuiToken", "CUI", 18){
//     _mint(msg.sender,10000000000 * (10 ** uint256(decimals())));
//   }
// }

contract TestToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    uint8 _decimal;
    mapping(address => bool) admin;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal_
    ) ERC20(name_, symbol_) {
        admin[_msgSender()] = true;
        _decimal = decimal_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function mint(address addr_, uint256 amount_) public onlyAdmin {
        _mint(addr_, amount_);
    }

    modifier onlyAdmin() {
        require(admin[_msgSender()], "not damin");
        _;
    }

    function setAdmin(address com_) public onlyOwner {
        require(com_ != address(0), "wrong adress");
        admin[com_] = true;
    }
}