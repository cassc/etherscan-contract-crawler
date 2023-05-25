// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {SignedAllowance} from '@0xdievardump/signed-allowances/contracts/SignedAllowance.sol';

import {PrimeList} from '../libraries/PrimeList.sol';

import {EtherealStatesCore} from './EtherealStatesCore.sol';

/// @title EtherealStatesMinter
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Minter logic
contract EtherealStatesMinter is EtherealStatesCore, SignedAllowance {
    error LengthMismatch();
    error TooManyRequested();
    error UnknownItem();

    error WrongMintProcess();
    error TooEarly();

    error WrongValue();

    error OneMintCallPerBlockForContracts();

    /// @notice Emitted so we can know which tokens have the HoldersTrait and quickly generate after reveal
    /// @param startTokenId the starting id
    /// @param quantity the amount of ids
    event TokensWithHoldersTrait(uint256 startTokenId, uint256 quantity);

    uint256 public constant START_TOKEN_INDEX = 1;

    uint256 public constant MAX_SUPPLY = 7000;

    uint256 public constant MAX_PUBLIC = 6;

    uint256 public constant MAX_PER_LIST = 2;

    uint256 public constant MINT_BUNDLE = 5;

    uint256 public constant MINT_PRICE = 0.08 ether;

    address public immutable MINT_PASSES_HOLDER;

    uint256 public currentTier;

    uint256 public teamAllocation = 40;

    uint256 private _extraDataMint;

    /// @notice quantity minted for an address in the allow list + public mint
    mapping(address => uint256) public mintsCounter;

    /// @notice last tx.origin mint block when using contracts
    mapping(address => uint256) private _contractLastBlockMinted;

    /////////////////////////////////////////////////////////
    // Modifiers                                           //
    /////////////////////////////////////////////////////////

    modifier onlyMinimumTier(uint256 tier) {
        if (currentTier < tier) {
            revert TooEarly();
        }
        _;
    }

    // this modifier helps to protect against people using contracts to mint
    // a big amount of NFTs in one call
    // for people minting through contracts (custom or even Gnosis-Safe)
    // we impose a limit on tx.origin of one call per block
    // ensuring a loop can not be used, but still allowing contract minting.
    // This allows Gnosis & other contracts wallets users to still be able to mint
    // This is not the perfect solution, but it's a "not perfect but I'll take it" compromise
    modifier protectOrigin() {
        if (tx.origin != msg.sender) {
            if (block.number == _contractLastBlockMinted[tx.origin]) {
                revert OneMintCallPerBlockForContracts();
            }
            _contractLastBlockMinted[tx.origin] = block.number;
        }
        _;
    }

    constructor(address mintPasses, address newSigner) {
        MINT_PASSES_HOLDER = mintPasses;

        _setAllowancesSigner(newSigner);
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function hasHoldersTrait(uint256 tokenId) public view returns (bool) {
        return _ownershipOf(tokenId).extraData == 1;
    }

    /////////////////////////////////////////////////////////
    // Minting                                             //
    /////////////////////////////////////////////////////////

    function mintPublic(uint256 quantity)
        external
        payable
        onlyMinimumTier(3)
        protectOrigin
    {
        uint256 alreadyMinted = mintsCounter[msg.sender];
        if (alreadyMinted + quantity > MAX_PUBLIC) {
            revert TooManyRequested();
        }
        mintsCounter[msg.sender] = alreadyMinted + quantity;

        _mintStates(msg.sender, quantity, 0, false);
    }

    function mintWithAllowlist(
        uint256 quantity,
        uint256 nonce,
        bytes memory signature
    ) external payable onlyMinimumTier(2) {
        // first validate signature
        validateSignature(msg.sender, nonce, signature);

        // then make sure the account doesn't try to mint more than MAX_PER_LIST
        uint256 alreadyMinted = mintsCounter[msg.sender];
        if (alreadyMinted + quantity > MAX_PER_LIST) {
            revert TooManyRequested();
        }

        // update minted
        mintsCounter[msg.sender] = alreadyMinted + quantity;

        _mintStates(msg.sender, quantity, 0, false);
    }

    function mintWithPasses(
        uint256[] memory ids,
        uint256[] memory amounts,
        bool addHoldersTrait
    ) external payable onlyMinimumTier(1) {
        // calculate how many to mint and how many are free
        uint256 free;
        uint256 quantity;
        uint256 length = ids.length;
        for (uint256 i; i < length; i++) {
            if (ids[i] == 1) {
                free += amounts[i];
            }
            quantity += amounts[i];
        }

        // we are not using safeMint so we can do that here.
        _mintStates(msg.sender, quantity, free, addHoldersTrait);

        // burn all the passes; will revert if someone tries to do weird stuff with
        // ids & amounts
        IERC1155Burnable(MINT_PASSES_HOLDER).burnBatch(
            msg.sender,
            ids,
            amounts
        );
    }

    /////////////////////////////////////////////////////////
    // Gated                                               //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to set current tier for the mint
    /// @notice (0 = no mint, 1 = holders, 2 = holders & allowlist, 3 = hholders & allowlist & public)
    /// @param newTier the new value for the current tier
    function setTier(uint256 newTier) external onlyOwner {
        currentTier = newTier;
    }

    /// @notice Allows owner to set the current signer for the allowlist
    /// @param newSigner the address of the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function teamMint(
        address[] calldata accounts,
        uint256[] calldata quantities
    ) external onlyOwner {
        uint256 length = accounts.length;

        if (accounts.length != quantities.length) {
            revert LengthMismatch();
        }

        uint256 _teamAllocation = teamAllocation;

        for (uint256 i; i < length; i++) {
            // will revert if too many requested
            _teamAllocation -= quantities[i];

            _mintStates(accounts[i], quantities[i], quantities[i], false);
        }

        teamAllocation = _teamAllocation;
    }

    /// @dev for tests; might forget to remove, so it's lock on testnets ids
    function testMints(
        address to,
        uint256 quantity,
        bool addHoldersTrait
    ) external onlyOwner {
        require(block.chainid == 4 || block.chainid == 31337, 'OnlyTests()');
        _mintStates(to, quantity, quantity, addHoldersTrait);
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // start at START_TOKEN_INDEX
    function _startTokenId() internal pure override returns (uint256) {
        return START_TOKEN_INDEX;
    }

    function _mintStates(
        address to,
        uint256 quantity,
        uint256 free,
        bool addHoldersTrait
    ) internal virtual {
        // check that there is enough supply
        if (_totalMinted() + quantity > MAX_SUPPLY) {
            revert TooManyRequested();
        }

        // check we have the right amount of ethereum with the tx
        if (msg.value != (quantity - free) * MINT_PRICE) {
            revert WrongValue();
        }

        // there is supply, mint price is good, lfgo
        uint256 nextTokenId = _nextTokenId();

        if (addHoldersTrait) {
            _extraDataMint = 1;
        }

        // here we make bundles of MINT_BUNDLE in order to have a mint not too expensive, but also
        // not transfer too much the cost of minting to future Transfers, which is what ERC721A does.
        if (quantity > MINT_BUNDLE) {
            uint256 times = quantity / MINT_BUNDLE;
            for (uint256 i; i < times; i++) {
                _mint(to, MINT_BUNDLE);
            }

            if (quantity % MINT_BUNDLE != 0) {
                _mint(to, quantity % MINT_BUNDLE);
            }
        } else {
            _mint(to, quantity);
        }

        if (addHoldersTrait) {
            _extraDataMint = 0;
            emit TokensWithHoldersTrait(nextTokenId, quantity);
        }
    }

    /// @dev Used to set the "hasHoldersTrait" flag on a token at minting time
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        // if minting, return the _extraDataMint value
        if (from == address(0)) {
            return uint24(_extraDataMint);
        }
        // else return the current value
        return previousExtraData;
    }
}

interface IERC1155Burnable {
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}