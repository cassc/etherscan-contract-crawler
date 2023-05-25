// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract DexpoolsToken is ERC20, ERC20Permit, Pausable, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    bytes32 public constant TAKE_FEE_ROLE = keccak256("TAKE_FEE_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    uint256 private _maxSupply = 100000000 * 10**decimals(); // 100M tokens is maximum supply
    uint256 private _initialSupply = 0; // 0 tokens is the initial supply

    address private _trustedForwarder;

    // Control support for EIP-2771 Meta Transactions
    bool public metaTxnsEnabled = false;

    event TokensRescued(address indexed sender, address indexed token, uint256 value);
    event MetaTxnsEnabled(address indexed caller);
    event MetaTxnsDisabled(address indexed caller);

    constructor(address trustedForwarder) ERC20("Dexpools Token", "DXP") ERC20Permit("Dexpools Token") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(RESCUER_ROLE, _msgSender());

        _trustedForwarder = trustedForwarder;

        _mint(_msgSender(), _initialSupply);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev Returns the maximum amount of tokens that can be minted.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= _maxSupply, "ERC20: cannot mint more tokens, cap exceeded");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function rescueTokens(IERC20 token, uint256 value) external onlyRole(RESCUER_ROLE) {
        token.transfer(_msgSender(), value);

        emit TokensRescued(_msgSender(), address(token), value);
    }

    // Enable support for meta transactions
    function enableMetaTxns() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!metaTxnsEnabled, "Meta transactions are already enabled");

        metaTxnsEnabled = true;
        emit MetaTxnsEnabled(_msgSender());
    }

    // Disable support for meta transactions
    function disableMetaTxns() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(metaTxnsEnabled, "Meta transactions are already disabled");

        metaTxnsEnabled = false;
        emit MetaTxnsDisabled(_msgSender());
    }
}