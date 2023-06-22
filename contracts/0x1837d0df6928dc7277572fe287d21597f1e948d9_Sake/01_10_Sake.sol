/*


███████╗ █████╗ ██╗  ██╗███████╗
██╔════╝██╔══██╗██║ ██╔╝██╔════╝
███████╗███████║█████╔╝ █████╗
╚════██║██╔══██║██╔═██╗ ██╔══╝
███████║██║  ██║██║  ██╗███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

Anime, meme and crypto are ways of expressing and sharing online culture

#Nihonshu
 https://www.sakeerc.io
 https://t.me/ErcSake
 https://twitter.com/Sake_ERC_

*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Sake is ERC20, Ownable {

    uint256 private _totalSupply = 10 * 1e9 * 10**18;

    address ZERO = 0x0000000000000000000000000000000000000000;

    address private pair_address;
    address private router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    bool public maxTxAmountEnabled = false;
    uint256 public maxTxAmount;

    bool private antiMEV;
    mapping (address => bool) private isContractExempt;


    struct Swap {
        uint256 block_number;
        uint256 count;
    }

    mapping (address => Swap) private addressSwaps;


    constructor() ERC20("Sake", "Nihonshu") {
        isContractExempt[address(this)] = true;
        isContractExempt[router_address] = true;
        _mint(msg.sender, _totalSupply);
    }

    function init() external onlyOwner {
        require( pair_address == ZERO, "Already initialized");
        IUniswapV2Router02 router = IUniswapV2Router02(router_address);
        address WETH = router.WETH();
        pair_address = IUniswapV2Factory(router.factory()).createPair(WETH, address(this));
        isContractExempt[pair_address] = true;
        _approve(address(this), router_address, type(uint256).max);
        antiMEV = true;
    }

    function setMaxTxAmount(uint256 _max) external onlyOwner {
        if (_max == 0) {
            maxTxAmountEnabled = false;
        } else {
            maxTxAmount = _max;
            maxTxAmountEnabled =true;
        }

    }




    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {

        // Max TX
        if(maxTxAmountEnabled && from != owner() && to != owner())
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // Anti MEV
        if(antiMEV && !isContractExempt[from] && !isContractExempt[to]){
            ensureHuman(from, to);
        }


        // Anti Sandwich
        address swapper = getAddressForSwap(from, to);


        if (swapper != ZERO) {

            if(addressSwaps[swapper].block_number > 0){
                Swap memory address_swaps = addressSwaps[swapper];

                if (address_swaps.block_number == block.timestamp) {
                    // The same block
                    require (address_swaps.count == 0, "Only one swap in a block please !!!");

                } else {
                    address_swaps.count = 1;
                    address_swaps.block_number = block.timestamp;
                    addressSwaps[swapper] = address_swaps;
                }
            } else {

                Swap memory address_swaps;
                address_swaps.block_number = block.timestamp;
                address_swaps.count = 1;
                addressSwaps[swapper] = address_swaps;
            }


        }


    }

    function getAddressForSwap(address to, address from) private view returns (address){
        if (to == pair_address) {
            // Sale
            return to;
        } else if (from == pair_address) {
            // Buy
            return to;
        }

        return ZERO;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }

    function toggleAntiMEV(bool toggle) external onlyOwner {
        antiMEV = toggle;
    }



    function ensureHuman(address _to, address _from) private view returns (address) {
        require(!isContract(_to) || !isContract(_from));

        if (isContract(_to)) return _from;
        else return _to;
    }

    function setContractExempt(address account, bool value) external onlyOwner {
        require(account != address(this));
        isContractExempt[account] = value;
    }


    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }


}