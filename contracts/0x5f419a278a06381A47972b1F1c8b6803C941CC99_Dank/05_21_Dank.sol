// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./ERC20PresetMinterRebaser.sol";

// ,------.    ,---.  ,--.  ,--.,--. ,--. 
// |  .-.  \  /  O  \ |  ,'.|  ||  .'   / 
// |  |  \  :|  .-.  ||  |' '  ||  .   '  
// |  '--'  /|  | |  ||  | `   ||  |\   \ 
// `-------' `--' `--'`--'  `--'`--' '--' 
// ,--.   ,--.,------.,--.   ,--.,------. 
// |   `.'   ||  .---'|   `.'   ||  .---' 
// |  |'.'|  ||  `--, |  |'.'|  ||  `--,  
// |  |   |  ||  `---.|  |   |  ||  `---. 
// `--'   `--'`------'`--'   `--'`------' 
//  ,---.  ,--.   ,--.  ,---.  ,------.   
// '   .-' |  |   |  | /  O  \ |  .--. '  
// `.  `-. |  |.'.|  ||  .-.  ||  '--' |  
// .-'    ||   ,'.   ||  | |  ||  | --'   
// `-----' '--'   '--'`--' `--'`--'     

abstract contract IDANK {
    event Rebase(
        uint256 epoch,
        uint256 prevDankScalingFactor,
        uint256 newDankScalingFactor
    );

    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);
}


contract Dank is ERC20PresetMinterRebaser, Ownable, IDANK {
    using SafeMath for uint256;

    /// @dev public variables
    uint256 public initSupply;
    uint256 public dankScalingFactor;
    uint256 public constant BASE = 10**18;
    uint256 public constant internalDecimals = 10**24;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    /// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice EIP-712 implementation
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @dev internal variables
    /// @dev not currently used
    bool internal _notEntered;
    mapping(address => uint256) internal _dankBalances;
    mapping(address => mapping(address => uint256)) internal _allowedFragments;

    /// @dev 69 ftw
    uint256 private INIT_SUPPLY = 6969696969696 * 10**18;
    uint256 private _totalSupply;

    /// I
    modifier validRecipient(address to) {
        require(to != address(this));
        require(to != address(0x0));
        _;
    }

    /// am
    constructor() ERC20PresetMinterRebaser("Dank", "DANK") {
        dankScalingFactor = BASE;
        initSupply = _fragmentToDank(INIT_SUPPLY);
        _totalSupply = INIT_SUPPLY;
        _dankBalances[owner()] = initSupply;

        emit Transfer(address(0), msg.sender, INIT_SUPPLY);
    }

    /// not
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// ryoshi
    function maxScalingFactor() external view returns (uint256) {
        return _maxScalingFactor();
    }

    /// @dev checks if scaling factor is too high to compute balances for rebasing
    function _maxScalingFactor() internal view returns (uint256) {
        // can only go up to 2**256-1 = initSupply * dankScalingFactor
        return uint256(int256(-1)) / initSupply;
    }

    function mint(address to, uint256 amount) 
        external 
        returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal override {
        _totalSupply = _totalSupply.add(amount);
        uint256 dankValue = _fragmentToDank(amount);
        initSupply = initSupply.add(dankValue);

        require(
            dankScalingFactor <= _maxScalingFactor(),
            "max scaling factor too low"
        );

        _dankBalances[to] = _dankBalances[to].add(dankValue);

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) public override {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        // decrease totalSupply
        _totalSupply = _totalSupply.sub(amount);

        // get underlying value
        uint256 dankValue = _fragmentToDank(amount);

        // decrease initSupply
        initSupply = initSupply.sub(dankValue);

        // decrease balance
        _dankBalances[msg.sender] = _dankBalances[msg.sender].sub(dankValue);
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Mints new tokens using underlying amount, increasing totalSupply, initSupply, and a users balance.
     */
    function mintUnderlying(address to, uint256 amount) public returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");

        _mintUnderlying(to, amount);
        return true;
    }

    /// @dev scales the input amount
    function _mintUnderlying(address to, uint256 amount) internal {
        initSupply = initSupply.add(amount);
        uint256 scaledAmount = _dankToFragment(amount);
        _totalSupply = _totalSupply.add(scaledAmount);

        require(
            dankScalingFactor <= _maxScalingFactor(),
            "scaling factor lower than max"
        );

        // add balance
        _dankBalances[to] = _dankBalances[to].add(amount);

        emit Mint(to, scaledAmount);
        emit Transfer(address(0), to, scaledAmount);
    }

    function transferUnderlying(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        // sub from balance of sender
        _dankBalances[msg.sender] = _dankBalances[msg.sender].sub(value);

        // add to balance of receiver
        _dankBalances[to] = _dankBalances[to].add(value);
        emit Transfer(msg.sender, to, _dankToFragment(value));
        return true;
    }

    function transfer(address to, uint256 value)
        public
        override
        validRecipient(to)
        returns (bool)
    {
        // minimum transfer value == dankScalingFactor / 1e24;
        uint256 dankValue = _fragmentToDank(value);

        _dankBalances[msg.sender] = _dankBalances[msg.sender].sub(dankValue);

        _dankBalances[to] = _dankBalances[to].add(dankValue);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validRecipient(to) returns (bool) {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
        ].sub(value);

        uint256 dankValue = _fragmentToDank(value);

        _dankBalances[from] = _dankBalances[from].sub(dankValue);
        _dankBalances[to] = _dankBalances[to].add(dankValue);
        emit Transfer(from, to, value);

        return true;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _dankToFragment(_dankBalances[who]);
    }

    function balanceOfUnderlying(address who) public view returns (uint256) {
        return _dankBalances[who];
    }

    function allowance(address owner_, address spender)
        public
        view
        override
        returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    /// @dev sets the allowed fragments for the spender
    function approve(address spender, uint256 value)
        public
        override
        returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev updates allowed fragments
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) public returns (uint256) {
        require(hasRole(REBASER_ROLE, _msgSender()), "Rebaser role required");

        if (indexDelta == 0) {
            emit Rebase(epoch, dankScalingFactor, dankScalingFactor);
            return _totalSupply;
        }

        uint256 prevDankScalingFactor = dankScalingFactor;

        if (!positive) {
            // negative rebase, decrease scaling factor
            dankScalingFactor = dankScalingFactor
                .mul(BASE.sub(indexDelta))
                .div(BASE);
        } else {
            // positive rebase, increase scaling factor
            uint256 newScalingFactor = dankScalingFactor
                .mul(BASE.add(indexDelta))
                .div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                dankScalingFactor = newScalingFactor;
            } else {
                dankScalingFactor = _maxScalingFactor();
            }
        }

        emit Rebase(epoch, prevDankScalingFactor, dankScalingFactor);
        _totalSupply = _dankToFragment(initSupply);
        return _totalSupply;
    }

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "DANK/permit-expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        require(owner != address(0), "DANK/invalid-address-0");
        require(owner == ecrecover(digest, v, r, s), "DANK/invalid-permit");
        _allowedFragments[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function dankToFragment(uint256 dank) public view returns (uint256) {
        return _dankToFragment(dank);
    }

    function fragmentToDank(uint256 value) public view returns (uint256) {
        return _fragmentToDank(value);
    }

    function _dankToFragment(uint256 dank) internal view returns (uint256) {
        return dank.mul(dankScalingFactor).div(internalDecimals);
    }

    function _fragmentToDank(uint256 value) internal view returns (uint256) {
        return value.mul(internalDecimals).div(dankScalingFactor);
    }

}