// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./CentWhitelist/CentBaseWhitelistBETA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

///@title Centaurify - NFT Minting Tool - CentStore.
///@author @Dadogg80, VBS - Viken Blockchain Solutions AS.
///@notice This is the base smart contract used to mint NFT's for Centaurify's Marketplace BETA launch.

///@dev This is a closed BETA and the public are not able to use the mint() functions.
///@dev The smart contract support OpenSea's { contractURI } method for query contract metadata.
///@dev This contract support ERC2981 Royalty Standard with the { royaltyInfo } method.          


///@custom:security-contact [email protected]
contract CentStore is
    ERC721,
    ERC721URIStorage,
    ERC721Royalty,
    Ownable,
    CentBaseWhitelistBETA,
    DefaultOperatorFilterer
{   
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    ///@dev The max royalty fee is set to 10% of sales price.
    uint96 public constant MAX_ROYALTY_FEE = 1000;
    uint96 public constant MAX_BATCH_MINT = 25;

    ///@dev The account to receive the funds from the rF (ReleaseFunds) function.
    address payable public treasury;

    ///@dev Used by OpenSea to query contract and royalty information.
    string internal contractUri;
    string internal _name;
    string internal _symbol;

    ///@dev royaltyList contain all deployed paymentsplitter addresses.
    address[] private royaltyList;

    modifier royaltyAmount(uint96 royaltyFee) {
        if (royaltyFee > MAX_ROYALTY_FEE)
            revert Code_Royalty_fee(royaltyFee, MAX_ROYALTY_FEE);
        _;
    }

    modifier costs(uint256 mintingFee) {
        if (msg.value != mintingFee) revert LowValue(msg.value, mintingFee);
        _;
    }

    modifier maxMinted(uint256 amount) {
        if (amount > MAX_BATCH_MINT) revert MaxAmount(amount, MAX_BATCH_MINT);
        _;
    }

    error Code_Royalty_fee(uint96 requested, uint96 max_available);
    error LowValue(uint256 value, uint256 mintingFee);
    error LowBalance(uint256 message);
    error MaxAmount(uint256 amount, uint256 MAX_BATCH_MINT);
    error TxFailed();
    error NoTreasury();

    event NewRoyaltySplitter(
        address indexed royaltySplitter,
        uint256 royaltyIndex
    );
    event Minted(
        uint256 indexed tokenId,
        string tokenURI,
        address indexed receiver,
        address indexed royaltyReceiver,
        uint96 royaltyFee
    );
    event Mint(
        address indexed receiver,
        address indexed royaltyReceiver,
        string tokenURI,
        uint256 royaltyFee
    );
    event BatchMintedURIs(
        address indexed receiver,
        address indexed royaltyReceiver,
        uint256 mintedAmount,
        uint256 royaltyFee
    );
    event BatchMinted(
        address indexed receiver,
        address indexed royaltyReceiver,
        uint256 mintedAmount,
        string tokenURI
    );
    event NewTokenAndSplitter(
        uint256 indexed tokenId,
        string tokenURI,
        address indexed receiver,
        address indexed royaltySplitter,
        uint256 royaltyIndex
    );
    event NewNameAndSymbol(string name, string symbol);
    event FundsReleased(uint256 amount);
    event TreasuryUpdated(address treasury);

    ///@dev _contractURI Used by OpenSea's URI method.
    ///@dev ref. { https://docs.opensea.io/docs/contract-level-metadata }
    constructor(address payable _treasury) ERC721("", "") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        
        _name = "CentMintStore";
        _symbol = "CMS";
        treasury = _treasury;
    }

    /* ---------------  EXTERNAL FUNCTIONS  --------------------------------------------------------------------- */

    /// @dev See {IERC721Metadata-name}.
    function name() public view override(ERC721) returns (string memory) {
        return _name;
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view override(ERC721) returns (string memory) {
        return _symbol;
    }

    ///@notice Mint a new token and set the token royalty.
    ///@dev Can only be called by the MINTER_ROLE during the BETA release.
    ///@param mintingFee The Centaurify minting fee, $5 calculated by the frontend.
    ///@param _tokenURI The uri pointing to the metadata of this token.
    ///@param _recipients Array of accounts to split the royalty amount between.
    ///@param _shares Array of shares correlating to the recipient array. total shares should amount to 100% shares.
    ///@dev Example of shares inputs: 5 = 5%, 25 = 25%, 50 = 50%, 100 = 100%, etc.
    ///@param royaltyFee The royalty fee as percentage points. 1000 = 10% .
    function mintAndDeployPaymentSplitter(
        uint256 mintingFee,
        string memory _tokenURI,
        address[] memory _recipients,
        uint256[] memory _shares,
        uint96 royaltyFee
    )
        external
        payable
        onlyWhitelistedUsers
        costs(mintingFee)
        royaltyAmount(royaltyFee)
        returns (address payable royaltySplitter)
    {
        ///@dev Uses PaymentSplitter.sol to splitt royalty sum between accounts.
        ///@dev the tokenId is used as salt for deploying the new royaltySplitter.
        (royaltySplitter) = _deployPaymentSplitter(
            _recipients,
            _shares,
            _tokenIdCounter.current()
        );
        _mint(_msgSender(), _tokenURI, royaltySplitter, royaltyFee);

        emit NewTokenAndSplitter(
            _tokenIdCounter.current(),
            _tokenURI,
            _msgSender(),
            royaltySplitter,
            royaltyList.length
        );
        return royaltySplitter;
    }

    ///@notice Mint a batch of new tokens from a list of Token URIs, and set the token royalty for each of the tokens.
    ///@dev Can only be called by whitelisted accounts during the BETA release.
    ///@dev ATT. Costs $5 worth of ETHER.
    ///@param mintingFee The Centaurify minting fee, $5 in ETH, calculated by the frontend. Example: Mint 5 tokens, costs $5 = 5$;
    ///@param _tokenURIs The array of tokenURIs pointing to the metadata of these tokens.
    ///@param royaltyAddress The account to receive the royalty amount from secondary marketsales.(This can be a splitter address)
    ///@param royaltyFee The royalty fee as percentage points. 1000 = 10% .
    function batchMintURIs(
        uint256 mintingFee,
        string[] calldata _tokenURIs,
        address payable royaltyAddress,
        uint96 royaltyFee
    )
        external
        payable
        onlyWhitelistedUsers
        costs(mintingFee)
        maxMinted(_tokenURIs.length)
        royaltyAmount(royaltyFee)
    {
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            _mint(_msgSender(), _tokenURIs[i], royaltyAddress, royaltyFee);
        }
        emit BatchMintedURIs(
            _msgSender(),
            royaltyAddress,
            _tokenURIs.length,
            royaltyFee
        );
    }

    ///@notice Mint a batch of nfts from one TokenURI, and set the token royalty. (AKA - Many of One).
    ///@dev Can only be called by whitelisted accounts during the BETA release.
    ///@param mintingFee The Centaurify minting fee, $5 calculated by the frontend. Example: Mint 5 tokens, costs $5 = 5$;
    ///@param _tokenURI The uri pointing to the metadata of this token.
    ///@param amount The amount of tokens to batch Mint.
    ///@param royaltyAddress The account to receive the royalty amount from secondary market sales.
    ///@param royaltyFee The royalty fee as percentage points. 1000 = 10% .
    function batchMint(
        uint256 mintingFee,
        string memory _tokenURI,
        uint256 amount,
        address payable royaltyAddress,
        uint96 royaltyFee
    )
        external
        payable
        onlyWhitelistedUsers
        costs(mintingFee)
        maxMinted(amount)
        royaltyAmount(royaltyFee)
    {
        for (uint256 i = 0; i < amount; i++) {
            _mint(_msgSender(), _tokenURI, royaltyAddress, royaltyFee);
        }
        emit BatchMinted(_msgSender(), royaltyAddress, amount, _tokenURI);
    }

    ///@notice Method returns the total amount of minted tokens.
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    ///@notice Burn an NFT.
    ///@dev restricted to only Owner.
    ///@param tokenId Id of the token to burn.
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    ///@notice Required to support OpenSea's royalty method.
    ///@return String with the uri to the metadata json file.
    function contractURI() external view returns (string memory) {
        return contractUri;
    }

    ///@notice Get RoyaltyList.
    ///@dev restricted to only Owner.
    function getRoyaltyList()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return royaltyList;
    }

    ///@notice Get treasury.
    ///@dev restricted to only Owner.
    function getTreasury() external view returns (address) {
        return treasury;
    }

    ///@notice Deploys a OpenZeppelin PaymentSplitter.sol to allow split royalty between multiple accounts.
    ///@dev the tokenId is used as salt for deploying the new royaltySplitter.
    ///@param recipients Array of accounts to split the royalty amount between.
    ///@param shares Array of shares correlating to the recipient array. Total shares should amount to 100% shares.
    ///@param salt Random number.
    ///@dev Example of shares inputs: 5 = 5%, 25 = 25%, 50 = 50%, 100 = 100%, etc.
    function deployPaymentSplitter(
        address[] memory recipients,
        uint256[] memory shares,
        uint256 salt
    ) external onlyWhitelistedUsers returns (address payable royaltySplitter) {
        return _deployPaymentSplitter(recipients, shares, salt);
    }

    /* ---------------  PUBLIC FUNCTIONS  --------------------------------------------------------------------- */

    ///@notice Mint a single new token.
    ///@dev Can only be called by whitelisted accounts during the BETA release.
    ///@param mintingFee The Centaurify minting fee, $5 calculated by the frontend.
    ///@param _tokenURI The uri pointing to the metadata of this token.
    ///@param royaltyAddress The account to receive the royalty amount from secondary market sales.
    ///@param royaltyFee The royalty fee as percentage points. 1000 = 10%
    ///@dev Remember to add the Minting tool account to the whitelisted users.
    function mintSingle(
        uint256 mintingFee,
        string memory _tokenURI,
        address payable royaltyAddress,
        uint96 royaltyFee
    )
        public
        payable
        onlyWhitelistedUsers
        costs(mintingFee)
        royaltyAmount(royaltyFee)
    {
        _mint(_msgSender(), _tokenURI, royaltyAddress, royaltyFee);
        emit Mint(_msgSender(), royaltyAddress, _tokenURI, royaltyFee);
    }

    ///@notice Method returns an URI, where the token metadata is located.
    ///@param tokenId The id of the token.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ///@notice Used to set the contract URI for OpenSea metadata.
    ///@param _contractUri The URI where the contract metadata is located.
    function setContractURI(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    /* ---------------  INTERNAL FUNCTIONS  --------------------------------------------------------------------- */

    ///@notice Internal method used to burn a token.
    ///@param tokenId The id of the token to burn.
    ///@dev Only the token owner can burn a token.
    function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function _mint(
        address to,
        string memory _tokenURI,
        address payable royaltyAddress,
        uint96 royaltyFee
    ) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _setTokenRoyalty(tokenId, royaltyAddress, royaltyFee);
        emit Minted(tokenId, _tokenURI, to, royaltyAddress, royaltyFee);
    }

    ///@notice Internal method for deploying a paymentsplitter smartcontract.
    ///@param recipients Array of accounts to split the royalty amount between.
    ///@param shares Array of royaltyFeesInBips correlating to the recipient array.
    ///@param salt random number used as salt.
    ///@return royaltyContract Address of the newely deployed PaymentSplitter contract.
    ///@dev ref. { https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol }
    function _deployPaymentSplitter(
        address[] memory recipients,
        uint256[] memory shares,
        uint256 salt
    ) internal returns (address payable royaltyContract) {
        PaymentSplitter royaltySplitter = new PaymentSplitter{
            salt: bytes32(salt)
        }(recipients, shares);
        royaltyContract = payable(royaltySplitter);
        royaltyList.push(royaltyContract);
        emit NewRoyaltySplitter(royaltyContract, royaltyList.length);
    }

    ///@notice Restricted method used to update the name and ticker of this minting tool contract.
    ///@param newName The new name for this contract.
    ///@param newSymbol The new symbol for this contract.
    function setNameAndTicker(
        string memory newName,
        string memory newSymbol
    ) external onlyOwner {
        _name = newName;
        _symbol = newSymbol;
        emit NewNameAndSymbol(newName, newSymbol);
    }

    ///@notice Method ued to transfer the funds from the minting tool, to treasury account.
    function rF() external onlyOwner {
        if (treasury == address(0)) revert NoTreasury();
        uint256 balance = address(this).balance;
        if (balance <= 0) revert LowBalance(balance);
        (bool success, ) = payable(treasury).call{value: balance}("");
        if (!success) revert TxFailed();
        emit FundsReleased(balance);
    }

    ///@notice Restricted method used to update the treasury account.
    ///@param _treasury The new treasury address.
    function updateTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}