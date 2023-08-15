// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*                                                                                                      
                                @@@@@@@  @@@@@  .                                                                       
                            @@@@@@@@@* @@@@@  /@@@@@@@@@%                                                               
                          @ @@@      #@@@@&      @@@@@@@@@@@@@@                                                         
                          @@@       @@@@@          /@@@@@@@@@@@@@@@@                                                    
                        *@@       @@@@@           @@@@@@@     @@@@@   @@(                                               
                       @@/      @@@@@*          @@@@@@@             @@@@@@@@                                            
                       @@@                    *@@@@@@%            (@@@@@@@                                              
                      %@@@@                    @@@@@             @@@@@@@%                                               
                   @@@@ @@@@.                                  @@@@@@@@                                                 
                  @@@@@@ /@@@                                 @@@@@@@*                 .@&                              
                 @@@ @@@@@@@%  @                              &@@@@@@@@@              @@@@@@                            
                 @@@@ .@@@@  @@@@@                                @@@@@@@@@(         @@@@@@@@@*                         
                 *@@@@@@      .@@@@@                                  @@@@@@@@@    @@@@@@@%@@@@@&                       
                   @@@@@   @@@@  @@@@@/                                  *@@@@@   @@@@@@@@&  @@@@@%                     
                        @@  @@@@@  @@@@@@                                       @@@@@@@@@@@@@  @@@@                     
                       @@@@@, @@@@@@@@@                                         @@@@@@@  @@@@@@  @                      
                         @@@@@@ @@@@@&                                            /@@@@@@  @@@@   @@@@@                 
                           @@@@@@@@@              (                                  @@@@@@. .   @@@@@@@                
                              @@@@               @@@@@&                                @@@@@@   *@@@ @@@                
                                   @@@@(       @@@@@@   @@@                              &@@  @@ @@@/ @@                
                                    @@@@@@@   @@@@@@   @@@@@@@@@                             &@@@ @@@#@                 
                                       @@@@@@@@@@@         /@@@@@@@@@/                       %@@@  @@                   
                                          .@@@@@@          @@@@@@@@@@@@@  @@#                 @@@@#@                    
                                              /          %@@@@@          @@@@@  @@@@@@@@@@@@@@ @@@@                     
                                                        @@@@@@         @@@@@*  *@@@@@@@@@@@@@   @/                      
                                                       %@@@@          @@@@@        @@@@                                 
                                                                    &@@@@%       (@@@(                                  
                                                                   @@@@@        @@@@                                    
                                                                               @@@@                                                           
*/                                                         

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/**
 * @title TITLES Edition ERC721 v1
 * @notice The TITLES Edition contract is an immutable ERC721 implementation that splits a share of proceeds amongst creators of samples used in its creation
 * @dev An immutable implementation of ERC721A
 */
contract TitlesEditionV1 is 
    ERC721AUpgradeable,  
    ERC2981Upgradeable, 
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable
{
    // ================ Configuration ================
    /// @dev Upper limit to the mint batch size for the ERC721A contract
    uint256 private immutable MAX_MINT_BATCH_SIZE = 8;

    /// @dev Sale begins upon initialization
    bool private saleStarted;

    // ================ Edition Metadata ================
    /// @dev Single metadata URI for the contract
    string private remixUri;

    // ================ Sales Configuration ================
    /// @notice User-set price of drop
    uint256 public price;

    /// @notice User-set maximum number of editions that can be minted for this contract, unbounded if zero
    uint256 public maxSupply;

    /// @notice User-set maximum number of editions that can be minted per wallet, unbounded if zero
    uint256 public mintLimitPerWallet;

    /// @notice User-set date that minting closes as a unix timestamp, unbounded if zero
    uint256 public saleEndTime;

    // ================ Proceeds Configuration ================
    /// @notice Derivative Fee - charged per mint, paid out to creators of remixed samples
    uint256 private immutable DERIVATIVE_FEE = 999000000000000; // 0.000999ETH

    /// @notice Recipient of primary and secondary sale proceeds, typically a Split
    address public creatorProceedRecipient;

    /// @notice Recipient of Derivative Fees, typically a Split
    address public derivativeFeeRecipient;

    /**
     * @notice Emitted on primary sale of edition
     * @param to Address that purchased the edition
     * @param quantity Quantity of tokens purchased
     * @param pricePerToken Price of each token paid to proceed recipient
     * @param firstTokenId The id of the first token purchased in this sale
     */
    event Sale(
        address to,
        uint256 quantity,
        uint256 pricePerToken,
        uint256 firstTokenId
    );

    /**
     * @notice Emitted when proceeds are paid out from a sale
     * @param value Amount paid out
     * @param recipient Proceeds recipient
     */
    event ProceedsPayout(
        uint256 value,
        address recipient
    );

    /**
     * @notice Emitted when Derivative Fee is paid out from a sale
     * @param value Amount paid out
     * @param recipient Derivative Fee recipient
     */
    event DerivativeFeePayout(
        uint256 value,
        address recipient
    );

    /**
     * @notice Emitted when funds are withdrawn from the contract
     * @param withdrawnBy Address that funds are withdrawn to
     * @param amount Amount of funds withdrawn
     */
    event FundsWithdrawal(
        address indexed withdrawnBy,
        uint256 amount
    );

    /**
     * @dev Constructor to prevent initialization of base implementation 
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create a new TITLES Edition contract
     * @param _creator Publisher of the edition
     * @param _name Contract name 
     * @param _symbol Contract symbol 
     * @param _uri Metadata URI 
     * @param _creatorProceedRecipient Proceeds recipient address
     * @param _derivativeFeeRecipient Derivative Fee recipient address 
     * @param _price Price of the edition in wei 
     * @param _maxSupply Maximum number of editions that can be minted for this contract, unbounded if zero 
     * @param _mintLimitPerWallet Maximum number of editions that can be minted per wallet, unbounded if zero
     * @param _saleEndTime Date that minting closes as a unix timestamp, unbounded if zero
     * @param _secondaryRoyaltyBps Portion of secondary sales distributed as royalties, in BPS (scale 10_000) 
     */
    function initialize(address _creator,
        string memory _name, 
        string memory _symbol, 
        string memory _uri, 
        address _creatorProceedRecipient,
        address _derivativeFeeRecipient,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _mintLimitPerWallet,
        uint256 _saleEndTime,
        uint96 _secondaryRoyaltyBps
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __ERC2981_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();
        __Ownable_init();

        remixUri = _uri;
        creatorProceedRecipient = _creatorProceedRecipient;
        derivativeFeeRecipient = _derivativeFeeRecipient;
        price = _price;
        maxSupply = _maxSupply;
        mintLimitPerWallet = _mintLimitPerWallet;
        saleEndTime = _saleEndTime;
        saleStarted = true;

        _setDefaultRoyalty(_creatorProceedRecipient, _secondaryRoyaltyBps);
        transferOwnership(_creator);
    }

    /**
     * @notice Contract URI getter
     * @return Contract URI
     */
    function contractURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Purchase a quantity of edition tokens
     * @param quantity Quantity to purchase
     */
    function purchase(uint256 quantity) external payable nonReentrant {
        // Check sale active
        require(_saleActive(), "Sale has ended");

        // Check supply
        if (maxSupply != 0 &&
            quantity + _totalMinted() > maxSupply) {
            revert("This drop is sold out");
        }

        // Check price
        uint256 expectedPrice = (price + DERIVATIVE_FEE) * quantity;
        require(msg.value == expectedPrice, "Incorrect purchase price");

        // Check limit
        if (mintLimitPerWallet != 0 && 
            _numberMinted(_msgSender()) + quantity > mintLimitPerWallet) {
            revert("This wallet cannot purchase that many");
        }

        // Mint
        _mintNFTs(_msgSender(), quantity);
        uint256 firstMintedTokenId = _lastMintedTokenId() - (quantity - 1);

        // Pay
        _distributeFunds(msg.value, quantity);

        emit Sale({
            to: _msgSender(),
            quantity: quantity,
            pricePerToken: price,
            firstTokenId: firstMintedTokenId
        });
    }

    /**
     * @notice Distribute funds between the derivative fee recipient and proceeds recipient
     * @dev This function should be called as part of any purchase function, with all funds in msg.value distributed here
     * @param totalFunds Amount of funds to be distributed
     * @param quantity Quantity of tokens purchased
     */
    function _distributeFunds(uint256 totalFunds, uint256 quantity) internal {
        uint256 totalDerivativeFee = DERIVATIVE_FEE * quantity;
        (bool feeSuccess, ) = derivativeFeeRecipient.call{value: totalDerivativeFee}("");
        require(feeSuccess, "Failed to send derivative fee");

        emit DerivativeFeePayout({
            value: totalDerivativeFee,
            recipient: derivativeFeeRecipient
        });

        uint256 proceeds = totalFunds - totalDerivativeFee;
        if (proceeds > 0) {
            (bool proceedsSuccess, ) = creatorProceedRecipient.call{value: proceeds}("");
            require(proceedsSuccess, "Failed to send purchase proceeds");

            emit ProceedsPayout({
                value: proceeds,
                recipient: creatorProceedRecipient
            });
        }
    }

    /**
     * @notice Function to mint NFTs
     * @dev (important: Does not enforce max supply limit, enforce that limit earlier)
     * @dev This batches in size of 8 as per recommended by ERC721A creators
     * @param to address to mint NFTs to
     * @param quantity number of NFTs to mint
     */
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > MAX_MINT_BATCH_SIZE
                ? MAX_MINT_BATCH_SIZE
                : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }

    /**
     * @notice Check if sale is active
     * @dev If sale end time is zero, this will always return true
     * @return Boolean whether the sale is still active
     */
    function _saleActive() internal view returns (bool) {
        if (!saleStarted) { return false; }
        if (saleEndTime == 0) { return true; }
        return saleEndTime > block.timestamp;
    }

    /**
     * @dev  Getter for last minted token ID (gets next token id and subtracts 1)
     */
    function _lastMintedTokenId() internal view returns (uint256) {
        return _nextTokenId() - 1;
    }

    /**
     * @dev Use a single metadata URI for the contract
     */
    function _baseURI() internal view override returns (string memory) {
        return remixUri;
    }

    /**
     * @notice Token URI getter
     * @dev Use a single metadata URI for tokens on the contract
     * @param tokenId Id of the token to get URI of
     * @return Token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "invalid token ID");
        return _baseURI();
    }

    /**
     * @notice Withdraw ETH from the contract to the owner. 
     * @notice As funds are automatically distributed during purchase, there generally shouldn't be any funds stored in the contract.
     */
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 funds = address(this).balance;
        address recipient = owner();
        require(recipient == _msgSender(), "Not authorized to withdraw");

        (bool withdrawSuccess, ) = recipient.call{value: funds}("");
        require(withdrawSuccess, "Failed to withdraw contract funds");

        emit FundsWithdrawal({
            withdrawnBy: recipient,
            amount: funds
        });
    }

    /// @notice Ability to recieve ETH
    receive() external payable {}

    /// @dev See {ERC721-setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-transferFrom}
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-safeTransferFrom}
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-safeTransferFrom}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice ERC165 supports interface
     * @param interfaceId interface id to check if supported
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view    
        override(
            ERC721AUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}