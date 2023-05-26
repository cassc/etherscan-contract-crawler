// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Lightweight token modelled after UNI-LP:
// https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/UniswapV2ERC20.sol
// Adds:
//   - An exposed `burn()` and `mint()` with minting role
//   - ERC-3009 (`transferWithAuthorization()`)
//   - domainSeparator is computed inside `_validateSignedData` to avoid reply-attacks due to Hardforks
//   - to != address(this) && to != address(0); To avoid people sending tokens to this smartcontract and
//          to distinguish burn events from transfer

contract NODE is IERC20 {
    uint256 public initialBalance;

    // bytes32 public constant PERMIT_TYPEHASH =
    //      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    //      keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;
    // bytes32 public constant EIP712DOMAIN_HASH =
    //      keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712DOMAIN_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 public constant NAME_HASH =
    //      keccak256("DAppNode DAO Token")
    bytes32 public constant NAME_HASH =
        0x1516f2223544938aa8c94ede78adef55df8fb03f42c0bafde0491ede41d2ade7;
    // bytes32 public constant VERSION_HASH =
    //      keccak256("1")
    bytes32 public constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    string public constant name = "DAppNode DAO Token";
    string public constant symbol = "NODE";
    uint8 public constant decimals = 18;

    address public minter;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    // ERC-2612, ERC-3009 state
    mapping(address => uint256) public nonces;
    mapping(address => mapping(bytes32 => bool)) public authorizationState;

    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event ChangeMinter(address indexed minter);

    modifier onlyMinter {
        require(msg.sender == minter, "NODE: NOT_MINTER");
        _;
    }

    constructor(address initialMinter) {
        _changeMinter(initialMinter);
    }

    function _validateSignedData(
        address signer,
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData)
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(
            recoveredAddress != address(0) && recoveredAddress == signer,
            "NODE: INVALID_SIGNATURE"
        );
    }

    function _changeMinter(address newMinter) internal {
        minter = newMinter;
        emit ChangeMinter(newMinter);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        // Balance is implicitly checked with solidity underflow protection
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(
            to != address(this) && to != address(0),
            "NODE: NOT_VALID_TRANSFER"
        );
        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function getChainId() public view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_HASH,
                    NAME_HASH,
                    VERSION_HASH,
                    getChainId(),
                    address(this)
                )
            );
    }

    function mint(address to, uint256 value)
        external
        onlyMinter
        returns (bool)
    {
        _mint(to, value);
        return true;
    }

    function changeMinter(address newMinter) external onlyMinter {
        _changeMinter(newMinter);
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != type(uint256).max) {
            // Allowance is implicitly checked with solidity underflow protection
            allowance[from][msg.sender] = fromAllowance - value;
        }
        _transfer(from, to, value);
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
    ) external {
        require(deadline >= block.timestamp, "NODE: AUTH_EXPIRED");
        bytes32 encodeData = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );
        _validateSignedData(owner, encodeData, v, r, s);
        _approve(owner, spender, value);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp > validAfter, "NODE: AUTH_NOT_YET_VALID");
        require(block.timestamp < validBefore, "NODE: AUTH_EXPIRED");
        require(!authorizationState[from][nonce], "NODE: AUTH_ALREADY_USED");

        bytes32 encodeData = keccak256(
            abi.encode(
                TRANSFER_WITH_AUTHORIZATION_TYPEHASH,
                from,
                to,
                value,
                validAfter,
                validBefore,
                nonce
            )
        );
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}