// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

import "./ERC1155B.sol";
import "./ILockManager.sol";
import "./ITickets.sol";

/// @title Solarbots Player Housing
/// @author Solarbots (https://solarbots.io)
contract PlayerHousing is ERC1155B, Ownable {
    // ---------- CONSTANTS ----------

    /// @notice Maximum amount of tokens that can be minted per faction
    /// Arboria tokens use IDs 0-5999, Illskagaard tokens use IDs 6000-11999,
    /// and Lacrean Empire tokens use IDs 12000-17999 for a total of 18000 tokens
    uint256 public constant MAX_SUPPLY_PER_FACTION = 6000;

    /// @notice Illskagaard tokens use IDs 6000-11999
    uint256 public constant ID_OFFSET_ILLSKAGAARD = 6000;

    /// @notice Lacrean Empire tokens use IDs 12000-17999
    uint256 public constant ID_OFFSET_LACREAN = 12000;

    /// @notice Maximum amount of tokens that can be minted per transaction
    uint256 public constant MAX_MINT_AMOUNT_PER_TX = 5;

    /// @notice Price to mint one token
    uint256 public constant MINT_PRICE = 0.1 ether;

    /// @notice Token ID of whitelist ticket in tickets contract
    uint256 public constant WHITELIST_TICKET_ID = 0;

    /// @notice FOA rewards emitted per second per token
    /// @dev 600_000_000e18 / 18_000 / 10 / 365 / 24 / 60 / 60
    uint256 public constant REWARDS_PER_SECOND = 105699306612548;

    string public constant ERROR_NO_CONTRACT_MINTING = "PlayerHousing: No contract minting";
    string public constant ERROR_NO_METADATA = "PlayerHousing: No metadata";
    string public constant ERROR_NOT_APPROVED_FOR_REWARDS = "PlayerHousing: Not approved for rewards";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA = "PlayerHousing: Arboria over max amount per tx";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD = "PlayerHousing: Illskagaard over max amount per tx";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN = "PlayerHousing: Lacrean Empire over max amount per tx";
    string public constant ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL = "PlayerHousing: Total over max amount per tx";
    string public constant ERROR_REACHED_MAX_SUPPLY_ARBORIA = "PlayerHousing: Reached max Arboria supply";
    string public constant ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD = "PlayerHousing: Reached max Illskagaard supply";
    string public constant ERROR_REACHED_MAX_SUPPLY_LACREAN = "PlayerHousing: Reached max Lacrean Empire supply";
    string public constant ERROR_SALE_NOT_READY_WHITELIST = "PlayerHousing: Whitelist sale not ready";
    string public constant ERROR_SALE_NOT_READY_PUBLIC = "PlayerHousing: Public sale not ready";
    string public constant ERROR_TOKEN_LOCKED = "PlayerHousing: Token locked";
    string public constant ERROR_TOTAL_AMOUNT_BELOW_TWO = "PlayerHousing: Total amount below 2";
    string public constant ERROR_WRONG_PRICE = "PlayerHousing: Wrong price";

    /// @notice End of FOA rewards emittance
    uint256 public immutable TIMESTAMP_REWARDS_END;

    /// @notice Start of whitelist sale
    uint256 public immutable TIMESTAMP_SALE_WHITELIST;

    /// @notice Start of public sale
    uint256 public immutable TIMESTAMP_SALE_PUBLIC;

    /// @notice Tickets contract
    /// @custom:security non-reentrant
    ITickets public immutable TICKETS;

    uint256 private constant _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD = 16;
    uint256 private constant _BITSHIFT_TOTAL_SUPPLY_LACREAN = 32;

    uint256 private constant _BITSHIFT_REWARDS_LAST_UPDATED = 16;
    uint256 private constant _BITSHIFT_REWARDS_BALANCE = 48;

    uint256 private constant _BITMASK_TOTAL_SUPPLY = type(uint16).max;
    uint256 private constant _BITMASK_TOTAL_SUPPLY_ARBORIA = ~_BITMASK_TOTAL_SUPPLY;
    uint256 private constant _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD = ~(_BITMASK_TOTAL_SUPPLY << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD);
    uint256 private constant _BITMASK_TOTAL_SUPPLY_LACREAN = ~(_BITMASK_TOTAL_SUPPLY << _BITSHIFT_TOTAL_SUPPLY_LACREAN);

    uint256 private constant _BITMASK_REWARDS_TOKEN_BALANCE = type(uint16).max;
    uint256 private constant _BITMASK_REWARDS_LAST_UPDATED = type(uint32).max;

    // ---------- STATE ----------

    /// @notice Contains rewards balance, token balance, and timestamp of last rewards update for each token owner
    /// @dev Bit Layout:
    /// [0-15] Token balance - `tokenBalance`
    /// [16-47] Timestamp of last rewards update - `lastUpdated`
    /// [48-255] Rewards balance - `rewardsBalance`
    mapping(address => uint256) public rewardsBitField;

    /// @notice Approved addresses have write access to `rewardsBitField`
    /// @custom:security write-protection="onlyOwner()"
    mapping(address => bool) public isApprovedForRewards;

    /// @notice Lock manager contract
    /// @custom:security non-reentrant
    /// @custom:security write-protection="onlyOwner()"
    ILockManager public lockManager;

    /// @notice Metadata base URI
    /// @custom:security write-protection="onlyOwner()"
    string public baseURI;

    /// @notice Metadata URI suffix
    /// @custom:security write-protection="onlyOwner()"
    string public uriSuffix;

    /// @notice Contains total supply of each faction
    /// @dev Bit Layout:
    /// [0-15] Total supply of Arboria tokens - `totalSupplyArboria`
    /// [16-31] Total supply of Illskagard tokens - `totalSupplyIllskagard`
    /// [32-47] Total supply of Lacrean Empire tokens - `totalSupplyLacrean`
    uint256 private _totalSupplyBitField;

    // ---------- EVENTS ----------

    event ApprovalForRewards(address indexed operator, bool approved);

    event LockManagerTransfer(address indexed previousLockManager, address indexed newLockManager);

    // ---------- CONSTRUCTOR ----------

    /// @param owner Contract owner
    /// @param timestampSaleWhitelist Start of whitelist sale
    /// @param timestampSalePublic Start of public sale
    /// @param timestampRewardsEnd End of FOA rewards emittance
    /// @param tickets Address of tickets contract
    /// @param _lockManager Address of lock manager contract
    // slither-disable-next-line protected-vars
    constructor(
        address owner,
        uint256 timestampSaleWhitelist,
        uint256 timestampSalePublic,
        uint256 timestampRewardsEnd,
        address tickets,
        address _lockManager
    ) {
        _transferOwnership(owner);
        TIMESTAMP_SALE_WHITELIST = timestampSaleWhitelist;
        TIMESTAMP_SALE_PUBLIC = timestampSalePublic;
        TIMESTAMP_REWARDS_END = timestampRewardsEnd;
        TICKETS = ITickets(tickets);
        lockManager = ILockManager(_lockManager);
    }

    // ---------- METADATA ----------

    /// @notice Get metadata URI
    /// @param id Token ID
    /// @return Metadata URI of token ID `id`
    function uri(uint256 id) public view override returns (string memory) {
        require(bytes(baseURI).length > 0, ERROR_NO_METADATA);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        return string(abi.encodePacked(baseURI, Strings.toString(id), uriSuffix));
    }

    /// @notice Set metadata base URI
    /// @param _baseURI New metadata base URI
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Set metadata URI suffix
    /// @param _uriSuffix New metadata URI suffix
    /// @dev Doesn't emit URI event, because `id` argument isn't used
    function setURISuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // ---------- TOTAL SUPPLY ----------

    function totalSupplyArboria() public view returns (uint256) {
        return _totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
    }

    function totalSupplyIllskagaard() public view returns (uint256) {
        return _totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
    }

    function totalSupplyLacrean() public view returns (uint256) {
        return _totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupplyArboria() + totalSupplyIllskagaard() + totalSupplyLacrean();
    }

    // ---------- LOCK MANAGER ----------

    function setLockManager(address _lockManager) external onlyOwner {
        emit LockManagerTransfer(address(lockManager), _lockManager);
        lockManager = ILockManager(_lockManager);
    }

    // ---------- REWARDS ----------

    function setApprovalForRewards(address operator, bool approved) external onlyOwner {
        isApprovedForRewards[operator] = approved;
        emit ApprovalForRewards(operator, approved);
    }

    function setRewardsBitField(address owner, uint256 _rewardsBitField) external {
        require(isApprovedForRewards[msg.sender], ERROR_NOT_APPROVED_FOR_REWARDS);
        rewardsBitField[owner] = _rewardsBitField;
    }

    /// @notice Returns the token balance of the given address
    /// @param owner Address to check
    function balanceOf(address owner) public view returns (uint256) {
        return rewardsBitField[owner] & _BITMASK_REWARDS_TOKEN_BALANCE;
    }

    /// @notice Returns the FOA rewards balance of the given address
    /// @param owner Address to check
    function rewardsOf(address owner) external view returns (uint256 rewardsBalance) {
        rewardsBalance = rewardsBitField[owner] >> _BITSHIFT_REWARDS_BALANCE;
        uint256 lastUpdated = rewardsBitField[owner] >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            // Use current block timestamp or rewards end timestamp if reached
            uint256 timestamp = block.timestamp < TIMESTAMP_REWARDS_END ? block.timestamp : TIMESTAMP_REWARDS_END;
            uint256 tokenBalance = balanceOf(owner);

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
            }
        }
    }

    function _updateRewardsForTransfer(address from, address to, uint256 tokenAmount) internal {
        // Use current block timestamp or rewards end timestamp if reached
        uint256 timestamp = block.timestamp < TIMESTAMP_REWARDS_END ? block.timestamp : TIMESTAMP_REWARDS_END;

        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[from];
        uint256 lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        // Update rewards bit field of `from`, unless it has already been updated since the reward emittence ended
        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
            uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                // Update rewards bit field of `from` with new token balance, last updated timestamp, and rewards balance
                rewardsBitField[from] = tokenBalance - tokenAmount | timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
            }
        }

        // Store bit field in memory to reduce number of SLOADs
        _rewardsBitField = rewardsBitField[to];
        lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;

        // Update rewards bit field of `to`, unless it has already been updated since the reward emittence ended
        if (lastUpdated != TIMESTAMP_REWARDS_END) {
            uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
            uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

            // Calculate rewards collected since last update and add them to balance
            if (lastUpdated > 0) {
                uint256 secondsSinceLastUpdate = timestamp - lastUpdated;
                unchecked {
                    rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
                }
            }

            unchecked {
                // Update rewards bit field of `to` with new token balance, last updated timestamp, and rewards balance
                rewardsBitField[to] = tokenBalance + tokenAmount | timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
            }
        }
    }

    function _updateRewardsForMint(address to, uint256 tokenAmount) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 _rewardsBitField = rewardsBitField[to];
        uint256 tokenBalance = _rewardsBitField & _BITMASK_REWARDS_TOKEN_BALANCE;
        uint256 lastUpdated = _rewardsBitField >> _BITSHIFT_REWARDS_LAST_UPDATED & _BITMASK_REWARDS_LAST_UPDATED;
        uint256 rewardsBalance = _rewardsBitField >> _BITSHIFT_REWARDS_BALANCE;

        // Calculate rewards collected since last update and add them to balance
        if (lastUpdated > 0) {
            uint256 secondsSinceLastUpdate = block.timestamp - lastUpdated;
            unchecked {
                rewardsBalance += secondsSinceLastUpdate * REWARDS_PER_SECOND * tokenBalance;
            }
        }

        unchecked {
            // Update rewards bit field of `to` with new token balance, last updated timestamp, and rewards balance
            rewardsBitField[to] = tokenBalance + tokenAmount | block.timestamp << _BITSHIFT_REWARDS_LAST_UPDATED | rewardsBalance << _BITSHIFT_REWARDS_BALANCE;
        }
    }

    // ---------- TRANSFER ----------

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(id < MAX_SUPPLY, ERROR_INVALID_ID);
        require(amount == 1, ERROR_INVALID_AMOUNT);
        require(!lockManager.isLocked(address(this), msg.sender, from, to, id), ERROR_TOKEN_LOCKED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Load address stored in `ownerOf[id]`
            let ownerOfId := sload(ownerOfIdSlot)
            // Make sure we're only using the first 160 bits of the storage slot
            // as the remaining 96 bits might not be zero
            ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

            // Revert with message "ERC1155B: From not token owner" if `ownerOf[id]` is not `from`
            if xor(ownerOfId, from) {
                // Load free memory position
                let freeMemory := mload(0x40)
                // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                // Store data offset
                mstore(add(freeMemory, 0x04), 0x20)
                // Store length of revert message
                mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_TOKEN_OWNER)
                // Store revert message
                mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_TOKEN_OWNER)
                revert(freeMemory, 0x64)
            }

            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        _updateRewardsForTransfer(from, to, amount);
        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(ids.length == amounts.length, ERROR_ARRAY_LENGTH_MISMATCH);
        require(msg.sender == from || isApprovedForAll[from][msg.sender], ERROR_NOT_AUTHORIZED);
        require(!lockManager.isLocked(address(this), msg.sender, from, to, ids), ERROR_TOKEN_LOCKED);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate length of arrays `ids` and `amounts` in bytes
            let arrayLength := mul(ids.length, 0x20)

            // Loop over all values in `ids` and `amounts` by starting
            // with an index offset of 0 to access the first array element
            // and incrementing this index by 32 after each iteration to
            // access the next array element until the offset reaches the end
            // of the arrays, at which point all values the arrays contain
            // have been accessed
            for
                { let indexOffset := 0x00 }
                lt(indexOffset, arrayLength)
                { indexOffset := add(indexOffset, 0x20) }
            {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                let id := calldataload(add(ids.offset, indexOffset))

                // Revert with message "ERC1155B: Invalid ID" if `id` is higher than `MAX_ID`
                if gt(id, MAX_ID) {
                    // Load free memory position
                    // slither-disable-next-line variable-scope
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_ID)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_ID)
                    revert(freeMemory, 0x64)
                }

                // Revert with message "ERC1155B: Invalid amount" if amount is not 1
                if xor(calldataload(add(amounts.offset, indexOffset)), 1) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_INVALID_AMOUNT)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_INVALID_AMOUNT)
                    revert(freeMemory, 0x64)
                }

                // Calculate storage slot of `ownerOf[id]`
                let ownerOfIdSlot := add(ownerOf.slot, id)
                // Load address stored in `ownerOf[id]`
                let ownerOfId := sload(ownerOfIdSlot)
                // Make sure we're only using the first 160 bits of the storage slot
                // as the remaining 96 bits might not be zero
                ownerOfId := and(ownerOfId, _BITMASK_ADDRESS)

                // Revert with message "ERC1155B: From not token owner" if `ownerOf[id]` is not `from`
                if xor(ownerOfId, from) {
                    // Load free memory position
                    let freeMemory := mload(0x40)
                    // Store "Error(string)" signature: bytes32(bytes4(keccak256("Error(string)")))
                    mstore(freeMemory, _ERROR_FUNCTION_SIGNATURE)
                    // Store data offset
                    mstore(add(freeMemory, 0x04), 0x20)
                    // Store length of revert message
                    mstore(add(freeMemory, 0x24), _ERROR_LENGTH_FROM_NOT_TOKEN_OWNER)
                    // Store revert message
                    mstore(add(freeMemory, 0x44), _ERROR_ENCODED_FROM_NOT_TOKEN_OWNER)
                    revert(freeMemory, 0x64)
                }

                // Store address of `to` in `ownerOf[id]`
                sstore(ownerOfIdSlot, to)
            }
        }

        _updateRewardsForTransfer(from, to, ids.length);
        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                ERROR_UNSAFE_RECIPIENT
            );
        } else require(to != address(0), ERROR_INVALID_RECIPIENT);
    }

    // ---------- WHITELIST SALE ----------

    /// @notice Mint a single Arboria token during whitelist sale
    function mintWhitelistArboria() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintArboria(msg.sender);
    }

    /// @notice Mint a single Illskagaard token during whitelist sale
    function mintWhitelistIllskagaard() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintIllskagaard(msg.sender);
    }

    /// @notice Mint a single Lacrean Empire token during whitelist sale
    function mintWhitelistLacrean() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);

        // Burn whitelist ticket
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, 1);

        _mintLacrean(msg.sender);
    }

    /// @notice Batch mint specified amount of tokens during whitelist sale
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    function batchMintWhitelist(uint256 amountArboria, uint256 amountIllskagaard, uint256 amountLacrean) external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_WHITELIST, ERROR_SALE_NOT_READY_WHITELIST);

        // Doing these checks and later calculating the total amount unchecked costs less gas
        // than not doing these checks and calculating the total amount checked
        require(amountArboria <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA);
        require(amountIllskagaard <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD);
        require(amountLacrean <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN);

        uint256 amountTotal;
        unchecked {
            amountTotal = amountArboria + amountIllskagaard + amountLacrean;
        }
        require(amountTotal <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL);
        require(amountTotal > 1, ERROR_TOTAL_AMOUNT_BELOW_TWO);
        unchecked {
            require(msg.value == amountTotal * MINT_PRICE, ERROR_WRONG_PRICE);
        }

        // Burn whitelist tickets
        TICKETS.burn(msg.sender, WHITELIST_TICKET_ID, amountTotal);

        _batchMint(msg.sender, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
    }

    // ---------- PUBLIC SALE ----------

    /// @notice Mint a single Arboria token during public sale
    function mintPublicArboria() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintArboria(msg.sender);
    }

    /// @notice Mint a single Illskagaard token during public sale
    function mintPublicIllskagaard() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintIllskagaard(msg.sender);
    }

    /// @notice Mint a single Lacrean Empire token during public sale
    function mintPublicLacrean() external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);
        require(msg.value == MINT_PRICE, ERROR_WRONG_PRICE);
        _mintLacrean(msg.sender);
    }

    /// @notice Batch mint specified amount of tokens during public sale
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    function batchMintPublic(uint256 amountArboria, uint256 amountIllskagaard, uint256 amountLacrean) external payable {
        require(msg.sender == tx.origin, ERROR_NO_CONTRACT_MINTING);
        require(block.timestamp >= TIMESTAMP_SALE_PUBLIC, ERROR_SALE_NOT_READY_PUBLIC);

        // Doing these checks and later calculating the total amount unchecked costs less gas
        // than not doing these checks and calculating the total amount checked
        require(amountArboria <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ARBORIA);
        require(amountIllskagaard <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_ILLSKAGAARD);
        require(amountLacrean <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_LACREAN);

        uint256 amountTotal;
        unchecked {
            amountTotal = amountArboria + amountIllskagaard + amountLacrean;
        }
        require(amountTotal <= MAX_MINT_AMOUNT_PER_TX, ERROR_OVER_MAX_AMOUNT_PER_TX_TOTAL);
        require(amountTotal > 1, ERROR_TOTAL_AMOUNT_BELOW_TWO);
        unchecked {
            require(msg.value == amountTotal * MINT_PRICE, ERROR_WRONG_PRICE);
        }

        _batchMint(msg.sender, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
    }

    // ---------- MINT ----------

    /// @notice Mint a single Lacrean Empire token as contract owner
    /// @param to Receiver of minted token
    function mintOwnerLacrean(address to) external onlyOwner {
        _mintLacrean(to);
    }

    /// @notice Batch mint as contract owner
    /// @param tos Receivers of minted tokens
    /// @param amountsArboria Amounts of Arboria tokens to mint
    /// @param amountsIllskagaard Amounts of Illskagaard tokens to mint
    /// @param amountsLacrean Amounts of Lacrean tokens to mint
    function batchMintOwner(
        address[] calldata tos,
        uint256[] calldata amountsArboria,
        uint256[] calldata amountsIllskagaard,
        uint256[] calldata amountsLacrean
    ) external onlyOwner {
        require(
            tos.length == amountsArboria.length &&
            amountsArboria.length == amountsIllskagaard.length &&
            amountsIllskagaard.length == amountsLacrean.length,
            ERROR_ARRAY_LENGTH_MISMATCH
        );

        // Calculate array length in bytes
        uint256 arrayLength;
        unchecked {
            arrayLength = tos.length * 0x20;
        }

        for (uint256 indexOffset = 0x00; indexOffset < arrayLength;) {
            address to;
            uint256 amountArboria;
            uint256 amountIllskagaard;
            uint256 amountLacrean;

            /// @solidity memory-safe-assembly
            assembly {
                // Load current array elements by adding offset of current
                // array index to start of each array's data area inside calldata
                to := calldataload(add(tos.offset, indexOffset))
                amountArboria := calldataload(add(amountsArboria.offset, indexOffset))
                amountIllskagaard := calldataload(add(amountsIllskagaard.offset, indexOffset))
                amountLacrean := calldataload(add(amountsLacrean.offset, indexOffset))

                // Increment index offset by 32 for next iteration
                indexOffset := add(indexOffset, 0x20)
            }

            unchecked {
                uint256 amountTotal = amountArboria + amountIllskagaard + amountLacrean;
                _batchMint(to, amountArboria, amountIllskagaard, amountLacrean, amountTotal);
            }
        }
    }

    /// @dev Mint a single Arboria token
    /// @param to Receiver of minted token
    function _mintArboria(address to) internal {
        // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
        uint256 id = _totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
        require(id < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ARBORIA);

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Incrementing the whole bit field increments just the total supply of
            // Arboria tokens, because only the value stored in the first bits gets updated
            _totalSupplyBitField++;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @dev Mint a single Illskagaard token
    /// @param to Receiver of minted token
    function _mintIllskagaard(address to) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
        uint256 _totalSupplyIllskagaard = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
        require(_totalSupplyIllskagaard < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD);

        uint256 id;
        unchecked {
            // Illskagaard token IDs start at 6000
            id = ID_OFFSET_ILLSKAGAARD + _totalSupplyIllskagaard;
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Second 16 bits need to be all set to 0 before the new total supply of
            // Illskagaard tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD | ++_totalSupplyIllskagaard << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @dev Mint a single Lacrean Empire token
    /// @param to Receiver of minted token
    function _mintLacrean(address to) internal {
        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
        uint256 _totalSupplyLacrean = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        require(_totalSupplyLacrean < MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_LACREAN);

        uint256 id;
        unchecked {
            // Lacrean Empire token IDs start at 12000
            id = ID_OFFSET_LACREAN + _totalSupplyLacrean;
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Calculate storage slot of `ownerOf[id]`
            let ownerOfIdSlot := add(ownerOf.slot, id)
            // Store address of `to` in `ownerOf[id]`
            sstore(ownerOfIdSlot, to)
        }

        unchecked {
            // Third 16 bits need to be all set to 0 before the new total supply of
            // Lacrean Empire tokens can be stored
            _totalSupplyBitField = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY_LACREAN | ++_totalSupplyLacrean << _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        }

        _updateRewardsForMint(to, 1);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    /// @notice Batch mint specified amount of tokens
    /// @param to Receiver of minted tokens
    /// @param amountArboria Amount of Arboria tokens to mint
    /// @param amountIllskagaard Amount of Illskagaard tokens to mint
    /// @param amountLacrean Amount of Lacrean tokens to mint
    /// @param amountTotal Total amount of tokens to mint
    function _batchMint(
        address to,
        uint256 amountArboria,
        uint256 amountIllskagaard,
        uint256 amountLacrean,
        uint256 amountTotal
    ) internal {
        // Token IDs and amounts are collected in arrays to later emit the TransferBatch event
        uint256[] memory ids = new uint256[](amountTotal);
        // Token amounts are all 1
        uint256[] memory amounts = new uint256[](amountTotal);

        // Keep track of the current index offsets for each array
        uint256 offsetIds;
        uint256 offsetAmounts;

        /// @solidity memory-safe-assembly
        assembly {
            // Skip the first 32 bytes containing the array length
            offsetIds := add(ids, 0x20)
            offsetAmounts := add(amounts, 0x20)
        }

        // Store bit field in memory to reduce number of SLOADs
        uint256 totalSupplyBitField = _totalSupplyBitField;
        // New bit field gets updated in memory to reduce number of SSTOREs
        // _totalSupplyBitField is only updated once after all tokens are minted
        uint256 newTotalSupplyBitField = totalSupplyBitField;

        if (amountArboria > 0) {
            // Total supply of Arboria tokens is stored in the first 16 bits of the bit field
            uint256 _totalSupplyArboria = totalSupplyBitField & _BITMASK_TOTAL_SUPPLY;
            uint256 newTotalSupplyArboria;
            unchecked {
                newTotalSupplyArboria = _totalSupplyArboria + amountArboria;
            }
            require(newTotalSupplyArboria <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ARBORIA);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Arboria token IDs
                for { let id := _totalSupplyArboria } lt(id, newTotalSupplyArboria) { id := add(id, 1) } {
                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // First 16 bits need to be all set to 0 before the new total supply of Arboria tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ARBORIA | newTotalSupplyArboria;
        }

        if (amountIllskagaard > 0) {
            // Total supply of Illskagaard tokens is stored in the second 16 bits of the bit field
            uint256 _totalSupplyIllskagaard = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD & _BITMASK_TOTAL_SUPPLY;
            uint256 newTotalSupplyIllskagaard;
            unchecked {
                newTotalSupplyIllskagaard = _totalSupplyIllskagaard + amountIllskagaard;
            }
            require(newTotalSupplyIllskagaard <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_ILLSKAGAARD);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Illskagaard token IDs
                for { let i := _totalSupplyIllskagaard } lt(i, newTotalSupplyIllskagaard) { i := add(i, 1) } {
                    // Illskagaard token IDs start at 6000
                    let id := add(ID_OFFSET_ILLSKAGAARD, i)

                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // Second 16 bits need to be all set to 0 before the new total supply of Illskagaard tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_ILLSKAGAARD | newTotalSupplyIllskagaard << _BITSHIFT_TOTAL_SUPPLY_ILLSKAGAARD;
        }

        if (amountLacrean > 0) {
            // Total supply of Lacrean Empire tokens is stored in the third 16 bits of the bit field
            uint256 _totalSupplyLacrean = totalSupplyBitField >> _BITSHIFT_TOTAL_SUPPLY_LACREAN;
            uint256 newTotalSupplyLacrean;
            unchecked {
                newTotalSupplyLacrean = _totalSupplyLacrean + amountLacrean;
            }
            require(newTotalSupplyLacrean <= MAX_SUPPLY_PER_FACTION, ERROR_REACHED_MAX_SUPPLY_LACREAN);

            /// @solidity memory-safe-assembly
            assembly {
                // Set owner of Lacrean Empire token IDs
                for { let i := _totalSupplyLacrean } lt(i, newTotalSupplyLacrean) { i := add(i, 1) } {
                    // Lacrean Empire token IDs start at 12000
                    let id := add(ID_OFFSET_LACREAN, i)

                    // Calculate storage slot of `ownerOf[id]`
                    let ownerOfIdSlot := add(ownerOf.slot, id)
                    // Store address of `to` in `ownerOf[id]`
                    sstore(ownerOfIdSlot, to)

                    // Store id and amount in the corresponding memory arrays
                    mstore(offsetIds, id)
                    mstore(offsetAmounts, 1)

                    // Increment index offsets by 32 for next iteration
                    offsetIds := add(offsetIds, 0x20)
                    offsetAmounts := add(offsetAmounts, 0x20)
                }
            }

            // Third 16 bits need to be all set to 0 before the new total supply of Lacrean Empire tokens can be stored
            newTotalSupplyBitField = newTotalSupplyBitField & _BITMASK_TOTAL_SUPPLY_LACREAN | newTotalSupplyLacrean << _BITSHIFT_TOTAL_SUPPLY_LACREAN;
        }

        // slither-disable-next-line costly-loop
        _totalSupplyBitField = newTotalSupplyBitField;
        _updateRewardsForMint(to, amountTotal);
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    // ---------- OWNERS ----------

    function owners() external view returns (address[MAX_SUPPLY] memory) {
        return ownerOf;
    }

    // ---------- WITHDRAW ----------

    /// @notice Withdraw all Ether stored in this contract to address of contract owner
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}