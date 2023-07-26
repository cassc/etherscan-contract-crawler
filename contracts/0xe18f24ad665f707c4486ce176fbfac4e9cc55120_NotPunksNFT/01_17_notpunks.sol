// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NotPunksNFT is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

   using Strings for uint256;

address payable public withdrawalWallet;

bool public isPublicMintingEnabled;

bool public isRevealed;

mapping(address => uint256) public addressMinted;

string public metadataURLPrefix;

string public metadataURLSuffix = ".json";

string public notRevealedMetadataURL;

uint256 public maxMintPerAddress = 20;

uint256 public maxSupply = 9999;

uint256 public price = 0.002 ether;

uint256 public freeMintPerAddress = 3;

constructor() ERC721A("Not Punks", "Not Punks") {}

function publicMint(uint256 amount) public payable {
    require(isPublicMintingEnabled == true, "Public mint status false, requires to be true");
    require(Address.isContract(msg.sender) == false, "Caller is a contract");
    require(addressMinted[msg.sender] + amount <= maxMintPerAddress, "Request exceeds max mint per address");
    require(totalSupply() + amount <= maxSupply, "Request exceeds max supply");

    uint256 remainingFreeMint = freeMintPerAddress - addressMinted[msg.sender];
    uint256 mintCount = 0;

    if (remainingFreeMint > 0 && amount <= remainingFreeMint) {
        _safeMint(msg.sender, amount);
        mintCount = amount;
    } else {
        uint256 requiredPaymentMint = amount - remainingFreeMint;
        require(msg.value >= price * requiredPaymentMint, "Insufficient funds");
        
        if (remainingFreeMint > 0) {
            _safeMint(msg.sender, remainingFreeMint);
            mintCount = remainingFreeMint;
        }
        
        if (requiredPaymentMint > 0) {
            _safeMint(msg.sender, requiredPaymentMint);
            mintCount += requiredPaymentMint;
        }
    }

    addressMinted[msg.sender] += mintCount;
}

function airdrop(address[] calldata recipients, uint256 amount) public onlyOwner {
    require(totalSupply() + recipients.length * amount <= maxSupply, "Request exceeds max supply");
    for (uint256 i = 0; i < recipients.length; i++) {
        _safeMint(recipients[i], amount);
    }
}

function mintInBatches(address recipient, uint256[] calldata nftQuantityForEachBatch) public onlyOwner {
    for (uint256 i = 0; i < nftQuantityForEachBatch.length; ++i) {
        require(totalSupply() + nftQuantityForEachBatch[i] <= maxSupply, "Request exceeds max supply");
        _safeMint(recipient, nftQuantityForEachBatch[i]);
    }
}

function setFreeMintPerAddress(uint256 freeMintAmount) public onlyOwner {
    require(freeMintAmount <= maxMintPerAddress, "Invalid free mint amount");
    freeMintPerAddress = freeMintAmount;
}

function setMaxMintPerAddress(uint256 maxMintAmount) public onlyOwner {
    require(maxMintAmount <= maxSupply, "Invalid max mint amount");
    maxMintPerAddress = maxMintAmount;
}

function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    require(newMaxSupply >= totalSupply(), "Invalid new max supply");
    maxSupply = newMaxSupply;
}

function setMetadataURLPrefix(string memory newMetadataURLPrefix) public onlyOwner {
    metadataURLPrefix = newMetadataURLPrefix;
}

function setMetadataURLSuffix(string memory newMetadataURLSuffix) public onlyOwner {
    metadataURLSuffix = newMetadataURLSuffix;
}

function setNotRevealedMetadataURL(string memory newNotRevealedMetadataURL) public onlyOwner {
    notRevealedMetadataURL = newNotRevealedMetadataURL;
}

function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
}

function setPublicMintingStatus(bool status) public onlyOwner {
    isPublicMintingEnabled = status;
}

function setRevealedStatus(bool status) public onlyOwner {
    isRevealed = status;
}

function setWithdrawalWallet(address newWithdrawalWallet) public onlyOwner {
    withdrawalWallet = payable(newWithdrawalWallet);
}

function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
}

function withdrawERC20(IERC20 token, address account, uint256 amount) public onlyOwner {
    SafeERC20.safeTransfer(token, account, amount);
}

function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
}

function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
}

function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
}

function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
}

function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
}

function walletOfOwner(address owner) public view returns (uint256[] memory ownedTokenIds) {
    ownedTokenIds = new uint256[](balanceOf(owner));
    uint256 currentTokenId = 1;
    uint256 currentTokenIndex = 0;
    while (currentTokenIndex < totalSupply() && currentTokenId <= totalSupply()) {
        if (_exists(currentTokenId) && ownerOf(currentTokenId) == owner) {
            ownedTokenIds[currentTokenIndex] = currentTokenId;
            currentTokenIndex++;
        }
        currentTokenId++;
    }
    return ownedTokenIds;
}

function walletOfOwnerInRange(address owner, uint256 startTokenId, uint256 stopTokenId) public view returns (uint256[] memory ownedTokenIds) {
    require(startTokenId >= 0 && startTokenId < stopTokenId, "Invalid range");
    require(stopTokenId > startTokenId && stopTokenId <= totalSupply(), "Invalid range");
    ownedTokenIds = new uint256[](stopTokenId - startTokenId + 1);
    uint256 currentTokenId = startTokenId;
    uint256 currentTokenIndex = 0;
    while (currentTokenIndex < stopTokenId && currentTokenId <= stopTokenId) {
        if (_exists(currentTokenId) && ownerOf(currentTokenId) == owner) {
            ownedTokenIds[currentTokenIndex] = currentTokenId;
            currentTokenIndex++;
        }
        currentTokenId++;
    }
    assembly { mstore(ownedTokenIds, currentTokenIndex) }
    return ownedTokenIds;
}

function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Nonexistent token");
    if (!isRevealed) {
        return notRevealedMetadataURL;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metadataURLSuffix)) : "";
}

function _baseURI() internal view virtual override returns (string memory) {
    return metadataURLPrefix;
}

function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
}
}