// SPDX-License-Identifier: MIT
// Creator: OrigamasksTeam

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

abstract contract NewKitContract {
    function mintNewKits(
        address to_,
        uint256[] memory tokenIds_
    ) public payable virtual;
}

error NotAuthorized();
error IncorrectPrice();
error ZeroAddress();
error NotAvailableYet();

contract OrigamasksSpecialKit is
    ERC721A,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    constructor(
        address payable deployerAddress_,
        string memory mainURI_,
        string memory contractMetadataURI_
    ) ERC721A("Origamasks Special Kit", "SPECIALKIT") {
        setWithdrawAddress(deployerAddress_);
        setRoyaltyInfo(500);
        setBaseTokenURI(mainURI_);
        setContractMetadataURI(contractMetadataURI_);
    }

    string private baseTokenURI;
    string private contractMetadataURI;
    address public origamasksAddress =
        0xf132f2c8F1EedE27070E0850775436A0E6e7268A;
    address public newKitContractAddress;

    uint256 public claimPrice;
    uint256 public mintNewKitPrice;
    bool public newKitAvailable;
    bool public sameTokenURI = true;

    function mintReward(
        address to_,
        uint256 tokenId_
    ) public payable returns (uint256) {
        if (msg.sender != origamasksAddress) revert NotAuthorized();
        if (msg.value != claimPrice) revert IncorrectPrice();

        _mint(to_, 1);

        return tokenId_;
    }

    function mintNewKits(uint256[] memory tokenIds_) public payable {
        if (!newKitAvailable) revert NotAvailableYet();

        uint256 tokenIdsCount = tokenIds_.length;
        if (msg.value != mintNewKitPrice * tokenIdsCount) {
            revert IncorrectPrice();
        }

        // BURN
        for (uint256 i = 0; i < tokenIdsCount; i++) {
            _burn(tokenIds_[i]);
        }

        // MINT NEW KIT
        NewKitContract newKitContract = NewKitContract(newKitContractAddress);
        newKitContract.mintNewKits{value: msg.value}(msg.sender, tokenIds_);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        if (sameTokenURI) {
            return baseURI;
        } else {
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                    : "";
        }
    }

    function setBaseTokenURI(string memory baseTokenURI_) public onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setSameTokenURI(bool same_) public onlyOwner {
        sameTokenURI = same_;
    }

    function setOrigamasksAddress(address newAddress_) public onlyOwner {
        origamasksAddress = newAddress_;
    }

    function setNewKitContractAddress(address newAddress_) public onlyOwner {
        newKitContractAddress = newAddress_;
    }

    function setClaimPrice(uint256 claimPrice_) public onlyOwner {
        claimPrice = claimPrice_;
    }

    function setMintNewKitPrice(uint256 mintNewKitPrice_) public onlyOwner {
        mintNewKitPrice = mintNewKitPrice_;
    }

    function setNewKitAvailable(bool available_) public onlyOwner {
        newKitAvailable = available_;
    }

    function setContractMetadataURI(
        string memory contractMetadataURI_
    ) public onlyOwner {
        contractMetadataURI = contractMetadataURI_;
    }

    function setWithdrawAddress(
        address payable withdrawAddress_
    ) public onlyOwner {
        if (withdrawAddress_ == address(0)) revert ZeroAddress();
        withdrawAddress = withdrawAddress_;
    }

    function setRoyaltyInfo(uint96 royaltyPercentage_) public onlyOwner {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(withdrawAddress, royaltyPercentage_);
    }

    // WITHDRAW

    address payable public withdrawAddress;

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    // ERC721A

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /* OPERATOR FILTERER */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}