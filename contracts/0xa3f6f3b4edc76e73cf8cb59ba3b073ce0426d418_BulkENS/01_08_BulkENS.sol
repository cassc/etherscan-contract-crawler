// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./interfaces/IBulkENS.sol";
import "./interfaces/ens/IETHRegistrarController.sol";
import "oz/access/Ownable.sol";
import "oz/token/ERC20/IERC20.sol";

/**
 * @title A contract to register and renew multiple .eth ENS domains at once.
 * @notice Only supports .eth domains. Optionally takes extra fee.
 * @author Alex Tkachenko <https://twitter.com/jackqack>.
 *
 * @dev Works on top of ENS v0.1.
 */
contract BulkENS is IBulkENS, Ownable {
    bytes[] EMPTY_DATA = new bytes[](0);

    IETHRegistrarController public immutable ens;
    uint256 registerFee = 2_000; // 20% in bps
    uint256 renewFee = 0; // 0% in bps

    constructor(IETHRegistrarController _ens) {
        ens = _ens;
    }

    /// @inheritdoc IBulkENS
    function getRegisterFee() external view returns (uint256) {
        return registerFee;
    }

    /// @inheritdoc IBulkENS
    function setRegisterFee(uint256 _registerFee) external onlyOwner {
        require(_registerFee >= 0 && _registerFee <= 10_000);
        registerFee = _registerFee;
    }

    /// @inheritdoc IBulkENS
    function getRenewFee() external view returns (uint256) {
        return renewFee;
    }

    /// @inheritdoc IBulkENS
    function setRenewFee(uint256 _renewFee) external onlyOwner {
        require(_renewFee >= 0 && _renewFee <= 10_000);
        renewFee = _renewFee;
    }

    /// @inheritdoc IBulkENS
    function commit(bytes32[] calldata _commitments) external {
        for (uint256 i; i < _commitments.length;) {
            ens.commit(_commitments[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBulkENS
    function register(
        string[] calldata _names,
        address[] calldata _owners,
        uint256[] calldata _durations,
        bytes32[] calldata _secrets,
        uint256[] calldata _prices
    ) external payable {
        uint256 initBalance = address(this).balance - msg.value;

        // Calculate prices on client to save gas. ENS uses
        // Chainlink ETH/USD oracle which is currently updated
        // once per hour or on 0.5% price change
        for (uint256 i = 0; i < _names.length;) {
            ens.register{value: _prices[i]}(
                _names[i], _owners[i], _durations[i], _secrets[i], address(0), EMPTY_DATA, false, 0
            );
            unchecked {
                ++i;
            }
        }

        require(address(this).balance >= initBalance, "not enough eth");

        uint256 totalRent = initBalance + msg.value - address(this).balance;
        uint256 fees = totalRent * registerFee / 10_000; // Rent must be too high for overflow
        require(address(this).balance - initBalance >= fees, "minimum fee not covered");

        // Return any excess funds (this check costs ~100 gas)
        if (address(this).balance > initBalance + fees) {
            payable(msg.sender).transfer(address(this).balance - (initBalance + fees));
        }
    }

    /// @inheritdoc IBulkENS
    function renew(string[] calldata _names, uint256[] calldata _durations, uint256[] calldata _prices)
        external
        payable
    {
        uint256 initBalance = address(this).balance - msg.value;

        // Prices are calculated on client to save gas, same as in register()
        for (uint256 i; i < _names.length;) {
            ens.renew{value: _prices[i]}(_names[i], _durations[i]);
            unchecked {
                ++i;
            }
        }

        require(address(this).balance >= initBalance, "not enough eth");

        uint256 totalRent = initBalance + msg.value - address(this).balance;
        uint256 fees = totalRent * renewFee / 10_000; // Rent must be too high for overflow
        require(address(this).balance - initBalance >= fees, "minimum fee not covered");

        // Return any excess funds (this check costs ~100 gas)
        if (address(this).balance > initBalance + fees) {
            payable(msg.sender).transfer(address(this).balance - (initBalance + fees));
        }
    }

    /// @inheritdoc IBulkENS
    function calculateRegisterPrice(string[] calldata _names, uint256[] calldata _durations)
        external
        view
        returns (uint256 _totalPrice, uint256[] memory _prices, uint256 _fee)
    {
        return _calculatePrice(_names, _durations, registerFee);
    }

    /// @inheritdoc IBulkENS
    function calculateRenewPrice(string[] calldata _names, uint256[] calldata _durations)
        external
        view
        returns (uint256 _totalPrice, uint256[] memory _prices, uint256 _fee)
    {
        return _calculatePrice(_names, _durations, renewFee);
    }

    function _calculatePrice(string[] calldata _names, uint256[] calldata _durations, uint256 _feeShare)
        private
        view
        returns (uint256 _totalPrice, uint256[] memory _prices, uint256 _fee)
    {
        _prices = new uint256[](_names.length);
        for (uint256 i = 0; i < _names.length; ++i) {
            Price memory p = ens.rentPrice(_names[i], _durations[i]);
            _prices[i] = p.base + p.premium;
            _totalPrice += _prices[i];
        }
        _fee = _totalPrice * _feeShare / 10_000;
        _totalPrice += _fee;
    }

    /// @inheritdoc IBulkENS
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @inheritdoc IBulkENS
    function withdrawTokens(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @inheritdoc IBulkENS
    function getENSAddress() external view returns (address _ens) {
        return address(ens);
    }

    receive() external payable {}
}