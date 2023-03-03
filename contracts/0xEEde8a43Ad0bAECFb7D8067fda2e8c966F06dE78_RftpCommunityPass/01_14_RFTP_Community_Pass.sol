//SPDX-License-Identifier: MIT

/*************************************
*                                    *
*     developed by brandneo GmbH     *
*        https://brandneo.de         *
*                                    *
**************************************/

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RftpCommunityPass is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, DefaultOperatorFilterer {

    enum ContractStatus {
        Claim,
        Paused
    }

    string  public baseURI;
    bytes32 public merkleRoot;
    address public burnContract;

    ContractStatus public status = ContractStatus.Paused;

    uint256 public maxSupply = 3333;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier callerIsBurnContract() {
        require(msg.sender == burnContract, "The caller is not the burn contract");
        _;
    }

    constructor(string memory contractBaseURI) ERC721A ("RFTP COMMUNITY PASS", "RFTPC") {
        baseURI = contractBaseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function isWalletWhitelisted(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account, allowedQuantity));
    }

    function generateMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setContractStatus(ContractStatus _status) external onlyOwner {
        status = _status;
    }

    function mint(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) external callerIsUser {
        require(status == ContractStatus.Claim, "Claim not available");
        require(_totalMinted() + quantity <= maxSupply, "Not enough supply");
        require(isWalletWhitelisted(msg.sender, allowedQuantity, proof), "Wallet verification failed");
        require(_numberMinted(msg.sender) + quantity <= allowedQuantity, "Exceeds allowed wallet quantity");
        _safeMint(msg.sender, quantity);
    }

    function getQuantityMintedForAddress(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function setBurnContract(address _burnContract) external onlyOwner {
        burnContract = _burnContract;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function burn(uint256 tokenId) public override callerIsBurnContract {
        _burn(tokenId, false);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        address owner = payable(msg.sender);

        bool success;

        (success,) = owner.call{value : (amount)}("");
        require(success, "Transaction Unsuccessful");
    }

    /* Overrides */

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(to) {
        super.approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}