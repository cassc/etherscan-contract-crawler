// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

contract VoltiEco is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable {

    uint256 public minVoltAmount;
    uint256 public maxWalletsAssociate;
    uint256 public tokenId = 0;
    uint256 public lockDate = 1 hours;

    address public owner;
    address public VOLT;
    address public VDSC;
    address[] public owners;
    
    string uriIPFS;

    bool public isPaused = true;

    // VoltiEco nft id => vdsc nft id
    mapping(uint256 => uint256) public nftOwners;

    // nft id => lock date
    mapping(uint256 => uint256) public nftLockDate;


    event Withdraw(
        address indexed user,
        uint256 indexed tokenid,
        uint256 indexed vdscid
    );

    event Stake(
        address indexed user,
        uint256 indexed tokenid,
        uint256 indexed vdscid
    );

    event Distribute(
        address indexed token,
        uint256 amount,
        address[] indexed users
    );

    constructor(uint256 _minVoltAmount, uint256 _maxWalletsAssociate,address _volt,address _vdsc,string memory _uriipfs) {
        require(_volt!=address(0),"");
        require(_vdsc!=address(0),"");
        initialize();
        minVoltAmount = _minVoltAmount;
        maxWalletsAssociate = _maxWalletsAssociate;
        owner = msg.sender;
        VOLT = _volt;
        VDSC = _vdsc;
        uriIPFS = _uriipfs;
    }

    function getminVoltAmount() public view returns(uint256){
        return minVoltAmount;
    }

    function getmaxWalletsAssociate() public view returns(uint256){
        return maxWalletsAssociate;
    }

    function gettokenId() public view returns(uint256){
        return tokenId;
    }

    function getowner() public view returns(address){
        return owner;
    }

    function getVOLT() public view returns(address){
        return VOLT;
    }

    function getVDSC() public view returns(address){
        return VDSC;
    }

    function getisPaused() public view returns(bool){
        return isPaused;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner of the contract.");
        _;
    }

    // CONFIG FUNCTIONS

    function initialize() initializer internal {
        __ERC721_init("VoltiEco", "VTEC");
        __ERC721Burnable_init();
    }

    function updateLockDate(uint256 newData) public onlyOwner {
        lockDate = newData;
    }

    function updateMaxWalletsAssociate(uint256 newData) public onlyOwner {
        maxWalletsAssociate = newData;
    }

    function updateOwner(address newData) public onlyOwner {
        owner = newData;
    }

    function updateUriIPFS(string memory newData) public onlyOwner {
        uriIPFS = newData;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriIPFS;
    }

    /* 
        VOLTIECO FUNCTIONS
     */

    function safeMint(address to, uint256 vdscTokenId) public {
        require(balanceOf(to) < 5, "nfts capacity per wallet reached");
        require(IERC20(VOLT).transferFrom(msg.sender,address(this), minVoltAmount));
        require(maxWalletsAssociate > owners.length,"Nfts limit reached.");
        tokenId = tokenId + 1;
        IERC721(VDSC).transferFrom(msg.sender, address(this), vdscTokenId);
        nftOwners[tokenId] = vdscTokenId;

        _safeMint(to, tokenId);
        owners.push(msg.sender);
        nftLockDate[tokenId] = block.timestamp + lockDate;
        emit Stake(msg.sender, tokenId, vdscTokenId);
    }

    function multiSafeMint(address to, uint256[] calldata vdscTokenId) public {
        require((balanceOf(to) + vdscTokenId.length) <= 5, "nfts capacity per wallet reached");
        require(maxWalletsAssociate >= owners.length + vdscTokenId.length,"Not enough items");
        for (uint i = 0; i < vdscTokenId.length; i++){
            safeMint(to, vdscTokenId[i]);
        }
    }

    function burn(uint256 tokenid) internal override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenid);

        for (uint i = 0; i < owners.length; i++) { 
            if (owners[i] == msg.sender) {  
                owners[i] = owners[owners.length-1];
                owners.pop();
                return;  
            }
        }
    }

    function withdraw(uint256 tokenid) public {
        require(_exists(tokenid), "Nft not exists.");
        require(ownerOf(tokenid) == msg.sender,"You are not the owner of nft.");
        require(!isPaused || block.timestamp >= nftLockDate[tokenId], "Withdrawal of blocked funds");

        IERC20(VOLT).transfer(msg.sender, minVoltAmount);
        IERC721(VDSC).transferFrom(address(this), msg.sender, nftOwners[tokenid]);
        // burn(tokenid);

        _burn(tokenid);

        emit Withdraw(msg.sender,tokenid,nftOwners[tokenid]);

        delete nftOwners[tokenid];

        for (uint i = 0; i < owners.length; i++) { 
            if (owners[i] == msg.sender) {  
                owners[i] = owners[owners.length-1];
                owners.pop();
                return;
            }
        }
    }

    function circulationSupply() public view returns(uint256){
        return owners.length;
    }

    function totalSupply() public view returns(uint256){
        return maxWalletsAssociate;
    }

    function distributeRewards(
        address tokenAddress,
        uint256 totalAmount
    ) public {
        // Obter a instância do token
        IERC20 token = IERC20(tokenAddress);

        // Verificar se o contrato tem permissão para transferir tokens em nome do remetente
        require(token.allowance(msg.sender, address(this)) >= totalAmount, "Not enough allowance to distribute");

        uint256 numRecipients = owners.length;
        uint256 amountPerRecipient = totalAmount / numRecipients;

        // Distribuir os tokens igualmente entre os endereços
        for (uint256 i = 0; i < numRecipients; i++) {
            token.transferFrom(msg.sender, owners[i], amountPerRecipient);
        }
    }

    function recoverTokens(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(tokenAmount <= contractBalance, "Insufficient contract balance");
        token.transfer(owner, tokenAmount);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenid
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenid), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenid);
        for (uint i = 0; i < owners.length; i++) { 
            if (owners[i] == _msgSender()) {  
                owners[i] = to;
                return;
            }
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenid
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenid), "ERC721: caller is not token owner or approved");
        safeTransferFrom(from, to, tokenid, "");
        for (uint i = 0; i < owners.length; i++) { 
            if (owners[i] == _msgSender()) {  
                owners[i] = to;
                return;
            }
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenid,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenid), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenid, data);
        for (uint i = 0; i < owners.length; i++) { 
            if (owners[i] == _msgSender()) {  
                owners[i] = to;
                return;
            }
        }
    }
}

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

interface IERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function totalSupply() external view returns (uint256);
}