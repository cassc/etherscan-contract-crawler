// SPDX-License-Identifier:MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//  helper contracts
import { Modifiers } from "../../earn-protocol-configuration/contracts/Modifiers.sol";

//  interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "@optyfi/defi-legos/interfaces/misc/contracts/IWETH.sol";
import { ICompound } from "@optyfi/defi-legos/ethereum/compound/contracts/ICompound.sol";
import { IETHGateway } from "@optyfi/defi-legos/interfaces/misc/contracts/IETHGateway.sol";

/**
 * @title ETH gateway for opty-fi's Compound adapter
 * @author Opty.fi
 * @dev Inspired from Aave WETH gateway
 */
contract CompoundETHGateway is IETHGateway, Modifiers {
    // solhint-disable-next-line var-name-mixedcase
    IWETH internal immutable WETH;

    // solhint-disable-next-line var-name-mixedcase
    address public immutable CETH;

    /**
     * @dev Sets the WETH address.
     * @param weth Address of the Wrapped Ether contract
     **/
    constructor(
        address weth,
        address _registry,
        address _ceth
    ) public Modifiers(_registry) {
        WETH = IWETH(weth);
        CETH = _ceth;
    }

    /**
     * @inheritdoc IETHGateway
     */
    function depositETH(
        address _vault,
        address _liquidityPool,
        address,
        uint256[2] memory _amounts,
        int128
    ) external override {
        IERC20(address(WETH)).transferFrom(_vault, address(this), _amounts[0]);
        WETH.withdraw(_amounts[0]);
        ICompound(_liquidityPool).mint{ value: address(this).balance }();
        IERC20(_liquidityPool).transfer(_vault, IERC20(_liquidityPool).balanceOf(address(this)));
    }

    /**
     * @inheritdoc IETHGateway
     */
    function withdrawETH(
        address _vault,
        address _liquidityPool,
        address,
        uint256 _amount,
        int128
    ) external override {
        IERC20(_liquidityPool).transferFrom(_vault, address(this), _amount);
        ICompound(_liquidityPool).redeem(_amount);
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
     * @dev Only WETH and CETH contracts are allowed to transfer ETH here. Prevent other addresses
     *      to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH) || msg.sender == address(CETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}