// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import {BoringBatchable} from "./boringcrypto/BoringBatchable.sol";
import {IBridgeMintable} from "./interfaces/IBridgeMintable.sol";
import {ITransferListener} from "./interfaces/ITransferListener.sol";

contract SAMAv3 is
    Context,
    BoringBatchable,
    AccessControlEnumerable,
    ERC20Permit,
    IBridgeMintable
{
    bytes32 public constant ADMIN_SETTER_ROLE = keccak256("ADMIN_SETTER_ROLE");
    bytes32 public constant MINTER_SETTER_ROLE =
        keccak256("MINTER_SETTER_ROLE");
    bytes32 public constant ICE_KING_SETTER_ROLE =
        keccak256("ICE_KING_SETTER_ROLE");
    bytes32 public constant ICE_QUEEN_SETTER_ROLE =
        keccak256("ICE_QUEEN_SETTER_ROLE");

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // ice king can freeze accounts or pause the contract
    bytes32 public constant ICE_KING_ROLE = keccak256("ICE_KING_ROLE");
    // ice queen can mint, burn or transfer from frozen accounts
    bytes32 public constant ICE_QUEEN_ROLE = keccak256("ICE_QUEEN_ROLE");

    mapping(address => bool) private _frozenAccount;

    uint256 private _cap;
    address private _transferListener;
    bool private _paused;
    bool private _locked;

    event TransferListenerSet(address transferListener);
    event Locked(uint256 cap);
    event Frozen(address account);
    event Thawed(address account);
    event Paused();
    event Unpaused();

    constructor(
        string memory name,
        string memory symbol,
        uint256 cap_,
        address _governance,
        address _admin,
        address _minter
    ) ERC20(name, symbol) ERC20Permit(name) {
        _setRoleAdmin(MINTER_SETTER_ROLE, MINTER_SETTER_ROLE);
        _setRoleAdmin(ADMIN_SETTER_ROLE, ADMIN_SETTER_ROLE);
        _setRoleAdmin(ICE_KING_SETTER_ROLE, ICE_KING_SETTER_ROLE);
        _setRoleAdmin(ICE_QUEEN_SETTER_ROLE, ICE_QUEEN_SETTER_ROLE);

        _setRoleAdmin(MINTER_ROLE, MINTER_SETTER_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_SETTER_ROLE);
        _setRoleAdmin(ICE_KING_ROLE, ICE_KING_SETTER_ROLE);
        _setRoleAdmin(ICE_QUEEN_ROLE, ICE_QUEEN_SETTER_ROLE);

        _setupRole(MINTER_SETTER_ROLE, _governance);
        _setupRole(ADMIN_SETTER_ROLE, _governance);
        _setupRole(ICE_KING_SETTER_ROLE, _governance);
        _setupRole(ICE_QUEEN_SETTER_ROLE, _governance);

        if (cap_ == 0) {
            _cap = type(uint256).max;
        } else {
            _cap = cap_;
        }

        if (_admin != address(0)) {
            _setupRole(ADMIN_ROLE, _admin);
        }

        if (_minter != address(0)) {
            _setupRole(MINTER_ROLE, _minter);
        }
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    // alias for cap()
    function maxSupply() public view virtual returns (uint256) {
        return _cap;
    }

    function owner() public pure returns (address) {
        return address(0);
    }

    // Alias for owner()
    function getOwner() public pure returns (address) {
        return address(0);
    }

    // returns true if individual account is frozen
    function isFrozen(address _account) public view returns (bool) {
        return _frozenAccount[_account];
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function transferListener() public view returns (address) {
        return _transferListener;
    }

    function lock(uint256 newCap) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SAMA::lock: forbidden");
        require(!_locked, "SAMA::lock: already");
        require(newCap >= ERC20.totalSupply(), "SAMA::lock: invalid");

        _locked = true;
        _cap = newCap;

        emit Locked(newCap);
    }

    function setTransferListener(address _transferListener_) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SAMA::setTL: forbidden");
        _transferListener = _transferListener_;

        emit TransferListenerSet(_transferListener_);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isFrozen(_msgSender()), "SAMA::tx: frozen");
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!isFrozen(from), "SAMA::txFrom: frozen");
        return super.transferFrom(from, to, amount);
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "SAMA::mint: forbidden");
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        address from = _msgSender();
        require(!isFrozen(from), "SAMA::burn: frozen");
        _burn(from, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        require(!isFrozen(account), "SAMA::burnFrom: frozen");
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    // multiverse portal mint interface
    function proxyMintBatch(
        address /*_minter */,
        address _account,
        uint256[] calldata /* _ids */,
        uint256[] calldata _amounts,
        bytes memory /* _data */
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "SAMA::mint: forbidden");
        _mint(_account, _amounts[0]);
    }

    function pause() public virtual {
        require(hasRole(ICE_KING_ROLE, _msgSender()), "SAMA::pause: forbidden");
        require(!_paused, "SAMA::pause: already");
        _paused = true;

        emit Paused();
    }

    function unpause() public virtual {
        require(
            hasRole(ICE_KING_ROLE, _msgSender()),
            "SAMA::unpause: forbidden"
        );
        require(_paused, "SAMA::unpause: not paused");
        _paused = false;

        emit Unpaused();
    }

    function freeze(address account) public virtual {
        require(
            hasRole(ICE_KING_ROLE, _msgSender()),
            "SAMA::freeze: forbidden"
        );
        _frozenAccount[account] = true;

        emit Frozen(account);
    }

    function thaw(address account) public virtual {
        require(hasRole(ICE_KING_ROLE, _msgSender()), "SAMA::thaw: forbidden");
        _frozenAccount[account] = false;

        emit Thawed(account);
    }

    // can mint to a frozen account or
    // when the whole contract is paused
    function frozenMintTo(address account, uint256 amount) public virtual {
        require(hasRole(ICE_QUEEN_ROLE, _msgSender()), "SAMA::fmt: forbidden");
        require(_paused || isFrozen(account), "SAMA::fmt: not frozen");

        _mint(account, amount);
    }

    // if someone accidentally sends tokens to this contract, we can rescue
    function rescue(address _token, address _to, uint256 _amount) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SAMA::rescue: forbidden");

        if (_token == address(0)) {
            (bool _success, ) = _to.call{value: _amount}("");
            require(_success, "SAMA::rescue: native failed");
            return;
        }

        require(
            IERC20(_token).transfer(_to, _amount),
            "SAMA::rescue: erc20 failed"
        );
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "SAMA: cap exceeded");

        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        address _sender = _msgSender();
        require(
            !_paused || hasRole(ICE_QUEEN_ROLE, _sender),
            "SAMA::tx: frozen"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._afterTokenTransfer(from, to, amount);

        if (_transferListener != address(0)) {
            try
                ITransferListener(_transferListener).onTransfer(
                    _msgSender(),
                    from,
                    to,
                    amount
                )
            {} catch {}
        }
    }
}