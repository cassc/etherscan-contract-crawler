// SPDX-License-Identifier: MIT
// Author: Philipp Adrian (ph101pp.eth)

pragma solidity ^0.8.0;

import "./ERC1155_.sol";
import "hardhat/console.sol";

// Extension of ERC1155 enables lazy minting of Range 
// with dynamic initial balance 
// also adds tracking of total supply per id.
abstract contract ERC1155MintRange is ERC1155_ {
    struct MintRangeInput {
        uint[] ids;
        uint[][] amounts;
    }

    // Mapping from token ID to balancesInitialzed flag
    mapping(address => mapping(uint => bool)) public isBalanceInitialized;

    // Mapping from token ID to totalSupplyDelta
    mapping(uint => int256) private _totalSupplyDelta;

    // Mapping to keep track of tokens minted via ERC1155._mint() or  ERC1155._mintBatch()
    mapping(uint => bool) public isManualMint;
    // used to check validity of mintRangeInput
    uint private _manualMintsCount;

    // Track initial holders across tokenID ranges + lookup mapping;
    address[][] internal _initialHolders;
    uint[] internal _initialHolderRanges;
    mapping(address => bool) public isInitialHolderAddress;
    mapping(address => bool) public isHolderAddress;

    // last tokenId minted via mintRange.
    uint public lastRangeTokenIdMinted;
    bool public isZeroMinted;

    constructor(address[] memory initialInitialHolders) {
        _initialHolderRanges.push(0);
        _initialHolders.push(initialInitialHolders);
        for (uint i = 0; i < initialInitialHolders.length; i++) {
            isInitialHolderAddress[initialInitialHolders[i]] = true;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Token Balances & Total Supply
    ///////////////////////////////////////////////////////////////////////////////

    // Implement: Return initial token balance for address.
    // This function MUST be pure: Always return the same values for a given input.
    function initialBalanceOf(
        address account,
        uint tokenId
    ) internal view virtual returns (uint);

    // Returns current token balance of account
    // calculates and returns initial dynamic balance 
    // if minted via _mintRange and not yet initialized.
    function balanceOf(
        address account,
        uint id
    ) public view virtual override returns (uint) {
        require(account != address(0), "ERC1155: not a valid owner");

        if (
            _maybeInitialHolder(account) &&
            !isBalanceInitialized[account][id] &&
            !isManualMint[id] &&
            _inRange(id)
        ) {
            return initialBalanceOf(account, id);
        }

        return _balances[id][account];
    }

    // Returns total amount of tokens of a given id.
    function totalSupply(uint tokenId) public view virtual returns (uint) {
        // Pre initialization
        if (_inRange(tokenId) && !isManualMint[tokenId]) {
            uint initialTotalSupplySum = 0;
            address[] memory initialHolderAddresses = initialHolders(tokenId);
            for (uint i = 0; i < initialHolderAddresses.length; i++) {
                initialTotalSupplySum += initialBalanceOf(
                    initialHolderAddresses[i],
                    tokenId
                );
            }
            return
                uint(
                    int256(initialTotalSupplySum) + _totalSupplyDelta[tokenId]
                );
        }

        // manually minted
        return uint(_totalSupplyDelta[tokenId]);
    }

    // - Tracks total supply per token
    // - Tracks manual mints (_mint | _mintBatch)
    // - Initializes dynamic initial balances 
    // before any transfer.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // for each token transferred:
        for (uint i = 0; i < ids.length; ++i) {
            uint id = ids[i];

            // when minting
            if (from == address(0)) {
                // set isManualMint flag if id doesnt exist -> minted via _mint||_mintBatch
                if (!exists(id)) {
                    isManualMint[id] = true;
                    _manualMintsCount++;
                }
                // track supply
                _totalSupplyDelta[id] += int256(amounts[i]);
            }
            // when burning
            if (to == address(0)) {
                // track supply 
                _totalSupplyDelta[id] -= int256(amounts[i]);
            }
            // initialize balances if minted via _mintRange
            _maybeInitializeBalance(from, id);
            _maybeInitializeBalance(to, id);
        }
        if (!isHolderAddress[to]) {
            isHolderAddress[to] = true;
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Writes dynamic initial Balance to state if initial holder is uninitialized.
    function _maybeInitializeBalance(address account, uint id) internal {
        if (
            _maybeInitialHolder(account) &&
            account != address(0) &&
            !isBalanceInitialized[account][id] &&
            !isManualMint[id] &&
            _inRange(id)
        ) {
            uint balance = initialBalanceOf(account, id);
            if (balance > 0) {
                _balances[id][account] = _balances[id][account] + balance;
            }
            isBalanceInitialized[account][id] = true;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Intitial Holders
    ///////////////////////////////////////////////////////////////////////////////

    // Set initial holders. mintRange() will distribute tokens to these holders
    function _setInitialHolders(address[] memory addresses) internal virtual {
        uint256 firstId = isZeroMinted ? lastRangeTokenIdMinted + 1 : 0;
        uint256 lastIndex = _initialHolders.length - 1;
        uint256 lastId = _initialHolderRanges[lastIndex];
        for (uint i = 0; i < addresses.length; i++) {
            address initialHolder = addresses[i];
            require(
                !isHolderAddress[initialHolder] ||
                    isInitialHolderAddress[initialHolder],
                "M:01"
            );
            require(initialHolder != address(0), "M:02");
            for (uint j = i + 1; j < addresses.length; j++) {
                require(initialHolder != addresses[j], "M:03");
            }
            isInitialHolderAddress[initialHolder] = true;
        }
        if (lastId == firstId) {
            _initialHolders[lastIndex] = addresses;
        } else {
            _initialHolderRanges.push(firstId);
            _initialHolders.push(addresses);
        }
    }

    // Returns initial holders of a token.
    function initialHolders(
        uint tokenId
    ) public view virtual returns (address[] memory) {
        // optimization for mintRange
        uint lastIndex = _initialHolderRanges.length - 1;
        if (_initialHolderRanges[lastIndex] <= tokenId) {
            return _initialHolders[lastIndex];
        }
        uint index = _findLowerBound(_initialHolderRanges, tokenId);
        return _initialHolders[index];
    }

    // Return current initial holders Range
    function initialHolderRanges()
        public
        view
        virtual
        returns (address[][] memory holders, uint[] memory ranges)
    {
        return (_initialHolders, _initialHolderRanges);
    }

    // Returns true if address is an initial holder of tokenId
    function _maybeInitialHolder(address account) internal view returns (bool) {
        return isInitialHolderAddress[account];
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Mint Range
    ///////////////////////////////////////////////////////////////////////////////

    // Implement: May be overwritten to add custom values to checksum test.
    // function _customMintRangeChecksum()
    //     internal
    //     view
    //     virtual
    //     returns (bytes32)
    // {
    //     return 0x00;
    // }

    // Generate mintRange inputs for x new tokens.
    function getMintRangeInput(
        uint numberOfTokens
    ) public view returns (MintRangeInput memory, bytes32) {
        uint firstId = isZeroMinted ? lastRangeTokenIdMinted + 1 : 0;
        address[] memory holders = initialHolders(firstId);
        uint[] memory ids = new uint[](numberOfTokens);
        uint[][] memory amounts = new uint[][](holders.length);

        uint newIndex = 0;
        for (uint i = 0; newIndex < numberOfTokens; i++) {
            uint newId = firstId + i;
            if (isManualMint[newId]) {
                continue;
            }
            ids[newIndex] = newId;
            for (uint b = 0; b < holders.length; b++) {
                if (newIndex == 0) {
                    amounts[b] = new uint[](numberOfTokens);
                }
                amounts[b][newIndex] = initialBalanceOf(holders[b], newId);
            }
            newIndex += 1;
        }
        bytes32 checksum = keccak256(
            abi.encode(
                ids,
                amounts,
                holders,
                lastRangeTokenIdMinted,
                isZeroMinted,
                _manualMintsCount
                // _customMintRangeChecksum()
            )
        );
        return (MintRangeInput(ids, amounts), checksum);
    }

    // Verifies the checksum generated by getMintRangeInput
    function _mintRange(
        MintRangeInput memory input,
        bytes32 inputChecksum
    ) internal virtual {
        address[] memory addresses = initialHolders(input.ids[0]);
        bytes32 checksum = keccak256(
            abi.encode(
                input.ids,
                input.amounts,
                addresses,
                lastRangeTokenIdMinted,
                isZeroMinted,
                _manualMintsCount
                // _customMintRangeChecksum()
            )
        );
        // invalid input -> use getMintRangeInput
        require(inputChecksum == checksum, "M:04");
        // Update last minted tokenId
        lastRangeTokenIdMinted = input.ids[input.ids.length - 1];

        if (isZeroMinted == false) {
            isZeroMinted = true;
        }

        // send mint transfer events.
        for (uint i = 0; i < addresses.length; i++) {
            emit TransferBatch(
                msg.sender,
                address(0),
                addresses[i],
                input.ids,
                input.amounts[i]
            );
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Uitilities
    ///////////////////////////////////////////////////////////////////////////////
    
    // Returns true if tokenId was minted.
    function exists(uint tokenId) public view virtual returns (bool) {
        return _inRange(tokenId) || isManualMint[tokenId] == true;
    }

    // Returns true if token is in existing id range.
    function _inRange(uint tokenId) private view returns (bool) {
        return isZeroMinted && tokenId <= lastRangeTokenIdMinted;
    }

    // Utility to find lower bound. 
    // Returns index of last element that is small 
    // than given element in a sorted array.
    function _findLowerBound(
        uint256[] memory array,
        uint256 element
    ) internal pure returns (uint256) {
        for (uint i = array.length - 1; i >= 0; i--) {
            if (element >= array[i]) {
                return i;
            }
        }
        return 0;
    }

    // Utility to find Address in array of addresses
    function _includesAddress(
        address[] memory array,
        address value
    ) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
}