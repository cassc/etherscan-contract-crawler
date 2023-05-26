// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721A, IERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from
    "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IRenderer} from "./IRenderer.sol";

/// @author frolic.eth
/// @title  Mint Button: Open Edition
/// @notice An experimental open edition. Mint a button for 0.00144 ETH. Minting closes ~48 hours after the last mint. The owner of the last mint can burn their button to withdraw 100% of the mint fees collected. GLHF!
/// @dev    Thank you irreverent.eth for the contract reviews!
contract MintButton is ERC721A, ERC721AQueryable, ERC721ABurnable, Ownable {
    IRenderer public renderer;

    uint256 public immutable startBlock = block.number;
    uint256 public lastMintBlock = block.number;
    address public winner;

    event Initialized();

    // https://eips.ethereum.org/EIPS/eip-4906
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    // ****************** //
    // *** INITIALIZE *** //
    // ****************** //

    constructor() ERC721A("Mint Button: Open Edition", "MINTBUTTON") {
        _mint(msg.sender, 1);
        emit Initialized();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A)
        returns (bool)
    {
        // https://eips.ethereum.org/EIPS/eip-4906
        return interfaceId == bytes4(0x49064906)
            || ERC721A.supportsInterface(interfaceId);
    }

    // ************ //
    // *** MINT *** //
    // ************ //

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function lastTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
    }

    function canMint() public view returns (bool) {
        return address(this).balance < 1 ether
            || block.number - lastMintBlock < 14400;
    }

    function mint(uint256 quantity) external payable {
        require(msg.value == quantity * 0.00144 ether, "wrong payment");
        require(canMint(), "mint closed");
        lastMintBlock = block.number;
        // update previous metadata token before minting
        emit MetadataUpdate(lastTokenId());
        _mint(msg.sender, quantity);
    }

    function _extraData(address, address, uint24 previousExtraData)
        internal
        view
        override
        returns (uint24)
    {
        return previousExtraData != 0
            ? previousExtraData
            : uint24(block.number - startBlock);
    }

    // ***************** //
    // *** RENDERING *** //
    // ***************** //

    function mintBlock(uint256 tokenId) public view returns (uint256) {
        return startBlock + explicitOwnershipOf(tokenId).extraData;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        return renderer.tokenURI(tokenId);
    }

    // ************************* //
    // *** BURN AND WITHDRAW *** //
    // ************************* //

    function burn(uint256 tokenId) public override {
        if (tokenId == lastTokenId()) {
            require(!canMint(), "can't burn the last token while mint is open");
            winner = ownerOf(tokenId);
        }
        super.burn(tokenId);
    }

    function withdraw(address to) public {
        uint256 balance = address(this).balance;
        require(balance > 0, "zero balance");

        require(!canMint(), "can't withdraw while mint is open");
        require(winner != address(0), "the last token has not been burned");
        require(msg.sender == winner, "you are not the winner");

        (bool sent,) = to.call{value: balance}("");
        require(sent, "failed to withdraw");
    }

    // ************* //
    // *** ADMIN *** //
    // ************* //

    function setRenderer(IRenderer nextRenderer) external onlyOwner {
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId());
        renderer = nextRenderer;
    }

    function refreshMetadata(uint256 tokenId) external onlyOwner {
        emit MetadataUpdate(tokenId);
    }

    function refreshAllMetadata() external onlyOwner {
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
    }
}