// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "../util/CriticalTracer.sol";
import "../ERC20/interfaces/IERC20Collateral.sol";
import "../Security/interfaces/IECDSASignatureCollateral.sol";

contract CollateralWrapper is CriticalTracer {
    using SafeERC20 for IERC20;
    IERC20 private collateral;
    IECDSASignatureCollateral private signatureCollateral;
    event CollateralAddressChanged(address newCollateralAddress);
    uint8 tokenDecimals;
    
    constructor(address _collateral, address _signatureCollateral) {
        collateral = IERC20(_collateral);
        tokenDecimals = IERC20Collateral(_collateral).decimals();
        signatureCollateral = IECDSASignatureCollateral(_signatureCollateral);
    }

    function getCollateralAddress() external view returns (address) {
        return address(collateral);
    }

    function setCollateralAddress(address tokenAddress, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external onlyOwner {
        signatureCollateral.verifyMessage(
            signatureCollateral.hashingSetCollateralMessage(tokenAddress),
            nonce,
            timestamp,
            signatures
        );
        require(tokenAddress != address(0), _ctMsg("address cannot be zero"));
        collateral = IERC20Collateral(tokenAddress);
        emit CollateralAddressChanged(tokenAddress);
    }

    function _collateralTransfer(address to, uint256 amount) validateBalance(amount) internal {
        require(to != address(0), _ctMsg("address cannot be zero"));
        require(amount > 0, _ctMsg("amount cannot be zero"));
        require(amount <= _collateralBalanceOf(address(this)), _ctMsg("not enough collateral"));
        collateral.safeTransfer(to, amount);
    }

    function _collateralTransferFrom(address from, address to, uint256 amount) validateBalanceFrom(amount) internal {
        require(to != address(0), _ctMsg("address cannot be zero"));
        require(from != address(0), _ctMsg("the from address cannot be zero"));
        require(amount > 0, _ctMsg("amount cannot be zero"));

        collateral.safeTransferFrom(from, to, amount);
    }

    function _collateralBalanceOf(address account) internal view returns (uint256) {
        return collateral.balanceOf(account);
    }

    function extractCollateral(address to, uint256 amount, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external {
        
        signatureCollateral.verifyMessage(
            signatureCollateral.hashingExtractMessage(to, amount),
            nonce,
            timestamp,
            signatures
        );

        _collateralTransfer(to, amount);
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }

    function raise(uint256 amount) internal view returns (uint256) {
        return amount * 10 ** decimals();
    }
    
    modifier validateBalance(uint256 price) {
        require(collateral.balanceOf(address(this)) >= price, _ctMsg("there is not enough collateral to transfer"));
        _;
    }

    modifier validateBalanceFrom(uint256 price) {
        require(collateral.balanceOf(msg.sender) >= price, _ctMsg("you dont have enough collateral"));
        _;
    }
}