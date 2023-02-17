/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;





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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
 contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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




contract KOK_AIRDROP is Ownable{

    mapping (IERC20=>bool) IsTokenWhitelist;
    mapping (IERC721=>bool) IsNFTWhitelist;


    event Received(address, uint);
    event ERC20transfer(address,address, uint);
    event ERC721transfer(address,address, uint);


    function sendERC20(IERC20 _token,uint256 _tokenamt) external 
    {
        require(IsTokenWhitelist[_token]==true,"This token is not whitelisted!");
        _token.transferFrom(msg.sender,address(this),_tokenamt);
        emit ERC20transfer(msg.sender,address(this), _tokenamt);

    }

     function sendERC721toContract(IERC721 _nftaddr,uint256[] memory _tokenids) external onlyOwner
     {
        require(IsNFTWhitelist[_nftaddr]==true,"This token is not whitelisted!");
        for(uint256 i=0;i<_tokenids.length;i++)
        {
        IERC721(_nftaddr).transferFrom(msg.sender,address(this),_tokenids[i]);
         emit ERC721transfer(msg.sender,address(this), _tokenids[i]);       
        }
     }

       function airdropERC721(IERC721 _nftaddr,address[] memory receivers, uint256[] memory _tokenids) external onlyOwner
    {
        
    IERC721(_nftaddr).setApprovalForAll(msg.sender,true);
    for(uint256 i=0;i<_tokenids.length;i++){
    require(IERC721(_nftaddr).ownerOf(_tokenids[i])==address(this),"Contract is not owner of this ID!");
    IERC721(_nftaddr).setApprovalForAll(msg.sender,true);
    IERC721(_nftaddr).transferFrom(address(this),receivers[i],_tokenids[i]);
    emit ERC721transfer(address(this),receivers[i], _tokenids[i]); 
    }     

    }

  

       // owner of this contract withdraw the any erc20 stored in the contract to own address
  function emergencyWithdraw(IERC20 _token,uint256 _tokenAmount) external onlyOwner
    {
         IERC20(_token).transfer(msg.sender, _tokenAmount);
    }
    // owner of this contract withdraw the ether stored in the contract to own address

    function emergencyWithdrawETH(uint256 Amount) external onlyOwner 
    {
        payable(msg.sender).transfer(Amount);
    }



    function withDrawERC721(IERC721 _nftaddr,uint256[] memory _tokenids) external onlyOwner
    {

    IERC721(_nftaddr).setApprovalForAll(msg.sender,true);
    for(uint256 i=0;i<_tokenids.length;i++){
    require(IERC721(_nftaddr).ownerOf(_tokenids[i])==address(this),"Contract is not owner of this ID!");
    IERC721(_nftaddr).setApprovalForAll(msg.sender,true);
    IERC721(_nftaddr).transferFrom(address(this),msg.sender,_tokenids[i]);
    emit ERC721transfer(address(this),msg.sender, _tokenids[i]); 
    }     

    }

      function setTokenwhitelist(IERC20 _token, bool _state) external onlyOwner
      {
        IsTokenWhitelist[_token]=_state;
      }

     function setNFTwhitelist(IERC721 _tokenID, bool _state) external onlyOwner
     {
        IsNFTWhitelist[_tokenID]=_state;
     }
    


   

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    


}