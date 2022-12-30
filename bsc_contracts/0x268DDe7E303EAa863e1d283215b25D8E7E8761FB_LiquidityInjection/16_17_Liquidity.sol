// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./utils/LPSwapSupport.sol";

contract LiquidityInjection is LPSwapSupport  {

    address public servicesWallet;
    address public tokenAddress;
    IBEP20 public altToken;
    uint256 public swapPercentage;
    uint256 public swapPercentageDenominator;

    constructor(address _contractOwner, address _lpReceiver, address _tokenAddress, address _servicesWallet, address _swapRouter,
                address _busd, uint256 _swapPercentage, uint256 _percentageDenominator) initializer {
        __LPSwapSupport_init(_lpReceiver);
        tokenAddress = _tokenAddress;
        servicesWallet = _servicesWallet;
        swapPercentage = _swapPercentage;
        swapPercentageDenominator = _percentageDenominator;
        updateRouter(_swapRouter);
        altToken = IBEP20(_busd);
        transferOwnership(_contractOwner);
    }

    function _balanceOf(address) internal view virtual override returns(uint256) {
        revert("Contract has no balance");
    }

    function _approve(address, address, uint256) internal view virtual override {
        revert("Contract has no balance");
    }

    function updateRouter(address newAddress) public virtual override onlyOwner {
        super.updateRouter(newAddress);
        IBEP20(tokenAddress).approve(address(swapRouter), type(uint256).max);
    }

    function updateToken(address _newTokenAddress) external onlyOwner {
        tokenAddress = _newTokenAddress;
        IBEP20(_newTokenAddress).approve(address(swapRouter), type(uint256).max);
    }

    receive() external payable {
        forceProcess();
    }

    function forceProcess() public {
        if(!inSwap){
            _forceProcess();
        }
    }

    function forceProcessToken(address _tokenAddress) external lockTheSwap {
        uint256 tokenBalance = IBEP20(_tokenAddress).balanceOf(address(this));

        if(tokenBalance > 0){
            swapTokensForCurrencyAdv(_tokenAddress, tokenBalance, address(this));
        } else {
            revert("No Tokens");
        }

        if(!inSwap){
            _forceProcessNoLock();
        }
    }

    function _forceProcess() internal lockTheSwap {
        _forceProcessNoLock();
    }

    function _forceProcessNoLock() internal {
        {
            uint256 altTokenBalance = altToken.balanceOf(address(this));
            if(altTokenBalance > 0){
                swapTokensForCurrencyAdv(address(altToken), altTokenBalance, address(this));
            }
        }
        uint256 balance = address(this).balance;
        if(balance > 0){
            swapCurrencyForTokensUnchecked(tokenAddress, balance * swapPercentage / swapPercentageDenominator, address(this));
            uint256 tokenBalance = IBEP20(tokenAddress).balanceOf(address(this));
            addLiquidityForToken(tokenAddress, tokenBalance, address(this).balance);
        }
        payable(servicesWallet).transfer(address(this).balance);
    }

    function updateSwapPercentage(uint256 _newPercentage, uint256 _newDenominator) external onlyOwner {
        if(_newDenominator == 0){
            revert("Cannot divide by 0");
        }
        swapPercentage = _newPercentage;
        swapPercentageDenominator = _newDenominator;
    }

    function updateServicesWallet(address _newServicesWallet) external onlyOwner {
        servicesWallet = _newServicesWallet;
    }

    function clearStuckToken(address _tokenAddress, address _to) public onlyOwner {
        IBEP20(_tokenAddress).transfer(_to, IBEP20(_tokenAddress).balanceOf(address(this)));
    }

    function clearStuckBNB(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function clearStuckTokenBatch(address[] memory _tokenAddress, address _to) external onlyOwner {
        for(uint256 i = 0; i < _tokenAddress.length; i++){
            clearStuckToken(_tokenAddress[i], _to);
        }
    }

    function updateAltTokenAddress(address _tokenAddress) external onlyOwner {
        altToken = IBEP20(_tokenAddress);
    }
}