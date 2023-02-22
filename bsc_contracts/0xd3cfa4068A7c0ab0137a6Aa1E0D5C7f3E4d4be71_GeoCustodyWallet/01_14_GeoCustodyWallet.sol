// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IGeoCustodyWallet.sol";

contract GeoCustodyWallet is Initializable, ContextUpgradeable, ERC165Upgradeable, IGeoCustodyWallet {

    bytes32 public constant RELEASER_ROLE = keccak256("RELEASER_ROLE");

    event EtherReturned(address indexed user, uint256 amount);
    event ERC20Returned(address indexed user, address indexed token, uint256 amount);

    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    IAccessControlUpgradeable private _accessStorage;

    uint256 private _released;
    mapping(address => uint256) private _erc20Released;

    address private _beneficiary;

    function initialize(address accessControlStorage, address beneficiaryAddress) override public initializer {
        require(accessControlStorage != address(0), "GeoCustodyWallet: access control storage is zero address");
        require(beneficiaryAddress != address(0), "GeoCustodyWallet: beneficiary is zero address");

        _accessStorage = IAccessControlUpgradeable(accessControlStorage);
        _beneficiary = beneficiaryAddress;
    }

    modifier onlyAllowed() {
        require(_accessStorage.hasRole(RELEASER_ROLE, msg.sender), 'Caller is not releaser');
        _;
    }

    function version() override public pure returns (uint32){
        //version in format aaa.bbb.ccc => aaa*1E6+bbb*1E3+ccc;
        return uint32(1000001);
    }

    function beneficiary() override public view returns (address) {
        return _beneficiary;
    }

    function released() override public view returns (uint256) {
        return _released;
    }

    function released(address token) override public view returns (uint256) {
        return _erc20Released[token];
    }

    function returnFunds(address payable wallet) onlyAllowed public returns(uint256) {
        uint256 releasable = address(this).balance;
        emit EtherReturned(wallet, releasable);
        Address.sendValue(wallet, releasable);
        return releasable;
    }

    function returnFunds(address payable wallet, address token) onlyAllowed public returns(uint256) {
        uint256 releasable = IERC20(token).balanceOf(address(this));
        emit ERC20Returned(wallet, token, releasable);
        SafeERC20.safeTransfer(IERC20(token), wallet, releasable);
        return releasable;
    }

    // consolidate
    function release() override onlyAllowed public returns (uint256) {
        uint256 releasable = address(this).balance;
        _released += releasable;
        emit EtherReleased(releasable);
        Address.sendValue(payable(beneficiary()), releasable);
        return releasable;
    }

    // consolidate
    function release(address token) override onlyAllowed public returns(uint256) {
        uint256 releasable = IERC20(token).balanceOf(address(this));
        _erc20Released[token] += releasable;
        emit ERC20Released(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), beneficiary(), releasable);
        return releasable;
    }

    receive() external payable {}

}