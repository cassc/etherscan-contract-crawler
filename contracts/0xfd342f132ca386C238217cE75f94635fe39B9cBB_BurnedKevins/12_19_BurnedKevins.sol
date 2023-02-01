// SPDX-License-Identifier: MIT
// Indelible Labs LLC

pragma solidity ^0.8.17;

import "./ERC721X.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "solady/src/utils/Base64.sol";
import "./interfaces/IOnChainKevin.sol";

contract BurnedKevins is ERC721X, DefaultOperatorFilterer, Ownable {

    struct ContractData {
        string name;
        string description;
        string website;
        uint royalties;
        string royaltiesRecipient;
    }

    error TokenIsSoulBound();

    mapping(uint => bool) internal renderTokenOffChain;
    bool internal transfersLocked = true;

    address public ockContractAddress;
    address public operatorAddress;
    string public baseURI = "https://onchainkevin.com/api/v4/png/";

    ContractData public contractData = ContractData(
        "Burned Kevins",
        "Burned Kevins are only able to be received by burning an OnChainKevin to mint a Tier 2 Indelible Pro token.",
        "https://onchainkevin.com",
        1000,
        "0x29FbB84b835F892EBa2D331Af9278b74C595EDf1"
    );

    constructor() ERC721("BurnedKevins", "BDERP") {}

    function mint(uint[] calldata tokenIds, address recipient) external {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not authorized");
        for (uint i; i < tokenIds.length; i += 1) {
            require(!_exists(tokenIds[i]), "Token has already been claimed");
            _mint(recipient, tokenIds[i]);
        }
    }

    function setOperatorAddress(address operator) external onlyOwner {
        operatorAddress = operator;
    }

    function setOCKContractAddress(address ockAddress) external onlyOwner {
        ockContractAddress = ockAddress;
    }

    function getTokenImage(uint tokenId, string memory tokenHash) internal view returns (string memory) {
        IOnChainKevin renderer = IOnChainKevin(ockContractAddress);
        bool shouldRenderOffChain = bytes(baseURI).length > 0 && renderTokenOffChain[tokenId];
        return shouldRenderOffChain
          ? string.concat(baseURI, Strings.toString(tokenId), "?dna=", tokenHash)
          : renderer.hashToSVG(tokenHash);
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid token");

        IOnChainKevin renderer = IOnChainKevin(ockContractAddress);

        string memory tokenHash = renderer.tokenIdToHash(tokenId);

        return string.concat(
            "data:application/json,",
            '{"name":"Burned Kevin #',
            Strings.toString(tokenId),
            '","image":"',
            getTokenImage(tokenId, tokenHash),
            '","attributes":',
            renderer.hashToMetadata(tokenHash),
            "}"
        );
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"',
                    contractData.name,
                    '","description":"',
                    contractData.description,
                    '","external_link":"',
                    contractData.website,
                    '","seller_fee_basis_points":',
                    Strings.toString(contractData.royalties),
                    ',"fee_recipient":"',
                    contractData.royaltiesRecipient,
                    '"}'
                )
            )
        );
    }

    function setContractData(ContractData memory data)
        external
        onlyOwner
    {
        contractData = data;
    }

    function setRenderOfTokenId(uint tokenId, bool renderOffChain) external {
        require(msg.sender == ownerOf(tokenId), "Only the token owner can set the render method");
        renderTokenOffChain[tokenId] = renderOffChain;
    }

    function setTransfersLocked(bool locked) external onlyOwner {
        transfersLocked = locked;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert("Failed");
    }

    // SOULBOUND OVERRIDES

    function transferFrom(address from, address to, uint tokenId) public override onlyAllowedOperator(from) {
        if (from != address(0) && transfersLocked) {
            revert TokenIsSoulBound();
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public override onlyAllowedOperator(from) {
        if (from != address(0) && transfersLocked) {
            revert TokenIsSoulBound();
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        if (from != address(0) && transfersLocked) {
            revert TokenIsSoulBound();
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override {
        if (transfersLocked) {
            revert TokenIsSoulBound();
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public override {
        if (transfersLocked) {
            revert TokenIsSoulBound();
        }
        super.setApprovalForAll(operator, _approved);
    }
}