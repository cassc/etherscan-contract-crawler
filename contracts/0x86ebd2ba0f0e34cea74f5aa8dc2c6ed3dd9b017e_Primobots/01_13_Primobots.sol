// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Primobots

// .______   .______       __  .___  ___.   ______   .______     ______   .___________.    _______.
// |   _  \  |   _  \     |  | |   \/   |  /  __  \  |   _  \   /  __  \  |           |   /       |
// |  |_)  | |  |_)  |    |  | |  \  /  | |  |  |  | |  |_)  | |  |  |  | `---|  |----`  |   (----`
// |   ___/  |      /     |  | |  |\/|  | |  |  |  | |   _  <  |  |  |  |     |  |        \   \
// |  |      |  |\  \----.|  | |  |  |  | |  `--'  | |  |_)  | |  `--'  |     |  |    .----)   |
// | _|      | _| `._____||__| |__|  |__|  \______/  |______/   \______/      |__|    |_______/

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title Primobots Smart Contract
/// @author Primobots Team
/// @notice This smart contract will fulfill the need of Primobots Collection drop
/// @dev This smart contract uses ERC721A, newly created and optimised verison of ERC721.
contract Primobots is ERC721A, Ownable, Pausable {
    /// @notice Price of each Primobot during main sale
    /// @return MINTING_PRICE uint256 price per Primobot
    uint256 public constant MINTING_PRICE = 0.0888 ether;

    /// @notice Price per each Primobot during presale
    /// @return PRESALE_PRICE uint256 price per Primobot during presale
    uint256 public constant PRESALE_PRICE = 0.05 ether;

    /// @notice Maximum number of Primobots that can ever exist
    /// @return HARD_CAP uint256 Maximum number of Primobots that can ever exist
    uint256 public constant HARD_CAP = 5_555;

    /// @notice Maximum number of Primobots to be sold in presale
    /// @return PRESALE_CAP uint256 Maximum number of Primobots to be sold in presale
    uint256 public constant PRESALE_CAP = 555;

    /// @notice Number of Primobots that will be minted and reserved at Primobots Vault
    /// @return RESERVED_CAP uint256 Number of Primobots that will be minted and reserved at Primobots Vault
    uint256 public constant RESERVED_CAP = 200;

    /// @notice Maximum number of Primobots allowed to buy per wallet and per transaction
    /// @return amountMinted uint256 Maximum number of Primobots allowed to buy per wallet and per transaction
    uint256 public constant MAX_LIMIT = 10;

    /// @notice Maximum number of Primobots allowed to buy per whitelisted wallet
    /// @return MAX_PRESALE_LIMIT uint8 Maximum number of Primobots allowed to buy per whitelisted wallet
    uint256 public constant MAX_PRESALE_LIMIT = 1;

    /// @notice Percentage adjusted to account for floating point, i.e. 100000 - 100%
    /// @return ROYALTY_HUNDRED_PERCENT uint256 100000 that represents 100%
    uint256 public constant ROYALTY_HUNDRED_PERCENT = 100_000;

    // bytes4 interface ID of ERC2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice Mapping of address and tokens minted by that address
    /// @return amountMinted uint8 number of tokens minted
    mapping(address => uint8) public minted;

    /// @notice Represents the state of presale,
    /// @return whitelist_active if true - presale active
    bool public whitelist_active;

    /// @notice Represents the state of sale (presale and main sale),
    /// @return sale_active if true - sale active
    bool public sale_active;

    /// @notice Represents the state of collection reveal,
    /// @return is_collection_revealed if true - collection is revealed
    bool public is_collection_revealed;

    /// @notice Represents the state of collection lock
    /// @return is_collection_locked if true - collection is locked and metadata cannot be updated
    bool public is_collection_locked;

    /// @notice Represents the state of collection sale end (after which no tokens can be sold)
    /// @return sale_ended if true - sale ended.
    bool public sale_ended; //

    /// @notice IPFS hash or CID which points to file or folder that contains the metadata
    /// @return ipfsHash IPFS CID
    string public ipfsHash;

    /// @notice IPFS hash or CID which points to JSON file that contains list of addresses that are whitelisted
    /// @return whitelistHash IPFS CID
    string public whitelistHash;

    /// @notice initial royalties value is 7.5%
    /// @return royaltiesValue uint256 royalties value
    uint256 public royaltiesValue = 7_500;

    /// @notice Merkle root of the tree generated using the list of whitelist addresses
    /// @return MERKLE_ROOT bytes32 merkle root
    bytes32 public MERKLE_ROOT;

    /// @notice address of Primobots vault
    /// @dev it will be a multisig wallet Gnosis Safe
    /// @return vault_address address of Primobots vault
    address public vault_address;

    // modifier that only allows function execution is collection is not locked
    modifier collectionNotLocked() {
        require(!is_collection_locked, "Collection locked");
        _;
    }

    /// @notice Sets name, ticker, whitelist info and pre-reveal media
    /// @param _name name of collection
    /// @param _ticker ticker of collection
    /// @param _ipfsHash IPFS hash or CID of pre-reveal media
    /// @param _whitelistHash IPFS hash or CID of JSON file which contains list of addresses that are whitelisted
    /// @param _vaultAddress address of vault
    /// @param _merkleRoot bytes32 merkle root of merkle tree generated using the whitelist addresses
    constructor(
        string memory _name,
        string memory _ticker,
        string memory _ipfsHash,
        string memory _whitelistHash,
        address _vaultAddress,
        bytes32 _merkleRoot
    ) ERC721A(_name, _ticker) {
        // set pre-reveal media
        ipfsHash = _ipfsHash;

        // set Primobots vault address
        vault_address = _vaultAddress;

        // set whitelist
        whitelistHash = _whitelistHash;
        MERKLE_ROOT = _merkleRoot;

        // reserve tokens
        _safeMint(vault_address, RESERVED_CAP);
    }

    //------------------------------------------------------//

    // Owner Functions

    //------------------------------------------------------//

    /// @notice set new IPFS hash
    /// @dev only by owner and when colelction is not locked
    /// @param _ipfsHash new IPFS hash or CID of file or folder that contains collection metadata
    function fixIpfsHash(string memory _ipfsHash)
        external
        onlyOwner
        collectionNotLocked
    {
        ipfsHash = _ipfsHash;
    }

    /// @notice method to start main sale
    /// @dev start main sale and stop presale, only invoked by owner when collection not locked
    function startSale() external onlyOwner collectionNotLocked {
        if (whitelist_active) {
            whitelist_active = false;
        }
        sale_active = true;
    }

    /// @notice method to start presale
    /// @dev start presale, only invoked by owner when collection not locked
    function startPresale() external onlyOwner collectionNotLocked {
        sale_active = true;
        whitelist_active = true;
    }

    /// @notice pause Primobot sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function pause() external onlyOwner collectionNotLocked {
        _pause();
    }

    /// @notice unpause Primobot sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function unpause() external onlyOwner collectionNotLocked {
        _unpause();
    }

    /// @notice locks collection so owner cannot change metadata of the collection
    /// @dev Explain to a developer any extra details
    function lockCollection() external onlyOwner collectionNotLocked {
        is_collection_locked = true;
    }

    /// @notice update the whitelist
    /// @dev sets new whitelist hash and merkle root
    /// @param _whitelistHash new IPFs hash or CID of JSON file that contains list of addresses that are whitelisted
    /// @param _root new merkle root generated by using the provided whitelist address
    function updateWhitelist(string memory _whitelistHash, bytes32 _root)
        external
        onlyOwner
        collectionNotLocked
    {
        whitelistHash = _whitelistHash;
        MERKLE_ROOT = _root;
    }

    /// @notice end sale, no more Primobots can be bought after this method is invoked
    /// @dev only owner can end sale and stop any further sale
    function endSale() external onlyOwner {
        sale_ended = true;
    }

    /// @notice transfer remaining Primobots after the sale ends.
    /// @dev only owner can transfer the Primobots
    /// @param _receiver receiver of Primbots
    /// @param _quantity number of Primobots to be minted to specified address
    function transferRemaining(address _receiver, uint256 _quantity)
        external
        onlyOwner
    {
        require(sale_ended, "Sale hasn't ended");
        require(
            totalSupply() + _quantity <= HARD_CAP,
            "Cannot exceed hard cap"
        );
        _safeMint(_receiver, _quantity);
    }

    /// @notice set new royalties percentage between 0%-10%
    /// @param _value new percentage, 1% - 1000, 100% - 100000
    function setRoyalties(uint256 _value) external onlyOwner {
        // royalties can be between 0% - 10%
        require(_value >= 0 && _value <= 10_000, "out of bounds");
        royaltiesValue = _value;
    }

    /// @notice reveal collection
    /// @dev sets state to collection revealed and updates with new IPFS hash
    /// @param _ipfsHash IPFS hash or CID with folder of metadata files that will conatin reveal media
    function revealCollection(string memory _ipfsHash) external onlyOwner {
        require(!is_collection_revealed, "already revealed");
        is_collection_revealed = true;
        ipfsHash = _ipfsHash;
    }

    /// @notice sets new vault address
    /// @dev vault address cannot be zero address
    /// @param _newAddress new vault address
    function fixVault(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Can't use black hole");
        vault_address = _newAddress;
    }

    /// @notice withdraws all balance of this contract to vault address
    /// @dev uses OpenZeppelin's Address.sol library to handle fund transfer
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(vault_address != address(0) && balance > 0, "Can't withdraw");
        Address.sendValue(payable(vault_address), balance);
    }

    //------------------------------------------------------//

    // External Functions

    //------------------------------------------------------//

    /// @notice method to buy during presale and main sale
    /// @dev uses merkle root and merkle proof to verify if the msg.sender is whitelisted
    /// @param _merkleProof an array of hashes necessary to prove the inclusion of msg.sender into whitelist
    /// @param _mintQuantity number of tokens to be minted
    function buy(bytes32[] calldata _merkleProof, uint256 _mintQuantity)
        external
        payable
        whenNotPaused
    {
        require(
            sale_active && !sale_ended,
            "Can't buy because sale is not active"
        );
        bool canMint;
        uint256 price;
        uint256 mintLimit;
        uint256 cap;

        if (whitelist_active) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            canMint = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
            price = PRESALE_PRICE;
            mintLimit = MAX_PRESALE_LIMIT;
            cap = PRESALE_CAP + RESERVED_CAP; // to account for already minted reserved tokens
        } else {
            canMint = true;
            price = MINTING_PRICE;
            mintLimit = MAX_LIMIT;
            cap = HARD_CAP;
        }
        require(
            canMint && msg.value == price * _mintQuantity,
            "Sorry you can't mint right now"
        );
        require(_mintQuantity >= 1, "usless transaction to mint zero");
        require(_mintQuantity + totalSupply() <= cap, "cap reached");
        require(
            minted[_msgSender()] + _mintQuantity <= mintLimit,
            "Out of limit"
        );
        minted[_msgSender()] += uint8(_mintQuantity);
        _safeMint(_msgSender(), _mintQuantity);
    }

    //------------------------------------------------------//

    // View Functions

    //------------------------------------------------------//

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @dev see {EIP-2981}
    /// @param _tokenId the NFT asset queried for royalty information
    /// @param _salePrice the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "RoyaltyQueryForNonexistentToken");
        return (
            vault_address,
            (_salePrice * royaltiesValue) / ROYALTY_HUNDRED_PERCENT
        );
    }

    /// @notice overriden to show that contract supports EIP2981
    /// @dev see {EIP-165}
    /// @param interfaceId interface id of implementation
    /// @return true if implements the interface else false
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /// @notice token URI of specified existing token ID
    /// @param _tokenId token ID
    /// @return string token URI
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URIQueryForNonexistentToken");
        if (is_collection_revealed == true) {
            string memory _tknId = Strings.toString(_tokenId);
            return
                string(
                    abi.encodePacked(
                        _baseURI(),
                        ipfsHash,
                        "/Erc721_Data_",
                        _tknId,
                        ".json"
                    )
                );
        } else {
            return string(abi.encodePacked(_baseURI(), ipfsHash, "/"));
        }
    }

    /// @notice list of tokens owned by a wallet
    /// @param _owner owner address
    /// @return ownerTokens array of token IDs owned by a wallet
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = _startTokenId(); tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice checks if an address is whitelisted or not
    /// @param _merkleProof an array of hashes necessary to prove the inclusion of msg.sender into whitelist
    /// @param _address address that needs to check for inclusion in whitelist
    function isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf);
        return whitelisted;
    }

    // method overriden to start token ID from 1.
    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    // method overriden to set base URI to desireable base URI
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}