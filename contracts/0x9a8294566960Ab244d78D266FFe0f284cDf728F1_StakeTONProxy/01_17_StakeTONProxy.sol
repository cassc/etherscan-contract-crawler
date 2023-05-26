// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {IStakeVaultStorage} from "../interfaces/IStakeVaultStorage.sol";
import {IIERC20} from "../interfaces/IIERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./StakeTONStorage.sol";
import "../common/AccessibleCommon.sol";
import {OnApprove} from "../tokens/OnApprove.sol";
import "./ProxyBase.sol";

/// @title Proxy for Stake contracts in Phase 1
contract StakeTONProxy is
    StakeTONStorage,
    AccessibleCommon,
    ProxyBase,
    OnApprove
{
    using SafeMath for uint256;

    event Upgraded(address indexed implementation);

    /// @dev event on staking TON
    /// @param to the sender
    /// @param amount the amount of staking
    event Staked(address indexed to, uint256 amount);

    /// @dev the constructor of StakeTONProxy
    /// @param _logic the logic address of StakeTONProxy
    constructor(address _logic) {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );

        require(_logic != address(0), "StakeTONProxy: logic is zero");

        _setImplementation(_logic);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(this));
    }

    /// @notice Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external onlyOwner {
        pauseProxy = _pause;
    }

    /// @notice Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external onlyOwner {
        require(impl != address(0), "StakeTONProxy: input is zero");
        require(
            _implementation() != impl,
            "StakeTONProxy: The input address is same as the state"
        );
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /// @dev returns the implementation
    function implementation() public view returns (address) {
        return _implementation();
    }

    /// @dev receive ether
    receive() external payable {
        _fallback();
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
            "StakeTONProxy: impl is zero OR proxy is false"
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

    /// @dev Approves function
    /// @dev call by WTON
    /// @param owner  who actually calls
    /// @param spender  Who gives permission to use
    /// @param tonAmount  how much will be available
    /// @param data  Amount data to use with users
    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external override returns (bool) {
        (address _spender, uint256 _amount) = _decodeStakeData(data);
        require(
            tonAmount == _amount && spender == _spender,
            "StakeTONProxy: tonAmount != stakingAmount "
        );
        require(
            stakeOnApprove(msg.sender, owner, _spender, _amount),
            "StakeTONProxy: stakeOnApprove fails "
        );
        return true;
    }

    function _decodeStakeData(bytes calldata input)
        internal
        pure
        returns (address spender, uint256 amount)
    {
        (spender, amount) = abi.decode(input, (address, uint256));
    }

    /// @dev stake with WTON
    /// @param from  WTON
    /// @param _owner  who actually calls
    /// @param _spender  Who gives permission to use
    /// @param _amount  how much will be available
    function stakeOnApprove(
        address from,
        address _owner,
        address _spender,
        uint256 _amount
    ) public returns (bool) {
        require(
            (paytoken == from && _amount > 0 && _spender == address(this)),
            "StakeTONProxy: stakeOnApprove init fail"
        );
        require(
            block.number >= saleStartBlock && block.number < startBlock,
            "StakeTONProxy: period not allowed"
        );

        require(
            !IStakeVaultStorage(vault).saleClosed(),
            "StakeTONProxy: end sale"
        );
        require(
            IIERC20(paytoken).balanceOf(_owner) >= _amount,
            "StakeTONProxy: insuffient"
        );

        LibTokenStake1.StakedAmount storage staked = userStaked[_owner];
        if (staked.amount == 0) totalStakers = totalStakers.add(1);

        staked.amount = staked.amount.add(_amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
        require(
            IIERC20(from).transferFrom(_owner, _spender, _amount),
            "StakeTONProxy: transfer fail"
        );

        emit Staked(_owner, _amount);
        return true;
    }

    /// @dev set initial storage
    /// @param _addr the array addresses of token, paytoken, vault, defiAddress
    /// @param _registry the registry address
    /// @param _intdata the array valued of saleStartBlock, stakeStartBlock, periodBlocks
    function setInit(
        address[4] memory _addr,
        address _registry,
        uint256[3] memory _intdata
    ) external onlyOwner {
        require(token == address(0), "StakeTONProxy: already initialized");

        require(
            _registry != address(0) &&
                _addr[2] != address(0) &&
                _intdata[0] < _intdata[1],
            "StakeTONProxy: setInit fail"
        );
        token = _addr[0];
        paytoken = _addr[1];
        vault = _addr[2];
        defiAddr = _addr[3];

        stakeRegistry = _registry;

        tokamakLayer2 = address(0);

        saleStartBlock = _intdata[0];
        startBlock = _intdata[1];
        endBlock = startBlock.add(_intdata[2]);
    }
}