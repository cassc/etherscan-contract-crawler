// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../interfaces/IDerivative.sol";
import "../../interfaces/frax/IsFrxEth.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/curve/IFrxEthEthPool.sol";
import "../../interfaces/frax/IFrxETHMinter.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "hardhat/console.sol";

/// @title Derivative contract for sfrxETH
/// @author Asymmetry Finance
contract SfrxEth is
    ERC165Storage,
    IDerivative,
    Initializable,
    OwnableUpgradeable
{
    address private constant SFRX_ETH_ADDRESS =
        0xac3E018457B222d93114458476f3E3416Abbe38F;
    address private constant FRX_ETH_ADDRESS =
        0x5E8422345238F34275888049021821E8E08CAa1f;
    address private constant FRX_ETH_CRV_POOL_ADDRESS =
        0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577;
    address private constant FRX_ETH_MINTER_ADDRESS =
        0xbAFA44EFE7901E04E39Dad13167D089C559c1138;

    uint256 public maxSlippage;
    uint256 public underlyingBalance;

    // As recommended by https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
        @notice - Function to initialize values for the contracts
        @dev - This replaces the constructor for upgradeable contracts
        @param _owner - owner of the contract which should be SafEth.sol
    */
    function initialize(address _owner) external initializer {
        require(_owner != address(0), "invalid address");
        _registerInterface(type(IDerivative).interfaceId);
        _transferOwnership(_owner);
        maxSlippage = (1 * 1e16); // 1%
    }

    /**
        @notice - Return derivative name
    */
    function name() public pure returns (string memory) {
        return "Frax";
    }

    /**
        @notice - Owner only function to set max slippage for derivative
    */
    function setMaxSlippage(uint256 _slippage) external onlyOwner {
        maxSlippage = _slippage;
    }

    /**
        @notice - Owner only function to Convert derivative into ETH
        @dev - Owner is set to SafEth contract
        @param _amount - Amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyOwner {
        underlyingBalance = underlyingBalance - _amount;
        uint256 frxEthBalanceBefore = IERC20(FRX_ETH_ADDRESS).balanceOf(
            address(this)
        );
        IsFrxEth(SFRX_ETH_ADDRESS).redeem(
            _amount,
            address(this),
            address(this)
        );
        uint256 frxEthBalanceAfter = IERC20(FRX_ETH_ADDRESS).balanceOf(
            address(this)
        );
        uint256 frxEthReceived = frxEthBalanceAfter - frxEthBalanceBefore;
        IsFrxEth(FRX_ETH_ADDRESS).approve(
            FRX_ETH_CRV_POOL_ADDRESS,
            frxEthReceived
        );

        uint256 minOut = ((ethPerDerivative() * _amount) *
            (1e18 - maxSlippage)) / 1e36;

        uint256 ethBalanceBefore = address(this).balance;
        IFrxEthEthPool(FRX_ETH_CRV_POOL_ADDRESS).exchange(
            1,
            0,
            frxEthReceived,
            minOut
        );

        uint256 ethBalanceAfter = address(this).balance;
        uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
        // solhint-disable-next-line
        (bool sent, ) = address(msg.sender).call{value: ethReceived}("");
        require(sent, "Failed to send Ether");
    }

    /**
        @notice - Owner only function to Deposit into derivative
        @dev - Owner is set to SafEth contract
     */
    function deposit() external payable onlyOwner returns (uint256) {
        IFrxETHMinter frxETHMinterContract = IFrxETHMinter(
            FRX_ETH_MINTER_ADDRESS
        );
        uint256 sfrxBalancePre = IERC20(SFRX_ETH_ADDRESS).balanceOf(
            address(this)
        );
        frxETHMinterContract.submitAndDeposit{value: msg.value}(address(this));
        uint256 sfrxBalancePost = IERC20(SFRX_ETH_ADDRESS).balanceOf(
            address(this)
        );
        uint256 updatedBalance = sfrxBalancePost - sfrxBalancePre;
        underlyingBalance = underlyingBalance + updatedBalance;
        return updatedBalance;
    }

    /**
        @notice - Get price of derivative in terms of ETH
     */
    function ethPerDerivative() public view returns (uint256) {
        // There is no chainlink price fees for frxEth
        // We making the assumption that frxEth is always priced 1-1 with eth
        // revert if the curve oracle price suggests otherwise
        // Theory is its very hard for attacker to manipulate price away from 1-1 for any long period of time
        // and if its depegged attack probably cant maniulate it back to 1-1
        uint256 oraclePrice = IFrxEthEthPool(FRX_ETH_CRV_POOL_ADDRESS)
            .price_oracle();
        uint256 priceDifference;
        if (oraclePrice > 1e18) priceDifference = oraclePrice - 1e18;
        else priceDifference = 1e18 - oraclePrice;
        require(priceDifference < 19e14, "frxEth possibly depegged"); // outside of 0.19% we assume depegged

        uint256 frxEthAmount = IsFrxEth(SFRX_ETH_ADDRESS).convertToAssets(1e18);
        return ((frxEthAmount * oraclePrice) / 10 ** 18);
    }

    /**
        @notice - Total derivative balance
     */
    function balance() public view returns (uint256) {
        return underlyingBalance;
    }

    receive() external payable {}
}