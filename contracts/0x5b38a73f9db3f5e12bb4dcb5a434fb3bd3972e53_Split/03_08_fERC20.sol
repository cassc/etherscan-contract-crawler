pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./Split.sol";
import "./Oracle.sol";
import "./interfaces/IOracle.sol";

function suffix(string memory str, bool future0, bool name) pure returns (string memory) {
    return
        name
        ? string(abi.encodePacked(str, future0 ? " POS" : " POW"))
        : string(abi.encodePacked(str, future0 ? "s" : "w"));
}

contract fERC20 is ERC20 {
    bool future0;
    address owner;
    IOracle oracle;
    uint8 decimals_;

    constructor(IERC20 _underlying, IOracle _oracle, bool _future0)
        ERC20(
            suffix(ERC20(address(_underlying)).name(), _future0, true),
            suffix(ERC20(address(_underlying)).symbol(), _future0, false)
        )
    {
        owner = msg.sender;
        future0 = _future0;
        oracle = _oracle;
        decimals_ = ERC20(address(_underlying)).decimals();
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }

    function mint(address to, uint256 wad) public isOwner {
        _mint(to, wad);
    }

    function burn(address from, uint256 wad) public isOwner {
        _burn(from, wad);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        if (to != address(0) && oracle.isExpired() && !oracle.isRedeemable(future0)) {
            unchecked {
                _burn(to, amount);
            }
        }
    }
}