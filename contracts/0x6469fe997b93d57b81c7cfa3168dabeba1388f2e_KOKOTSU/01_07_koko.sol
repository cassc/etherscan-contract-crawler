// SPDX-License-Identifier: MIT
//.
pragma solidity ^0.8.10;

// Import the IERC20 interface and and SafeMath library
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract KOKOTSU is ERC20, Ownable {
    using SafeMath for uint256;

    address public constant deadAddress = address(0xdead);

    bool public Bone = false;
    uint256 public maxWallet;
    uint256 public initialSupply;

    mapping (address => bool) public automatedMarketMakerPairs;
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("Kokotsu", "KOKO")
    {
        initialSupply = 230000000 * 1e18;
        maxWallet = 5750000 * 1e18;

        _mint(owner(), initialSupply);
    }

    receive() external payable {

   }

    // Launch
    function Honu() external onlyOwner {
        require(!Bone, "Trading is already active");
        Bone = true;
    }

    function pauseTrading() external onlyOwner {
        Bone = false;
    }

    function resumeTrading() external onlyOwner {
        Bone = true;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10**18);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        //require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ){
            require(Bone, 'Trading is not active');

            //when buy
            if (automatedMarketMakerPairs[from]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
             //when transfer
            if (!(automatedMarketMakerPairs[to]) &&  !(automatedMarketMakerPairs[from])) {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }

        super._transfer(from, to, amount);
    }

}