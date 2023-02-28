// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";

import "contracts/routers/GenericRouter.sol";

import "contracts/interfaces/IAggregationExecutor.sol";

pragma solidity 0.8.17;

/// @notice Main contract incorporates a number of routers to perform swaps and limit orders protocol to fill limit orders
contract BrewlabsAggregationRouter is EIP712("Brewlabs Aggregation Router", "5"), Ownable,
    GenericRouter
{
    using SafeERC20 for IERC20; 
    using UniERC20 for IERC20;
    
    uint256 public treasuryFee;
    address payable public treasuryWalletAddress;

    uint256 public strategyFeeNumerator = 3;
    uint256 public strategyFeeDenominator = 1000;
    address payable public strategyWalletAddress;


    event UpdateTreasuryFee(uint256 indexed _old, uint256 indexed _new);
    event UpdateTreasuryWalletAddress(address indexed _old, address indexed _new);

    event UpdateStrategyFeePercentage(uint8 indexed _old, uint8 indexed _new);
    event UpdateStrategyWalletAddress(address indexed _old, address indexed _new);

    event SwapToken(address indexed caller, address indexed srcToken, address indexed dstToken, uint256 spentAmount, uint256 returnAmount);

    error ZeroAddress();

    /**
     * @dev Sets the wrapped eth token and clipper exhange interface
     * Both values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 _treasuryFee, address payable _treasuryWalletAddress, address payable _strategyWalletAddress)
    {
        treasuryFee = _treasuryFee;
        treasuryWalletAddress = _treasuryWalletAddress;

        strategyWalletAddress = _strategyWalletAddress;
    }

    function updateTreasuryFee(uint256 _new) external onlyOwner {
        require(_new != treasuryFee, "Brewlabs: Cannot update to same value");
        uint256 _old = treasuryFee;
        treasuryFee = _new;
        emit UpdateTreasuryFee(_old, _new);
    }

    function updateTreasuryWalletAddress(address payable _new) external onlyOwner {
        require(_new != treasuryWalletAddress, "Brewlabs: Cannot update to same value");
        address _old = treasuryWalletAddress;
        treasuryWalletAddress = _new;
        emit UpdateTreasuryWalletAddress(_old, _new);
    }

    function updateStrategyWalletAddress(address payable _new) external onlyOwner {
        require(_new != treasuryWalletAddress, "Brewlabs: Cannot update to same value");
        address _old = treasuryWalletAddress;
        treasuryWalletAddress = _new;
        emit UpdateStrategyWalletAddress(_old, _new);
    }

    function _transferTreasuryFee(IERC20 srcToken, uint256 amount) private {
        bool srcETH = srcToken.isETH();

        if (srcETH) {
            require(msg.value >= amount + treasuryFee, "Brewlabs: Not Enough ETH");
        } else {
            require(msg.value == treasuryFee, "Brewlabs: ETH is not correct");
        }

        treasuryWalletAddress.transfer(treasuryFee);
    }

    function _transferStrategyFee(IERC20 srcToken, uint256 amount) private returns(uint256) {
        bool srcETH = srcToken.isETH();

        require(amount > 0, "Brewlabs: Not Enough Token");

        uint256 strategyFee = amount * strategyFeeNumerator / strategyFeeDenominator;

        if (srcETH) {
            strategyWalletAddress.transfer(strategyFee);
        } else {
            srcToken.safeTransferFrom(msg.sender, strategyWalletAddress, strategyFee);
        }

        return amount - strategyFee;
    }

    function swapAggregateCall(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data,
        uint256 amount
    ) external payable {
        IERC20 srcToken = desc.srcToken;
        IERC20 dstToken = desc.dstToken;
        bool srcETH = srcToken.isETH();
        uint256 msgValue = srcETH ? desc.amount : 0;

        _transferTreasuryFee(srcToken, amount);
        _transferStrategyFee(srcToken, amount);
        (uint256 returnAmount, uint256 spentAmount) = swap(executor, desc, permit, data, msgValue);

        emit SwapToken(msg.sender, address(srcToken), address(dstToken), spentAmount, returnAmount);
    } 

    /**
     * @notice Retrieves funds accidently sent directly to the contract address
     * @param token ERC20 token to retrieve
     * @param amount amount to retrieve
     */
    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.uniTransfer(payable(msg.sender), amount);
    }

    /**
     * @notice Destroys the contract and sends eth to sender. Use with caution.
     * The only case when the use of the method is justified is if there is an exploit found.
     * And the damage from the exploit is greater than from just an urgent contract change.
     */
    function destroy() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function _receive() internal override(EthReceiver) {
        EthReceiver._receive();
    }
}