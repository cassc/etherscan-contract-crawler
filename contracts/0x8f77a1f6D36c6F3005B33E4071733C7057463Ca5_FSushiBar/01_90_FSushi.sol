// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IFSushi.sol";
import "./libraries/DateUtils.sol";

contract FSushi is Ownable, ERC20, IFSushi {
    using DateUtils for uint256;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    uint256 public immutable override startWeek;

    mapping(address => bool) public override isMinter;
    bool public override mintersLocked;

    mapping(address => uint256) public override nonces;
    /**
     * @return minimum number of minted total supply during the whole week (only available >= startWeek)
     */
    mapping(uint256 => uint256) public override totalSupplyDuring;
    /**
     * @notice totalSupplyDuring is guaranteed to be correct before this week (exclusive)
     */
    uint256 public override lastCheckpoint;

    modifier onlyMinter() {
        if (!isMinter[msg.sender]) revert Forbidden();
        _;
    }

    constructor() ERC20("Flash Sushi Token", "fSUSHI") {
        uint256 nextWeek = block.timestamp.toWeekNumber() + 1;
        startWeek = nextWeek;
        lastCheckpoint = nextWeek;

        bytes32 hashedName = keccak256(bytes("Flash Sushi Token"));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function setMinter(address account, bool _isMinter) external override onlyOwner {
        if (mintersLocked) revert MintersLocked();

        isMinter[account] = _isMinter;

        emit SetMinter(account, _isMinter);
    }

    function lockMinters() external onlyOwner {
        mintersLocked = true;

        emit LockMinters();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (block.timestamp > deadline) revert Expired();

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) revert InvalidSignature();

        _approve(owner, spender, value);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);

        checkpoint();
    }

    function checkpointedTotalSupplyDuring(uint256 week) external override returns (uint256) {
        checkpoint();
        return totalSupplyDuring[week];
    }

    /**
     * @dev if this function doesn't get called for 512 weeks (around 9.8 years) this contract breaks
     */
    function checkpoint() public {
        uint256 from = lastCheckpoint;
        uint256 until = block.timestamp.toWeekNumber();
        if (until < from) return;

        for (uint256 i; i < 512; ) {
            uint256 week = from + i;
            uint256 old = totalSupplyDuring[week];
            if (week == until) {
                uint256 current = totalSupply();
                if (current > old) {
                    totalSupplyDuring[week] = current;
                }
                break;
            } else if (startWeek < week && old == 0) {
                totalSupplyDuring[week] = totalSupplyDuring[week - 1];
            }

            unchecked {
                ++i;
            }
        }

        lastCheckpoint = until;

        emit Checkpoint(until);
    }
}