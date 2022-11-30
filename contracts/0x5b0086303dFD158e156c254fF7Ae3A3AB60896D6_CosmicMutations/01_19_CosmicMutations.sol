// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./CosmicMutationVoucherSigner.sol";
import "./CosmicMutationVoucher.sol";

// Cosmic Mutations v1.3

contract CosmicMutations is DefaultOperatorFilterer, ERC721Enumerable, Ownable, CosmicMutationVoucherSigner {
    using Address for address;

    // Mint Controls
    bool public claimActive = true;

    // Token Supply
    uint256 public MAX_SUPPLY = 4444;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    mapping (uint => uint) public claimedVouchers;

    // Contract Construction
    constructor(string memory newBaseURI, address voucherSigner)
        ERC721("Cosmic Mutations", "CM")
        CosmicMutationVoucherSigner(voucherSigner)
    {
        setBaseURI(newBaseURI);
    }

    // ================ Mint Functions ================ //

    function mintMutation(CosmicMutationVoucher.Voucher calldata v) public {
        require(claimActive, "Claim period not active.");
        require(CosmicMutationVoucher.validateVoucher(v, getVoucherSigner()),"Invalid Voucher - Voucher details does NOT match voucher assignment");
        require(v.to == msg.sender, "Invalid Voucher - Sender does NOT match voucher assignment");
        require(claimedVouchers[v.voucherId] < 1, "Mutant already minted.");
        require(totalSupply() + 1 <= MAX_SUPPLY, "All Mutants Claimed");
        claimedVouchers[v.voucherId] += 1;
        _safeMint(msg.sender, v.voucherId);
    }

    // Validate Voucher
    function validateVoucher(CosmicMutationVoucher.Voucher calldata v)
        external view returns (bool)
    {
        return CosmicMutationVoucher.validateVoucher(v, getVoucherSigner());
    }

    // ================ Only Owner Functions ================ //

    // Admin Mint Function
    function adminMint(address _to, uint256 _tokenID) external onlyOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY,"All mutants have been claimed.");
        _safeMint(_to, _tokenID);
    }

    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Claim On/Off
    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }

    // ================ Opensea Operator Filter Overrides ================ //

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}