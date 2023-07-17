// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OnApprove } from "./OnApprove.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "./libraries/BytesLib.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface IIWTON {
    function swapToTON(uint256 wtonAmount) external returns (bool);
    function swapFromTON(uint256 tonAmount) external returns (bool);
}

interface IIWETH {
    function withdraw(uint wad) external;
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface IIL1Bridge {
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;

    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;
}

contract BridgeSwap is OnApprove {
    using SafeERC20 for IERC20;
    using BytesLib for bytes;

    address public ton;
    address public wton;
    address public l2Token;
    address public l1Bridge;
    address public weth;


    event DepositedWTON (
        address sender,
        uint256 wtonAmount,
        uint256 tonAmount
    );

    event DepositedTON (
        address sender,
        uint256 tonAmount
    );

    event DepositWETH (
        address sender,
        uint wethAmount
    );

    event DepositedWTONTo (
        address sender,
        address to,
        uint256 wtonAmount,
        uint256 tonAmount
    );

    event DepositedTONTo (
        address sender,
        address to,
        uint256 tonAmount
    );

    event DepositWETHTo (
        address sender,
        address to,
        uint wethAmount
    );

    event Received(address, uint);

    constructor(
        address _ton,
        address _wton,
        address _l2Token,
        address _l1Bridge,
        address _weth
    ) {
        ton = _ton;
        wton = _wton;
        l2Token = _l2Token;
        l1Bridge = _l1Bridge;
        weth = _weth;

        IERC20(ton).approve(
            l1Bridge,
            type(uint256).max
        );
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice calling approveAndCall in wton and ton.
    /// @param sender sender is msg.sender requesting approveAndCall.
    /// @param amount If it is called from TONContract, it is TONAmount, and if it is called from WTONContract, it is WTONAmount.
    /// @param data The first 64 digits of data indicate the l2gas value, and the next 64 digits indicate the data value.
    /// @return Whether or not the execution succeeded
    function onApprove(
        address sender,
        address,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(amount > 0, "need the input amount");
        require(msg.sender == address(ton) || msg.sender == address(wton), "only TON and WTON");
        require(data.length >= 4, "need input L2gas");
        
        uint32 l2GasUsed = uint32(bytes4(data[0:4]));
        address to;
        bytes calldata callData = data[4:];
        if(data.length > 23) {
            to = data.toAddress(4);
            if(data.length > 24) {
                callData = data[24:];
            }
        }
        
        if(msg.sender == address(ton)) {
            _depositTON(
                sender,
                to,
                amount,
                l2GasUsed,
                callData
            );
        } else if (msg.sender == address(wton)) {
            _depositWTON(
                sender,
                to,
                amount,
                l2GasUsed,
                callData
            );
        }

        return true;
    }

    /// @notice This function is called after approve or permit is done in advance.
    /// @param depositAmount this is wtonAmount.
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositWTON (
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) external {
        require(depositAmount > 0, "need input amount");
        require(IERC20(wton).allowance(msg.sender, address(this)) >= depositAmount, "wton exceeds allowance");
        _depositWTON(
            msg.sender,
            address(0),
            depositAmount,
            l2gas,
            data
        );
    }

    /// @notice This function is called after approve or permit is done in advance.
    /// @param depositAmount this is wtonAmount.
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositWTONTo(
        address to,
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    )   external {
        require(depositAmount > 0, "need input amount");
        require(to != address(0), "need the toAddress");
        require(IERC20(wton).allowance(msg.sender, address(this)) >= depositAmount, "wton exceeds allowance");
        _depositWTON(
            msg.sender,
            to,
            depositAmount,
            l2gas,
            data
        );
    }


    /// @notice This function is called after approve or permit is done in advance.
    /// @param depositAmount this is tonAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositTON(
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) external {
        require(depositAmount > 0, "need input amount");
        require(IERC20(ton).allowance(msg.sender, address(this)) >= depositAmount, "ton exceeds allowance");
        _depositTON(
            msg.sender,
            address(0),
            depositAmount,
            l2gas,
            data
        );
    }

    /// @notice This function is called after approve or permit is done in advance.
    /// @param to This address is get TON L2 account
    /// @param depositAmount this is tonAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositTONTo(
        address to,
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) external {
        require(depositAmount > 0, "need input amount");
        require(to != address(0), "need the toAddress");
        require(IERC20(ton).allowance(msg.sender, address(this)) >= depositAmount, "ton exceeds allowance");
        _depositTON(
            msg.sender,
            to,
            depositAmount,
            l2gas,
            data
        );
    }

    /// @notice This function is called after approve or permit is done in advance.
    /// @param depositAmount this is WETHAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositWETH(
        uint depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) external payable {
        _checkWETH(depositAmount);
        IIWETH(weth).withdraw(depositAmount);
        (bool success,) = address(l1Bridge).call{value: depositAmount}(
            abi.encodeWithSignature(
                "depositETHTo(address,uint32,bytes)", 
                msg.sender,l2gas,data
            )
        );
        require(success,"Failed to send Ether");

        emit DepositWETH(msg.sender, depositAmount);
    }

    /// @notice This function is called after approve or permit is done in advance.
    /// @param to This is get ETH L2Account
    /// @param depositAmount this is WETHAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data This is the data value entered when depositing into L2.
    function depositWETHTo(
        address to,
        uint depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) external payable {
        require(to != address(0), "need the toAddress");
        _checkWETH(depositAmount);
        IIWETH(weth).withdraw(depositAmount);
        (bool success,) = address(l1Bridge).call{value: depositAmount}(
            abi.encodeWithSignature(
                "depositETHTo(address,uint32,bytes)", 
                to,l2gas,data
            )
        );
        require(success,"Failed to send Ether");

        emit DepositWETHTo(msg.sender, to, depositAmount);
    }

    /// @notice This function is called when depositing wton in approveAndCall.
    /// @param depositAmount this is wtonAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data It is decoded in approveAndCall and is data in memory form.
    function _depositWTON(
        address sender,
        address to,
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) internal {
        IERC20(wton).safeTransferFrom(sender,address(this),depositAmount);
        IIWTON(wton).swapToTON(depositAmount);
        uint256 tonAmount = _toWAD(depositAmount);
        _checkAllowance(tonAmount);
        if(to == address(0)){
            _depoistERC20To(
                sender,
                tonAmount,
                l2gas,
                data
            );

            emit DepositedWTON(sender, depositAmount, tonAmount);
        } else {
            _depoistERC20To(
                to,
                tonAmount,
                l2gas,
                data
            );

            emit DepositedWTONTo(sender, to, depositAmount, tonAmount);
        }
    }

    /// @notice This function is called when depositing ton in approveAndCall.
    /// @param sender This is TON from account
    /// @param depositAmount This is tonAmount
    /// @param l2gas This is the gas value entered when depositing in L2.
    /// @param data It is decoded in approveAndCall and is data in memory form.
    function _depositTON(
        address sender,
        address to,
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) internal {
        IERC20(ton).safeTransferFrom(sender,address(this),depositAmount);
        _checkAllowance(depositAmount);
        if(to == address(0)){
            _depoistERC20To(
                sender,
                depositAmount,
                l2gas,
                data
            );

            emit DepositedTON(sender, depositAmount);
        } else {
            _depoistERC20To(
                to,
                depositAmount,
                l2gas,
                data
            );

            emit DepositedTONTo(sender, to, depositAmount);
        }
    }

    function _depoistERC20To(
        address to,
        uint256 depositAmount,
        uint32 l2gas,
        bytes calldata data
    ) internal {
        IIL1Bridge(l1Bridge).depositERC20To(
            ton,
            l2Token,
            to,
            depositAmount,
            l2gas,
            data
        );
    }

    function _checkWETH(
        uint256 depositAmount
    ) internal {
        require(depositAmount > 0, "need input amount");
        require(msg.value == 0, "dont input eth");
        require(IERC20(weth).allowance(msg.sender, address(this)) >= depositAmount, "weth exceeds allowance");
        IIWETH(weth).transferFrom(msg.sender,address(this), depositAmount);
    }

    function _checkAllowance(
        uint256 _depositAmount
    ) internal {
        if(_depositAmount > IERC20(ton).allowance(address(this),l1Bridge)) {
            require(
                IERC20(ton).approve(
                    l1Bridge,
                    type(uint256).max
                ),
                "ton approve fail"
            );
        }
    }

    function _toWAD(uint256 v) internal pure returns (uint256) {
        return v / 10 ** 9;
    }

}