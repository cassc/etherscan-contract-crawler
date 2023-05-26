// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDai.sol";

contract TransferHandler is ERC2771Context, Ownable, Pausable, ReentrancyGuard {
    struct PermitOptions {
        uint256 value;
        uint256 nonce;
        uint256 deadline;
        bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    event Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    /**
     * @dev Trigger contract stop or resume
     * Can only be called by the current owner.
     */
    function setPause(bool val) external onlyOwner {
        if (val) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Transfers ERC20 token to intended recipient
     * @param token : address of ERC20 token contract
     * @param to : recipient address
     * @param amount : amount of token transferred to recipient
     */
    function transfer(
        address token,
        address to,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), to, amount);
        emit Transfer(token, _msgSender(), to, amount);
    }

    /**
     * @dev
     * - obtains a permit to spend tokens worth options.value amount
     * - Transfers ERC20 token to intended recipient
     * @param token : address of ERC20 token contract supporting EIP2612
     * @param to : recipient address
     * @param amount : amount of token transferred to recipient
     * @param options: the permit request options for executing permit
     */
    function permitEIP2612AndTransfer(
        address token,
        address to,
        uint256 amount,
        PermitOptions memory options
    ) external whenNotPaused nonReentrant {
        SafeERC20.safePermit(
            IERC20Permit(token),
            _msgSender(),
            address(this),
            options.value,
            options.deadline,
            options.v,
            options.r,
            options.s
        );
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), to, amount);
        emit Transfer(token, _msgSender(), to, amount);
    }

    /**
     * @dev
     * - obtains a permit to spend tokens since options.allowed = true
     * - Transfers ERC20 token to intended recipient
     * @param token : address of ERC20 token contract supporting DAI
     * @param to : recipient address
     * @param amount : amount of token transferred to recipient
     * @param options: the permit request options for executing permit
     */
    function permitDAIAndTransfer(
        address token,
        address to,
        uint256 amount,
        PermitOptions memory options
    ) external whenNotPaused nonReentrant {
        IDai(token).permit(
            _msgSender(),
            address(this),
            options.nonce,
            options.deadline,
            options.allowed,
            options.v,
            options.r,
            options.s
        );
        SafeERC20.safeTransferFrom(IERC20(token), _msgSender(), to, amount);
        emit Transfer(token, _msgSender(), to, amount);
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external view returns (string memory) {
        return "1";
    }
}