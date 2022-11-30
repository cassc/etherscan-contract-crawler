// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin/access/Ownable2Step.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/Strings.sol";
import "solmate/tokens/ERC721.sol";

import "./ILockManager.sol";

/// @title Solarbots Christmas 2022
/// @author Solarbots (https://solarbots.io)
contract Christmas2022 is Ownable2Step, ERC721 {
    // ---------- CONSTANTS ----------

    string public constant ERROR_NO_METADATA = "NO_METADATA";
    string public constant ERROR_MINT_NOT_STARTED = "MINT_NOT_STARTED";
    string public constant ERROR_MINT_ENDED = "MINT_ENDED";
    string public constant ERROR_MINT_REQUIRES_4_MK1 = "MINT_REQUIRES_4_MK1";
    string public constant ERROR_ALREADY_MINTED = "ALREADY_MINTED";
    string public constant ERROR_BURN_BEFORE_MINT_ENDED = "BURN_BEFORE_MINT_ENDED";
    string public constant ERROR_NOT_TOKEN_OWNER = "NOT_TOKEN_OWNER";
    string public constant ERROR_UNSAFE_RECIPIENT = "UNSAFE_RECIPIENT";
    string public constant ERROR_TOKEN_LOCKED = "TOKEN_LOCKED";

    /// @notice Mk.1 Solarbots contract
    IERC721 public immutable MK1_SOLARBOTS;

    /// @notice Unix timestamp of mint start
    uint256 public immutable TIMESTAMP_MINT_START;

    /// @notice Unix timestamp of mint end
    uint256 public immutable TIMESTAMP_MINT_END;

    // ---------- STATE ----------

    /// @notice Total token supply
    uint256 public totalSupply;

    /// @notice Token URI base
    /// @custom:security write-protection="onlyOwner()"
    string public tokenURIBase;

    /// @notice Token URI suffix
    /// @custom:security write-protection="onlyOwner()"
    string public tokenURISuffix;

    /// @notice Lock manager contract
    /// @custom:security non-reentrant
    /// @custom:security write-protection="onlyOwner()"
    ILockManager public lockManager;

    // ---------- EVENTS ----------

    /// @notice Emitted when lock manager changes
    /// @param previousLockManager Previous lock manager address
    /// @param newLockManager New lock manager address
    event LockManagerTransfer(address indexed previousLockManager, address indexed newLockManager);

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    /// @param mk1Solarbots Address of Mk.1 Solarbots contract
    /// @param timestampMintStart Unix timestamp of mint start
    /// @param timestampMintEnd Unix timestamp of mint end
    /// @param _lockManager Address of lock manager contract
    constructor(
        address owner,
        address mk1Solarbots,
        uint256 timestampMintStart,
        uint256 timestampMintEnd,
        address _lockManager
    ) ERC721("Solarbots Christmas 2022", "SBXMAS2022") {
        _transferOwnership(owner);
        MK1_SOLARBOTS = IERC721(mk1Solarbots);
        TIMESTAMP_MINT_START = timestampMintStart;
        TIMESTAMP_MINT_END = timestampMintEnd;
        lockManager = ILockManager(_lockManager);
    }

    // ---------- METADATA ----------

    /// @notice Token URI
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(bytes(tokenURIBase).length > 0, ERROR_NO_METADATA);
        return string(abi.encodePacked(tokenURIBase, Strings.toString(id), tokenURISuffix));
    }

    /// @notice Set token URI base
    /// @param _tokenURIBase New token URI base
    function setTokenURIBase(string calldata _tokenURIBase) external onlyOwner {
        tokenURIBase = _tokenURIBase;
    }

    /// @notice Set token URI suffix
    /// @param _tokenURISuffix New token URI suffix
    function setTokenURISuffix(string calldata _tokenURISuffix) external onlyOwner {
        tokenURISuffix = _tokenURISuffix;
    }

    // ---------- LOCK MANAGER ----------

    /// @notice Set lock manager
    /// @param _lockManager New lock manager address
    /// @dev Emits LockManagerTransfer event
    function setLockManager(address _lockManager) external onlyOwner {
        emit LockManagerTransfer(address(lockManager), _lockManager);
        lockManager = ILockManager(_lockManager);
    }

    // ---------- TRANSFER ----------

    /// @notice Transfer token from current owner to recipient
    /// @param from Token owner address
    /// @param to Token recipient address
    /// @param id Token ID
    /// @dev Emits Transfer event
    function transferFrom(address from, address to, uint256 id) public override {
        require(!lockManager.isLocked(address(this), msg.sender, from, to, id), ERROR_TOKEN_LOCKED);

        super.transferFrom(from, to, id);
    }

    // ---------- MINT ----------

    /// @notice Mint one token to message sender
    function mint() external {
        require(block.timestamp >= TIMESTAMP_MINT_START, ERROR_MINT_NOT_STARTED);
        require(block.timestamp < TIMESTAMP_MINT_END, ERROR_MINT_ENDED);

        // Minting is only enabled for owners of 4 Mk.1 Solarbots (1 full team) or more
        require(MK1_SOLARBOTS.balanceOf(msg.sender) > 3, ERROR_MINT_REQUIRES_4_MK1);

        // Only accounts that don't already own a token can mint
        require(balanceOf(msg.sender) == 0, ERROR_ALREADY_MINTED);

        uint256 id = totalSupply;

        // The internal `_safeMint` function contains unnecessary checks,
        // so we use a slightly modified inline version here.

        // Counter overflow is incredibly unrealistic
        unchecked {
            _balanceOf[msg.sender]++;
            totalSupply++;
        }

        _ownerOf[id] = msg.sender;

        emit Transfer(address(0), msg.sender, id);

        if (msg.sender.code.length != 0) {
            require(
                ERC721TokenReceiver(msg.sender).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        }
    }

    // ---------- BURN ----------

    /// @notice Burn token
    /// @param id Token ID
    function burn(uint256 id) external {
        // Only allow burning after minting has ended in order to prevent messing with the token ID sequence.
        // The token ID used in the mint function is based on the current total supply, but the burn function
        // needs to decrement the total supply. Allowing burning before minting has ended would require more code
        // to keep track of the next token ID, because it would no longer be equal to the current total supply.
        // This is not worth the effort, because burning will be rare, especially before minting has ended.
        require(block.timestamp >= TIMESTAMP_MINT_END, ERROR_BURN_BEFORE_MINT_ENDED);

        require(!lockManager.isLocked(address(this), msg.sender, msg.sender, address(0), id), ERROR_TOKEN_LOCKED);

        // The internal `_burn` function does not include the `owner == msg.sender` check,
        // so we use a slightly modified inline version here.

        address owner = _ownerOf[id];
        require(owner == msg.sender, ERROR_NOT_TOKEN_OWNER);

        // Ownership check above ensures no underflow
        unchecked {
            _balanceOf[owner]--;
            totalSupply--;
        }

        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}