// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import {Passport} from "../Passport/Passport.sol";

contract Badges is ERC1155, Ownable {
    Passport public immutable passport;
    mapping(uint256 => mapping(uint256 => address)) private passportToTokenToAddress;

    error Disabled();

    modifier updateAddress(uint256 passportId, uint256[] memory tokenIds) {
        updateOwner(passportId, tokenIds);
        _;
    }

    constructor(address owner, address passport_, string memory uri_) ERC1155(uri_) {
        passport = Passport(passport_);
        // check that the owner is an admin of the passport
        require(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), owner), "Badges: initial owner must be passport admin");
        transferOwnership(owner);
    }

    function updateOwner(uint256 passportId, uint256[] memory tokenIds) public {
        address passportOwner = passport.ownerOf(passportId); // reverts if does not exist
        mapping(uint256 => address) storage passportAddressForToken = passportToTokenToAddress[passportId];

        for (uint256 tokenIndex = 0; tokenIndex < tokenIds.length; tokenIndex++) {
            uint256 currentTokenId = tokenIds[tokenIndex];
            address currentTokenOwner = passportAddressForToken[currentTokenId];

            if (currentTokenOwner == address(0)) {
                // its the first time we see this passport for this token
                passportAddressForToken[currentTokenId] = passportOwner;
            } else if (currentTokenOwner != passportOwner) {
                // the passport has moved
                uint256 balance = balanceOf(passportAddressForToken[currentTokenId], currentTokenId);
                _safeTransferFrom(currentTokenOwner, passportOwner, currentTokenId, balance, "");

                passportAddressForToken[currentTokenId] = passportOwner;
            }
        }
    }

    function setURI(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function mint(uint256 passportId, uint256 tokenId, uint256 amount, bytes memory data) external onlyOwner {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        updateOwner(passportId, tokenIds);
        _mint(passport.ownerOf(passportId), tokenId, amount, data);
    }

    function mintBatch(uint256 passportId, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
        external
        onlyOwner
        updateAddress(passportId, tokenIds)
    {
        _mintBatch(passport.ownerOf(passportId), tokenIds, amounts, data);
    }

    function burn(uint256 passportId, uint256 tokenId, uint256 amount) external onlyOwner {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        updateOwner(passportId, tokenIds);
        _burn(passport.ownerOf(passportId), tokenId, amount);
    }

    function burnBatch(uint256 passportId, uint256[] memory tokenIds, uint256[] memory values)
        external
        onlyOwner
        updateAddress(passportId, tokenIds)
    {
        _burnBatch(passport.ownerOf(passportId), tokenIds, values);
    }

    function balanceOf(uint256 passportId, uint256 tokenId) external view returns (uint256) {
        return super.balanceOf(passport.ownerOf(passportId), tokenId);
    }

    function balanceOfBatch(uint256[] memory passportIds, uint256[] memory ids)
        external
        view
        returns (uint256[] memory)
    {
        address[] memory accounts = new address[](passportIds.length);

        for (uint256 i = 0; i < passportIds.length; ++i) {
            accounts[i] = passport.ownerOf(passportIds[i]); // this is safe, the passport can be trusted. Also if it should fail, it will be possible to call again with less number of passports
        }
        return balanceOfBatch(accounts, ids);
    }

    function setApprovalForAll(
        address,
        /* operator */
        bool /* approved */
    ) public pure override {
        revert Disabled();
    }

    function isApprovedForAll(
        address,
        /* account */
        address operator
    ) public view override returns (bool) {
        return address(this) == operator;
    }

    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256, /* tokenId */
        uint256, /*amount*/
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }

    function safeBatchTransferFrom(
        address, /* from*/
        address, /* to*/
        uint256[] memory, /* ids*/
        uint256[] memory, /* amounts*/
        bytes memory /* data */
    ) public pure override {
        revert Disabled();
    }
}