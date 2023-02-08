// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uniswap Interfaces for Swapping rules
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";

contract WVWToken is ERC20, ERC20Burnable, Ownable {
    uint256 _swapWhen;
    uint8 private _fee;
    address private _marketingWalletAddress;
    bool private swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _automatedMarketMakerPairs;

    IUniswapV2Router02 uniswapV2Router;
    address uniswapV2Pair;

    event TransferWithFee(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SwapForFees(
        uint256 tokensSwapped,
        uint256 ethReceived,
        address addressReceived
    );

    event ChangeExcludeFromFee(address indexed newAddress, bool status);
    event ChangeAutomatedMarketPairs(address indexed newAddress, bool status);

    constructor(
        address owner_,
        address distributionContract_,
        uint8 fee_,
        uint256 swapWhen_,
        address marketingWalletAddress_,
        address uniswapV2Router_,
        address[] memory excludeFromFeeAddresses_
    ) ERC20("WVW Token", "WVW") {
        _mint(distributionContract_, 100000000 * 10**decimals());
        _marketingWalletAddress = marketingWalletAddress_;
        _fee = fee_;
        _swapWhen = swapWhen_;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            uniswapV2Router_
        );

        // Creates a Uniswap Pair for the new token.
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // Include uniswap pair on automatedMarket
        _automatedMarketMakerPairs[_uniswapV2Pair] = true;

        //Excludes address from fees.
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[uniswapV2Router_] = true;
        _isExcludedFromFees[marketingWalletAddress_] = true;

        // Send list of Custom excluded from fees
        for (uint256 i = 0; i < excludeFromFeeAddresses_.length; i++) {
            _isExcludedFromFees[excludeFromFeeAddresses_[i]] = true;
        }

        // Transfer ownership if sender is not the owner_
        if (msg.sender != owner_) {
            transferOwnership(owner_);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isTrade = false;

        if (
            _automatedMarketMakerPairs[from] || _automatedMarketMakerPairs[to]
        ) {
            isTrade = true;
        }

        bool canSwap = balanceOf(address(this)) > _swapWhen;

        if (
            canSwap &&
            !swapping &&
            !_automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            swapTokensForEth(balanceOf(address(this)));
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee && isTrade) {
            uint256 feeAmount = _calcFee(amount);
            amount -= feeAmount;
            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);
    }

    function _calcFee(uint256 amount) private view returns (uint256) {
        return (amount * _fee) / 100;
    }

    function setExcludeFromFeesAddress(address _address, bool activate)
        external
        onlyOwner
    {
        _isExcludedFromFees[_address] = activate;
        emit ChangeExcludeFromFee(_address, activate);
    }

    function getExcludeFromFeesAddress(address _address)
        external view
        returns (bool _verify)
    {
        return _isExcludedFromFees[_address];
    }

    function setAutomatedMarketMakerPairsAddress(
        address _address,
        bool activate
    ) external onlyOwner {
        _automatedMarketMakerPairs[_address] = activate;
        emit ChangeAutomatedMarketPairs(_address, activate);
    }

    function getAutomatedMarketMakerPairsAddress(address _address) external view returns (bool _verify) {
        return _automatedMarketMakerPairs[_address];
    }

    function setMarketingWalletAddress(address _address) external onlyOwner {
        _marketingWalletAddress = _address;
    }

    function setSwapWhen(uint256 _amount) external onlyOwner {
        _swapWhen = _amount;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generates the uniswap pair path of token <> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        // Send ETH from contract to marketingWalletAddress
        payable(_marketingWalletAddress).transfer(address(this).balance);
        emit SwapForFees(
            tokenAmount,
            address(this).balance,
            _marketingWalletAddress
        );
    }

    function getFounds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "WVWToken: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    receive() external payable {}
}