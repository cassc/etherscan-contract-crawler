// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <=0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ███████╗██████╗ ███████╗███████╗    ███████╗ █████╗  ██████╗██╗  ██╗
// ██╔════╝██╔══██╗██╔════╝██╔════╝    ╚══███╔╝██╔══██╗██╔════╝██║  ██║
// █████╗  ██████╔╝█████╗  █████╗        ███╔╝ ███████║██║     ███████║
// ██╔══╝  ██╔══██╗██╔══╝  ██╔══╝       ███╔╝  ██╔══██║██║     ██╔══██║
// ██║     ██║  ██║███████╗███████╗    ███████╗██║  ██║╚██████╗██║  ██║
// ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
                                                                    
contract ZachYachtClub is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    using Strings for uint256;

    address payable public withdrawalAddress;

    bool public publicMintingStatus;

    bool public revealedStatus;

    mapping(address => uint256) public addressMinted;

    string public metadataURLPrefix;

    string public metadataURLSuffix = ".json";

    string public notRevealedMetadataURL;

    uint256 public maxMintPerAddress = 10;

    uint256 public maxSupply = 5000;

    uint256 public price = 0.003 ether;

    uint256 public freeMintPerAddress = 1;

    constructor() ERC721A("Zach Yacht Club", "ZYC") {}

    // PUBLIC FUNCTION, WRITE CONTRACT FUNCTION //

    function publicMint(uint256 amount) public payable {
        require(publicMintingStatus == true, "Public mint status false, requires to be true");
        require(Address.isContract(msg.sender) == false, "Caller is a contract");
        require(addressMinted[msg.sender] + amount <= maxMintPerAddress, "Request exceeds max mint per address");
        require(totalSupply() + amount <= maxSupply, "Request exceeds max supply");
        if (addressMinted[msg.sender] + amount <= freeMintPerAddress) {
            _safeMint(msg.sender, amount);
            addressMinted[msg.sender] += amount;
        } else if (addressMinted[msg.sender] + amount > freeMintPerAddress && addressMinted[msg.sender] + amount <= maxMintPerAddress) {
            require(msg.value >= price * ((addressMinted[msg.sender] + amount) - freeMintPerAddress), "Not enough funds");
            _safeMint(msg.sender, amount);
            addressMinted[msg.sender] += amount;
        }
    }

    function airdrop(address[] calldata recipients, uint256 amount) public onlyOwner {
        require(totalSupply() + recipients.length * amount <= maxSupply, "Request exceeds max supply");
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amount);
        }
    }

    function mintInBatches(address recipient, uint256[] calldata nftQuantityForEachBatch) public onlyOwner {
        for (uint256 i = 0; i < nftQuantityForEachBatch.length; ++i) {
            require(totalSupply() + nftQuantityForEachBatch[i] <= maxSupply, "Request exceeds maxSupply");
            _safeMint(recipient, nftQuantityForEachBatch[i]);
        }
    }

    function setFreeMintPerAddress(uint256 freeMintAmount) public onlyOwner {
        require(freeMintAmount <= maxMintPerAddress, "freeMintAmount must be less than or equal to the maxMintPerAddress");
        freeMintPerAddress = freeMintAmount;
    }

    function setMaxMintPerAddress(uint256 maxMintAmount) public onlyOwner {
        require(maxMintAmount <= maxSupply, "maxMintAmount must be less than or equal to the maxSupply");
        maxMintPerAddress = maxMintAmount;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= totalSupply(), "newMaxSupply must be greater than or equal to the totalSupply");
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
        publicMintingStatus = status;
    }

    function setRevealedStatus(bool status) public onlyOwner {
        revealedStatus = status;
    }

    function setWithdrawalAddress(address newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = payable(newWithdrawalAddress);
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(withdrawalAddress).call{ value: address(this).balance }("");
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

    // GETTER FUNCTIONS, READ CONTRACT FUNCTIONS //

    /**
     * @notice Function queries and returns all the NFT tokenIds owned by an address.
     * Enter the address in the owner field.
     * Click on query after filling out the field.
     */
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

    /**
     * @notice Function scans and returns all the NFT tokenIds owned by an address from startTokenId till stopTokenId.
     * startTokenId must be equal to or greater than zero and smaller than stopTokenId.
     * stopTokenId must be greater than startTokenId and smaller or equal to totalSupply.
     * Enter the tokenId from where the scan is to be started in the startTokenId field.
     * Enter the tokenId till where the scan is to be done in the stopTokenId field.
     * For example, if startTokenId is 10 and stopTokenId is 80, the function will return all the NFT tokenIds owned by the address from tokenId 10 till tokenId 80.
     * Click on query after filling out all the fields.
     */
    function walletOfOwnerInRange(address owner, uint256 startTokenId, uint256 stopTokenId) public view returns (uint256[] memory ownedTokenIds) {
        require(startTokenId >= 0 && startTokenId < stopTokenId, "startTokenId must be equal to or greater than zero and smaller than stopTokenId");
        require(stopTokenId > startTokenId && stopTokenId <= totalSupply(), "stopTokenId must be greater than startTokenId and smaller or equal to totalSupply");
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

    // OVERRIDDEN GETTER FUNCTIONS, READ CONTRACT FUNCTIONS //

    /**
     * @notice Function queries and returns the URI for a NFT tokenId.
     * Enter the tokenId of the NFT in tokenId field.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealedStatus == false) {
            return notRevealedMetadataURL;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metadataURLSuffix)) : "";
    }

    // INTERNAL FUNCTIONS //

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURLPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}