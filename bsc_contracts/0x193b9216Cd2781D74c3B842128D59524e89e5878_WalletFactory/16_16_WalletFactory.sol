// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IWalletFactory.sol";
import "./ManagedVestingWallet.sol";


/**
 * @title WalletFactory
 * @dev Used to reduce crowdsale conract size.
 */
contract WalletFactory is IWalletFactory, AccessControl {

    bytes32 public constant CROWDSALE_ROLE = keccak256("CROWDSALE_ROLE");

    bytes32 public constant INIT_CODE_VESTING_WALLET_HASH = keccak256(abi.encodePacked(type(ManagedVestingWallet).creationCode));

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdminOrSale {
        require(hasRole(CROWDSALE_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "WalletFactory: only admin or registered sale");
        _;
    }

    /**
     * @dev Return vesting wallet for given beneficiary and vesting manager.
     *
     * May strictly check is vesting wallet exist or not.
     *
     * @param beneficiary The beneficiary
     * @param vestingManager The vesting manager
     * @param strict If true will check deployed contract size to ensure that contract was already deployed by factory.
     */
    function walletFor(address beneficiary, address vestingManager, bool strict) external view returns (address) {
        address wallet = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(beneficiary, vestingManager)),
            INIT_CODE_VESTING_WALLET_HASH
        )))));
        if (strict) {
            uint256 size;
            assembly {
                size := extcodesize(wallet)
            }
            return size > 0 ? wallet : address(0);
        }
        return wallet;
    }

    /**
     * @dev Creates managed vesting wallet for given beneficiary and vesting manager. Can be used only by admin or sale.
     *
     * @param beneficiary The beneficiary
     * @param vestingManager The vesting manager
     */
    function createManagedVestingWallet(address beneficiary, address vestingManager) external onlyAdminOrSale returns (address) {
        address wallet;
        bytes memory bytecode = type(ManagedVestingWallet).creationCode;
        uint256 size;
        bytes32 salt = keccak256(abi.encodePacked(beneficiary, vestingManager));
        assembly {
            wallet := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            size := extcodesize(wallet)
            if iszero(extcodesize(wallet)) {
                revert(0, 0)
            }
        }
        // 0x485cc955: bytes4(keccak256(bytes('initialize(address,address)')));
        (bool success, bytes memory data) = wallet.call(abi.encodeWithSelector(0x485cc955, beneficiary, vestingManager));
        require(success && abi.decode(data, (bool)), "WalletFactory: initialize failed");
        return wallet;
    }

    /**
     * @dev Add crowdsale contract address `sale_` to the token.
     *
     * Can be added only in origin chain.
     */
    function addSale(address sale_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(sale_ != address(0), "WalletFactory: zero address given");
        _grantRole(CROWDSALE_ROLE, sale_);
    }

    /**
     * @dev Remove crowdsale contract address `sale_` from the token. 
     *
     * Can be removed only in origin chain.
     */
    function removeSale(address sale_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(sale_ != address(0), "WalletFactory: zero address given");
        _revokeRole(CROWDSALE_ROLE, sale_);
    }

}