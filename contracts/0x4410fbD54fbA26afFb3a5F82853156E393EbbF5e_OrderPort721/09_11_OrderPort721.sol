// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../library/opensea-operatorfilter/v1/FlexibleOperatorFilterer.sol";
import "../library/sealable/v1/Sealable.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

error ErrNoEffect();
error ErrQuotaExceeded();
error ErrMaxSupplyExceeded();
error ErrNotStarted();
error ErrStartingIndexAlreadySet();
error ErrContractSealed();
error ErrCallerIsNotAllowed();
error ErrContractPaused();
error ErrInvalidArguments(string);
error ErrQuotaPerMintExceeded();

/**
 * @title OrderPortGuard
 * @author BaseLabs
 */
contract OrderPortGuard is Ownable {
    event OrderPortAddressUpdated(address contractAddress);
    address private _orderPortAddress;

    constructor(address address_) {
        _orderPortAddress = address_;
    }

    /**
     * @notice getOrderPortAddress is used to get the address of OrderPort contract.
     * @return contract address
     */
    function getOrderPortAddress() public view returns (address) {
        return _orderPortAddress;
    }

    /**
     * @notice setOrderPortAddress is used to set the OrderPort contract address.
     * @param address_ OrderPort contract address
     */
    function setOrderPortAddress(address address_) external onlyOwner {
        if (getOrderPortAddress() == address_) revert ErrNoEffect();
        _orderPortAddress = address_;
        emit OrderPortAddressUpdated(address_);
    }

    /***********************************|
    |             Modifier              |
    |__________________________________*/

    /**
     * @notice onlyOrderPort is used to restrict the method to be called only by the OrderPort contract.
     */
    modifier onlyOrderPort() {
        if (getOrderPortAddress() != _msgSender())
            revert ErrCallerIsNotAllowed();
        _;
    }
}

/**
 * @title OrderPort721
 * @author BaseLabs
 */
contract OrderPort721 is
    ERC721A,
    OrderPortGuard,
    Pausable,
    ReentrancyGuard,
    Sealable,
    FlexibleOperatorFilterer
{
    event Withdraw(address indexed account, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    struct Config {
        uint32 maxToken;
        string provenanceHash;
        string baseURI;
        WhitelistSaleConfig whitelistSale;
        PublicSaleConfig publicSale;
    }
    struct WhitelistSaleConfig {
        uint256 startTime;
        uint256 endTime;
        uint32 quota;
        uint32 quotaPerMint;
    }
    struct PublicSaleConfig {
        uint256 startTime;
        uint256 endTime;
        uint32 quota;
        uint32 quotaPerMint;
    }

    Config private _config;
    uint256 public startingIndex;

    constructor(
        string memory name_,
        string memory symbol_,
        address orderPortAddress_,
        Config memory config_
    ) ERC721A(name_, symbol_) OrderPortGuard(orderPortAddress_) {
        _config = config_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice airdrop is used to airdrop tokens to the given addresses.
     * @param addresses_ the addresses to airdrop
     * @param nums_ number of tokens to airdrop for each address
     */
    function airdrop(
        address[] calldata addresses_,
        uint64[] calldata nums_
    ) external onlyOwner nonReentrant {
        if (addresses_.length != nums_.length)
            revert ErrInvalidArguments("addresses_ and nums_");
        if (addresses_.length == 0) revert ErrInvalidArguments("addresses_");
        for (uint256 i = 0; i < addresses_.length; ++i) {
            _mintNFT(addresses_[i], nums_[i]);
        }
    }

    /**
     * @notice whitelistSale is used for whitelist sale.
     * @param address_ the address to mint token
     * @param num_ number of tokens
     */
    function whitelistSale(
        address address_,
        uint32 num_
    ) external payable onlyOrderPort nonReentrant {
        if (
            !_checkTimestamp(
                _config.whitelistSale.startTime,
                _config.whitelistSale.endTime
            )
        ) revert ErrNotStarted();
        if (num_ == 0) revert ErrNoEffect();
        if (
            _config.whitelistSale.quotaPerMint > 0 &&
            num_ > _config.whitelistSale.quotaPerMint
        ) revert ErrQuotaPerMintExceeded();
        if (_config.whitelistSale.quota > 0) {
            (uint32 whitelistMinted, uint32 publicMinted) = getMinted(address_);
            whitelistMinted += num_;
            if (whitelistMinted > _config.whitelistSale.quota)
                revert ErrQuotaExceeded();
            _setMinted(address_, whitelistMinted, publicMinted);
        }
        _mintNFT(address_, num_);
    }

    /**
     * @notice publicSale is used for public sale.
     * @param address_ the address to mint token
     * @param num_ number of tokens
     */
    function publicSale(
        address address_,
        uint32 num_
    ) external payable onlyOrderPort nonReentrant {
        if (
            !_checkTimestamp(
                _config.publicSale.startTime,
                _config.publicSale.endTime
            )
        ) revert ErrNotStarted();
        if (num_ == 0) revert ErrNoEffect();
        if (
            _config.publicSale.quotaPerMint > 0 &&
            num_ > _config.publicSale.quotaPerMint
        ) revert ErrQuotaPerMintExceeded();
        if (_config.publicSale.quota > 0) {
            (uint32 whitelistMinted, uint32 publicMinted) = getMinted(address_);
            publicMinted += num_;
            if (publicMinted > _config.publicSale.quota)
                revert ErrQuotaExceeded();
            _setMinted(address_, whitelistMinted, publicMinted);
        }
        _mintNFT(address_, num_);
    }

    /**
     * @notice internal method, _sale is used to sell tokens
     * @param address_ the address to mint token
     * @param num_ number of tokens
     */
    function _mintNFT(address address_, uint64 num_) internal {
        if (totalMinted() + num_ > _config.maxToken)
            revert ErrMaxSupplyExceeded();
        _safeMint(address_, num_);
    }

    /**
     * @notice issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |             Setters               |
    |__________________________________*/

    /**
     * @notice setStartingIndex is used to set the starting index
     * It determines a randomly generated offset to determine the metadata of all blindboxes.
     */
    function setStartingIndex() external onlyOwner {
        if (startingIndex != 0) revert ErrStartingIndexAlreadySet();
        uint256 entropy = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.difficulty,
                    block.timestamp,
                    block.coinbase,
                    tx.origin
                )
            )
        );
        startingIndex = entropy % _config.maxToken;
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    /**
     * @notice setProvenanceHash is used to set the provenance hash in special cases.
     * This process is under the supervision of the community.
     * @param provenanceHash_ provenance hash is used to prove that metadata has not been tampered.
     */
    function setProvenanceHash(
        string memory provenanceHash_
    ) external onlyOwner {
        _config.provenanceHash = provenanceHash_;
    }

    /**
     * @notice setWhitelistConfig is used to set the whitelist sale config in special cases.
     * This process is under the supervision of the community.
     * @param config_ the config of whitelist sale.
     */
    function setWhitelistConfig(
        WhitelistSaleConfig memory config_
    ) external onlyOwner {
        _config.whitelistSale = config_;
    }

    /**
     * @notice setPublicSaleConfig is used to set the public sale config in special cases.
     * This process is under the supervision of the community.
     * @param config_ the config of public sale.
     */
    function setPublicSaleConfig(
        PublicSaleConfig memory config_
    ) external onlyOwner {
        _config.publicSale = config_;
    }

    /**
     * @notice setBaseURI is used to set the base URI in special cases.
     * @param baseURI_ baseURI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _config.baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }

    /**
     * @notice _setMinted is used to set the number of token that minted at whiltelist sale period and public sale period.
     * @param address_ account address
     * @param whiltelistMinted_ the number of tokens that minted at whiltelist sale period.
     * @param publicSaleMinted_ the number of tokens that minted at public sale period.
     */
    function _setMinted(
        address address_,
        uint32 whiltelistMinted_,
        uint32 publicSaleMinted_
    ) internal {
        _setAux(address_, packUint64(whiltelistMinted_, publicSaleMinted_));
    }

    /***********************************|
    |               Getter              |
    |__________________________________*/

    /**
     * @notice getConfig is used to get the contract config.
     * @return config data
     */
    function getConfig() public view returns (Config memory) {
        return _config;
    }

    /**
     * @notice _checkTimestamp is used to check whether the current time is appropriate
     * @param startTime_ the value of startTime
     * @param endTime_ the value of endTime
     * @return whether the current time is appropriate
     */
    function _checkTimestamp(
        uint256 startTime_,
        uint256 endTime_
    ) internal view returns (bool) {
        if (startTime_ == 0 || startTime_ > block.timestamp) return false;
        if (endTime_ > 0 && endTime_ < block.timestamp) return false;
        return true;
    }

    /**
     * @notice _baseURI is used to override the _baseURI method.
     * @return baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _config.baseURI;
    }

    /**
     * @notice totalMinted is used to return the total number of tokens minted.
     * Note that it does not decrease as the token is burnt.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    /**
     * @notice getMinted is used to get the number of tokens that minted at whiltelist sale period and public sale period.
     * @param address_ account address
     * @return whiltelistMinted the number of tokens that minted at whiltelist sale period.
     * @return publicSaleMinted the number of tokens that minted at public sale period.
     */
    function getMinted(
        address address_
    ) public view returns (uint32 whiltelistMinted, uint32 publicSaleMinted) {
        return unpackUint64(_getAux(address_));
    }

    /**
     * @notice packUint64 is used to pack two uint32 numbers into one uint64.
     */
    function packUint64(uint32 a, uint32 b) public pure returns (uint64) {
        return (uint64(a) << 32) | uint64(b);
    }

    /**
     * @notice unpackUint64 is used to unpack one uint64 into two uint32 numbers.
     */
    function unpackUint64(uint64 c) public pure returns (uint32 a, uint32 b) {
        return (uint32(c >> 32), uint32(c));
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused()) revert ErrContractPaused();
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner onlyNotSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner onlyNotSealed {
        _unpause();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner onlyNotSealed {
        _sealContract();
    }

    /***********************************|
    |     Operator Filter Registry      |
    |__________________________________*/

    /**
     * @notice setApprovalForAll is used to set an operator's approval for all token transfers.
     * @param operator The address of the operator to set approval for.
     * @param approved Whether the operator is approved or not.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice approve is used to set an operator's approval for specified token transfers.
     * @param operator The address of the operator to set approval for.
     * @param tokenId The token id to set approval for.
     */
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice transferFrom is used to transfer tokens from one account to another.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param tokenId The ID of the token being transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice safeTransferFrom is used to safely transfer tokens from one account to another.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param tokenId The ID of the token being transferred.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice safeTransferFrom is used to safely transfer tokens from one account to another.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param tokenId The ID of the token being transferred.
     * @param data Additional data provided with the transfer.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice owner is used to get the owner address of this contract.
     * @return the address of the owner of this contract
     */
    function owner()
        public
        view
        virtual
        override(Ownable, FlexibleOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }
}