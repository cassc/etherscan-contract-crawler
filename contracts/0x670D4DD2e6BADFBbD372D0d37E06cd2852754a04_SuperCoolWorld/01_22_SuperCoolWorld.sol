// SPDX-License-Identifier: MIT

/*
                                                                                                    
                                    @@@@@@@     @@@@@@@@@   @@@@@@@@                                
                                    @@     @@@  @@          @@     @@@                              
                               @@@  @@      @@  @@          @@     @@@                              
                     @        @@@@  @@@@@@@@@   @@@@@@@@@   @@@@@@@@@@                              
                    @@        @@@   @@          @@          @@  @@                                  
                    @@       @@@@   @@          @@          @@   @@                                 
                    @@       @@@    @@          @@@@@@@@@   @@    @@                                
                    @@      @@@           #############            @@                               
                    @@      @@        #####################         @@                              
                    @@@@ @@@@       #########################                                       
               @@@@               #############################                                     
             @@@   @@            ###############################        @@@@@@                      
            @@@     @@          #################################     @@     @@                     
             @@@                #################################     @@                            
               @@@@@@           #################################     @@                            
                    @@          #######/@@@//###///####//@@//####     @@@    @@                     
             @@     @@          ################////#############       @@@@@@                      
              @@@@@@@           ################/////####/////###                                   
                                #################//////##////####       @@@@@@                      
                                #########/////###////////########     @@@    @@                     
                                #########/////####///////########     @@     @@                     
                                #################################     @@     @@                     
                                #################################     @@     @@                     
                                #################//////////######       @@@@@@                      
                                #################################                                   
                                #################################       @@@@@@                      
                                #################################     @@     @@                     
                                 ###############################      @@     @@                     
                                  #############################       @@     @@                     
                                    #########################         @@     @@                     
                                       ###################              @@@@@@                      
                                            #########                                               
                              @@@      @@      @@@@@      @@@@@@@      @@          @@@@@@@@         
                              @@@      @@    @@     @@    @@     @@    @@          @@     @@@       
                              @@   @@  @@    @@     @@    @@     @@    @@          @@      @@       
                              @@  @@@@ @@    @@     @@    @@@@@@@      @@          @@      @@       
                              @@ @@  @@@@    @@     @@    @@  @@@      @@          @@      @@       
                              @@@@    @@@    @@    @@@    @@   @@@     @@          @@     @@        
                              @@@      @@      @@@@@      @@     @@    @@@@@@@@@   @@@@@@@          
*/

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./lib/MerkleDistributorV2.sol";
import "./lib/ClaimBitmap.sol";

contract SuperCoolWorld is
    ERC721A,
    ERC2981,
    MerkleDistributorV2,
    ClaimBitmap,
    ReentrancyGuard,
    AccessControl,
    Ownable
{
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant MAX_RESERVE_SUPPLY = 480;
    uint256 public maxSupply = 5080;
    uint256 public price = 0.5 ether;

    string public provenance;
    string private _baseURIextended;

    uint256 public reserveSupply = MAX_RESERVE_SUPPLY;

    IERC721Enumerable public immutable baseContractAddress;
    address payable public immutable shareholderAddress;
    bool public saleActive;
    bool public claimActive;

    /**
     * cannot initialize shareholder address to 0
     */
    error ShareholderAddressIsZeroAddress();

    /**
     * cannot set base contract address if not ERC721Enumerable
     */
    error ContractIsNotERC721Enumerable();

    /**
     * cannot exceed maximum supply
     */
    error PurchaseWouldExceedMaximumSupply();

    /**
     * cannot mint if public sale is not active
     */
    error PublicSaleIsNotActive();

    /**
     * cannot exceed maximum reserve supply
     */
    error ExceedMaximumReserveSupply();

    /**
     * ether value sent is not correct
     */
    error EtherValueSentIsNotCorrect();

    /**
     * cannot exceed maximum public mint
     */
    error PurchaseWouldExceedMaximumPublicMint();

    /**
     * withdraw failed
     */
    error WithdrawFailed();

    /**
     * cannot mint if mint pass claim is not active
     */
    error ClaimIsNotActive();

    /**
     * cannot claim if token id has already been claimed
     */
    error TokenIdAlreadyClaimed(uint256 tokenId);

    /**
     * cannot exceed claim supply
     */
    error PurchaseWouldExceedClaimSupply();

    /**
     * callee is not the owner of the token id in the base contract
     */
    error NotOwnerOfMintPass(uint256 tokenId);

    /**
     * cannot set the price to 0
     */
    error SalePriceCannotBeZero();

    /**
     * cannot set supply to less than the total supply
     */
    error MaxSupplyLessThanTotalSupply();

    /**
     * cannot change states when minting is enabled
     */
    error MintingIsEnabled();

    /**
     * @notice constructor
     * @param shareholderAddress_ the shareholder address
     * @param contractAddress the contract address for mint passes
     */
    constructor(address payable shareholderAddress_, address contractAddress) ERC721A("Super Cool World", "COOL") {
        if (shareholderAddress_ == address(0)) revert ShareholderAddressIsZeroAddress();
        if (!IERC721Enumerable(contractAddress).supportsInterface(0x780e9d63)) revert ContractIsNotERC721Enumerable();

        // set immutable variables
        shareholderAddress = shareholderAddress_;
        baseContractAddress = IERC721Enumerable(contractAddress);

        // setup
        _initializeBitmap(IERC721Enumerable(contractAddress).totalSupply());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @notice checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (totalSupply() + numberOfTokens > maxSupply) revert PurchaseWouldExceedMaximumSupply();
        _;
    }

    /**
     * @notice checks to see whether saleActive is true
     */
    modifier isPublicSaleActive() {
        if (!saleActive) revert PublicSaleIsNotActive();
        _;
    }

    /**
     * @notice checks to see whether claimActive is true
     */
    modifier isClaimActive() {
        if (!claimActive) revert ClaimIsNotActive();
        _;
    }

    /**
     * @notice emitted when the price has been changed
     */
    event PriceChanged(uint256 newPrice);

    /**
     * @notice emitted when the max supply has been changed
     */
    event MaxSupplyChanged(uint256 newMaxSupply);

    ////////////////
    // admin
    ////////////////
    /**
     * @notice reserves a number of tokens
     * @param numberOfTokens the number of tokens to be minted
     */
    function devMint(uint256 numberOfTokens)
        external
        onlyRole(SUPPORT_ROLE)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        uint256 reserveSupplyRemaining = reserveSupply;
        if (reserveSupplyRemaining < numberOfTokens) revert ExceedMaximumReserveSupply();

        reserveSupply = reserveSupplyRemaining - numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice allows public sale minting
     * @param state the state of the public sale
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /**
     * @notice allows claiming of tokens
     * @param state the state of allowing claims to be made
     */
    function setClaimActive(bool state) external onlyRole(SUPPORT_ROLE) {
        claimActive = state;
    }

    /**
     * @notice set a new token price in wei
     * @param newPriceInWei the new price to set, per token, in wei
     */
    function setPrice(uint256 newPriceInWei) external onlyRole(SUPPORT_ROLE) {
        if (newPriceInWei == 0) revert SalePriceCannotBeZero();
        if (saleActive || allowListActive || claimActive) revert MintingIsEnabled();
        price = newPriceInWei;

        emit PriceChanged(price);
    }

    /**
     * @notice set a new max supply
     * @param newMaxSupply the new max supply to set
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyRole(SUPPORT_ROLE) {
        if (totalSupply() > newMaxSupply) revert MaxSupplyLessThanTotalSupply();
        if (saleActive || allowListActive || claimActive) revert MintingIsEnabled();
        maxSupply = newMaxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    ////////////////
    // allow list
    ////////////////
    /**
     * @notice allows minting from a list of clients
     * @param allowListActive the state of the allow list
     */
    function setAllowListActive(bool allowListActive) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(allowListActive);
    }

    /**
     * @notice sets the merkle root for the allow list
     * @param merkleRoot the merkle root
     */
    function setAllowList(bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @notice sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @notice See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     * @param tokenId the token id to burn
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // public
    ////////////////
    /**
     * @notice allow claims based on token ids, you can claim up to 2 tokens per mint pass
     * each mint pass can be used only once, i.e. claiming 1 token will exhaust a full mint pass
     * @param tokenIds array of token ids owned in the base contract
     * @param numberOfTokens the number of tokens to be minted
     */
    function claimByTokenIds(uint256[] memory tokenIds, uint256 numberOfTokens)
        public
        payable
        isClaimActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        uint256 mintPasses = tokenIds.length;
        uint256 mintPassesToClaim = Math.ceilDiv(numberOfTokens, 2);
        if (mintPassesToClaim > mintPasses) revert PurchaseWouldExceedClaimSupply();
        if (numberOfTokens * price != msg.value) revert EtherValueSentIsNotCorrect();

        // set passes claimed
        for (uint256 index; index < mintPassesToClaim; index++) {
            uint256 tokenId = tokenIds[index];
            if (baseContractAddress.ownerOf(tokenId) != msg.sender) revert NotOwnerOfMintPass(tokenId);
            if (isClaimed(tokenId)) revert TokenIdAlreadyClaimed(tokenId);

            _setClaimed(tokenId);
        }

        // mint tokens
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice get all tokens owned in the base contract, then claims the tokens
     * @dev this will revert if any tokens have been claimed already
     * @param numberOfTokens the number of tokens to be minted
     */
    function claim(uint256 numberOfTokens) external payable {
        uint256[] memory tokenIds = availableIdsToClaim(msg.sender);

        claimByTokenIds(tokenIds, numberOfTokens);
    }

    /**
     * @notice gets the balance of tokens owned in the base contract, and subtracts the amount already claimed
     * @param from the address to check
     */
    function availableToClaim(address from) external view returns (uint256) {
        uint256 baseBalance = baseContractAddress.balanceOf(from);
        uint256 amountClaimable;

        for (uint256 index; index < baseBalance; index++) {
            if (!isClaimed(baseContractAddress.tokenOfOwnerByIndex(from, index))) {
                amountClaimable++;
            }
        }

        return amountClaimable;
    }

    /**
     * @notice utility function to get available ids to claim
     * @param from the address to check
     */
    function availableIdsToClaim(address from) public view returns (uint256[] memory) {
        uint256 totalMintPasses = baseContractAddress.balanceOf(from);
        uint256[] memory availableTokenIds = new uint256[](totalMintPasses);

        uint256 amountClaimable;

        for (uint256 index; index < totalMintPasses; index++) {
            uint256 tokenId = baseContractAddress.tokenOfOwnerByIndex(from, index);

            if (!isClaimed(tokenId)) {
                availableTokenIds[amountClaimable] = tokenId;
                amountClaimable++;
            }
        }

        uint256[] memory unclaimedTokenIds = new uint256[](amountClaimable);
        for (uint256 index; index < amountClaimable; index++) {
            unclaimedTokenIds[index] = availableTokenIds[index];
        }

        return unclaimedTokenIds;
    }

    /**
     * @notice allow minting if the msg.sender is on the allow list
     * @param numberOfTokens the number of tokens to be minted
     * @param merkleProof the merkle proof for the msg.sender
     */
    function mintAllowList(uint256 numberOfTokens, bytes32[] memory merkleProof)
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, MAX_ALLOWLIST_MINT)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        if (numberOfTokens * price != msg.value) revert EtherValueSentIsNotCorrect();

        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice allow public minting
     * @param numberOfTokens the number of tokens to be minted
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        isPublicSaleActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        if (numberOfTokens > MAX_PUBLIC_MINT) revert PurchaseWouldExceedMaximumPublicMint();
        if (numberOfTokens * price != msg.value) revert EtherValueSentIsNotCorrect();

        _safeMint(msg.sender, numberOfTokens);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @notice See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @notice See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // withdraw
    ////////////////
    /**
     * @notice withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }
}