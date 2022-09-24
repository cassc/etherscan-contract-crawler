// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "./CNPRadmin.sol";
import {CouponSet} from "./lib/CouponSet.sol";
import "./lib/CNPRdescriptor.sol";

/**
 *  @title The CNPR ERC-721A token.
 *  @dev This is the contract we deploy to the blockchain.
 */
contract CNPR is CNPRadmin, ERC721A("CNP Rookies", "CNPR") {
    using CouponSet for CouponSet.Coupon;

    constructor(address _adminSigner) {
        admin = address(0);
        adminSigner = _adminSigner;
        _safeMint(WITHDRAW_ADDRESS, 500);
    }

    /**
     *  @notice If the conditions are met, a CNPR token is minted and sent to the specified address.
     *  @dev Whitelist authentication creates an off-chain signed coupon for each address and restores the public address for authentication (ECDSA).
     *  @param _quantity Amount of tokens.
     *  @param _allotted The total number of tokens the minter is allowed to claim.
     *  @param _coupon Coupon for verifying the signer.
     */
    function presaleMint(
        uint256 _quantity,
        uint256 _allotted,
        CouponSet.Coupon memory _coupon
    ) external payable {
        require(phase == SalePhase.PreSale, "presale event is not active");
        require(_quantity != 0, "the quantity is zero");
        require(
            _coupon._isVerifiedCoupon(
                CouponSet.CouponType.Presale,
                _allotted,
                presaleMintIndex,
                adminSigner
            ),
            "invalid coupon"
        );
        require(
            presaleMintCount[msg.sender] + _quantity <= _allotted,
            "exceeds number of earned Tokens"
        );
        require(MINT_COST * _quantity <= msg.value, "not enough eth");
        require(
            _quantity + totalSupply() <= MAX_SUPPLY,
            "claim is over the max supply"
        );
        presaleMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     *  @notice If the conditions are met, the existing tokens are burned and new tokens are minted.
     *  @dev Whitelist authentication creates an off-chain signed coupon for each address and restores the public address for authentication (ECDSA).
     *  @param _burnTokenIds The ID of tokens to be burned.
     *  @param _allotted The total number of tokens the minter is allowed to claim.
     *  @param _coupon Coupon for verifying the signer.
     */
    function burnMint(
        uint256[] memory _burnTokenIds,
        uint256 _allotted,
        CouponSet.Coupon memory _coupon
    ) external payable {
        require(phase == SalePhase.BurnMint, "burn mint is not activated");
        require(_burnTokenIds.length != 0, "the quantity is zero");
        require(
            _coupon._isVerifiedCoupon(
                CouponSet.CouponType.BurnMint,
                _allotted,
                burnMintIndex,
                adminSigner
            ),
            "invalid coupon"
        );
        require(
            burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[
                msg.sender
            ] +
                _burnTokenIds.length <=
                _allotted,
            "address already claimed max amount"
        );
        require(
            burnMintCost * _burnTokenIds.length <= msg.value,
            "not enough eth"
        );
        require(
            _burnTokenIds.length + _totalBurned() <= maxBurnMintSupply,
            "over total burn count"
        );

        burnMintStructs[burnMintIndex].numberOfBurnMintByAddress[
                msg.sender
            ] += _burnTokenIds.length;

        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require(
                _msgSender() == ownerOf(tokenId),
                "sender is not the owner of the token"
            );
            _burn(tokenId);
        }

        _safeMint(msg.sender, _burnTokenIds.length);
    }

    /**
     *  @notice Only owners or admins can use this function to mint CNPR tokens.
     *  @dev Tokens held by the operation are minted by the constructor, but this function is used when there is an urgent need for more.
     *  It is also used for airdropping.
     *  Only callable by the owner or admin.
     *  @param _to The Address to send token.
     *  @param _quantity The amount of tokens to be minted.
     */
    function adminMint(address[] calldata _to, uint256[] memory _quantity)
        external
        onlyAdmin
    {
        require(
            _to.length == _quantity.length,
            "the address and quantity do not match"
        );

        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _quantity.length; i++) {
            require(_quantity[i] != 0, "the quantity is zero");
            _mintAmount += _quantity[i];
        }

        require(
            _mintAmount + totalSupply() <= MAX_SUPPLY,
            "claim is over the max supply"
        );

        for (uint256 i = 0; i < _quantity.length; i++) {
            _safeMint(_to[i], _quantity[i]);
        }
    }

    /**
     *  @notice Given a token ID, construct a token URI for the CNPR.
     *  @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *  @param _tokenId The token id.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (isOnchain) {
            return descriptor.tokenURI(_tokenId);
        }

        return
            string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
    }

    /**
     *  @dev Returns whether `tokenId` exists.
     */
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function totalBurned() public view virtual returns (uint256) {
        return _totalBurned();
    }

    /**
     *  @dev Return the URI of the base
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     *  @dev Set start to 1 for token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}