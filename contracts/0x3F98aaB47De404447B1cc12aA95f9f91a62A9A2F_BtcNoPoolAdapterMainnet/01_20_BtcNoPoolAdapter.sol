// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BtcNoPoolAdapterMainnet is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public wallet;
    bool public upgradeStatus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

   function initialize(address _multiSigWallet, address _liquidityHandler) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Adapter: Not contract");
        require(_liquidityHandler.isContract(), "Adapter: Not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(DEFAULT_ADMIN_ROLE, _liquidityHandler);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);
        wallet = _multiSigWallet;
    }

    function deposit(address _token, uint256 _fullAmount, uint256 _leaveInPool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 toSend = _fullAmount - _leaveInPool;
        if(toSend != 0){
            IERC20(WBTC).safeTransfer(wallet, toSend / 10**10);
        }
    } 

    function withdraw(address _user, address _token, uint256 _amount ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(WBTC).safeTransfer(_user, _amount / 10**10);
    }
    
    function getAdapterAmount() external view returns (uint256) {
        return IERC20(WBTC).balanceOf(address(this)) * 10**10;
    }

    function getCoreTokens() external pure returns ( address mathToken, address primaryToken ){
        return (WBTC, WBTC);
    }

    function setWallet(address _newWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wallet = _newWallet;
    }

    /**
     * @dev admin function for removing funds from contract
     * @param _address address of the token being removed
     * @param _amount amount of the token being removed
     */
    function removeTokenByAddress(address _address, address _to, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(_address).safeTransfer(_to, _amount);
    }

    function changeUpgradeStatus(bool _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        upgradeStatus = _status;
    }
    
    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(upgradeStatus, "Adapter: Upgrade not allowed");
        upgradeStatus = false;
    }
}