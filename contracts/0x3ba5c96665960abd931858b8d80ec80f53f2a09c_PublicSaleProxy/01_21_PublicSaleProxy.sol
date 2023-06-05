// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../interfaces/IPublicSaleProxy.sol";

import "../common/ProxyAccessCommon.sol";
import "./PublicSaleStorage.sol";
import "../stake/ProxyBase.sol";

import { OnApprove } from "./OnApprove.sol";
import "../interfaces/IWTON.sol";
import "../interfaces/IPublicSale.sol";

contract PublicSaleProxy is
    PublicSaleStorage,
    ProxyAccessCommon,
    ProxyBase,
    OnApprove,
    IPublicSaleProxy
{
    event Upgraded(address indexed implementation);

    event Pause(address indexed addr, uint256 time);

    /// @dev constructor of PublicSaleProxy
    constructor() {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        _setRoleAdmin(PROJECT_ADMIN_ROLE, PROJECT_ADMIN_ROLE);
        _setupRole(PROJECT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev set the logic
    /// @param _impl the logic address of PublicSaleProxy
    function setImplementation(address _impl) external override onlyProxyOwner {
        require(_impl != address(0), "PublicSaleProxy: logic is zero");

        _setImplementation(_impl);
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external override onlyOwner {
        pauseProxy = _pause;
        emit Pause(msg.sender,block.timestamp);
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external override onlyProxyOwner {
        require(impl != address(0), "PublicSaleProxy: input is zero");
        require(_implementation() != impl, "PublicSaleProxy: same");
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public override view returns (address) {
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
            "PublicSaleProxy: impl OR proxy is false"
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

    /// @dev Initialize
    function initialize(
        address _saleTokenAddress,
        address _getTokenOwner,
        address _vaultAddress
    ) external override onlyProxyOwner {
        require(startAddWhiteTime == 0, "possible to setting the whiteTime before");
        saleToken = IERC20(_saleTokenAddress);
        getTokenOwner = _getTokenOwner;
        liquidityVaultAddress = _vaultAddress;
        deployTime = block.timestamp;
    }

    function changeBasicSet(
        address _getTokenAddress,
        address _sTOS,
        address _wton,
        address _uniswapRouter,
        address _TOS
    ) external override onlyProxyOwner {
        require(startAddWhiteTime == 0, "possible to setting the whiteTime before");
        getToken = _getTokenAddress;
        sTOS = ILockTOS(_sTOS);
        wton = _wton;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        tos = IERC20(_TOS);
        IERC20(wton).approve(
            address(uniswapRouter),
            type(uint256).max
        );
        IERC20(getToken).approve(
            wton,
            type(uint256).max
        );
    }

    function setMaxMinPercent(
        uint256 _min,
        uint256 _max
    ) external override onlyProxyOwner {
        require(_min < _max, "need min < max");
        minPer = _min;
        maxPer = _max;
    }

    function setSTOSstandard(
        uint256 _tier1,
        uint256 _tier2,
        uint256 _tier3,
        uint256 _tier4
    ) external override onlyProxyOwner {
        require(
            (_tier1 < _tier2) &&
            (_tier2 < _tier3) &&
            (_tier3 < _tier4),
            "tier set error"
        );
        stanTier1 = _tier1;
        stanTier2 = _tier2;
        stanTier3 = _tier3;
        stanTier4 = _tier4;
    }

    function setDelayTime(
        uint256 _delay
    ) external override onlyProxyOwner {
        delayTime = _delay;
    }

    function onApprove(
        address sender,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == address(getToken) || msg.sender == address(IWTON(wton)), "PublicSale: only accept TON and WTON approve callback");
        if(msg.sender == address(getToken)) {
            uint256 wtonAmount = IPublicSale(address(this))._decodeApproveData(data);
            if(wtonAmount == 0){
                if(block.timestamp >= startExclusiveTime && block.timestamp < endExclusiveTime) {
                    IPublicSale(address(this)).exclusiveSale(sender,amount);
                } else {
                    require(block.timestamp >= startDepositTime && block.timestamp < endDepositTime, "PublicSale: not SaleTime");
                    IPublicSale(address(this)).deposit(sender,amount);
                }
            } else {
                uint256 totalAmount = amount + wtonAmount;
                if(block.timestamp >= startExclusiveTime && block.timestamp < endExclusiveTime) {
                    IPublicSale(address(this)).exclusiveSale(sender,totalAmount);
                }
                else {
                    require(block.timestamp >= startDepositTime && block.timestamp < endDepositTime, "PublicSale: not SaleTime");
                    IPublicSale(address(this)).deposit(sender,totalAmount);
                }
            }
        } else if (msg.sender == address(IWTON(wton))) {
            uint256 wtonAmount = IPublicSale(address(this))._toWAD(amount);
            if(block.timestamp >= startExclusiveTime && block.timestamp < endExclusiveTime) {
                IPublicSale(address(this)).exclusiveSale(sender,wtonAmount);
            }
            else {
                require(block.timestamp >= startDepositTime && block.timestamp < endDepositTime, "PublicSale: not SaleTime");
                IPublicSale(address(this)).deposit(sender,wtonAmount);
            }
        }

        return true;
    }
}