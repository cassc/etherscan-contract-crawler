// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (ChampMarketplace.sol)
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation allows to use an underlying ERC20 token as an ERC777 token.
 */
contract ERC777Proxy is Context, IERC777, IERC20 {
    using Address for address;

    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    mapping(address => mapping(address => bool)) private _operators;

    IERC20Metadata private immutable _underlying;

    constructor(address underlying_) {
        _underlying = IERC20Metadata(underlying_);

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC777Token"),
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC20Token"),
            address(this)
        );
    }

    /**
     * @dev Returns underlying ERC20 token address.
     */
    function underlying() external view returns (address) {
        return address(_underlying);
    }

    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _underlying.name();
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _underlying.symbol();
    }

    /**
     * @dev See {ERC20-decimals}.
     */
    function decimals() public view virtual returns (uint8) {
        return _underlying.decimals();
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply()
        public
        view
        virtual
        override(IERC20, IERC777)
        returns (uint256)
    {
        return _underlying.totalSupply();
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address tokenHolder)
        public
        view
        virtual
        override(IERC20, IERC777)
        returns (uint256)
    {
        return _underlying.balanceOf(tokenHolder);
    }

    /**
     * @dev See {IERC777-send}.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            recipient != address(0),
            "ERC777: transfer to the zero address"
        );

        address from = _msgSender();

        _callTokensToSend(from, from, recipient, amount, "", "");

        _move(from, from, recipient, amount, "", "");

        _callTokensReceived(from, from, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder)
        public
        view
        virtual
        override
        returns (bool)
    {
        require(
            _underlying.allowance(tokenHolder, address(this)) > 0,
            "ERC777Proxy: No allowance on underlying"
        );
        return (operator == tokenHolder || _operators[tokenHolder][operator]);
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     * You should also approve this ERC777Proxy to spend your tokens:
     * IERC20(this.underlying()).approve(address(this), type(uint256).max);
     */
    function authorizeOperator(address operator) public virtual override {
        require(
            _msgSender() != operator,
            "ERC777: authorizing self as operator"
        );

        _operators[_msgSender()][operator] = true;

        emit AuthorizedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        delete _operators[_msgSender()][operator];

        emit RevokedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators()
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return new address[](0);
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(
            isOperatorFor(_msgSender(), sender),
            "ERC777: caller is not an operator for holder"
        );
        _send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(
            isOperatorFor(_msgSender(), account),
            "ERC777: caller is not an operator for holder"
        );
        _burn(account, amount, data, operatorData);
    }

    /**
     * @dev Not permitted
     */
    function allowance(address, address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        revert("ERC777Proxy: Operation not permitted");
    }

    /**
     * @dev Not permitted
     */
    function approve(address, uint256) public virtual override returns (bool) {
        revert("ERC777Proxy: Operation not permitted");
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(
            recipient != address(0),
            "ERC777: transfer to the zero address"
        );
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = _msgSender();

        _callTokensToSend(spender, holder, recipient, amount, "", "");

        _move(spender, holder, recipient, amount, "", "");

        _callTokensReceived(spender, holder, recipient, amount, "", "", false);

        return true;
    }

    /**
     * @dev Not permitted
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Not permitted
     */
    function _mint(
        address,
        uint256,
        bytes memory,
        bytes memory,
        bool
    ) internal virtual {
        revert("ERC777Proxy: Operation not permitted");
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            requireReceptionAck
        );
    }

    /**
     * @dev Not permitted
     */
    function _burn(
        address,
        uint256,
        bytes memory,
        bytes memory
    ) internal virtual {
        revert("ERC777Proxy: Operation not permitted");
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        _underlying.transferFrom(from, to, amount);

        emit Sent(operator, from, to, amount, userData, operatorData);
    }

    /**
     * @dev Not permitted
     */
    function _approve(
        address,
        address,
        uint256
    ) internal virtual {
        revert("ERC777Proxy: Operation not permitted");
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(
            from,
            _TOKENS_SENDER_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(
            to,
            _TOKENS_RECIPIENT_INTERFACE_HASH
        );
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(
                operator,
                from,
                to,
                amount,
                userData,
                operatorData
            );
        } else if (requireReceptionAck) {
            require(
                !to.isContract(),
                "ERC777: token recipient contract has no implementer for ERC777TokensRecipient"
            );
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}