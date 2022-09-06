pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./fERC20.sol";
import "./Oracle.sol";

contract Split {
    IERC20 public underlying;
    fERC20 public future0;
    fERC20 public future1;
    IOracle public oracle;

    constructor(IERC20 _underlying, IOracle _oracle) {
        require(!_oracle.isExpired());
        oracle = _oracle;
        underlying = _underlying;
        future0 = new fERC20(_underlying, oracle, true);
        future1 = new fERC20(_underlying, oracle, false);
    }

    function futures() public view returns (fERC20, fERC20) {
        return (future0, future1);
    }

    function mint(uint256 _wad) public {
        mintTo(msg.sender, _wad);
    }

    function mintTo(address _who, uint256 _wad) public {
        require(!oracle.isExpired(), "Merge has already happened");

        future0.mint(_who, _wad);
        future1.mint(_who, _wad);
        underlying.transferFrom(msg.sender, address(this), _wad);
    }

    function burn(uint256 _wad) public {
        require(!oracle.isExpired(), "Merge has already happened");

        future0.burn(msg.sender, _wad);
        future1.burn(msg.sender, _wad);
        underlying.transfer(msg.sender, _wad);
    }

    function redeem(uint256 _wad) public {
        require(oracle.isExpired(), "Merge has not happened yet");

        if (oracle.isRedeemable(true)) {
            future0.burn(msg.sender, _wad);
        }

        if (oracle.isRedeemable(false)) {
            future1.burn(msg.sender, _wad);
        }

        underlying.transfer(msg.sender, _wad);
    }
}