pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OATHMigrator {
    IERC20 public immutable OATH;
    IERC20 public immutable OATHV2;

    bool public exchangeOpen = true;

    address public admin;

    constructor(IERC20 _OATH, IERC20 _OATHV2) {
        OATH = _OATH;
        OATHV2 = _OATHV2;
        admin = msg.sender;
    }

    function setAdmin(address _admin) public {
        require(msg.sender == admin, "only admin");
        admin = _admin;
    }

    function toggle(bool _toggle) external {
        require(msg.sender == admin, "only admin");
        exchangeOpen = _toggle;
    }
    function exchange(uint256 amount) public {
        require(exchangeOpen, "exchange closed");
        OATH.transferFrom(msg.sender, address(this), amount);
        OATHV2.transfer(msg.sender, amount);
    }
}