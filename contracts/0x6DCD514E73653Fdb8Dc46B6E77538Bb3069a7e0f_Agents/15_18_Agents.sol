//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./IDelegationRegistry.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 __   _ _______ __   _  _____       _______  ______ _______ __   _ _______ _______
 | \  | |_____| | \  | |     |      |_____| |  ____ |______ | \  |    |    |______
 |  \_| |     | |  \_| |_____|      |     | |_____| |______ |  \_|    |    ______|

 By NanoverseHQ                                                                                                                                                                 
 */

contract Agents is Ownable, ERC721A, OperatorFilterer, ERC2981 {
    enum SalePhase {
        Locked,
        FreeClaim
    }
    SalePhase public phase = SalePhase.Locked;

    bool public operatorFilteringEnabled;

    uint256 public MAX_SUPPLY = 5555;
    address public DEV_ADDRESS = 0x28aa39C6571da8E8011c05c0e426Badc4D679Adf;

    mapping(uint256 => bool) public tokenIdToFreeMintAlready;

    bool public REVEALED;
    string public UNREVEALED_URI;
    string public BASE_URI;

    IERC721 nanoContract;
    IDelegationRegistry delegateCash;

    constructor(address _nanoAddress, address delegateCashAddress)
        ERC721A("Agents", "AGENTS")
    {
        _registerForOperatorFiltering();
        nanoContract = IERC721(_nanoAddress);
        delegateCash = IDelegationRegistry(delegateCashAddress);
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 10% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function isOwnerOfNano(uint256 tokenId) public view returns (bool) {
        address ownerAddress = nanoContract.ownerOf(tokenId);
        return ownerAddress == msg.sender || delegateCash.checkDelegateForToken(
            msg.sender,
            ownerAddress,
            address(nanoContract),
            tokenId
        );
    }

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function batchClaim(uint256[] calldata tokenIds) external {
        require(phase == SalePhase.FreeClaim, "FreeClaim is not active");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(isOwnerOfNano(tokenId), "Sender is neither a delegate nor owner for the tokenId");
            require(!tokenIdToFreeMintAlready[tokenId], "Each nano token can only mint free once");
            tokenIdToFreeMintAlready[tokenId] = true;
        }

        //Mint them
        _safeMint(msg.sender, tokenIds.length);
    }

    // This is just here in case someone accidentally sends money *shrug*
    function withdrawFunds() public onlyOwner {
        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{value: finalFunds}("");
        require(succ, "transfer failed");
    }

    function setRevealData(bool _revealed, string memory _unrevealedURI)
        public
        onlyOwner
    {
        REVEALED = _revealed;
        UNREVEALED_URI = _unrevealedURI;
    }

    function setPhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
        } else {
            return UNREVEALED_URI;
        }
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}