pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * https://twitter.com/ttoonft
 * https://ttoonft.io
 * @title This Thing Of Ours
 * @author BowTiedPickle
 */
contract ThisThingOfOurs is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    event NewRoyalty(uint96 _newRoyalty);
    event NewPrice(uint256 _newPrice);
    event NewURI(string _newURI);
    event URIFrozen(string _finalURI);
    event NewRoot(uint8 _whitelist, bytes32 _root);
    event PublicSaleStarted(uint256 _available);
    event PublicSaleStopped();
    event WhitelistSaleStatus(bool _status);
    event Withdrawal(uint256 _balance);

    string public baseURI;
    bool public frozen;

    uint8 public constant REGULAR_WL = 1;
    uint8 public constant OG_WL = 2;
    uint8 public constant CAPO_WL = 3;

    bytes32 public merkleRoot;
    bytes32 public ogMerkleRoot;
    bytes32 public capoMerkleRoot;
    mapping(address => uint256) public claimedSoldiers;
    mapping(address => uint256) public claimedCapos;

    // TokenIds 1-163 are reserved for whitelisted Capos
    uint256 public nextId = 164;
    uint256 public nextCapo = 1;
    uint256 public constant maxCapoSupply = 163;

    uint256 public mintPrice = 250e6; // Denominated in USDC

    uint256 public constant maxSupply = 2000;

    bool public whitelistSaleActive;
    bool public publicSaleActive;
    uint256 public publicSupplyAvailable;

    IERC20 internal immutable USDC;

    /**
     * @param   _owner          Owner address
     * @param   _royaltyBPS     Royalty in basis points, max is 10% (1000 BPS)
     * @param   _merkleRoot     Merkle whitelist root for normal users
     * @param   _ogMerkleRoot   Merkle whitelist root for OG users
     * @param   _capoMerkleRoot Merkle whitelist root for Capo users
     * @param   _USDC           Address of the USDC token proxy
     * @param   _treasury       Address to receive initial allocation
     */
    constructor(
        address _owner,
        uint96 _royaltyBPS,
        bytes32 _merkleRoot,
        bytes32 _ogMerkleRoot,
        bytes32 _capoMerkleRoot,
        address _USDC,
        address _treasury
    ) ERC721("This Thing Of Ours", "TTOO") {
        require(_owner != address(0), "!addr");
        require(_USDC != address(0), "!addr");
        require(_royaltyBPS <= 1000, "!bps");

        // Set Ownership
        _transferOwnership(_owner);
        _setDefaultRoyalty(owner(), _royaltyBPS);

        // Set the merkle roots
        merkleRoot = _merkleRoot;
        ogMerkleRoot = _ogMerkleRoot;
        capoMerkleRoot = _capoMerkleRoot;

        // Set the USDC deployment
        USDC = IERC20(_USDC);

        // Mint admin allocation
        mintInternal(_treasury, 75, false);
    }

    /**
     * @notice  Mint an NFT
     * @dev     User must have approved this contract for mintPrice * total quantity.
                It is implicit that users should be only whitelisted for one category as they will not be able to utilize more than one tier fully.
     * @param   _whitelist      Enter 1 for regular WL, 2 for OG WL, 3 for Capo WL
     * @param   _regularQty     Amount of regular NFTs to mint
     * @param   _capoQty        Amount of Capos to mint
     * @param   _proof          Merkle proof for the chosen WL Merkle tree
     */
    function mint(
        uint8 _whitelist,
        uint256 _regularQty,
        uint256 _capoQty,
        bytes32[] calldata _proof
    ) external {
        require(whitelistSaleActive, "!phase");
        require(!publicSaleActive, "!phase");
        require(_regularQty > 0 || _capoQty > 0, "!qty");

        uint256 totalCost = mintPrice * (_regularQty + _capoQty);
        require(
            USDC.transferFrom(msg.sender, address(this), totalCost),
            "!value"
        );

        // Verify and assign tokenId based on which WL the user is in
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (_whitelist == REGULAR_WL) {
            require(MerkleProof.verify(_proof, merkleRoot, leaf), "!proof");
            require(_regularQty > 0, "!qty");

            claimedSoldiers[msg.sender] += _regularQty;
            require(claimedSoldiers[msg.sender] <= 2, "!max");

            mintInternal(msg.sender, _regularQty, false);
        } else if (_whitelist == OG_WL) {
            require(MerkleProof.verify(_proof, ogMerkleRoot, leaf), "!proof");
            require(_regularQty > 0, "!qty");

            claimedSoldiers[msg.sender] += _regularQty;
            require(claimedSoldiers[msg.sender] <= 3, "!max");

            mintInternal(msg.sender, _regularQty, false);
        } else if (_whitelist == CAPO_WL) {
            require(MerkleProof.verify(_proof, capoMerkleRoot, leaf), "!proof");

            claimedSoldiers[msg.sender] += _regularQty;
            claimedCapos[msg.sender] += _capoQty;
            require(claimedSoldiers[msg.sender] <= 2, "!max");
            require(claimedCapos[msg.sender] <= 1, "!max");

            if (_regularQty > 0) {
                mintInternal(msg.sender, _regularQty, false);
            }

            if (_capoQty > 0) {
                mintInternal(msg.sender, _capoQty, true);
            }
        } else {
            revert("!invalid");
        }
    }

    function mintInternal(
        address _to,
        uint256 _qty,
        bool _capo
    ) internal {
        uint256 i;
        uint256 tokenId;

        if (_capo) {
            for (; i < _qty; ) {
                tokenId = nextCapo;
                nextCapo++;
                _mint(_to, tokenId);

                unchecked {
                    ++i;
                }
            }
        } else {
            for (; i < _qty; ) {
                tokenId = nextId;
                nextId++;
                _mint(_to, tokenId);

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice  Purchase an NFT during public sale
     * @dev     User must have approved the contract for mintPrice
     * @param   _qty    Quantity of NFTs to purchase, must be > 0 and <= 4
     */
    function purchase(uint256 _qty) external {
        require(publicSaleActive, "!phase");
        require(_qty <= 4 && _qty > 0, "!qty");
        require(publicSupplyAvailable >= _qty, "!supply");

        // We have already checked this will not underflow
        unchecked {
            publicSupplyAvailable -= _qty;
        }

        require(
            USDC.transferFrom(msg.sender, address(this), mintPrice * _qty),
            "!value"
        );

        uint256 caposLeft = maxCapoSupply + 1 > nextCapo
            ? maxCapoSupply + 1 - nextCapo
            : 0;
        uint256 soldiersToMint = _qty;

        // Mint Capos if any are left, otherwise mint regular tokens
        if (caposLeft > 0) {
            uint256 caposToMint = _qty > caposLeft ? caposLeft : _qty;
            soldiersToMint = _qty > caposLeft ? _qty - caposLeft : 0;
            mintInternal(msg.sender, caposToMint, true);
        }

        if (soldiersToMint > 0) {
            mintInternal(msg.sender, soldiersToMint, false);
        }
    }

    // ----- View Functions -----

    /**
     * @notice  Get the total number of NFTs claimed for the user.
     * @param   _user   Address to query
     */
    function totalClaimed(address _user) external view returns (uint256) {
        return claimedSoldiers[_user] + claimedCapos[_user];
    }

    // ----- Admin Functions -----

    /**
     * @notice  Disable whitelist minting and start a public sale of the remaining supply
     */
    function startPublicSale() external onlyOwner {
        require(!publicSaleActive, "!phase");

        whitelistSaleActive = false;
        publicSaleActive = true;
        publicSupplyAvailable = (maxSupply +
            maxCapoSupply -
            nextId -
            nextCapo +
            2);
        // ----- Example Math -----
        // Mint 1000 regular + 100 Capos = 900 available
        //      2000 + 163 - 1159 - 101 + 2 = 900
        // Mint 1845 regular + 155 Capo = 0 available
        //      2000 + 163 - 2001 - 163 + 2 = 0
        // ------------------------

        emit PublicSaleStarted(publicSupplyAvailable);
    }

    /**
     * @notice  Stop a public sale
     */
    function stopPublicSale() external onlyOwner {
        require(publicSaleActive, "!phase");

        publicSaleActive = false;
        publicSupplyAvailable = 0;

        emit PublicSaleStopped();
    }

    /**
     * @notice  Start or stop the whitelist sale
     */
    function setWhitelistSaleStatus(bool _status) external onlyOwner {
        require(!publicSaleActive, "!phase");
        whitelistSaleActive = _status;

        emit WhitelistSaleStatus(_status);
    }

    /**
     * @notice  Set a new mint price
     * @param   _newPrice   New mint price in USDC (6 decimals)
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
        emit NewPrice(_newPrice);
    }

    /**
     * @notice  Withdraw profits from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.transfer(owner(), balance);
        emit Withdrawal(balance);
    }

    /**
     * @notice  Sets a new royalty numerator
     * @dev     Cannot exceed 10%
     * @param   _royaltyBPS   New royalty, denominated in BPS (10000 = 100%)
     * @return  True on success
     */
    function setRoyalty(uint96 _royaltyBPS) external onlyOwner returns (bool) {
        require(_royaltyBPS <= 1000, "!bps");

        _setDefaultRoyalty(owner(), _royaltyBPS);

        emit NewRoyalty(_royaltyBPS);
        return true;
    }

    /**
     * @notice  Set a new base URI
     * @param   _newURI     new URI string
     */
    function setURI(string memory _newURI) external onlyOwner {
        require(!frozen, "!frozen");
        baseURI = _newURI;
        emit NewURI(_newURI);
    }

    /**
     * @notice  Freeze the URI, preventing further changes
     */
    function freezeURI() external onlyOwner {
        require(!frozen, "!frozen");
        frozen = true;
        emit URIFrozen(baseURI);
    }

    /**
     * @notice  Set a Merkle root
     * @param   _whitelist  ID of the whitelist to change
     * @param   _root       New Merkle root
     */
    function setRoot(uint8 _whitelist, bytes32 _root) external onlyOwner {
        if (_whitelist == REGULAR_WL) {
            merkleRoot = _root;
        } else if (_whitelist == OG_WL) {
            ogMerkleRoot = _root;
        } else if (_whitelist == CAPO_WL) {
            capoMerkleRoot = _root;
        } else {
            revert("Not valid WL");
        }

        emit NewRoot(_whitelist, _root);
    }

    // ----- Overrides -----

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId ||
            ERC721.supportsInterface(interfaceId);
    }
}