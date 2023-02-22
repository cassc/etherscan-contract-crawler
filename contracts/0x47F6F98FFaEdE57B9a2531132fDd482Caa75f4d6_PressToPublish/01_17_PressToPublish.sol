// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//              ____________________________________________
//              |                                          |
//              |                                          |
//              |               JumpNews.xyz               |
//              |                                          |
//              |                                          |
//        ______|__________________________________________|_______
//       /                                                         \
//      /                                                           \
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      | (J)(U)(M)(P)(_)(P)(R)(I)(N)(T)(I)(N)(G)(_)(P)(R)(E)(S)(S) |
//      \___________________________________________________________/


import { ERC721A } from "chiru-labs/ERC721A/ERC721A.sol";
import { IERC721A } from "chiru-labs/ERC721A/IERC721A.sol";
import { ERC721AQueryable } from "chiru-labs/ERC721A/extensions/ERC721AQueryable.sol";
import { IERC721AQueryable } from "chiru-labs/ERC721A/extensions/IERC721AQueryable.sol";
import { ERC721ABurnable } from "chiru-labs/ERC721A/extensions/ERC721ABurnable.sol";
import { IERC721ABurnable } from "chiru-labs/ERC721A/extensions/IERC721ABurnable.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC2981, ERC2981} from "openzeppelin/ERC2981.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { OwnableRoles } from "solady/auth/OwnableRoles.sol";
import { LibString } from "solady/utils/LibString.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";


contract PressToPublish is

    ERC721AQueryable,
    ERC721ABurnable,
    OwnableRoles,
    OperatorFilterer,
    ERC2981{


    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /**
     * @dev A role for extensible minter module must have in order to mint new tokens.
     */
    uint256 public constant MINTER_ROLE = _ROLE_1;

    /**
     * @dev A role the owner can grant for performing admin actions.
     */
    uint256 public constant ADMIN_ROLE = _ROLE_0;

    /**
     * @dev The maximum limit for the mint or airdrop `quantity`.
     *      Prevents the first-time transfer costs for tokens near the end of large mint batches
     *      via ERC721A from becoming too expensive due to the need to scan many storage slots.
     *      See: https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     */
    uint256 public constant ADDRESS_BATCH_MINT_LIMIT = 255;

    /**
     * @dev The interface ID for EIP-2981 (royaltyInfo)
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;



    // =============================================================
    //                           STORAGE
    // =============================================================

    string private _normalUri;
    string private _contractURI;
    address public fundingRecipient;
    uint32 public editionMaxMintableLower;
    uint32 public editionMaxMintableUpper;
    uint32 public editionCutoffTime;
    uint256 public PRICE;
    bool public mintIsOpen = true;

    // Supports  Factory Functionality
    mapping (uint256 => string) customURIs;

    constructor(
    ) ERC721A("Press To Publish","Press To Publish") {
        _initializeOwner(msg.sender);
        fundingRecipient = 0x6952566b3d3b1bb6e76FD0c3EeE14D39eeaE3846;
        editionMaxMintableUpper = 25000000;
        editionMaxMintableLower = 1; //
        editionCutoffTime = 1677715199; // Wed Mar 01 2023 23:59:59 GMT // 1677715199
        PRICE = 10000000000000000; // .1 ETH
        //_normalUri = "ipfs://QmZrRjK8bTCCXBswBLVUCA7q5whtFgpPhgJAX9PoDiwG67";
       // _contractURI = "ipfs://QmUPDUuwcGw7b2fi1a7EKsU8XQKNmGcS9jXjfu6kNXoB3W";
        _registerForOperatorFiltering();
        _grantRoles(0x8AB5496a45c92c36eC293d2681F1d3706eaff85D,1);
        _grantRoles(0x979CEA08C0a766B26b3c96c1fbb1D83498373E01,1);
        _setDefaultRoyalty(0x6952566b3d3b1bb6e76FD0c3EeE14D39eeaE3846, 1000);

    }

    // =============================================================
    //                          MINT FUNCTIONS
    // =============================================================

    function mint(address to, uint256 quantity)
        external
        payable
        requireWithinAddressBatchMintLimit(quantity) // batch limit 255
        requireMintable(quantity) // Supply check + 
        returns (uint256 fromTokenId)
    {
        uint256 price = PRICE * quantity;
        require(mintIsOpen, "Mint is not open right now");
        require(msg.value >= price, "Not enough ETH");
        

        fromTokenId = _nextTokenId();
        // Mint the tokens. Will revert if `quantity` is zero.
        _mint(to, quantity);

        emit Minted(to, quantity, fromTokenId);

        // refund excess ETH
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function ownerMint(address to, uint256 quantity)
        external
        payable
        onlyRolesOrOwner(ADMIN_ROLE | MINTER_ROLE)
        requireWithinAddressBatchMintLimit(quantity) // batch limit 255
        requireMintable(quantity) //mint total does not exceed maxmintabke
        returns (uint256 fromTokenId)
    {
        fromTokenId = _nextTokenId();
        // Mint the tokens. Will revert if `quantity` is zero.
        _mint(to, quantity);

        emit Minted(to, quantity, fromTokenId);
    }

    function airdrop(address[] calldata to, uint256 quantity)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
        requireWithinAddressBatchMintLimit(quantity)
        requireMintable(to.length * quantity)
       // updatesMintRandomness
        returns (uint256 fromTokenId)
    {
        if (to.length == 0) revert NoAddressesToAirdrop();

        fromTokenId = _nextTokenId();

        // Won't overflow, as `to.length` is bounded by the block max gas limit.
        unchecked {
            uint256 toLength = to.length;
            // Mint the tokens. Will revert if `quantity` is zero.
            for (uint256 i; i != toLength; ++i) {
                _mint(to[i], quantity);
            }
        }

        emit Airdropped(to, quantity, fromTokenId);
    }

    // =============================================================
    //                   SALE CONTROL FUNCTIONS
    // =============================================================

    function setEditionMaxMintableRange(uint32 editionMaxMintableLower_, uint32 editionMaxMintableUpper_)
        external
        onlyRolesOrOwner(ADMIN_ROLE)
    {
        if (mintConcluded()) revert MintHasConcluded();

        uint32 currentTotalMinted = uint32(_totalMinted());

        if (currentTotalMinted != 0) {
            editionMaxMintableLower_ = uint32(FixedPointMathLib.max(editionMaxMintableLower_, currentTotalMinted));

            editionMaxMintableUpper_ = uint32(FixedPointMathLib.max(editionMaxMintableUpper_, currentTotalMinted));

            // If the upper bound is larger than the current stored value, revert.
            if (editionMaxMintableUpper_ > editionMaxMintableUpper) revert InvalidEditionMaxMintableRange();
        }

        // If the lower bound is larger than the upper bound, revert.
        if (editionMaxMintableLower_ > editionMaxMintableUpper_) revert InvalidEditionMaxMintableRange();

        editionMaxMintableLower = editionMaxMintableLower_;
        editionMaxMintableUpper = editionMaxMintableUpper_;

        emit EditionMaxMintableRangeSet(editionMaxMintableLower, editionMaxMintableUpper);
    }


    function setEditionCutoffTime(uint32 editionCutoffTime_) external onlyRolesOrOwner(ADMIN_ROLE) {
        if (mintConcluded()) revert MintHasConcluded();

        editionCutoffTime = editionCutoffTime_;

        emit EditionCutoffTimeSet(editionCutoffTime_);
    }

       function editionMaxMintable() public view returns (uint32) {
        if (block.timestamp < editionCutoffTime) {
            return editionMaxMintableUpper;
        } else {
            return uint32(FixedPointMathLib.max(editionMaxMintableLower, _totalMinted()));
        }
    }

    
    // Toggle Mint Status
    function toggleMint() public onlyRolesOrOwner(ADMIN_ROLE) {
        mintIsOpen = !mintIsOpen;
    }
    
    // =============================================================
    //                   SALE SUPPORT FUNCTIONS
    // =============================================================

    function mintConcluded() public view returns (bool) {
        return _totalMinted() == editionMaxMintable();
    }


    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }


    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }


    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }


    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }


    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    // =============================================================
    //                   SALE RELATED MODIFIERS
    // =============================================================


    /* @dev Ensures that `totalQuantity` can be minted.
     * @param totalQuantity The total number of tokens to mint.
     */
    modifier requireMintable(uint256 totalQuantity) {
        unchecked {
            uint256 currentTotalMinted = _totalMinted();
            uint256 currentEditionMaxMintable = editionMaxMintable();
            // Check if there are enough tokens to mint.
            // We use version v4.2+ of ERC721A, which `_mint` will revert with out-of-gas
            // error via a loop if `totalQuantity` is large enough to cause an overflow in uint256.
            if (currentTotalMinted + totalQuantity > currentEditionMaxMintable) {
                // Won't underflow.
                //
                // `currentTotalMinted`, which is `_totalMinted()`,
                // will return either `editionMaxMintableUpper`
                // or `max(editionMaxMintableLower, _totalMinted())`.
                //
                // We have the following invariants:
                // - `editionMaxMintableUpper >= _totalMinted()`
                // - `max(editionMaxMintableLower, _totalMinted()) >= _totalMinted()`
                uint256 available = currentEditionMaxMintable - currentTotalMinted;
                revert ExceedsEditionAvailableSupply(uint32(available));
            }
        }
        _;
    }

    /**
     * @dev Ensures that the `quantity` does not exceed `ADDRESS_BATCH_MINT_LIMIT`.
     * @param quantity The number of tokens minted per address.
     */
    modifier requireWithinAddressBatchMintLimit(uint256 quantity) {
        if (quantity > ADDRESS_BATCH_MINT_LIMIT) revert ExceedsAddressBatchMintLimit();
        _;
    }

    // =============================================================
    //                   Withdraw functions
    // =============================================================
   

    function withdrawETH() external {
        uint256 amount = address(this).balance;
        SafeTransferLib.safeTransferETH(fundingRecipient, amount);
        emit ETHWithdrawn(fundingRecipient, amount, msg.sender);
    }


    function withdrawERC20(address[] calldata tokens) external {
        unchecked {
            uint256 n = tokens.length;
            uint256[] memory amounts = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
                SafeTransferLib.safeTransfer(tokens[i], fundingRecipient, amount);
                amounts[i] = amount;
            }
            emit ERC20Withdrawn(fundingRecipient, tokens, amounts, msg.sender);
        }
    }


    //=================================================//
    //         URI related settings
    //=================================================//

        function setNewTokenURI(uint256 typeOfURI, uint256 tokenId, string memory newURI) external onlyRolesOrOwner(ADMIN_ROLE){
        if(typeOfURI == 0) 
            _normalUri = newURI;
        else 
            customURIs[tokenId] = newURI;

         emit newURISet(tokenId, newURI);//change event
        }
    
         function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return (bytes(customURIs[tokenId]).length == 0) ? _normalUri : customURIs[tokenId];
         }


    function setContractURI(string memory newContractURI) external onlyRolesOrOwner(ADMIN_ROLE)  {
       _contractURI = newContractURI;

        emit ContractURISet(newContractURI);
    }

    // Set new PRICE
    
    function setPrice(uint256 newPrice) external onlyRolesOrOwner(ADMIN_ROLE)  {
       PRICE = newPrice;
    }

    // Set new PRICE


    function setFundingRecipient(address fundingRecipient_) external onlyRolesOrOwner(ADMIN_ROLE) {
        if (fundingRecipient_ == address(0)) revert InvalidFundingRecipient();
        fundingRecipient = fundingRecipient_;
        emit FundingRecipientSet(fundingRecipient_);
    }


     /* @dev 
     * Enable operator filtering to comply with opensea roylaties
     */
   function setOperatorFilteringEnabled() external onlyRolesOrOwner(ADMIN_ROLE) {
                _registerForOperatorFiltering();
        
        emit OperatorFilteringEnablededSet();
    }

    // =============================================================
    //                  Internal  Overides
    // =============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }


    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================
    function contractURI() external view returns (string memory){
        return _contractURI;
    }

    function editionInfo() external view returns (EditionInfo memory info) {
        info.baseURI = getbaseURI();
        info.contractURI = _contractURI;
        info.name = name();
        info.symbol = symbol();
        info.fundingRecipient = fundingRecipient;
        info.editionMaxMintable = editionMaxMintable();
        info.editionMaxMintableUpper = editionMaxMintableUpper;
        info.editionMaxMintableLower = editionMaxMintableLower;
        info.editionCutoffTime = editionCutoffTime;
        info.mintConcluded = mintConcluded();
        info.nextTokenId = nextTokenId();
        info.totalMinted = totalMinted();
        info.totalBurned = totalBurned();
        info.totalSupply = totalSupply();
    }

    struct EditionInfo {
    // Base URI for the tokenId.
        string baseURI;
    // Contract URI for OpenSea storefront.
        string contractURI;
    // Name of the collection.
        string name;
    // Symbol of the collection.
        string symbol;
    // Address that receives primary and secondary royalties.
        address fundingRecipient;
    // The current max mintable amount;
        uint32 editionMaxMintable;
    // The lower limit of the maximum number of tokens that can be minted.
        uint32 editionMaxMintableUpper;
    // The upper limit of the maximum number of tokens that can be minted.
        uint32 editionMaxMintableLower;
    // The timestamp (in seconds since unix epoch) after which the
    // max amount of tokens mintable will drop from
    // `maxMintableUpper` to `maxMintableLower`.
        uint32 editionCutoffTime;
    // Whether the mint has concluded.
        bool mintConcluded;
    // Next token ID to be minted.
        uint256 nextTokenId;
    // Total number of tokens burned.
        uint256 totalBurned;
    // Total number of tokens minted.
        uint256 totalMinted;
    // Total number of tokens currently in existence.
        uint256 totalSupply;
    }

    // =============================================================
    //                      Getter Functions
    // =============================================================


    function operatorFilteringEnabled() public view returns (bool) {
        return _operatorFilteringEnabled();
    }

        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
        ERC721A.supportsInterface(interfaceId) ||
        interfaceId == _INTERFACE_ID_ERC2981 ||
        interfaceId == this.supportsInterface.selector;
    }

 
    function getbaseURI() public view  returns (string memory) {
        return _normalUri;
    }

 
    // ============================================================= //
    //                           IERC2981                            //
    // ============================================================= //

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    // =============================================================
    //                  INTERNAL / PRIVATE HELPERS
    // =============================================================


    /**
     * @dev For skipping the operator check if the operator is the OpenSea Conduit.
     * If somehow, we use a different address in the future, it won't break functionality,
     * only increase the gas used back to what it will be with regular operator filtering.
     */
    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }



    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when the `baseURI` is set.
     * @param baseURI the base URI of the edition.
     */
     
    event newURISet(uint256 tokenId, string baseURI);

    /**
     * @dev Emitted when the `contractURI` is set.
     * @param contractURI The contract URI of the edition.
     */
    event ContractURISet(string contractURI);


    /**
     * @dev Emitted when the `fundingRecipient` is set.
     * @param fundingRecipient The address of the funding recipient.
     */
    event FundingRecipientSet(address fundingRecipient);


    /**
     * @dev Emitted when the edition's maximum mintable token quantity range is set.
     * @param editionMaxMintableLower_ The lower limit of the maximum number of tokens that can be minted.
     * @param editionMaxMintableUpper_ The upper limit of the maximum number of tokens that can be minted.
     */
    event EditionMaxMintableRangeSet(uint32 editionMaxMintableLower_, uint32 editionMaxMintableUpper_);

    /**
     * @dev Emitted when the edition's cutoff time set.
     * @param editionCutoffTime_ The timestamp.
     */
    event EditionCutoffTimeSet(uint32 editionCutoffTime_);

    /**
     * @dev Emitted when the `operatorFilteringEnabled` is set.
     */
    event OperatorFilteringEnablededSet();

    /**
     * @dev Emitted upon ETH withdrawal.
     * @param recipient The recipient of the withdrawal.
     * @param amount    The amount withdrawn.
     * @param caller    The account that initiated the withdrawal.
     */
    event ETHWithdrawn(address recipient, uint256 amount, address caller);

    /**
     * @dev Emitted upon ERC20 withdrawal.
     * @param recipient The recipient of the withdrawal.
     * @param tokens    The addresses of the ERC20 tokens.
     * @param amounts   The amount of each token withdrawn.
     * @param caller    The account that initiated the withdrawal.
     */
    event ERC20Withdrawn(address recipient, address[] tokens, uint256[] amounts, address caller);

    /**
     * @dev Emitted upon a mint.
     * @param to          The address to mint to.
     * @param quantity    The number of minted.
     * @param fromTokenId The first token ID minted.
     */
    event Minted(address to, uint256 quantity, uint256 fromTokenId);

    /**
     * @dev Emitted upon an airdrop.
     * @param to          The recipients of the airdrop.
     * @param quantity    The number of tokens airdropped to each address in `to`.
     * @param fromTokenId The first token ID minted to the first address in `to`.
     */
    event Airdropped(address[] to, uint256 quantity, uint256 fromTokenId);
   
    // =============================================================
    //                            ERRORS
    // =============================================================



    /**
     * @dev The given `randomnessLockedAfterMinted` value is invalid.
     */
    error InvalidRandomnessLock();

    /**
     * @dev The requested quantity exceeds the edition's remaining mintable token quantity.
     * @param available The number of tokens remaining available for mint.
     */
    error ExceedsEditionAvailableSupply(uint32 available);

    /**
     * @dev The given amount is invalid.
     */
    error InvalidAmount();

    /**
     * @dev The given `fundingRecipient` address is invalid.
     */
    error InvalidFundingRecipient();

    /**
     * @dev The `editionMaxMintableLower` must not be greater than `editionMaxMintableUpper`.
     */
    error InvalidEditionMaxMintableRange();

    /**
     * @dev The `editionMaxMintable` has already been reached.
     */
    error MaximumHasAlreadyBeenReached();

    /**
     * @dev The mint `quantity` cannot exceed `ADDRESS_BATCH_MINT_LIMIT` tokens.
     */
    error ExceedsAddressBatchMintLimit();

    /**
     * @dev No addresses to airdrop.
     */
    error NoAddressesToAirdrop();

    /**
     * @dev The mint has already concluded.
     */
    error MintHasConcluded();

    
}