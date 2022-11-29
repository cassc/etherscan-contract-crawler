// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/WETH.sol";
import "contracts/interfaces/ISeuro.sol";
import "contracts/Stage1/SEuroCalculator.sol";
import "contracts/Stage1/TokenManager.sol";
import "contracts/Stage1/BondingCurve.sol";
import "contracts/Pausable.sol";
import "contracts/Drainable.sol";

contract SEuroOffering is Ownable, Pausable, Drainable {
    // address of the wallet which will receive the collateral provided in swap and swapETH
    address public collateralWallet;
    Status public status;
    ISeuro public immutable Seuro;
    SEuroCalculator public sEuroRateCalculator;    
    TokenManager public tokenManager;
    BondingCurve public bondingCurve;

    event Swap(address indexed _user, string _token, uint256 amountIn, uint256 amountOut);
    struct Status { bool active; uint256 start; uint256 stop; }

    /// @param _seuroAddr address of sEURO token
    /// @param _sEuroRateCalculator address of SEuroRateCalculator contract
    /// @param _tokenManager address of TokenManager contract
    /// @param _bondingCurve address of BondingCurve contract
    constructor(address _seuroAddr, address _sEuroRateCalculator, address _tokenManager, address _bondingCurve) {
        Seuro = ISeuro(_seuroAddr);
        sEuroRateCalculator = SEuroCalculator(_sEuroRateCalculator);
        tokenManager = TokenManager(_tokenManager);
        bondingCurve = BondingCurve(_bondingCurve);
    }

    modifier ifActive() { require(activated() && notEnded(), "err-ibco-inactive"); _; }

    modifier validAddress(address _newAddress) { require(_newAddress != address(0), "err-addr-invalid"); _; }

    modifier valueNotZero(uint256 _value) { require(_value > 0, "err-invalid-value"); _; }

    function setCalculator(address _newAddress) external onlyOwner validAddress(_newAddress) {
        sEuroRateCalculator = SEuroCalculator(_newAddress);
    }

    function setTokenManager(address _newAddress) external onlyOwner validAddress(_newAddress) {
        tokenManager = TokenManager(_newAddress);
    }

    function setBondingCurve(address _newAddress) external onlyOwner validAddress(_newAddress) {
        bondingCurve = BondingCurve(_newAddress);
    }

    function getSeuros(uint256 _amount, TokenManager.TokenData memory _token) private returns (uint256) {
        return sEuroRateCalculator.calculate(_amount, _token);
    }

    function activated() private view returns (bool) { return status.active == true && status.start > 0; }

    function notEnded() private view returns (bool) { return status.stop == 0 || status.stop > block.timestamp; }

    function transferCollateral(IERC20 _token, uint256 _amount) private {
        require(collateralWallet != address(0), "err-no-collat-wallet");
        SafeERC20.safeTransfer(_token, collateralWallet, _amount);
    }

    // A read-only function to estimate how much sEURO would be received for the given amount of token
    // This function provides a simplified calculation and is therefore just an estimation
    // Provide a 32-byte array of "WETH" to estimate the exchange for ETH
    /// @param _amount the amount of the given token that you'd like to estimate the exchange value for
    function readOnlyCalculateSwap(string memory _symbol, uint256 _amount) external view returns (uint256) {
        if (cmpString(_symbol, "ETH")) _symbol = "WETH";
        return sEuroRateCalculator.readOnlyCalculate(_amount, tokenManager.get(_symbol));
    }

    // Swap any accepted ERC20 token for an equivalent amount of sEURO
    // Accepted tokens and their byte array values are dictated by the TokenManager contract
    /// @param _amount the amount of the given token that you'd like to exchange for sEURO
    function swap(string memory _symbol, uint256 _amount) external ifActive ifNotPaused valueNotZero(_amount) {
        TokenManager.TokenData memory token = tokenManager.get(_symbol);
        IERC20 erc20Token = IERC20(token.addr);
        require(erc20Token.balanceOf(msg.sender) >= _amount, "err-tok-bal");
        require(erc20Token.allowance(msg.sender, address(this)) >= _amount, "err-tok-allow");
        SafeERC20.safeTransferFrom(erc20Token, msg.sender, address(this), _amount);
        uint256 seuros = getSeuros(_amount, token);
        Seuro.mint(msg.sender, seuros);
        bondingCurve.updateCurrentBucket(seuros);
        transferCollateral(erc20Token, _amount);
        emit Swap(msg.sender, _symbol, _amount, seuros);
    }

    // Payable function that exchanges the ETH value of the transaction for an equivalent amount of sEURO
    function swapETH() external payable ifActive ifNotPaused valueNotZero(msg.value) {
        TokenManager.TokenData memory token = tokenManager.get("WETH");
        WETH(token.addr).deposit{value: msg.value}();
        uint256 seuros = getSeuros(msg.value, token);
        Seuro.mint(msg.sender, seuros);
        bondingCurve.updateCurrentBucket(seuros);
        transferCollateral(IERC20(token.addr), msg.value);
        emit Swap(msg.sender, "ETH", msg.value, seuros);
    }

    // Restricted function to activate the sEURO Offering
    function activate() external onlyOwner {
        status.active = true;
        status.start = block.timestamp;
    }

    // Restricted function to complete the sEURO Offering
    function complete() external onlyOwner {
        status.active = false;
        status.stop = block.timestamp;
    }

    // Sets the wallet that will receive all collateral exchanged for sEURO
    function setCollateralWallet(address _collateralWallet) external onlyOwner { collateralWallet = _collateralWallet; }

    function cmpString(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}