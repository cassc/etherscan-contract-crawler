// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./WCNFTMerkle.sol";
import "./WCNFTToken.sol";
import { DefaultOperatorFilterer } from "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract Rugfools is ERC721A, Ownable, DefaultOperatorFilterer, WCNFTMerkle, WCNFTToken {

    uint256 public immutable maxSupply;
    uint256 public mintPrice;
    string public baseURI;
    bool public isTransferable;
    bytes32 public whitelistMerkleRoot;

    event AllowListClaimMint(
        address indexed userAddress,
        uint256 numberOfTokens
    );

    error ExceedsMaximumSupply();

    error WrongETHValueSent();

    constructor(uint256 _mintPrice) ERC721A("Rugfools", "RUGS") {
        maxSupply = 20000;
        mintPrice = _mintPrice;
        isTransferable = false;
    }

    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > maxSupply) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setIsTransferable(bool _newIsTransferable) public onlyOwner returns(bool) {
        require(isTransferable != _newIsTransferable, "No state change!");
        isTransferable = _newIsTransferable;
        return true;
    }

    function setAllowListActive(bool isActive)
        external
        override
        onlyOwner
    {
        if (merkleRoot == bytes32(0)) revert MerkleRootNotSet();

        _setAllowListActive(isActive);
    }

    function _baseURI() view internal override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _checkOwner();
        baseURI = _newBaseURI;
    }

    function totalSupply() public view override returns (uint256) {
        return maxSupply;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        require(isTransferable, "Token not transferable right now");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        require(isTransferable, "Token not transferable right now");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        require(isTransferable, "Token not transferable right now");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function _setAllowList(bytes32 merkleRoot_) internal virtual {
        merkleRoot = merkleRoot_;
        emit MerkleRootChanged(merkleRoot);
    }

    function safeMint(address to, uint256 numberOfTokens)
        public
        payable
        supplyAvailable(numberOfTokens)
    {
        require(numberOfTokens > 0, "Number of Tokens should be more than 0");

        uint256 price = numberOfTokens * mintPrice;
        if (msg.value < price) revert WrongETHValueSent();

        _safeMint(to, numberOfTokens);
    }

    function mintAllowList(
        uint256 numberOfTokens,
        uint256 tokenQuota,
        bytes32[] calldata proof
    )
        external
        isAllowListActive
        supplyAvailable(numberOfTokens)
    {
        address claimer = msg.sender;


        // check if the claimer is on the allowlist
        if (!onAllowListB(claimer, tokenQuota, proof)) {
            revert NotOnAllowList();
        }

        // check if the claimer has tokens remaining in their quota
        uint256 tokensClaimed = getAllowListMinted(claimer);
        if (tokensClaimed + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }

        // claim tokens
        _setAllowListMinted(claimer, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens, "");
        emit AllowListClaimMint(msg.sender, numberOfTokens);
    }

    function withdrawMoney() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, WCNFTToken)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}