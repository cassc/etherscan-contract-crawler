// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IABDropManager.sol';
import './interfaces/IERC721AB.sol';
import './ERC721ABErrors.sol';

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Storage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract ERC721AB is ERC721Enumerable, ERC721ABErrors, ERC165Storage, Ownable {
    // AnotherblockV1 address
    address public anotherblock;

    // Denominator used to calculate fees
    uint256 private constant DENOMINATOR = 1e6;

    // Stores the drop ID for a given Token ID
    mapping(uint256 => uint256) public dropIdPerToken;

    // Stores the amounts of tokens minted per address and per drop for the public sale
    mapping(uint256 => mapping(address => uint256))
        public mintedPerDropPublicSale;

    // Stores the amounts of tokens minted per address and per drop for the private sale
    mapping(uint256 => mapping(address => uint256))
        public mintedPerDropPrivateSale;

    /**
     * @notice
     *  ERC721AB contract constructor
     *
     * @param _anotherblock : Anotherblock contract address
     * @param _name : name of the NFT contract
     * @param _symbol : symbol / ticker of the NFT contract
     **/
    constructor(
        address _anotherblock,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        // Check that _anotherblock address matches IABDropManager interface
        if (
            !ERC165Checker.supportsInterface(
                _anotherblock,
                type(IABDropManager).interfaceId
            )
        ) revert IncorrectInterface();
        anotherblock = _anotherblock;

        // Grant the DEFAULT_ADMIN_ROLE to the contract deployer
        _registerInterface(type(IERC721AB).interfaceId);
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Return an array containing the token IDs owned by the given address
     *
     * @param _owner : owner address
     * @return result : array containing all the token IDs owned by `_owner`
     */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        // If _owner doesnt own any tokens, return an empty array
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; ++index) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev See {ERC721-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC165Storage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //
    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

    /**
     * @notice
     *  Update anotherblock address
     *  Only the contract owner can perform this operation
     *
     * @param _anotherblock : new anotherblock address
     */
    function setAnotherblock(address _anotherblock) external onlyOwner {
        // Check that the new address corresponds to IABDropManager interface
        if (
            !ERC165Checker.supportsInterface(
                _anotherblock,
                type(IABDropManager).interfaceId
            )
        ) revert IncorrectInterface();
        anotherblock = _anotherblock;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Let a whitelisted user mint `_quantity` token(s) of the given `_dropId`
     *
     * @param _dropId : drop identifier
     * @param _quantity : amount of tokens to be minted
     * @param _proof : merkle tree proof used to verify whitelisted user
     */
    function _mintAB(
        address _to,
        uint256 _dropId,
        uint256 _quantity,
        bytes32[] memory _proof
    ) internal virtual {
        IABDropManager.Drop memory drop = IABDropManager(anotherblock).drops(
            _dropId
        );

        // Check if the drop is not sold-out
        if (drop.sold == drop.tokenInfo.supply) revert DropSoldOut();

        // Check that the whitelisted sale started
        if (block.timestamp < drop.salesInfo.privateSaleTime)
            revert SaleNotStarted();

        // Check that there are enough tokens available for sale
        if (drop.sold + _quantity > drop.tokenInfo.supply)
            revert NotEnoughTokensAvailable();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (msg.value != drop.tokenInfo.price * _quantity)
            revert IncorrectETHSent();

        // Check that user is whitelisted in case the public sale did not start yet
        if (
            drop.merkleRoot != 0x0 &&
            block.timestamp < drop.salesInfo.publicSaleTime
        ) {
            // Check that user did not mint the maximum amount per address for the private sale
            if (
                mintedPerDropPrivateSale[drop.dropId][_to] + _quantity >
                drop.salesInfo.privateSaleMaxMint
            ) revert MaxMintPerAddress();

            bool isWhitelisted = MerkleProof.verify(
                _proof,
                drop.merkleRoot,
                keccak256(abi.encodePacked(_to))
            );

            // Revert if user is not whitelisted
            if (!isWhitelisted) {
                revert NotInMerkle();
            }

            mintedPerDropPrivateSale[drop.dropId][_to] += _quantity;
        } else {
            // Check that user did not mint the maximum amount per address for the public sale
            if (
                mintedPerDropPublicSale[drop.dropId][_to] + _quantity >
                drop.salesInfo.publicSaleMaxMint
            ) revert MaxMintPerAddress();
            mintedPerDropPublicSale[drop.dropId][_to] += _quantity;
        }

        uint256 currentDropTokenIndex = drop.firstTokenIndex + drop.sold;
        for (uint256 i = 0; i < _quantity; ++i) {
            dropIdPerToken[currentDropTokenIndex + i] = drop.dropId;
            _safeMint(_to, currentDropTokenIndex + i);
        }

        IABDropManager(anotherblock).updateDropCounter(_dropId, _quantity);

        // Send Right Holder Fee to the owner address
        if (msg.value > 0) {
            uint256 feeToRightHolder = (msg.value * drop.rightHolderFee) /
                DENOMINATOR;
            if (feeToRightHolder > 0) {
                payable(drop.owner).transfer(feeToRightHolder);
            }
        }
    }

    /**
     * @dev See {ERC721Enumerable-beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}