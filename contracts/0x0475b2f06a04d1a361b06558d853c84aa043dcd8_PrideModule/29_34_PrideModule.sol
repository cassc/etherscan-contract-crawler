// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

import {INFModule, NFBaseModule, ERC165, IERC165} from '@0xdievardump/niftyforge/contracts/Modules/NFBaseModule.sol';
import {INFModuleTokenURI} from '@0xdievardump/niftyforge/contracts/Modules/INFModuleTokenURI.sol';
import {INFModuleWithRoyalties} from '@0xdievardump/niftyforge/contracts/Modules/INFModuleWithRoyalties.sol';
import {INiftyForge721} from '@0xdievardump/niftyforge/contracts/INiftyForge721.sol';

import {IBokkyPooBahsDateTimeContract} from './interfaces/IBokkyPooBahsDateTimeContract.sol';
import {NiftyPrideAuctionHouse} from './NiftyPrideAuctionHouse.sol';
import {IRenderer} from './Renderers/IRenderer.sol';
import {Base64} from './utils/Base64.sol';

contract PrideModule is
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties,
    NiftyPrideAuctionHouse
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    error InvalidParameter();
    error RendererExists();
    error UnknownRenderer();

    error TooLate();

    error InvalidDate();

    error NotAuthorized();

    struct Renderer {
        address creator; // the renderer creator
        uint32 royalties; // the renderer royalties
        uint32 remainingUse; // how many times this renderer can be used
    }

    struct TokenMeta {
        address renderer; // the renderer for this token;
        uint96 creation;
        bytes32 seed; // the seed for this token
    }

    mapping(address => Renderer) public renderers;

    mapping(uint256 => TokenMeta) public tokensMeta;

    EnumerableSet.AddressSet internal _availableRenderers;

    EnumerableSet.AddressSet internal _beneficiaries;

    uint256 beneficiaryIndex;

    // The ERC721 token contract
    address public nftContract;

    constructor(address weth_) NFBaseModule('') NiftyPrideAuctionHouse(weth_) {}

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    /// @inheritdoc	INFModule
    function onAttach() external virtual override returns (bool) {
        if (nftContract == address(0)) {
            nftContract = msg.sender;
            return true;
        }

        // only allows attachment if nftContract if not set
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        TokenMeta memory tokenMeta = tokensMeta[tokenId];
        Renderer memory renderer = renderers[tokenMeta.renderer];

        return (renderer.creator, uint256(renderer.royalties));
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        TokenMeta memory tokenMeta = tokensMeta[tokenId];

        (string memory imageURI, string memory animationURI) = IRenderer(
            tokenMeta.renderer
        ).render(tokenMeta.seed);

        return
            Base64.toB64JSON(
                abi.encodePacked(
                    '{"name":"Pride | ',
                    _getDate(tokenMeta.creation),
                    '","description":"',
                    IRenderer(tokenMeta.renderer).description(),
                    '","image":"',
                    imageURI,
                    '"',
                    (
                        bytes(animationURI).length > 0
                            ? abi.encodePacked(
                                ',"animation_url":"',
                                animationURI,
                                '"'
                            )
                            : bytes('')
                    ),
                    '}'
                )
            );
    }

    ////////////////////////////////////////////////////
    ///// Getters                                     //
    ////////////////////////////////////////////////////

    function getAvailableRenderers()
        external
        view
        returns (Renderer[] memory availableRenderers)
    {
        uint256 length = _availableRenderers.length();

        availableRenderers = new Renderer[](length);
        for (uint256 i; i < length; i++) {
            availableRenderers[i] = renderers[_availableRenderers.at(i)];
        }
    }

    ////////////////////////////////////////////////////
    ///// Setters                                     //
    ////////////////////////////////////////////////////

    /// @notice allows a renderer creator to change where the renderer points (for Royalties purpose mainly)
    /// @param renderer the renderer to edit
    /// @param creator the new creator address
    function setRendererCreator(address renderer, address creator) external {
        if (msg.sender != renderers[renderer].creator) {
            revert NotAuthorized();
        }

        renderers[renderer].creator = creator;
    }

    ////////////////////////////////////////////////////
    ///// Misc                                        //
    ////////////////////////////////////////////////////

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public view returns (bytes4) {
        // if not our nftContract and not a mint
        if (msg.sender != nftContract || operator != address(this)) {
            revert NotAuthorized();
        }

        return this.onERC721Received.selector;
    }

    ////////////////////////////////////////////////////
    ///// Owner                                       //
    ////////////////////////////////////////////////////

    /// @notice allows owner to start the first auction which is a bit special.
    function startFirst() external onlyOwner {
        uint256 tokenId = _mintNext();

        if (tokenId != 1) revert TooLate();

        // forcing the first auction timestamp at June 1st 3PM UTC because I started this project late late on
        // June 1st 2022 and I am not sure I can deploy before June 2nd
        uint256 startTime = 1654095600;
        uint256 endTime = startTime + duration;

        tokensMeta[tokenId].creation = uint96(startTime);

        auction = Auction({
            tokenId: tokenId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(tokenId, startTime, endTime);

        _unpause();
    }

    /// @notice allows owner to add a new renderer contract
    function addRenderer(
        address renderer,
        address creator,
        uint32 royalties,
        uint32 times
    ) public onlyOwner {
        if (times == 0) revert InvalidParameter();
        if (creator == address(0)) revert InvalidParameter();
        if (renderers[renderer].creator != address(0)) revert RendererExists();

        renderers[renderer] = Renderer(creator, royalties, times);
        _availableRenderers.add(renderer);
    }

    /// @notice allows owner to remove a contract from the available renderers
    function removeAvailableRenderer(address renderer) external onlyOwner {
        if (!_availableRenderers.remove(renderer)) revert UnknownRenderer();
    }

    /// @notice adds `beneficiary` to the list of beneficiaries
    /// @param beneficiary the new beneficiary
    function addBeneficiary(address beneficiary) public onlyOwner {
        if (beneficiary == address(0)) revert InvalidParameter();
        if (!_beneficiaries.add(beneficiary)) revert InvalidParameter();
    }

    /// @notice removes `beneficiary` from the list of beneficiaries
    /// @param beneficiary the beneficiary to remove
    function removeBeneficiary(address beneficiary) public onlyOwner {
        if (!_beneficiaries.remove(beneficiary)) revert InvalidParameter();
    }

    ////////////////////////////////////////////////////
    ///// Internals                                   //
    ////////////////////////////////////////////////////

    function _createAuction() internal override {
        (uint256 year, uint256 month, ) = _getYearMonthDay(block.timestamp);

        // only June 2022 for this contract.
        if (year != 2022 || month != 6) {
            revert InvalidDate();
        }

        super._createAuction();
    }

    /// @dev internal function to allow transfer to revenue recipient(s)
    function _transferToRecipients(uint256 tokenId, uint256 amount)
        internal
        virtual
        override
    {
        uint256 creatorShare = (amount * 10) / 100;
        // transfer 10% to the creator of the Renderer linked the the NFT
        _safeTransferETHWithFallback(
            renderers[tokensMeta[tokenId].renderer].creator,
            creatorShare
        );

        // transfer what's left to the next "beneficiary" in the list of all beneficiaries
        _safeTransferETHWithFallback(_nextBeneficiary(), amount - creatorShare);
    }

    function _mintNext() internal override returns (uint256) {
        uint256 tokenId = INiftyForge721(nftContract).mint(address(this));

        bytes32 seed = keccak256(
            abi.encodePacked(
                msg.sender,
                block.timestamp,
                block.difficulty,
                tokenId
            )
        );

        address renderer = _availableRenderers.at(
            uint256(seed) % _availableRenderers.length()
        );

        // decrement the remaining use for this renderer
        if (--renderers[renderer].remainingUse == 0) {
            // and remove this renderer from the list of available renderers if 0
            _availableRenderers.remove(renderer);
        }

        tokensMeta[tokenId] = TokenMeta({
            renderer: renderer,
            creation: uint96(block.timestamp),
            seed: seed
        });

        return tokenId;
    }

    function _getRegistry() internal view override returns (address) {
        return nftContract;
    }

    function _getDate(uint256 timestamp) internal view returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = _getYearMonthDay(
            timestamp
        );
        return
            string(
                abi.encodePacked(
                    year.toString(),
                    '/',
                    month.toString(),
                    '/',
                    day.toString()
                )
            );
    }

    function _getYearMonthDay(uint256 timestamp)
        internal
        view
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        address bokky;
        if (block.chainid == 1) {
            bokky = address(0x23d23d8F243e57d0b924bff3A3191078Af325101);
        } else if (block.chainid == 4) {
            bokky = address(0x047C6386C30E785F7a8fd536945410802a605395);
        }

        if (address(0) != bokky) {
            (year, month, day, , , ) = IBokkyPooBahsDateTimeContract(bokky)
                .timestampToDateTime(timestamp);
        } else {
            // force 2022-06 for chainid not 1 or 4
            year = 2022;
            month = 6;
        }
    }

    function _nextBeneficiary() internal returns (address) {
        uint256 length = _beneficiaries.length();
        uint256 beneficiaryIndex_ = beneficiaryIndex;
        address beneficiary = _beneficiaries.at(beneficiaryIndex_ % length);
        beneficiaryIndex = (beneficiaryIndex_ + 1) % length;
        return beneficiary;
    }
}