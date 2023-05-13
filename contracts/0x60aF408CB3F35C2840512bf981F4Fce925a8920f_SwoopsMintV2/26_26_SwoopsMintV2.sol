// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./SwoopsERC721.sol";
import "./OwnershipClaimable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwoopsMintV2 is OwnershipClaimable, ReentrancyGuard {
    ///@dev Emitted when the token supply increased.
    event TokenSupplyIncreased(uint256 _newSupply);
    ///@dev Emitted when the price per token changes.
    event PriceChanged(uint256 _newPrice);
    ///@dev Emitted when balance of a non-native ERC20 are withdrawn from this contract.
    event ForeignTokenWithdrawn(
        address tokenAddress,
        uint256 amount,
        address destination
    );
    ///@dev Emitted when the balance is withdrawn from this contract.
    event BalanceWithdrawn(uint256 amount, address destination);
    ///@dev Emitted when the whitelist sale flag is updated.
    event WhitelistSaleActiveUpdated(bool active);
    ///@dev Emitted when the direct sale flag is updated.
    event DirectSaleActiveUpdated(bool active);
    ///@dev Emitted when the mint with quota flag is updated.
    event MintWithQuotaActiveUpdated(bool active);

    SwoopsERC721 public swoopsNftContract;

    uint256 public maxTokenSupply = 100;
    uint256 public maxTokensPerWhitelistedWallet = 3;
    uint256 public price = 0.00001 ether;
    uint256 public whitelistDropId = 0;
    bool public isSaleActive = false;
    bool public directMintEnabled = false;
    bool public mintWithQuotaEnabled = false;
    bytes32 public root;
    mapping(address => mapping(uint256 => uint256))
        public tokensMintedPerWhitelistedWallet;

    /// @notice Constructor.
    /// @param nftContractAddress the address of the ERC721 contract that mints the tokens.
    constructor(address nftContractAddress) {
        swoopsNftContract = SwoopsERC721(nftContractAddress);

        require(
            Address.isContract(nftContractAddress) &&
                swoopsNftContract.supportsInterface(type(IERC721).interfaceId),
            "Address must point to a 721-compliant contract"
        );
    }

    /// @notice Mint a Swoops token.
    /// @dev Amount of ether sent must be at least tokensRequested * price.
    /// @param quantity The number of tokens requested.
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        canMint(quantity)
    {
        require(directMintEnabled, "Minting directly is not active");

        for (uint256 i = 0; i < quantity; i++) {
            swoopsNftContract.safeMint(msg.sender);
        }
    }

    /// @notice Mint a Swoops token with consideration for a quota per mint generation.
    /// @dev Amount of ether sent must be at least tokensRequested * price.
    /// @param quantity The number of tokens requested.
    /// @param to The destination address for the token.
    function mintWithQuota(uint256 quantity, address to)
        external
        payable
        nonReentrant
        canMint(quantity)
    {
        require(mintWithQuotaEnabled, "Minting via quota mint is not active");

        tokensMintedPerWhitelistedWallet[to][whitelistDropId] =
            tokensMintedPerWhitelistedWallet[to][whitelistDropId] +
            quantity;

        require(
            tokensMintedPerWhitelistedWallet[to][whitelistDropId] <=
                maxTokensPerWhitelistedWallet,
            "Quantity of tokens requested exceeds amount of tokens you can purchase"
        );


        for (uint256 i = 0; i < quantity; i++) {
            swoopsNftContract.safeMint(to);
        }
    }

    /// @notice Mint a Swoops token according to if the sender is whitelisted.
    /// @dev Amount of ether sent must be at least tokensRequested * price and the
    ///      proof obtained from the playswoops.com mint page. NOTE: there is a
    ///      cap on the number of tokens one whitelisted sender can mint.
    /// @param quantity The number of tokens requested.
    /// @param merkleProof The proof the sender is whitelisted.
    function whitelistedMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        canMint(quantity)
    {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Incorrect proof"
        );

        tokensMintedPerWhitelistedWallet[msg.sender][whitelistDropId] =
            tokensMintedPerWhitelistedWallet[msg.sender][whitelistDropId] +
            quantity;

        require(
            tokensMintedPerWhitelistedWallet[msg.sender][whitelistDropId] <=
                maxTokensPerWhitelistedWallet,
            "Quantity of tokens requested exceeds amount of tokens you can purchase"
        );

        for (uint256 i = 0; i < quantity; i++) {
            swoopsNftContract.safeMint(msg.sender);
        }
    }

    /// @notice Set the new max token supply.
    /// @dev Only callable by the contract owner. Emits a { TokenSupplyIncreased } event.
    /// @param newMaxTokenSupply The new max token supply.
    function setMaxTokenSupply(uint256 newMaxTokenSupply) external onlyOwner {
        require(
            newMaxTokenSupply > swoopsNftContract.totalSupply(),
            "Desired token supply is less than the total supply of tokens already issued"
        );
        maxTokenSupply = newMaxTokenSupply;
        emit TokenSupplyIncreased(maxTokenSupply);
    }

    /// @notice Set the new number of max tokens mintable per drop.
    /// @dev Only callable by the contract owner.
    /// @param newMaxTokensPerDrop The new max tokens per wallet per drop.
    function setMaxTokensPerWhitelistedWalletPerDrop(
        uint256 newMaxTokensPerDrop
    ) external onlyOwner {
        maxTokensPerWhitelistedWallet = newMaxTokensPerDrop;
    }

    /// @notice Set the new price per token.
    /// @dev Only callable by the contract owner. Emits a { PriceChanged } event.
    /// @param newPrice The new token price.
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceChanged(price);
    }

    /// @notice Set the new merkle tree (whitelist) root.
    /// @dev Only callable by the contract owner.
    /// @param newRoot The new merkle whitelist root.
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        root = newRoot;
    }

    /// @notice Set if the sale of tokens is active.
    /// @dev Only callable by the contract owner.
    /// @param active The new state for if token sales are active.
    function setIsSaleActive(bool active) external onlyOwner {
        isSaleActive = active;
        emit WhitelistSaleActiveUpdated(isSaleActive);
    }

    /// @notice Set if the direct 3rd party minting of tokens is active.
    /// @dev Only callable by the contract owner.
    /// @param enabled The new state for if direct minting is enabled.
    function setDirectMintEnabled(bool enabled) external onlyOwner {
        directMintEnabled = enabled;
        emit DirectSaleActiveUpdated(enabled);
    }

    /// @notice Set if the minting of tokens with a consideration for a quota is active.
    /// @dev Only callable by the contract owner.
    /// @param enabled The new state for if minting with a quota is enabled.
    function setMintWithQuotaEnabled(bool enabled) external onlyOwner {
        mintWithQuotaEnabled = enabled;
        emit MintWithQuotaActiveUpdated(enabled);
    }

    /// @notice Increase the drop id.
    /// @dev Only callable by the contract owner.
    function increaseWhitelistDropId() external onlyOwner {
        whitelistDropId++;
    }

    /// @notice Retrieve the total balance of this contract.
    /// @return the total balance of this contract.
    function totalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Withdraw funds from this contract.
    /// @dev Only callable by the contract owner. Emits a { BalanceWithdrawn } event.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        emit BalanceWithdrawn(balance, msg.sender);
        payable(msg.sender).transfer(balance);
    }

    /// @notice Withdraws the balance of a given token from this contract to the
    ///         owners wallet.
    /// @dev callable only by the contract owner. Emits a { ForeignTokenWithdrawn } event.
    /// @param token Address of the ERC20 token to withdraw from this wallet.
    /// @return bool True if the transfer was successful, otherwise throws.
    function withdrawToken(address token) external onlyOwner returns (bool) {
        IERC20 foreignToken = IERC20(token);
        uint256 balance = foreignToken.balanceOf(address(this));
        emit ForeignTokenWithdrawn(token, balance, msg.sender);
        SafeERC20.safeTransfer(foreignToken, msg.sender, balance);
    }

    /// @notice Given a quantity of tokens, throw if the contract's criteria for
    ///         minting is met, or if the caller has not sent enough funds.
    /// @param quantity The quantity of tokens desired to mint.
    modifier canMint(uint256 quantity) {
        require(isSaleActive, "Sale is currently not active");
        require(
            quantity > 0,
            "Some positive number of tokens must be requested"
        );
        require(
            quantity + swoopsNftContract.totalSupply() <= maxTokenSupply,
            "Not enough tokens left to buy the requested quantity"
        );
        require(
            msg.value >= price * quantity,
            "Amount of ether sent is insufficent"
        );
        _;
    }
}