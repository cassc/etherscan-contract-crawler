// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./tokens/IERC20Operator.sol";

/**
 * @dev Adaptation of OpenZeppelin's ERC20Permit
 */
contract SignedMoveProxy is AccessControlEnumerable, EIP712 {

    bytes32 public immutable AUTHORIZED_ROLE = keccak256("AUTHORIZED_ROLE");
    mapping(address => mapping(bytes32 => bool)) internal _authorizationStates;
    address public tokenAddress;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _MOVE_TYPEHASH = keccak256("Move(address from,address to,uint256 value,bytes32 nonce,uint256 deadline)");

    modifier  onlyAuthorizedRole() {
        require(hasRole(AUTHORIZED_ROLE, msg.sender), "SignedMoveProxy: caller is not an AUTHORIZED_ROLE");
        _;
    }

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name, address _tokenAddress) EIP712(name, "1") {
        tokenAddress = _tokenAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    // @todo token address setter

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function moveWithSignature(
        address from,
        address to,
        uint256 value,
        bytes32 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public  onlyAuthorizedRole {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "SignedMoveProxy: expired deadline");
        require(
            !_authorizationStates[from][nonce],
            "SignedMoveProxy: authorization is used"
        );

        bytes32 structHash = keccak256(
            abi.encode(
                _MOVE_TYPEHASH,
                from,
                to,
                value,
                nonce,
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == from, "SignedMoveProxy: invalid signature");

        _authorizationStates[from][nonce] = true;

        IERC20Operator(tokenAddress).forcedTransfer(from, to, value);

        emit AuthorizationUsed(from, nonce);
    }

    function authorizationState(address authorizer, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return _authorizationStates[authorizer][nonce];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

}