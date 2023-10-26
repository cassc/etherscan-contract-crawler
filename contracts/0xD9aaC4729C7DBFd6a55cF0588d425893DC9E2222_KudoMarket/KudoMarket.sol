/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/KudoeMarket.sol


pragma solidity 0.8.17;








// Interface to call ERC721 Functions
contract ERC721 {
    function safeMint(address to,string memory uri) external{}
    function transferOwnership(address newOwner)external{}
}

// Contract for the NFT marketplace
contract KudoMarket is ReentrancyGuard,Ownable { 
    constructor(address _escrow){
        escrow = _escrow;
    }

   
    // Instance of the ERC721 contract (Our NFT Contract)
    address public escrow; //Owner of MarketPlace
    address public signerWallet; 
    uint256 public listingPercent; 
    ERC721 public MintingContract;

      // Function to set the address of the ERC721 contract
    function setMintingAddress(address _mintingAddress) external onlyOwner {
        require(_mintingAddress != address(0), "Invalid ERC721 address");
        MintingContract = ERC721(_mintingAddress);
    }
 
    // Transfer ownership back to another address
    function transferERC721Ownership(address newOwner) external onlyOwner {
         require(newOwner != address(0), "Invalid New Owner address");
        MintingContract.transferOwnership(newOwner);
    }
    
    /**
    * @notice Mapping to keep track of cancelled listings
    * @dev A true value indicates that the listing has been cancelled or nft is sold
    */
    mapping(bytes => bool) public isCancelled; 
    
    struct ItemParams {
    address seller;
    address erc721;
    address erc20;
    uint256 tokenId;
    uint256 price;
    uint256 endTime;
    address[] collaboratorAddress;
    uint256[] collaboratorAmount;
    string collectionId;
    uint256 tokenType;
    string uri;
    }
     
    struct BuyParams {
    address seller;
    address erc721;
    address erc20;
    uint256 tokenId;
    uint256 price;
    uint256 endTime;
    bytes[] signature;
    address[] collaboratorAddress;
    uint256[] collaboratorAmount;
    string collectionId;
    uint256 tokenType;
    string uri;
    }
  
 
    // Events
        event Bought (
        uint256 tokenId,
        address buyer,
        uint256 price,
        string collectionId
    );

    // FUNCTIONS
/**
 * @notice Allows a buyer to purchase an NFT listed on the marketplace
 * @param seller The address of the NFT seller
 * @param erc721 contain the address of erc721 used for minting
 * @param tokenId The ID of the NFT being purchased
 * @param price The price of the NFT in the specified ERC20 token
 * @param endTime The timestamp indicating when the listing ends
 * @param signature The signature of the listing by the seller
 * @param collaboratorAddress The addresses of collaborators who receive a portion of the payment
 * @param collaboratorAmount The corresponding amounts to be sent to the collaborators
 * @param collectionId The ID of the NFT collection or category
 * @param tokenType The type of the NFT (0 for minted by the marketplace, 1 for existing ERC721 token)
 */
    function buy(
        address seller,
        address erc721,     
        address erc20,     
        uint256 tokenId,
        uint256 price,   
        uint256 endTime,
        bytes[] memory signature,
        address[] memory collaboratorAddress,
        uint256[] memory collaboratorAmount,
        string memory collectionId,
        uint256 tokenType,
        string memory uri
    ) 
        public  {
    ItemParams memory params = ItemParams(
    seller,
    erc721,
    erc20,
    tokenId,
    price,
    endTime,
    collaboratorAddress,
    collaboratorAmount,
    collectionId,
    tokenType,
    uri
    );

    
     
        require(isCancelled[signature[0]]== false, "This listing was cancelled");
        require(block.timestamp < endTime,"Listing time has expired");
        require(seller != msg.sender ,"Owner cannot buy his own NFT");
        bytes32 eip712DomainHash = geteip712DomainHash ();
        bytes32 hashStruct = gethashStruct(params.seller,erc721,erc20,params.tokenId,params.price,params.endTime,collaboratorAddress,collaboratorAmount,params.collectionId,params.tokenType);
        require(verifySignature(signature[0],hashStruct,eip712DomainHash) == seller,"Seller signature not Verified");
        require(verifySignature(signature[1],hashStruct,eip712DomainHash) == signerWallet,"System signature not Verified");
        transferMoney(params.seller,params.price,erc20,collaboratorAddress,collaboratorAmount);
 
        if (tokenType == 0){
        MintingContract.safeMint(msg.sender,uri);
        }
        else{
           require(IERC721(erc721).ownerOf(tokenId)== seller,
            "Seller is not the owner of this NFT"
        );
        IERC721(erc721).transferFrom(params.seller,msg.sender,params.tokenId);
        }
        
        isCancelled[signature[0]]= true;
        
        emit Bought(
        tokenId,
        msg.sender,
        price,
        collectionId);

    }


   function sweep(BuyParams[] memory items) external   {
    for (uint256 i = 0; i < items.length; i++) {
        BuyParams memory item = items[i];

        buy(
            item.seller,
            item.erc721,
            item.erc20,
            item.tokenId,
            item.price,
            item.endTime,
            item.signature,
            item.collaboratorAddress,
            item.collaboratorAmount,
            item.collectionId,
            item.tokenType,
            item.uri
        );
    }
}

/**
 * @notice Transfers funds from the buyer to the seller and collaborators and market owner
 * @param seller The address of the NFT seller
 * @param price The total price of the NFT
 * @param erc20 The address of the ERC20 contract used for payment
 * @param collaboratorAddress The addresses of collaborators who receive a portion of the payment
 * @param collaboratorAmount The corresponding amounts to be sent to the collaborators
 */
        function transferMoney ( address seller,uint256 price, address erc20 ,  address[] memory collaboratorAddress,
        uint256[] memory collaboratorAmount)
        private 
    {   
         uint256 fee = ((price*listingPercent)/100)/10;
         uint256 totalColab=0;
        for (uint i=0; i<collaboratorAddress.length; i++) {  
             totalColab= totalColab + collaboratorAmount[i] ;
             }


        // Transfer to collaborators
        for (uint i=0; i<collaboratorAddress.length; i++) {  
        require(
            IERC20(erc20).transferFrom(
                msg.sender,  
                collaboratorAddress[i], 
                collaboratorAmount[i]   
            ),
            "Failed to transfer listing fee to Collaborators"
        );
           }

        // Transfer to seller
        require(
            IERC20(erc20).transferFrom(
                msg.sender,                  
                seller,
                price-fee-totalColab
            ),
            "Failed to transfer money to the seller"
        );

        // Listing fee from buyer to escrow
        require(
            IERC20(erc20).transferFrom(
                msg.sender,  
                escrow, 
                fee
            ),
            "Failed to transfer listing fee to escrow"
        );

    }


/**
 * @notice Allows the owner to cancel a listing by its signature
 * @param signature The signature of the listing to be cancelled
 * @dev Updates the cancellation status of the listing to true
 * @dev Reverts if the listing is already cancelled
 */
        function cancelListing ( bytes memory signature) external nonReentrant{
        require(isCancelled[signature]== false, "This listing was already cancelled");
        isCancelled[signature] = true;
    }


/**
 * @notice Sets the percentage fee for listing or auction
 * @param percentage The new listing fee percentage to be set
 * @dev Only the contract owner can call this function
 */
     function setListingFee(uint256 percentage)external onlyOwner{
         listingPercent=percentage;
     }


/**
 * @notice Changes the address for the fee collection (escrow) account
 * @param _newAddress The new address to set as the fee collection address
 * @dev Only the contract owner can call this function
 */
     function changeFeeAddress(address _newAddress) external onlyOwner{
         escrow = _newAddress;
     }

/**
 * @notice Changes the address for the system signer account
 * @param _newAddress The new address to set as the Signer address
 * @dev Only the contract owner can call this function
 */
     function changeSignerWallet(address _newAddress) external onlyOwner{
         signerWallet = _newAddress;
     }




/**
 * @notice Retrieves the EIP712 domain hash for signature verification
 * @return The EIP712 domain hash
 * @dev The EIP712 domain hash is calculated based on the contract's name, version, and verifying contract address
 */
    function geteip712DomainHash () private view  returns (bytes32) {
        return
        keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("Listing")),
            keccak256(bytes("1")),
            1,
            address(this)
        )
        );
    }
    

/**
 * @notice Generates the hash struct used for signature verification
 * @return The hash struct representing the listing parameters
 */ 
      function gethashStruct(
        address seller, 
        address erc721,
        address erc20,
        uint256 tokenId,
        uint256 price,
        uint256 endTime,
        address[] memory collaboratorAddress,
        uint256[] memory collaboratorAmount,
        string memory collectionId,
        uint256 tokenType
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('ListedItem(address seller,address erc721,address erc20,uint256 tokenId,uint256 price,uint256 endTime,address[] collaboratorAddress,uint256[] collaboratorAmount,string collectionId,uint256 tokenType)'),
                    seller,
                    erc721,
                    erc20,
                    tokenId,
                    price,
                    endTime,
                    keccak256(abi.encodePacked(collaboratorAddress)),
                    keccak256(abi.encodePacked(collaboratorAmount)),
                    keccak256(bytes(collectionId)),
                    tokenType
                )
            );
    } 



    

/**
 * @notice Verifies the provided signature using the given hash and domain
 * @param signature The signature to be verified
 * @param hashStruct The hash struct representing the listing parameters
 * @param domain The EIP712 domain hash
 * @return The address recovered from the signature
 */
        function verifySignature(bytes memory signature, bytes32 hashStruct, bytes32 domain) private pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;

        require(signature.length == 65, "Invalid signature");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0,mload(add(signature, 96)))
        }
              
              if (v < 27) {
                v += 27;
                }
    if (v != 27 && v != 28) {
        return address(0);
    }

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domain, hashStruct));

    return ecrecover(hash, v, r, s);
        }

}