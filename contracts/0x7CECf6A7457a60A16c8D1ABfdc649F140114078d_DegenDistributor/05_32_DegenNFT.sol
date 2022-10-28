// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.10;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AddressProvider } from "../core/AddressProvider.sol";
import { ContractsRegister } from "../core/ContractsRegister.sol";

import { ACLTrait } from "../core/ACLTrait.sol";
import { NotImplementedException } from "../interfaces/IErrors.sol";

import { ICreditManagerV2 } from "../interfaces/ICreditManagerV2.sol";
import { ICreditFacade } from "../interfaces/ICreditFacade.sol";
import { IDegenNFT } from "../interfaces/IDegenNFT.sol";

contract DegenNFT is ERC721, ACLTrait, IDegenNFT {
    using Address for address;

    /// @dev Stores the total number of tokens on holder accounts
    uint256 public override totalSupply;

    /// @dev address of Contracts register
    ContractsRegister internal immutable contractsRegister;

    /// @dev address of the current minter
    address public minter;

    /// @dev mapping from address to supported Credit Facade status
    mapping(address => bool) public isSupportedCreditFacade;

    /// @dev Stores the base URI for NFT metadata
    string public override baseURI;

    /// @dev contract version
    uint256 public constant override version = 1;

    /// @dev Restricts calls to this contract's minter
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert MinterOnlyException();
        }
        _;
    }

    /// @dev Restricts calls to the configurator or Credit Facades
    modifier creditFacadeOrConfiguratorOnly() {
        if (
            !isSupportedCreditFacade[msg.sender] &&
            !_acl.isConfigurator(msg.sender)
        ) {
            revert CreditFacadeOrConfiguratorOnlyException();
        }
        _;
    }

    constructor(
        address _addressProvider,
        string memory _name,
        string memory _symbol
    )
        ACLTrait(_addressProvider)
        ERC721(_name, _symbol) // F:[DNFT-1]
    {
        contractsRegister = ContractsRegister(
            AddressProvider(_addressProvider).getContractsRegister()
        );
    }

    function setMinter(address minter_)
        external
        configuratorOnly // F:[DNFT-2B]
    {
        minter = minter_; // F: [DNFT-5A]
        emit NewMinterSet(minter);
    }

    function addCreditFacade(address creditFacade_)
        external
        configuratorOnly // F: [DNFT-2C]
    {
        if (!isSupportedCreditFacade[creditFacade_]) {
            if (!creditFacade_.isContract()) {
                revert InvalidCreditFacadeException(); // F:[DNFT-6]
            }

            address creditManager;
            try ICreditFacade(creditFacade_).creditManager() returns (
                ICreditManagerV2 cm
            ) {
                creditManager = address(cm);
            } catch {
                revert InvalidCreditFacadeException(); // F:[DNFT-6]
            }

            if (
                !contractsRegister.isCreditManager(creditManager) ||
                ICreditFacade(creditFacade_).degenNFT() != address(this) ||
                ICreditManagerV2(creditManager).creditFacade() != creditFacade_
            ) revert InvalidCreditFacadeException(); // F:[DNFT-6]

            isSupportedCreditFacade[creditFacade_] = true; // F: [DNFT-10]
            emit NewCreditFacadeAdded(creditFacade_);
        }
    }

    function removeCreditFacade(address creditFacade_)
        external
        configuratorOnly // F: [DNFT-2D]
    {
        if (isSupportedCreditFacade[creditFacade_]) {
            isSupportedCreditFacade[creditFacade_] = false; // F: [DNFT-9]
            emit NewCreditFacadeRemoved(creditFacade_);
        }
    }

    function setBaseUri(string calldata baseURI_)
        external
        configuratorOnly // F:[DNFT-2A]
    {
        baseURI = baseURI_; // F:[DNFT-5]
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI; // F:[DNFT-5]
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721Metadata, ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _baseURI();
    }

    /// @dev Mints a specified amount of tokens to the address
    /// @param to Address the tokens are minted to
    /// @param amount The number of tokens to mint
    function mint(address to, uint256 amount)
        external
        override
        onlyMinter // F:[DNFT-3]
    {
        uint256 balanceBefore = balanceOf(to); // F:[DNFT-7]

        for (uint256 i; i < amount; ) {
            uint256 tokenId = (uint256(uint160(to)) << 40) + balanceBefore + i; // F:[DNFT-7]
            _mint(to, tokenId); // F:[DNFT-7]

            unchecked {
                ++i; // F:[DNFT-7]
            }
        }

        totalSupply += amount; // F:[DNFT-7]
    }

    /// @dev Burns a number of tokens from a specified address
    /// @param from The address a token will be burnt from
    /// @param amount The number of tokens to burn
    function burn(address from, uint256 amount)
        external
        override
        creditFacadeOrConfiguratorOnly // F:[DNFT-4]
    {
        uint256 balance = balanceOf(from); // F:[DNFT-8,8A]

        if (balance < amount) {
            revert InsufficientBalanceException(); // F:[DNFT-8A]
        }

        for (uint256 i; i < amount; ) {
            uint256 tokenId = (uint256(uint160(from)) << 40) + balance - i - 1; // F:[DNFT-8]
            _burn(tokenId); // F:[DNFT-8]

            unchecked {
                ++i; // F:[DNFT-8]
            }
        }

        totalSupply -= amount; // F:[DNFT-8]
    }

    /// @dev Not implemented as the token is not transferrable
    function approve(address, uint256)
        public
        pure
        virtual
        override(IERC721, ERC721)
    {
        revert NotImplementedException(); // F:[DNFT-11]
    }

    /// @dev Not implemented as the token is not transferrable
    function setApprovalForAll(address, bool)
        public
        pure
        virtual
        override(IERC721, ERC721)
    {
        revert NotImplementedException(); // F:[DNFT-11]
    }

    /// @dev Not implemented as the token is not transferrable
    function transferFrom(
        address,
        address,
        uint256
    ) public pure virtual override(IERC721, ERC721) {
        revert NotImplementedException(); // F:[DNFT-11]
    }

    /// @dev Not implemented as the token is not transferrable
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure virtual override(IERC721, ERC721) {
        revert NotImplementedException(); // F:[DNFT-11]
    }

    /// @dev Not implemented as the token is not transferrable
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure virtual override(IERC721, ERC721) {
        revert NotImplementedException(); // F:[DNFT-11]
    }
}