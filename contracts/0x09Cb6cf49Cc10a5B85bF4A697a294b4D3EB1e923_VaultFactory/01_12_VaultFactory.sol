// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IVaultFactory.sol";
import "./tokens/MintableBurnableERC20.sol";
import "./Vault.sol";

contract VaultFactory is IVaultFactory, Ownable {

    IERC20 public immutable override collateral;
    IMintableBurnableERC20 public immutable override token;
    address public immutable vaultImplementation;

    address public override protocolFeeTo;
    uint public override maxProtocolFee;
    address public override redemptionFeeTo;
    uint public override minRedemptionFee;
    uint public override maxRedemptionAdjustment;
    uint public constant override PRECISION = 1e18;

    mapping(address => address) public override getVault;
    address[] public override allVaults;
    mapping(address => bool) public override isVaultManager;

    constructor(IERC20 _collateral, string memory _name, string memory _symbol) {
        collateral = _collateral;
        token = new MintableBurnableERC20(_name, _symbol);
        vaultImplementation = address(new Vault());
        protocolFeeTo = msg.sender;
        redemptionFeeTo = msg.sender;
        maxProtocolFee = 40e16; // default to 40%
        minRedemptionFee = 5e15; // default to 0.5%
        maxRedemptionAdjustment = 15e15; // default to 1.5%
    }

    function vaultsLength() external override view returns (uint) {
        return allVaults.length;
    }

    function createVault(address _owner) external override returns (address) {
        require(getVault[_owner] == address(0), 'exists');
        bytes32 salt = keccak256(abi.encodePacked(_owner));
        address vault = Clones.cloneDeterministic(vaultImplementation, salt);
        IVault(vault).initialize(_owner);
        token.setMinter(vault, true);
        getVault[_owner] = vault;
        allVaults.push(vault);
        emit VaultCreated(_owner, vault, allVaults.length - 1);
        return vault;
    }

    function setVaultManager(address _manager, bool _status) external override onlyOwner {
        isVaultManager[_manager] = _status;
        emit SetVaultManager(_manager, _status);
    }

    function setMinRedemptionFee(uint _minRedemptionFee) external override onlyOwner {
        require(_minRedemptionFee > 0 && _minRedemptionFee <= 10e16, "fee needs to be > 0 and < 10%");
        minRedemptionFee = _minRedemptionFee;
        emit SetMinRedemptionFee(_minRedemptionFee);
    }

    function setMaxRedemptionAdjustment(uint _maxRedemptionAdjustment) external override onlyOwner {
        require(_maxRedemptionAdjustment > 0 && _maxRedemptionAdjustment <= 10e16, "adjustment needs to be > 0 and < 10%");
        maxRedemptionAdjustment = _maxRedemptionAdjustment;
        emit SetMaxRedemptionAdjustment(_maxRedemptionAdjustment);
    }

    function setRedemptionFeeTo(address _redemptionFeeTo) external override onlyOwner {
        redemptionFeeTo = _redemptionFeeTo;
        emit SetRedemptionFeeTo(_redemptionFeeTo);
    }

    function setMaxProtocolFee(uint _maxProtocolFee) external override onlyOwner {
        require(_maxProtocolFee > 0 && _maxProtocolFee <= 1e18, "fee needs to be > 0 and < 100%");
        maxProtocolFee = _maxProtocolFee;
        emit SetMaxProtocolFee(_maxProtocolFee);
    }

    function setProtocolFeeTo(address _protocolFeeTo) external override onlyOwner {
        protocolFeeTo = _protocolFeeTo;
        emit SetProtocolFeeTo(_protocolFeeTo);
    }

    // Factory should not have any balances, allow rescuing of accidental transfers
    function rescue(address _token, address payable _recipient) external onlyOwner {
        if (_token == address(0)) {
            (bool sent, ) = _recipient.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
        } else {
            uint _balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_recipient, _balance);
        }
    }

    event VaultCreated(address indexed owner, address indexed vault, uint id);
    event SetVaultManager(address indexed manager, bool status);
    event SetMinRedemptionFee(uint minRedemptionFee);
    event SetMaxRedemptionAdjustment(uint maxRedemptionAdjustment);
    event SetRedemptionFeeTo(address indexed redemptionFeeTo);
    event SetMaxProtocolFee(uint maxProtocolFee);
    event SetProtocolFeeTo(address indexed protocolFeeTo);
}