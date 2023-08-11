// SPDX-License-Identifier:MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//  helper contracts
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";

//  interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "@optyfi/defi-legos/interfaces/misc/contracts/IWETH.sol";
import { IETHGateway } from "@optyfi/defi-legos/interfaces/misc/contracts/IETHGateway.sol";
import { ICurveETHSwapV1 as ICurveETHSwap } from "@optyfi/defi-legos/ethereum/curve/contracts/ICurveETHSwapV1.sol";
import { ILidoDeposit } from "@optyfi/defi-legos/ethereum/lido/contracts/ILidoDeposit.sol";

/**
 * @title ETH gateway for opty-fi's Curve Swap adapter
 * @author Opty.fi
 * @dev Inspired from Aave WETH gateway
 */
contract CurveSwapETHGateway is IETHGateway, Modifiers {
    using SafeMath for uint256;
    // solhint-disable-next-line var-name-mixedcase
    IWETH internal immutable WETH;

    // solhint-disable-next-line var-name-mixedcase
    mapping(address => bool) public ethPools;

    /**
     * @notice Optional address used as referral on deposit
     */
    address public referralAddress;

    /** @notice Curve ETH/stETH StableSwap contract address to check for direct deposits into Lido */
    address public constant ETH_stETH_STABLESWAP = address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    /** @notice stETH address */
    address public constant stEth = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    /** @notice Flag to convert ETH to stETH if true */
    bool public convertToStEth;

    /**
     * @dev Initializes the WETH address, registry and curve's Eth pools
     * @param _weth Address of the Wrapped Ether contract
     * @param _registry Address of the registry
     * @param _ethPools Array of Curve's Eth pools
     **/
    constructor(
        address _weth,
        address _registry,
        address[4] memory _ethPools,
        bool _convertToStEth
    ) public Modifiers(_registry) {
        WETH = IWETH(_weth);
        convertToStEth = _convertToStEth;
        for (uint256 _i = 0; _i < _ethPools.length; _i++) {
            ethPools[_ethPools[_i]] = true;
        }
    }

    /**
     * @notice Sets the referralAddress for Lido deposits
     * @param _referralAddress address used as referral on deposit
     **/
    function setLidoReferralAddress(address _referralAddress) external onlyOperator {
        referralAddress = _referralAddress;
    }

    /**
     * @notice Sets the convertToStEth flag
     * @param _convertToStEth if true convert ETH to stETH before adding liquidity
     **/
    function setConvertToStEth(bool _convertToStEth) external onlyStrategyOperator {
        convertToStEth = _convertToStEth;
    }

    /**
     * @inheritdoc IETHGateway
     */
    function depositETH(
        address _vault,
        address _liquidityPool,
        address _liquidityPoolToken,
        uint256[2] memory _amounts,
        int128 _tokenIndex
    ) external override {
        IERC20(address(WETH)).transferFrom(_vault, address(this), _amounts[uint256(_tokenIndex)]);
        WETH.withdraw(_amounts[uint256(_tokenIndex)]);
        uint256 _minAmount =
            (_amounts[uint256(_tokenIndex)].mul(10**18).mul(95)).div(
                ICurveETHSwap(_liquidityPool).get_virtual_price().mul(100)
            );
        if (convertToStEth && _liquidityPool == ETH_stETH_STABLESWAP) {
            ILidoDeposit(stEth).submit{ value: address(this).balance }(referralAddress);
            uint256[2] memory amounts = [uint256(0), IERC20(stEth).balanceOf(address(this))];
            IERC20(stEth).approve(_liquidityPool, amounts[1]);
            ICurveETHSwap(_liquidityPool).add_liquidity(amounts, _minAmount);
        } else {
            ICurveETHSwap(_liquidityPool).add_liquidity{ value: address(this).balance }(_amounts, _minAmount);
        }
        IERC20(_liquidityPoolToken).transfer(_vault, IERC20(_liquidityPoolToken).balanceOf(address(this)));
    }

    /**
     * @inheritdoc IETHGateway
     */
    function withdrawETH(
        address _vault,
        address _liquidityPool,
        address _liquidityPoolToken,
        uint256 _amount,
        int128 _tokenIndex
    ) external override {
        IERC20(_liquidityPoolToken).transferFrom(_vault, address(this), _amount);
        uint256 _minAmount =
            ICurveETHSwap(_liquidityPool).calc_withdraw_one_coin(_amount, _tokenIndex).mul(95).div(100);
        ICurveETHSwap(_liquidityPool).remove_liquidity_one_coin(_amount, _tokenIndex, _minAmount);
        WETH.deposit{ value: address(this).balance }();
        IERC20(address(WETH)).transfer(_vault, IERC20(address(WETH)).balanceOf(address(this)));
    }

    /**
     * @inheritdoc IETHGateway
     */
    function emergencyTokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyOperator {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * @inheritdoc IETHGateway
     */
    function emergencyEtherTransfer(address to, uint256 amount) external override onlyOperator {
        _safeTransferETH(to, amount);
    }

    /**
     * @inheritdoc IETHGateway
     */
    function getWETHAddress() external view override returns (address) {
        return address(WETH);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param _to recipient of the transfer
     * @param _value the amount to send
     */
    function _safeTransferETH(address _to, uint256 _value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _to.call{ value: _value }(new bytes(0));
        require(_success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev Only WETH and ethPool contracts are allowed to transfer ETH here. Prevent other addresses
     *      to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH) || ethPools[msg.sender], "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}