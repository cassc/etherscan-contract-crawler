// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@notice access control
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice libraries & utils
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice ERC721, extensions & interfaces
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @notice ERC721
import "./ERC721A.sol";

/* 
    @title Spartan Pass
    @notice ERC721-ready Spartan contract
    @author cryptoware.eth | Spartan
*/

contract Spartan721A is Ownable, ERC721A, Pausable, PaymentSplitter {
    /// @notice using Strings for uints conversions such as => tokenId
    using Strings for uint256;

    /// @notice using Address for addresses extended functionality
    using Address for address;

    /// @notice using MerkleProof library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// This is a Uniform Resource Identifier, distinct used to identify each unique nft from the other.
    string private _baseTokenURI;

    /// @notice root of the new Merkle tree
    bytes32 private _merkleRoot;

    /// @notice the max supply fot SFTs and NFTs, metadata file type
    string private constant _METADATA_EXTENSION = ".json";

    /// @notice max amount of nfts that can be minted per wallet address
    uint32 public mintingLimit;

    /// @notice the mint price of each NFT
    uint256 public mintPrice;

    ///@notice the minimum price of ethereum in dollars
    uint256 public minEthPriceInDollars;

    /// @notice Indicates if the mint id has been already used
    mapping(bytes16 => bool) public mintId;

    /// @notice indicates the amount of mints per user
    mapping(address => uint256) public mintsPerUser;

    ///@notice Minter address that can mint to custodial
    address public minterAddress;

    ///@notice Max token Id that can be minted;
    uint256 public maxId;

    /// @notice Admin mint event to be emitted when an Admin mints
    event AdminMinted(
        address indexed to,
        uint256 indexed startToken,
        uint256 quantity
    );

    /// @notice Mint event to be emitted upon NFT mint
    event Minted(
        address indexed to,
        uint256 indexed startToken,
        uint256 quantity
    );

    /// @notice Event that indicates which mint id has been used during minting
    event MintIdUsed(bytes16 indexed mintId);

    modifier onlyOwnerOrMinter() {
        require ((owner() == msg.sender) || (minterAddress == msg.sender), "The caller of the contract is neither the owner nor the minter");
        _;
    }

    /**
     * @notice constructor
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param uri_ token metadata URI
     **/
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint32 mintingLimit_,
        uint32 maxId_,
        uint256 mintPrice_,
        uint256 minEthPriceInDollars_,
        bytes32 root_,
        address minterAddress_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_) Ownable() PaymentSplitter(payees_, shares_) {
        _merkleRoot = root_;
        mintingLimit = mintingLimit_;
        mintPrice = mintPrice_;
        maxId = maxId_;
        _baseTokenURI = uri_;
        minterAddress = minterAddress_;
        minEthPriceInDollars = minEthPriceInDollars_;
    }

    /// @notice pauses the contract (minting and transfers)
    function pause() external virtual onlyOwner {
        _pause();
    }

    /// @notice unpauses the contract (minting and transfers)
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @notice changes the mint amount per wallet address
     * @param mintingLimit_ number of mints per wallet address
     **/
    function changeMintingLimitPerUser(uint32 mintingLimit_)
        external
        onlyOwner
    {
        require(
            mintingLimit_ != mintingLimit,
            "SPTN: Minting limit should be different from the previous value."
        );
        mintingLimit = mintingLimit_;
    }

    /**
     * @notice changes the minEthPrice
     * @param minterAddress_  min price of eth
     **/
    function changeMinterAddress (address minterAddress_) external onlyOwner{
        require(
            minterAddress != minterAddress_, 
            "SPTN: Minter address can not be same"
        );
        minterAddress = minterAddress_;
    }

    /**
     * @notice changes the minEthPrice in dollars
     * @param minEthPrice_  min price of eth
     **/
    function changeMinEthPrice(uint256 minEthPrice_) external onlyOwner {
        require(
            minEthPriceInDollars != minEthPrice_, 
            "SPTN: Min ETH Price should be different than the previous price"
        );
        minEthPriceInDollars = minEthPrice_;
    }


    /**
     * @notice changes the mint price of an already existing token ID
     * @param mintPrice_ new mint price of token
     **/
    function changeMintPriceOfToken(uint256 mintPrice_) external onlyOwner {
        require(
            mintPrice_ != mintPrice,
            "SPTN: Mint Price should be different than the previous price"
        );
        mintPrice = mintPrice_;
    }

    /**
     * @notice changes the max supply of an already existing token ID
     * @param maxId_ id of token
     **/
    function changeMaxSupplyOfToken(uint256 maxId_) public onlyOwner {
        require(
            maxId_ != maxId,
            "SPTN: Max Supply should be different than the previous supply"
        );

        maxId = maxId_;
    }

    /**
     * @notice gets the URI per token ID
     * @param tokenId token type ID to return proper URI
     **/
    function uri(uint256 tokenId) public view virtual returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (tokenId <= maxId) {
            return
                string(
                    abi.encodePacked(
                        _baseTokenURI,
                        tokenId.toString(),
                        _METADATA_EXTENSION
                    )
                );
        }
    }

    function changeBaseUri(string memory newBaseUri_) public onlyOwner{
        require(
            (keccak256(abi.encodePacked((newBaseUri_))) !=
                keccak256(abi.encodePacked((_baseTokenURI)))),
            "SPTN: Base URI cannot be same as previous"
        );
        _baseTokenURI = newBaseUri_;
    }

    /**
     * @notice mints tokens based on parameters
     * @param to address of the user minting
     * @param amount amount of tokens to be minted
     * @param proof_ verify if msg.sender is allowed to mint
     * @param mintId_ mint id used to mint
     **/
    function mint(
        address to,
        uint32 amount,
        bytes32[] memory proof_,
        bytes16 mintId_,
        uint256 currentEthPrice
    ) external payable whenNotPaused {
        uint256 received = msg.value; //Wei
        uint256 dollarsExpected = mintPrice*amount; //Dollar
        uint256 minDollarsExpected = dollarsExpected-(dollarsExpected/100); //Dollar
        uint256 maxDollarsExpected = dollarsExpected+(dollarsExpected/100); //Dollar

        require(to != address(0), "SPTN: Address cannot be 0");
        require(currentEthPrice>=minEthPriceInDollars, "SPTN: Invalid ETH Price");
        require(
            minDollarsExpected<= (received*currentEthPrice/1000000000000000000), //Dollar
            "SPTN: Dollars sent is less than the minimum"
        );
        require(
            (received*currentEthPrice/1000000000000000000)<=maxDollarsExpected, //Dollar
            "SPTN: Dollars sent is more than the maximum"
        );
        require(
            _currentIndex + (amount - (1)) <= maxId,
            "SPTN: max SPARTAN token limit exceeded"
        );
        require(
            mintsPerUser[to] + amount <= mintingLimit,
            "SPTN: Max NFT per address exceeded"
        );
        require(!mintId[mintId_], "SPTN: mint id already used");
        _merkleRoot > bytes32(0) && isAllowedToMint(proof_, mintId_);
        mintsPerUser[to] += amount;
        mintId[mintId_] = true;

        uint256 startToken = _currentIndex;
        _safeMint(to, amount);

        emit Minted(to, startToken, amount);
        emit MintIdUsed(mintId_);
    }

    /**
     * @notice a function for admins to mint cost-free
     * @param to the address to send the minted token to
     * @param amount amount of tokens to be minted
     **/
    function adminMint(address to, uint256 amount)
        external
        whenNotPaused
        onlyOwnerOrMinter
    {
        require(to != address(0), "SPTN: Address cannot be 0");

        require(_currentIndex <= maxId, "SPTN: Token id mismatch");

        require(amount + _currentIndex <= maxId + 1, "SPTN: Amount mismatch");

        uint256 startToken = _currentIndex;
        _safeMint(to, amount);
        emit AdminMinted(to, startToken, amount);
    }

    /**
     * @notice the public function validating addresses
     * @param proof_ hashes validating that a leaf exists inside merkle tree aka _merkleRoot
     * @param mintId_ Id sent from the db to check it this token number is minted or not
     **/
    function isAllowedToMint(bytes32[] memory proof_, bytes16 mintId_)
        internal
        view
        returns (bool)
    {
        require(
            MerkleProof.verify(
                proof_,
                _merkleRoot,
                keccak256(abi.encodePacked(mintId_))
            ),
            "SPTN: Please register before minting"
        );
        return true;
    }

    /**
     * @notice changes merkleRoot in case whitelist list updated
     * @param merkleRoot_ root of the Merkle tree
     **/

    function changeMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        require(
            merkleRoot_ != _merkleRoot,
            "SPTN: Merkle root cannot be same as previous"
        );
        _merkleRoot = merkleRoot_;
    }

    /**
     * @notice a burn function for burning specific tokenId
     * @param tokenId Id of the Token
     **/

    function burn(uint256 tokenId) external {
        require(_msgSender() != address(0), "SPTN: Address cannot be 0");
        require(_exists(tokenId), "SPTN: Token Id does not exist");
        require(
            _ownershipOf(tokenId).addr == _msgSender(),
            "SPTN: You do not own this token"
        );
        _burn(tokenId);
    }

    /**
     * @notice a function for admins to transfer tokens
     * @param from current owner of the token
     * @param to new owner of the token
     * @param tokenId Id of the Token
     **/
    function adminTransfer(
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        require(_exists(tokenId), "SPTN: Token Id does not exist");
        require(
            _ownershipOf(tokenId).addr == from,
            "SPTN: Address does not own this token"
        );
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        _beforeTokenTransfers(from, to, tokenId, 1);

        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }
}