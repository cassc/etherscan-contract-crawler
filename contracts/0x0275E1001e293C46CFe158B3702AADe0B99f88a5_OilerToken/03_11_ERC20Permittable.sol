pragma solidity 0.5.12;

import "./ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


/**
 * @title ERC20Permittable
 * @dev This is ERC20 contract extended by the `permit` function (see EIP712).
 */
contract ERC20Permittable is ERC20, ERC20Detailed {

    string public constant version = "1";

    // EIP712 niceties
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public expirations;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20Detailed(_name, _symbol, _decimals) public {
        uint256 chainId = 0;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));
    }

    /// @dev transferFrom in this contract works in a slightly different form than the generic
    /// transferFrom function. This contract allows for "unlimited approval".
    /// Should the user approve an address for the maximum uint256 value,
    /// then that address will have unlimited approval until told otherwise.
    /// @param _sender The address of the sender.
    /// @param _recipient The address of the recipient.
    /// @param _amount The value to transfer.
    /// @return Success status.
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);

        if (_sender != msg.sender) {
            uint256 allowedAmount = allowance(_sender, msg.sender);

            if (allowedAmount != uint256(-1)) {
                // If allowance is limited, adjust it.
                // In this case `transferFrom` works like the generic
                _approve(_sender, msg.sender, allowedAmount.sub(_amount));
            } else {
                // If allowance is unlimited by `permit`, `approve`, or `increaseAllowance`
                // function, don't adjust it. But the expiration date must be empty or in the future.
                // Note that the expiration timestamp can have a 900-second error:
                // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
                require(
                    // solium-disable-next-line security/no-block-members
                    expirations[_sender][msg.sender] == 0 || expirations[_sender][msg.sender] >= _now(),
                    "expiry is in the past"
                );
            }
        } else {
            // If `_sender` is `msg.sender`,
            // the function works just like `transfer()`
        }

        return true;
    }

    /// @dev An alias for `transfer` function.
    /// @param _to The address of the recipient.
    /// @param _amount The value to transfer.
    function push(address _to, uint256 _amount) public {
        transferFrom(msg.sender, _to, _amount);
    }

    /// @dev Makes a request to transfer the specified amount
    /// from the specified address to the caller's address.
    /// @param _from The address of the holder.
    /// @param _amount The value to transfer.
    function pull(address _from, uint256 _amount) public {
        transferFrom(_from, msg.sender, _amount);
    }

    /// @dev An alias for `transferFrom` function.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _amount The value to transfer.
    function move(address _from, address _to, uint256 _amount) public {
        transferFrom(_from, _to, _amount);
    }

    /// @dev Allows to spend holder's unlimited amount by the specified spender.
    /// The function can be called by anyone, but requires having allowance parameters
    /// signed by the holder according to EIP712.
    /// @param _holder The holder's address.
    /// @param _spender The spender's address.
    /// @param _nonce The nonce taken from `nonces(_holder)` public getter.
    /// @param _expiry The allowance expiration date (unix timestamp in UTC).
    /// Can be zero for no expiration. Forced to zero if `_allowed` is `false`.
    /// @param _allowed True to enable unlimited allowance for the spender by the holder. False to disable.
    /// @param _v A final byte of signature (ECDSA component).
    /// @param _r The first 32 bytes of signature (ECDSA component).
    /// @param _s The second 32 bytes of signature (ECDSA component).
    function permit(
        address _holder,
        address _spender,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_expiry == 0 || _now() <= _expiry, "invalid expiry");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                _holder,
                _spender,
                _nonce,
                _expiry,
                _allowed
            ))
        ));

        require(_holder == ecrecover(digest, _v, _r, _s), "invalid signature or parameters");
        require(_nonce == nonces[_holder]++, "invalid nonce");

        uint256 amount = _allowed ? uint256(-1) : 0;
        _approve(_holder, _spender, amount);

        expirations[_holder][_spender] = _allowed ? _expiry : 0;
    }

    function _now() internal view returns(uint256) {
        return now;
    }

}