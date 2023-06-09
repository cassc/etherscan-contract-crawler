// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <=0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// ▒█████   ██▀███  ▓█████▄ ▓█████  ██▀███      ▒█████    █████▒   ▄▄▄█████▓ ██░ ██ ▓█████     ▒█████   ▄████▄   ▄████▄   █    ██  ██▓  ▄▄▄█████▓
//▒██▒  ██▒▓██ ▒ ██▒▒██▀ ██▌▓█   ▀ ▓██ ▒ ██▒   ▒██▒  ██▒▓██   ▒    ▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▒██▒  ██▒▒██▀ ▀█  ▒██▀ ▀█   ██  ▓██▒▓██▒  ▓  ██▒ ▓▒
//▒██░  ██▒▓██ ░▄█ ▒░██   █▌▒███   ▓██ ░▄█ ▒   ▒██░  ██▒▒████ ░    ▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██░  ██▒▒▓█    ▄ ▒▓█    ▄ ▓██  ▒██░▒██░  ▒ ▓██░ ▒░
//▒██   ██░▒██▀▀█▄  ░▓█▄   ▌▒▓█  ▄ ▒██▀▀█▄     ▒██   ██░░▓█▒  ░    ░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ▒██   ██░▒▓▓▄ ▄██▒▒▓▓▄ ▄██▒▓▓█  ░██░▒██░  ░ ▓██▓ ░ 
//░ ████▓▒░░██▓ ▒██▒░▒████▓ ░▒████▒░██▓ ▒██▒   ░ ████▓▒░░▒█░         ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░ ████▓▒░▒ ▓███▀ ░▒ ▓███▀ ░▒▒█████▓ ░██████▒▒██▒ ░ 
//░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒▓  ▒ ░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ▒░▒░▒░  ▒ ░         ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░   ░ ▒░▒░▒░ ░ ░▒ ▒  ░░ ░▒ ▒  ░░▒▓▒ ▒ ▒ ░ ▒░▓  ░▒ ░░   
//  ░ ▒ ▒░   ░▒ ░ ▒░ ░ ▒  ▒  ░ ░  ░  ░▒ ░ ▒░     ░ ▒ ▒░  ░             ░     ▒ ░▒░ ░ ░ ░  ░     ░ ▒ ▒░   ░  ▒     ░  ▒   ░░▒░ ░ ░ ░ ░ ▒  ░  ░    
//░ ░ ░ ▒    ░░   ░  ░ ░  ░    ░     ░░   ░    ░ ░ ░ ▒   ░ ░         ░       ░  ░░ ░   ░      ░ ░ ░ ▒  ░        ░         ░░░ ░ ░   ░ ░   ░      
//    ░ ░     ░        ░       ░  ░   ░            ░ ░                       ░  ░  ░   ░  ░       ░ ░  ░ ░      ░ ░         ░         ░  ░       
 //                  ░                                                                                 ░        ░                                
//
//                   ░                                                                                 ░        ░                                
    
                                                                                                          

contract OOTC is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    
    using Strings for uint256;

    // STATE VARIABLES //

    /// @notice Funds withdrawal address.
    address payable public withdrawalAddress;

    /// @notice Boolean for enabling and disabling public minting.
    bool public publicMintingStatus;

    /// @notice Boolean for whether collection is revealed or not.
    bool public revealedStatus;

    /// @notice Mapping for number of NFTs minted by an address.
    mapping(address => uint256) public addressMinted;

    /// @notice Revealed metadata url prefix.
    string public metadataURLPrefix;
    
    /// @notice Revealed metadata url suffix.
    string public metadataURLSuffix = ".json";

    /// @notice Not revealed metadata url.
    string public notRevealedMetadataURL;

    /// @notice Max mint per wallet.
    uint256 public maxMintPerAddress = 6;

    /// @notice Collection max supply.
    uint256 public maxSupply = 5000;

    /// @notice Price of one NFT.
    uint256 public price = 0.005 ether;

    /// @notice Free mint per wallet.
    uint256 public freeMintPerAddress = 1;

    constructor() ERC721A("Order of the Occult","OC") {}

    // PUBLIC FUNCTION, WRITE CONTRACT FUNCTION //

    /**
     * @notice Public payable function.
     * Function mints a specified amount of tokens to the caller's address.
     * Requires public minting status to be true.
     * Requires sufficient ETH to execute.
     * Enter the amount of tokens to be minted in the amount field.
     */
    function publicMint(uint256 amount) public payable {
       require(publicMintingStatus == true, "Public mint status false, requires to be true");
       require(Address.isContract(msg.sender) == false, "Caller is a contract");
       require(addressMinted[msg.sender] + amount <= maxMintPerAddress, "Request exceeds max mint per address");
       require(totalSupply() + amount <= maxSupply, "Request exceeds max supply");
       if (addressMinted[msg.sender] + amount <= freeMintPerAddress) {
          _safeMint(msg.sender, amount);
          addressMinted[msg.sender] += amount;
        }
        else if (addressMinted[msg.sender] + amount > freeMintPerAddress && addressMinted[msg.sender] + amount <= maxMintPerAddress) {
            require(msg.value >= price * ((addressMinted[msg.sender] + amount) - freeMintPerAddress), "Not enough funds");
            _safeMint(msg.sender, amount);
            addressMinted[msg.sender] += amount;
        }
    }

    // SMART CONTRACT OWNER ONLY FUNCTIONS, WRITE CONTRACT FUNCTIONS //

    /**
     * @notice Smart contract owner only function.
     * Function airdrops a specified amount of tokens to an array of addresses.
     * Enter the recepients in an array form like this [address1,address2,address3] in the recipients field and enter the amount of NFTs to be airdropped to each recipient in the amount field.
     */
    function airdrop(address[] calldata recipients, uint256 amount) public onlyOwner {
        require(totalSupply() + recipients.length * amount <= maxSupply, "Request exceeds max supply");
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amount);
        }
    }

    /** 
     * @notice Smart contract owner only function.
     * Function can mint different quantities of NFTs in batches to the recipient.
     * Enter the recipient's address in the recipient field.
     * Enter the NFT quantity for each batch in an array form in the nftQuantityForEachBatch field.
     * For example if the nftQuantityForEachBatch array is like this [30,50,70] in total 150 NFTs would be minted in batches of 30, 50 and 70.
     */
    function mintInBatches(address recipient, uint256[] calldata nftQuantityForEachBatch) public onlyOwner {
        for (uint256 i = 0; i < nftQuantityForEachBatch.length; ++i) {   
            require(totalSupply() + nftQuantityForEachBatch[i] <= maxSupply, "request exceeds maxSupply");
            _safeMint(recipient, nftQuantityForEachBatch[i]);
        }
    }

    /**
     * @notice Smart contract owner only function.
     * Function sets the free mint per address amount.
     * Enter the new free mint per address in the freeMintAmount field.
     * The freeMintAmount must be less than or equal to the maxMintPerAddress.
     */
    function setFreeMintPerAddress(uint256 freeMintAmount) public onlyOwner {
        require(freeMintAmount <= maxMintPerAddress, "freeMintAmount must be less than or equal to the maxMintPerAddress");
        freeMintPerAddress = freeMintAmount;
    }  

    /**
     * @notice Smart contract owner only function.
     * Function sets the max mint per address amount.
     * Enter the new max mint per address in the maxMintAmount field.
     * The maxMintAmount must be less than or equal to the maxSupply.
     */
    function setMaxMintPerAddress(uint256 maxMintAmount) public onlyOwner {
        require(maxMintAmount <= maxSupply, "maxMintAmount must be less than or equal to the maxSupply");
        maxMintPerAddress = maxMintAmount;
    }

    /**
     * @notice Smart contract owner only function.
     * Function sets a new max supply of tokens which can be minted from the contract.
     * Enter the new max supply in the newMaxSupply field.
     * The newMaxSupply must be greater than or equal to the totalSupply.
     */
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= totalSupply(), "newMaxSupply must be greater than or equal to the totalSupply");
        maxSupply = newMaxSupply;
    }

    /**
     * @notice Smart contract owner only function.
     * Function updates the metadata url prefix.
     * Enter the new metadata url prefix in the newMetadataURLPrefix field.
     */
    function setMetadataURLPrefix(string memory newMetadataURLPrefix) public onlyOwner {
        metadataURLPrefix = newMetadataURLPrefix;
    }

    /**
     * @notice Smart contract owner only function.
     * Function updates the metadata url suffix.
     * Enter the new metadata url suffix in the newMetadataURLSuffix field.
     */
    function setMetadataURLSuffix(string memory newMetadataURLSuffix) public onlyOwner {
        metadataURLSuffix = newMetadataURLSuffix;
    }

    /**
     * @notice Smart contract owner only function.
     * Function updates the not revealed metadata url.
     * Enter the new not revealed metadata url in the newNotRevealedMetadataURL field.
     */
    function setNotRevealedMetadataURL(string memory newNotRevealedMetadataURL) public onlyOwner {
        notRevealedMetadataURL = newNotRevealedMetadataURL;
    }

    /**
     * @notice Smart contract owner only function.
     * Function updates the price for minting a single NFT.
     * Enter the new price in the newPrice field, entered price must be in wei, check ether to wei conversion.
     */
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /**
     * @notice Smart contract owner only function.
     * Function sets the public minting status.
     * Enter the word true in the status field to enable public minting.
     * Enter the word false in the status field to disable public minting.
     */
    function setPublicMintingStatus(bool status) public onlyOwner {
        publicMintingStatus = status;
    }

    /**
     * @notice Smart contract owner only function.
     * Function sets the revealed status for the collection.
     * Enter the word true in the status field to reveal the collection.
     * Enter the word false in the status field to hide or unreveal the collection.
     */
    function setRevealedStatus(bool status) public onlyOwner {
        revealedStatus = status;
    }

    /** 
     * @notice Smart contract owner only function.
     * Function sets the withdrawal address for the funds in the smart contract.
     * Enter the new withdrawal address in the newWithdrawalAddress field.
     * To withdraw to a payment splitter smart contract,
     * enter the payment splitter smart contract's contract address in the newWithdrawalAddress field. 
     */ 
    function setWithdrawalAddress(address newWithdrawalAddress) public onlyOwner {
        withdrawalAddress = payable(newWithdrawalAddress);
    }

    /**
     * @notice Smart contract owner only function.
     * Function withdraws the funds in the smart contract to the withdrawal address.
     * Enter the number 0 in the withdraw field to withdraw the funds successfully.
     */
    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(withdrawalAddress).call{value: address(this).balance}("");
        require(success);
    }

    /**
     * @notice Smart contract owner only function.
     * Function withdraws the ERC20 token amount accumulated in the smart contract to the entered account address.
     * Enter the ERC20 token contract address in the token field, the address to which the accumulated ERC20 tokens would be transferred in the account field and the amount of accumulated ERC20 tokens to be transferred in the amount field.
     */
    function withdrawERC20(IERC20 token, address account, uint256 amount) public onlyOwner {
        SafeERC20.safeTransfer(token, account, amount);
    }

    // OVERRIDDEN PUBLIC WRITE CONTRACT FUNCTIONS: OpenSea's Royalty Filterer Implementation. //

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
        assembly{mstore(ownedTokenIds, currentTokenIndex)}
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
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metadataURLSuffix))
        : "";
    }

    // INTERNAL FUNCTIONS //

    /// @notice Internal function which is called by the tokenURI function.
    function _baseURI() internal view virtual override returns (string memory) {
        return metadataURLPrefix;
    }

    /// @notice Internal function which ensures the first minted NFT has tokenId as 1.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}