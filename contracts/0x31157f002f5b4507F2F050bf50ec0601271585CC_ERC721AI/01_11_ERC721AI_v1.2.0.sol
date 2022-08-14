// SPDX-License-Identifier: MIT
// Inspired Contracts v1.2.0
// Creator: Inspired Member, LLC
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ERC721AI is ERC721A, Pausable, Ownable, IERC2981 {

// TYPES

    // Summary of mint information
    struct MintInto{
        // The maximum amount of tokens that can be minted.
        uint256 maxSupply;
        // The number of tokens minted.
        uint256 minted;
        // The price to mint 1 token.
        uint256 price;
        // Indicates if minting is active.
        bool active;
    }

// STATE VARIABLES
    
    // Maximum royalty that can be set (denominator)
    uint256 private constant ROYALTY_MAX=100;

    // The maximum amount of tokens that can be minted. 
    uint256 private _maxSupply;

    // The price to mint a single token.
    uint256 private _price;

    // The royalty amount (numerator)
    uint8 private _royaltyAmount;

    // The royalty address
    address private _royaltyAddress;

    // The base uri for token metadata
    string private _baseUri;

    // Mapping of admin addresses 
    mapping(address => bool) private _adminsMap;

    // List of addresses in admin map
    address[] private _adminsList;

    // Mapping of address to allowlist allocations (for mint)
    mapping(address => uint8) private _allows;
    
    // Merkleroot for bulk drops (for mintMerkle)
    bytes32 private _merkleRoot;

    // Counter used to 'reset' merkle claims across drops
    uint256 private _merkleCounter;

    // The maxiumum number of claims for each address in the merkle drop.
    uint8 private _merkleClaimLimit;
    
    // Mapping of address to merkle cliams, for a given merkle counter.
    mapping(uint256 => mapping(address => uint256)) private _merkleClaims;

// EVENTS

    /**
     * @dev Emitted when `value` is received from `from`.
     */
    event Receive(address from, uint256 value);

// MODIFIERS

    /**
     * @dev Modifier that checks if value sent is enough for quantity minted.
     */
    modifier paidEnough(uint8 quantity) {
        if(msg.value < quantity * _price){
            revert("Insufficient value");
        }
        _;
    }

    /**
     * @dev Modifier that checks if quantity is available to mint from the maxSupply.
     */
    modifier hasSupply(uint256 quantity) {
        if( ERC721A._totalMinted() + quantity > _maxSupply) {
            revert("Insufficient supply");
        }
        _;
    }

    /**
     * @dev Modifier that checks if sender is owner or has admin permission.
     */
    modifier onlyOwnerAndAdmins() {
      if (!(_adminsMap[_msgSender()] || owner() == _msgSender())) {
        revert ("Owner and admins only");
      }
        _;
    }

// CONSTRUCTOR

    constructor(string memory name_, string memory symbol_, string memory baseUri_) 
        ERC721A(name_, symbol_) Pausable() Ownable() {
        setBaseURI(baseUri_);
        setRoyalty(address(this), 10); // 10%
    }

// EXTERNAL

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    /**
     * @dev Airdrops `quantity` tokens to `to`.  
     *
     * Does not use allowlist or merkleclaim.
     */
    function airdrop(address to, uint8 quantity) external hasSupply(quantity) onlyOwnerAndAdmins {
        _safeMint(to, quantity);
    }

    /**
     * @dev Mints `quantity` tokens to `msg.sender` from allowlist.
     *
     * Requires allows(msg.sender) >= quantity.
     */
    function mint(uint8 quantity) external payable whenNotPaused hasSupply(quantity) paidEnough(quantity) {
        address minter = _msgSender();
        if (_allows[minter] < quantity) {
            revert("Insufficient allows");
        }
        _allows[minter] -= quantity;
        _safeMint(minter, quantity);
    }

    /**
     * @dev Mints `quantity` tokens to `msg.sender` from merkle drop.
     *
     * Requires claims(msg.sender) + `quantity` <= merkleClaimLimit()
     */
    function mintMerkle(
        uint8 quantity, 
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused hasSupply(quantity) paidEnough(quantity) {   
        address minter = _msgSender();
        bytes32 leaf = keccak256(abi.encodePacked(minter));
        if(!MerkleProof.verify(merkleProof, _merkleRoot, leaf)) {
            revert("Invalid merkle proof");
        }
        uint256 claims = _merkleClaims[_merkleCounter][minter] + quantity;
        if (claims > _merkleClaimLimit) {
            revert("Insufficient allows.");
        }
        _merkleClaims[_merkleCounter][minter] = claims;
        _safeMint(minter, quantity);
    }

     /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
    
    /**
     * @dev Sets the maximum supply of tokens that can be minted.
     */
    function setMaxSupply(uint256 maxSupply) external onlyOwnerAndAdmins {
        if(_maxSupply < ERC721A._totalMinted()) {
            revert("Invalid max supply");
        }
        _maxSupply = maxSupply;
    }

    /**
     * @dev Sets the price per token minted.
     */
    function setPrice(uint256 price) external onlyOwnerAndAdmins {
        _price = price;
    }
    
    /**
     * @dev Sets allowlist for all `addrs` to `quantity` (for mint)
     */
    function setAllows(address[] calldata addrs, uint8 quantity) external onlyOwnerAndAdmins {
        for(uint256 i = 0 ; i < addrs.length ; i++) {
            _allows[addrs[i]] = quantity;
        }        
    }

    /**
     * @dev Updates the merkleroot (for mintMerkle).
     *
     * Does not reset claim counts.
     */
    function setMerkleRoot(bytes32 merkleRoot_, uint8 claimLimit) external onlyOwnerAndAdmins {
        setMerkleRoot(merkleRoot_, claimLimit, false);
    }

    /**
     * @dev Updates the claim limit for merkleMint (number of tokens per address in drop)
     */
    function setMerkleClaimLimit(uint8 claimLimit) external onlyOwnerAndAdmins {
        _merkleClaimLimit = claimLimit;
    }

    /**
     * @dev Disables mints (from allowlist and merkle proofs)
     */
    function pause() external onlyOwnerAndAdmins {
        _pause();
    }    

    /**
     * @dev Enables mints (from allowlist and merkle proofs).
     */
    function unpause() external onlyOwnerAndAdmins {
        _unpause();
    }

    /**
     * @dev Add addr as admin account
     */
    function addAdmin(address addr) external onlyOwner {
        if(!_adminsMap[addr]){
            _adminsMap[addr] = true;
            _adminsList.push(addr);
        }
    }

    /**
     * @dev Removes addr as admin account
     */
    function removeAdmin(address addr) external onlyOwner {
        if(_adminsMap[addr]) {
            delete _adminsMap[addr];
            uint256 loc;
            for (uint256 i = 0; i < _adminsList.length; i++) {
                if (_adminsList[i] == addr) {
                    loc = i;
                    break;
                }
            }
            _adminsList[loc] = _adminsList[_adminsList.length - 1];
            _adminsList.pop();
        }
    }

    /**
     * @dev Transfers funds from the contract balance to `to`.
     */
    function withdraw(address to, uint256 amount) external  onlyOwner {
        if(amount > address(this).balance){
            revert("Invalid withdraw amount");
        }
        address payable receiver = payable(to);
        receiver.transfer(amount);
    }    

    /**
     * @dev Transfers ERC20 funds from the contract balance to `to`
     */
    function withdrawERC20(address to, address tokenAddress, uint256 amount) external onlyOwner {   
        IERC20 tokenContract = IERC20(tokenAddress);
        if(amount > tokenContract.balanceOf(address(this))){
            revert("Invalid withdraw amount");
        }
        require(tokenContract.transfer(to, amount), "Transfer failed");
    }

// EXTERNAL VIEW

    /**
     * @dev Gets the base URI.
     */
    function baseURI() external view returns (string memory) {
       return _baseURI();
    }

    /**
     * @dev Gets detailed related to the mint sale.
     */
    function info() external view returns (MintInto memory) {
        MintInto memory mintInfo = MintInto({
            maxSupply: _maxSupply,
            minted: ERC721A._totalMinted(),
            price: _price,
            active: !paused()
        });
        return mintInfo;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) external view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * _royaltyAmount) / ROYALTY_MAX;
        return (_royaltyAddress, royaltyAmount);
    }

    /**
     * @dev Gets `addr` allow list allocations for mint.
     */
    function allows(address addr) external view returns (uint8) {
        return _allows[addr];
    }

    /**
     * @dev Gets the merkle root used for mintMerkle.
     */
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    } 

    /**
     * @dev The maxiumum number of claims for each address in the merkle drop.
     */
    function merkleClaimLimit() external view returns (uint8) {
        return _merkleClaimLimit;
    } 

    /**
     * @dev Gets `addr` number of tokens claims in current merkle root.
     */
    function merkleClaims(address addr) external view returns (uint256) {
        return _merkleClaims[_merkleCounter][addr];
    } 

    /**
     * Returns the total number of tokens minted by `addr`.
     */
    function mints(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    /**
     * @dev Gets admins
     */
    function admins() external view returns (address[] memory) {
        return _adminsList;
    }

// PUBLIC

    /**
     * @dev Updates the merkleroot and claim limit (for mintMerkle).
     *
     * Use `resetClaims` = true to clear previous claims counts.
     */
    function setMerkleRoot(bytes32 merkleRoot_, uint8 claimLimit, bool resetClaims) public onlyOwnerAndAdmins {
        _merkleRoot = merkleRoot_;
        _merkleClaimLimit = claimLimit;
        if(resetClaims) {
            _merkleCounter++;
        }
    }

    /**
     * @dev Sets the base URI for computing {tokenURI}. If set, the resulting URI 
     * for each token will be the concatenation of the `baseURI` and the `tokenId`. 
     * Empty by default, can be overriden in child contracts.
     */
    function setBaseURI(string memory uri) public onlyOwnerAndAdmins {
       _baseUri = uri;
    }

    /**
     * @dev Sets the royaly address and percentage for IERC2981 standard. 
     * royaly % = feeNumerator / feeDenominator (100)
     */
    function setRoyalty(address addr, uint8 royalty) public onlyOwnerAndAdmins {
        if (_royaltyAmount > ROYALTY_MAX) {
            revert ("Invalid royalty");
        }
        _royaltyAddress = addr;
        _royaltyAmount = royalty;
    }

// PUBLIC VIEW

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
// INTERNAL

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {ERC721A-_startTokenId}.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}