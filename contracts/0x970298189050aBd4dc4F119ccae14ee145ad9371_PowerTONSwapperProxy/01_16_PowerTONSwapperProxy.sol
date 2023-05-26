// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPoolProxy.sol";

import "../common/AccessibleCommon.sol";
import "../stake/ProxyBase.sol";
import "./PowerTONSwapperStorage.sol";

// import "hardhat/console.sol";

/// @title The proxy of PowerTONSwapper
contract PowerTONSwapperProxy is
    PowerTONSwapperStorage,
    AccessibleCommon,
    ProxyBase,
    IPoolProxy
{
    event Upgraded(address indexed implementation);


    /// @dev constructor of PowerTONSwapperProxy
    constructor(
        address _impl,
        address _wton,
        address _tos,
        address _uniswapRouter,
        address _autocoinageSnapshot,
        address _layer2Registry,
        address _seigManager
    ) {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        require(_impl != address(0), "PowerTONSwapperProxy: logic is zero");

        _setImplementation(_impl);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);

        wton = _wton;
        tos = ITOS(_tos);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        autocoinageSnapshot = _autocoinageSnapshot;
        layer2Registry = _layer2Registry;
        seigManager = _seigManager;

    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external override onlyOwner {
        require(impl != address(0), "PowerTONSwapperProxy: input is zero");
        require(_implementation() != impl, "PowerTONSwapperProxy: same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view override returns (address) {
        return _implementation();
    }

    /// @dev receive ether
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = _implementation();
        require(
            _impl != address(0) && !pauseProxy,
            "PowerTONSwapperProxy: impl OR proxy is false"
        );

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

}