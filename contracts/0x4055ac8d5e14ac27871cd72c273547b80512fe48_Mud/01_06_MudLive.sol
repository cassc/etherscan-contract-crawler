// SPDX-License-Identifier: MIT




/*

@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P~.!&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
B:   7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B!    ~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
7     .?PGB#######&@@@@@@@@@@@@@@#GBB###BBGGJ     :~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@#PJ~.      ......^[email protected]@@@@@@@@@@@G.           ^7JPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@&P.           [email protected]@@@@@@@@@5            [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@:            [email protected]@@@@@@@J             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@GJYYYYYYYYYYYYYYYY5PB&@@@@@@
@@@@@@&:             :#@@@@@&7              [email protected]@@BBGPP5Y?7#@@#BBGP5J7^[email protected]@#?.       .Y55Y?~    .~Y#@@@
@@@@@@&:   !:         [email protected]@@@#~   .Y.         [email protected]@@J:       [email protected]@B!       [email protected]@@@!       [email protected]@@@@@#J.    [email protected]
@@@@@@&:   5#:         [email protected]@G:   :B&.         [email protected]@@@P       [email protected]@@@^      [email protected]@@@!       [email protected]@@@@@@@G.     .5
@@@@@@&:   [email protected]#:         P5    ^#@&:         [email protected]@@@#       [email protected]@@@~      [email protected]@@@!       [email protected]@@@@@@@@?      .
@@@@@@&:   [email protected]@B.             ^#@@&:         [email protected]@@@#.      [email protected]@@@!      [email protected]@@@!       [email protected]@@@@@@@@Y      :
@@@@@@&:   [email protected]@@P            ~&@@@&:         [email protected]@@@B       [email protected]@@@^      [email protected]@@@!       [email protected]@@@@@@@@!      Y
@@@@@@&:   [email protected]@@@Y          ~&@@@@&.         [email protected]@@@&:      ~B&@G.      [email protected]@@@!       [email protected]@@@@@@@Y      [email protected]
@@@@@@@:   [email protected]@@@@?        [email protected]@@@@@B          [email protected]@@@@5        .::       :&@@@!       [email protected]@@@@@B!     [email protected]@
@@@@@&P.   ?#&@@@@?      [email protected]@@@@@@J          ~#&@@@@G?~^^^^~?P&Y^^^^~~~JP#P:       :?55Y7^..:[email protected]@@@
@@@@J^.    .:^[email protected]@@@J    [email protected]@@@@B~^      ....::^!?#@@@@@@@@@@@@@@@@@@@@@@@GJY55555555Y555PGB#&@@@@@@@@

Shrek is love, Shrek is life,
Owning a Mud token, void of strife.
In green-hued swamps, our hearts do trek,
Bound in joy, in the world of Shrek.

🌎 https://www.mudcoin.xyz/
💬 https://twitter.com/muddedxyz
💬 https://t.me/muderc

Pepe lives in the past. It's time for $MUD to rise out of the swamp... */





pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Mud is Ownable, ERC20 {
    address public uniswapV2Pair;

    constructor() ERC20("Mud", "MUD") {
        _mint(msg.sender, 69_420_000_000_000 * 10**18);
    }

    function setRule(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading has yet to descend into the swamps of commerce");
            return;
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}