// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC1155Metadata} from "../token/ERC1155Metadata.sol";
import {AllowsImmutableProxy} from "../util/AllowsImmutableProxy.sol";
import {MaxMintable} from "../util/MaxMintable.sol";
import {OwnerPausable} from "../util/OwnerPausable.sol";
import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {TimeLock} from "../util/TimeLock.sol";

///@notice abstract ERC1155 implementation with access control and specialized minting extensions
///@author emo.eth
abstract contract ERC1155Extended is
    ERC1155Metadata,
    AllowsImmutableProxy,
    MaxMintable,
    OwnerPausable,
    ReentrancyGuard,
    TimeLock
{
    uint256 public immutable NUM_OPTIONS;
    uint256 public immutable MAX_SUPPLY_PER_ID;
    uint256 public mintPrice;
    mapping(uint256 => uint256) public numMinted;

    error InvalidOptionID();
    error MaxSupplyForID();
    error IncorrectPayment();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _mintPrice,
        uint256 _numOptions,
        uint256 _maxSupply,
        uint256 _maxMintsPerWallet,
        uint256 _unlockTime,
        address _proxyAddress
    )
        ERC1155Metadata(_name, _symbol, _uri)
        TimeLock(_unlockTime)
        MaxMintable(_maxMintsPerWallet)
        AllowsImmutableProxy(_proxyAddress, true)
    {
        name = _name;
        symbol = _symbol;
        mintPrice = _mintPrice;
        NUM_OPTIONS = _numOptions;
        MAX_SUPPLY_PER_ID = _maxSupply;
    }

    ////////////////////////////
    // Access control helpers //
    ////////////////////////////

    ///@notice check that msg includes correct payment for minting a quantity of tokens
    ///@param _quantity number of tokens to mint
    modifier includesCorrectPayment(uint256 _quantity) {
        // will revert on overflow
        if (msg.value != (mintPrice * _quantity)) {
            revert IncorrectPayment();
        }
        _;
    }

    ///@notice atomically check and increase supply of tokenId
    ///@param _id tokenId to check
    ///@param _quantity number being minted
    function _ensureSupplyAvailableForIdAndIncrement(
        uint256 _id,
        uint256 _quantity
    ) internal {
        if (_id >= NUM_OPTIONS) {
            revert InvalidOptionID();
        }
        // will revert on overflow
        if ((numMinted[_id] + _quantity) > MAX_SUPPLY_PER_ID) {
            revert MaxSupplyForID();
        }
        unchecked {
            numMinted[_id] += _quantity;
        }
    }

    ///////////////////////////
    // Configuration Methods //
    ///////////////////////////

    ///@notice set mint price as used in includesCorrectPayment. OnlyOwner
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    //////////////////
    // Mint Methods //
    //////////////////

    ///@notice bulk mint tokens to an address. OnlyOwner
    ///@param _to receiving address
    ///@param _id tokenId to mint
    ///@param _quantity number to mint
    function bulkMint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) external onlyOwner {
        _ensureSupplyAvailableForIdAndIncrement(_id, _quantity);
        _mint(_to, _id, _quantity, "");
    }

    ////////////////////////
    // Overridden methods //
    ////////////////////////

    ///@dev overridden to allow proxy approvals for gas-free listing
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            isApprovedForProxy(_owner, _operator) ||
            super.isApprovedForAll(_owner, _operator);
    }

    function isValidTokenId(uint256 _id) public view returns (bool) {
        return (_id < NUM_OPTIONS);
    }
}