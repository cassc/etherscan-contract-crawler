// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC1155Extended} from "./token/ERC1155Extended.sol";
import {AllowList} from "./util/AllowList.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TwoStepOwnable} from "./util/TwoStepOwnable.sol";
import {CommissionWithdrawable} from "./util/CommissionWithdrawable.sol";

/*
    ___ ____        _          __  __                                     __               
   / (_) __/__     (_)___     / /_/ /_  ___     ____  ____ ___________   / /___ _____  ___ 
  / / / /_/ _ \   / / __ \   / __/ __ \/ _ \   / __ \/ __ `/ ___/ ___/  / / __ `/ __ \/ _ \
 / / / __/  __/  / / / / /  / /_/ / / /  __/  / /_/ / /_/ (__  |__  )  / / /_/ / / / /  __/
/_/_/_/  \___/  /_/_/ /_/   \__/_/ /_/\___/  / .___/\__,_/____/____/  /_/\__,_/_/ /_/\___/ 
                                            /_/                                                                                                                                                     
*/

contract CameoPass is
    ERC1155Extended,
    AllowList,
    CommissionWithdrawable,
    TwoStepOwnable
{
    uint256 private tokenIndex;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _mintPrice
    )
        ERC1155Extended(
            _name,
            _symbol,
            _uri,
            _mintPrice,
            3, /* numOptions */
            2000, /* maxSupplyPerOption */
            6, /* maxMintsPerWallet */
            1645142400, /* unlockTime */
            0xa5409ec958C83C3f309868babACA7c86DCB077c1 /* openseaProxyAddress */
        )
        AllowList(
            6, /* maxAllowListRedemptions */
            0xed2ea62124906818bda99512204fa6beb610c56a9ffead65673043928746a924 /* merkleRoot */
        )
        CommissionWithdrawable(
            0x5b3256965e7C3cF26E11FCAf296DfC8807C01073, /* commissionPayoutAddress */
            50 /* commissionPayoutPerMille */
        )
    {}

    ///@notice Mint a single token. TokenIds will be distributed evenly among mints.
    function mint()
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        onlyAfterUnlock
        includesCorrectPayment(1)
    {
        _mintAndIncrement();
    }

    ///@notice Mint a quantity of each token ID. Limited to max mints per wallet.
    function batchMint(uint256 _quantity)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyAfterUnlock
        includesCorrectPayment(_quantity * 3)
    {
        _mintAndIncrementBatch(_quantity);
    }

    ///@notice Mint before unlock by providing a Merkle proof. TokenIds will be distributed evenly among mints.
    ///@param _proof Merkle proof to verify msg.sender is part of allow list
    function mintAllowList(bytes32[] calldata _proof)
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        includesCorrectPayment(1)
        onlyAllowListed(_proof)
    {
        _ensureAllowListRedemptionsAvailableAndIncrement(1);
        _mintAndIncrement();
    }

    ///@notice Mint a quantity of each ID by providing a Merkle proof. Limited to max allow list redemptions.
    ///@param _quantity number of each ID to mint
    ///@param _proof Merkle proof to verify msg.sender is part of allow list
    function batchMintAllowList(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        whenNotPaused
        includesCorrectPayment(_quantity * 3)
        onlyAllowListed(_proof)
    {
        _ensureAllowListRedemptionsAvailableAndIncrement(_quantity * 3);
        _mintAndIncrementBatch(_quantity);
    }

    ///@notice check/increment appropriate values and mint one token
    function _mintAndIncrement() internal {
        _incrementTokenIndex();
        _ensureSupplyAvailableForIdAndIncrement(tokenIndex % 3, 1);
        _ensureWalletMintsAvailableAndIncrement(1);
        _mint(msg.sender, tokenIndex % 3, 1, "");
    }

    ///@notice check/increase appropriate values and mint one of each token
    function _mintAndIncrementBatch(uint256 _quantity) internal {
        _ensureSupplyAvailableAndIncrementBatch(_quantity);
        _ensureWalletMintsAvailableAndIncrement(_quantity * 3);
        _mint(msg.sender, 0, _quantity, "");
        _mint(msg.sender, 1, _quantity, "");
        _mint(msg.sender, 2, _quantity, "");
    }

    ///@notice atomically check and increase quantity of each token ID minted
    function _ensureSupplyAvailableAndIncrementBatch(uint256 _quantity)
        internal
    {
        // will revert on overflow
        if (
            (numMinted[0] + _quantity) > MAX_SUPPLY_PER_ID ||
            (numMinted[1] + _quantity) > MAX_SUPPLY_PER_ID ||
            (numMinted[2] + _quantity) > MAX_SUPPLY_PER_ID
        ) {
            revert MaxSupplyForID();
        }
        // would have reverted above
        unchecked {
            numMinted[0] += _quantity;
            numMinted[1] += _quantity;
            numMinted[2] += _quantity;
        }
    }

    ///@notice increments tokenIndex so mints are distributed across IDs, with logic to prevent it from getting stuck
    function _incrementTokenIndex() private {
        // increment index
        ++tokenIndex;
        // check if index is mintable; increment if not
        // stop once we make a complete loop (fully minted out)
        for (uint256 i; i < 3; ++i) {
            if (numMinted[tokenIndex % 3] >= MAX_SUPPLY_PER_ID) {
                ++tokenIndex;
            } else {
                break;
            }
        }
    }

    ///@notice Initiate ownership transfer to _newOwner. Note: new owner will have to manually claimOwnership
    ///@param _newOwner address of potential new owner
    function transferOwnership(address _newOwner)
        public
        virtual
        override(Ownable, TwoStepOwnable)
        onlyOwner
    {
        if (_newOwner == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        _potentialOwner = _newOwner;
    }
}