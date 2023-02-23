// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721psi/ERC721Psi.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Helper we wrote to encode in Base64
import "../libs/Base64.sol";
import "../interfaces/IGenesisOwnerKey.sol";
import "solidity-bits/contracts/BitMaps.sol";

// Hardhat util for console output
//import "hardhat/console.sol";

contract GenesisOwnerKey is ERC721Psi, IGenesisOwnerKey, Ownable {
    struct GameProp {
        uint256 token_transaction;
        uint256 game_play;
    }

   // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;

    using Strings for uint256;
    // A modifier to lock/unlock token transfer
    bool public locked;
    bool public tradingAllowed;
    address public nftPoolAddress;
    mapping(uint256 => GameProp) internal _gameProps;
    uint256 public maxOwnLimit = 2;

    string public tierName;
    string public tierImageURI;
    string public tierAnimationURL;
    string public tierExternalURL;

    uint256 public tierSupply;

    constructor(string memory name_, string memory symbol_)
        ERC721Psi(name_, symbol_)
    {}

    modifier notLocked() {
        require(!locked, "GenesisOwnerKey: can't operate - currently locked");
        _;
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function initialize(
        string calldata _tierName,
        string calldata _tierImageURI,
        uint256 _tierSupply
    ) external onlyOwner {
        tierName = _tierName;
        tierImageURI = _tierImageURI;
        tierSupply = _tierSupply;
    }

    // ---------------------------------------
    // -          External Functions         -
    // ---------------------------------------
    function setupPool(address nftpool) external onlyOwner {
        require(nftpool != address(0), "GenesisOwnerKey: ZERO_ADDRESS");
        nftPoolAddress = nftpool;
        emit SetupPool(msg.sender, nftpool);
    }

    function toggleLock() external onlyOwner {
        locked = !locked;
        emit Locked(msg.sender, locked);
    }

    function toggleTradingAllowed() external onlyOwner {
        tradingAllowed = !tradingAllowed;
        emit TradingAllowed(msg.sender, tradingAllowed);
    }

    function mint(address to, uint256 quantity) public onlyOwner {
        require(
            tierSupply == totalSupply() + quantity,
            "GenesisOwnerKey: The tier qunatity doesn't match"
        );
        _safeMint(to, quantity);
        emit Mint(_msgSender(), to, quantity);
    }

    // Batch minting to all tiers for gas optimization
    function mintToPool() external onlyOwner {
        require(
            nftPoolAddress != address(0),
            "GenesisOwnerKey: POOL_ZERO_ADDRESS"
        );
        require(tierSupply > 0, "GenesisOwnerKey: NOT_INITIALIZED");
        require(
            tierSupply > totalSupply(),
            "GenesisOwnerKey: ALREADY_MINT_TO_POOL"
        );
        uint256 mintAmount = tierSupply - totalSupply();

        _safeMint(nftPoolAddress, mintAmount);
        emit MintToPool(msg.sender, mintAmount);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }

    function setImage(string calldata _url) external onlyOwner {
        tierImageURI = _url;
        emit UpdateMetadataImage(_url);
    }

    function setAnimationUrls(string calldata _url) external onlyOwner {
        tierAnimationURL = _url;
        emit UpdateMetadataAnimationUrl(_url);
    }

    function setExternalUrls(string calldata _url) external onlyOwner {
        tierExternalURL = _url;
        emit UpdateMetadataExternalUrl(_url);
    }

    function setGameProp(
        uint256 tokenId,
        uint256 gameplay,
        uint256 tokentransaction
    ) external onlyOwner {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        _gameProps[tokenId].game_play = gameplay;
        _gameProps[tokenId].token_transaction = tokentransaction;
    }

    // ---------------------------------------
    // -          Public Functions           -
    // ---------------------------------------
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        GameProp memory gp = _gameProps[tokenId];
        string memory strTokenId = Strings.toString(tokenId);
        string memory s1 = string(
            abi.encodePacked(
                '{"name": "',
                name(),
                ": ",
                tierName,
                " #",
                strTokenId,
                '", "image": "',
                tierImageURI,
                '", "external_url": "',
                tierExternalURL,
                '", "animation_url": "',
                tierAnimationURL
            )
        );
        string memory s2 = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        s1,
                        '", "description": "PlayEstates Founding Member Token"',
                        ', "attributes": [',
                        '{ "trait_type": "Tier", "value": "',
                        tierName,
                        '"},',
                        '{ "trait_type": "ID", "value": "',
                        strTokenId,
                        '"},',
                        '{ "display_type": "number", "trait_type": "Game Play", "value": ',
                        Strings.toString(gp.game_play),
                        "},",
                        '{ "display_type": "number", "trait_type": "Token Transaction", "value": ',
                        Strings.toString(gp.token_transaction),
                        "}",
                        "]}"
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", s2)
        );
        return output;
    }

    function gamePlayOf(uint256 tokenId) public view returns (uint256) {
        return _gamePropOf(tokenId).game_play;
    }

    function tokenTransactionOf(uint256 tokenId) public view returns (uint256) {
        return _gamePropOf(tokenId).token_transaction;
    }

    // ---------------------------------------
    // -          Internal Functions         -
    // ---------------------------------------
    function _gamePropOf(uint256 tokenId)
        internal
        view
        returns (GameProp memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        GameProp memory gameprop = _gameProps[tokenId];
        return gameprop;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function setMaxOwnLimit(uint256 _maxLimit) public onlyOwner {
        maxOwnLimit = _maxLimit;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 quantity
    ) internal virtual override {
        require(!locked, "GenesisOwnerKey: can't operate - currently locked");

        // Checking sender side
        if (from == address(0)) {
            // if minting, then return
            return;
        }
        // Checking receiver
        if (to == address(0)) {
            //if burning, then return
            return;
        }
        if (from == nftPoolAddress) {
            if (to != nftPoolAddress) {
                require(
                    balanceOf(to) + quantity <= maxOwnLimit,
                    "GenesisOwnerKey: Member Maximum Limit"
                );
            }
        } else {
            if (to != nftPoolAddress) {
                require(
                    tradingAllowed,
                    "GenesisOwnerKey: user transfer coming soon"
                );
                require(
                    balanceOf(to) + quantity <= maxOwnLimit,
                    "GenesisOwnerKey: Member Maximum Limit"
                );
            }
        }
    }

    // ---------------------------------------
    // -          Burn Features          -
    // ---------------------------------------

    // for Burn
   /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        
        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view override virtual returns (bool){
        if(_burnedToken.get(tokenId)) {
            return false;
        } 
        return super._exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned();
    }

    /**
     * @dev Returns number of token burned.
     */
    function _burned() internal view returns (uint256 burned){
        uint256 totalBucket = (_minted >> 8) + 1;

        for(uint256 i=0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    /**
     * @dev Returns number of set bits.
     */
    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked{
            for (count=0; x!=0; count++)
                x &= x - 1;
        }
    }

    // ---------------------------------------
    // -          BalanceOf Features          -
    // ---------------------------------------    
        /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(owner_ != address(0), "ERC721Psi: balance query for the zero address");
        return uint256(_addressData[owner_].balance);   
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        require(quantity < 2 ** 64);
        uint64 _quantity = uint64(quantity);

        if(from != address(0)){
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if(to != address(0)){
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }
}