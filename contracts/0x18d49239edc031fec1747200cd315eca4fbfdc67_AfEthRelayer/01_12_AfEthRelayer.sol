// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external_interfaces/IAfEth.sol";
import "contracts/external_interfaces/ISafEth.sol";
import "contracts/strategies/AbstractStrategy.sol";

// AfEth is the strategy manager for safEth and votium strategies
contract AfEthRelayer is Initializable {
    address public constant SAF_ETH_ADDRESS =
        0x6732Efaf6f39926346BeF8b821a04B6361C4F3e5;
    address public constant AF_ETH_ADDRESS =
        0x5F10B16F0959AaC2E33bEdc9b0A4229Bb9a83590;

    // As recommended by https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
        @notice - Initialize values for the contracts
        @dev - This replaces the constructor for upgradeable contracts
    */
    function initialize() external initializer {}

    /**
        @notice - Deposits into the SafEth contract and relay to owner address
        @param _minout - Minimum amount of SafEth to mint
        @param _owner - Owner of the SafEth
    */
    function depositSafEth(
        uint256 _minout,
        address _owner
    ) external payable virtual {
        uint256 beforeDeposit = IERC20(SAF_ETH_ADDRESS).balanceOf(address(this));
        ISafEth(SAF_ETH_ADDRESS).stake{value: msg.value}(
            _minout
        );
        uint256 amountToTransfer = IERC20(SAF_ETH_ADDRESS).balanceOf(
            address(this)
        ) - beforeDeposit;
        IERC20(SAF_ETH_ADDRESS).transfer(_owner, amountToTransfer);
    }

    /**
        @notice - Deposits into the AfEth contract and relay to owner address
        @param _minout - Minimum amount of AfEth to mint
        @param _deadline - Time before transaction expires
        @param _owner - Owner of the AfEth
    */
    function depositAfEth(
        uint256 _minout,
        uint256 _deadline,
        address _owner
    ) external payable virtual {
        uint256 beforeDeposit = IERC20(AF_ETH_ADDRESS).balanceOf(address(this));
        IAfEth(AF_ETH_ADDRESS).deposit{value: msg.value}(_minout, _deadline);
        uint256 amountToTransfer = IERC20(AF_ETH_ADDRESS).balanceOf(
            address(this)
        ) - beforeDeposit;
        IERC20(AF_ETH_ADDRESS).transfer(_owner, amountToTransfer);
    }
}