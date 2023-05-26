// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TCH is ERC1155, ERC2981, Ownable, ReentrancyGuard {
    string public constant name = "Childhood by Tewoz";
    string public constant symbol = "TCH";

    using Strings for uint;

    /* Project steps
     * none : can't mint
     * mintGenesis : initial mint, genesis NFT only
     * genesisSoldOut : genesis collection sold out
     * mintPostGenesis : postGenesis items mint
     */
    enum Step {
        none,
        mintGenesis,
        genesisSoldOut,
        mintPostGenesis
    }

    // Collection state
    struct Collection {
        Step step;
        address payable artist;
        uint maxId;
        uint nextMint;
        uint8 maxGenesisId;
        uint8 royaltiesPercent;
        bool revealed;
    }

    // Items metadata
    struct Item {
        string name;
        string description;
        string uri;
        bool isGenesis;
        bool isSequel;
        bool genesisHolderOnlyMint;
        bool genesisOrSequelHolderOnlyMint;
        uint price;
        uint currentSupply;
        uint maxSupply;
    }

    // Stockage de tous les items de la collection
    mapping (uint => Item) public items;

    // Stockage de la collection
    Collection public collection;

    // Stockage simple des freemints
    // Pas de merkleproof ici
    // On stocke juste le nombre de freemints autorisés par adresse dans un tableau
    //  plus pratique à delete.
    struct Freemint {
        address account;
        uint    number;
    }

    Freemint[] freemints;

    // Modifier : Need an existing Id
    modifier ifIdExists(uint _id) {
        require(_id >= 1 &&
                _id <= collection.maxId,
                "Nonexistent id");
        _;
    }

    // Modifier : Artist Only
    modifier onlyArtist () {
        require(msg.sender == collection.artist,
                "This feature is restricted to the artist");
        _;
    }

    // Event : An NFT from the collection was minted
    event ItemMinted(uint id, address who);

    // Event : project step changed
    event StepChanged(Step step);

    // Event Collection revealed
    event CollectionRevealed();

    // Event : Withdrawal successful
    event Withdrawal(address account);

    // Initialize Contract
    constructor(string memory _uri, address payable _artist) ERC1155(_uri) {
        // Initialize the collection state
        collection.step = Step.none;
        // There will be 31 genesis NFTs
        collection.maxGenesisId = 31;
        // None of which are minted yet
        collection.maxId = 0;
        // Next ID to Mint
        collection.nextMint = 1;
        // Not revealed
        collection.revealed = false;
        // Artist address
        collection.artist = _artist;
        // Default royalties
        collection.royaltiesPercent = 7;
        // Set Royalties for EIP 2981 Interface
        _setDefaultRoyalty(collection.artist, 100*uint96(collection.royaltiesPercent));
    }

    // Change default URI
    function setURI(string memory _newuri) external onlyOwner {
        _setURI(_newuri);
    }

    // Change artist Address
    function setArtist(address payable _artist) external onlyOwner {
        collection.artist = _artist;
        // Set Royalties for EIP 2981 Interface
        _setDefaultRoyalty(collection.artist, 100*uint96(collection.royaltiesPercent));

    }

    // Change current step
    function setStep(Step _step)
        external
        onlyOwner
    {
        collection.step = _step;
        emit StepChanged(_step);
    }

    // Set royalties
    function setRoyaltiesPercent(uint8 _percent) external onlyOwner {
        collection.royaltiesPercent = _percent;
        // Set Royalties for EIP 2981 Interface
        _setDefaultRoyalty(collection.artist, 100*uint96(collection.royaltiesPercent));
    }

    // Internal function to set account's freemints
    function _setFreemintPerUser(address _account, uint _number) internal {
        // If this account is already registered
        for (uint i = 0 ; i < freemints.length ; ++i) {
            if (freemints[i].account == _account) {
                // It is updated
                freemints[i].number = _number;
                return;
            }
        }

        // Else we create it
        Freemint memory _fm = Freemint(_account, _number);
        freemints.push(_fm);
    }

    // Set account's freemints
    function setFreemintPerUser(address _account, uint _number)
        external
        onlyOwner
    {
        _setFreemintPerUser(_account, _number);
    }

    // Delete freemints data
    function razFreemints()
        external
        onlyOwner
    {
        delete freemints;
    }

    // Check account's freemints
    function userFreemints(address _account) public view returns (uint) {
        for (uint i = 0 ; i < freemints.length ; ++i) {
            if (freemints[i].account == _account) {
                return freemints[i].number;
            }
        }
        return 0;
    }

    // Check account's Genesis items
    function userHoldsGenesisItems(address _account) public view returns (bool) {
        for (uint i = 1 ; i < collection.maxGenesisId ; ++i) {
            if (balanceOf(_account, i) > 0) {
                return true;
            }
        }
        return false;
    }

    // Check account's Genesis or Sequel
    function userHoldsSequelOrGenesisItems(address _account) public view returns (bool) {
        for (uint i = 1 ; i < collection.maxId ; ++i) {
            if ((items[i].isGenesis || items[i].isSequel) &&
                balanceOf(_account, i) > 0) {
                return true;
            }
        }
        return false;
    }

    // reveal the collection
    function reveal()
        external
        onlyOwner
    {
        collection.revealed = true;
        emit CollectionRevealed();
    }

    // handle Items uri retrieval
    function uri(uint256 _id) 
        override
        public
        view
        ifIdExists(_id)
        returns (string memory)
    {
        if ( ! collection.revealed ) {
            // The original uri
            // Unrevealed image
            return super.uri(0);
        } else {
            // A Dynamic JSON Data URL
            // Actual art and specific metadata
            return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "', items[_id].name,
                                    '", "image": "', items[_id].uri,
                                    unicode'", "description": "Illustration inspirée de ', items[_id].description, unicode' dessinée à la main avec amour sur IpadPro en suivant la silhouette de mon personnage.',
                                    '", "attributes": [',
                                        (items[_id].isGenesis ? '{"trait_type": "Genesis", "value": "yes"}' : ''),
                                        (items[_id].isSequel ? '{"trait_type": "Sequel", "value": "yes"}' : ''),
                                    ']',
                                    '}'
                                )
                            )
                        )
                    )
                )
            );
        }
    }

    // Add an item to the project
    function addNFT (Item memory _newItem)
        public 
        nonReentrant
        onlyOwner
        returns (uint256)
    {
        collection.maxId++;
        items[collection.maxId] = _newItem;
        return collection.maxId;
    }

    // Add multiples item to the project
    function addNFTs (Item[] memory _newItems)
        public 
        nonReentrant
        onlyOwner
        returns (uint256)
    {
        for (uint i = 0 ; i<_newItems.length ; i++) {
            collection.maxId++;
            items[collection.maxId] = _newItems[i];
        }
        return collection.maxId;
    }

    // Update items metadata
    function updateMetadata (uint[] memory ids, string[] memory _names,
                             string[] memory _descriptions, string[] memory _uris,
                             bool[] memory _isGenesis, bool[] memory _isSequel,
                             bool[] memory _genesisHolderOnlyMint, bool[] memory _genesisOrSequelHolderOnlyMint,
                             uint[] memory _price, uint[] memory _maxSupply)
        external 
        onlyOwner
    {
        for (uint i = 0 ; i<ids.length ; i++) {
            require(ids[i] >= 1 && ids[i] <= collection.maxId, "Nonexistent id");
            items[ids[i]].name = _names[i];
            items[ids[i]].description = _descriptions[i];
            items[ids[i]].uri = _uris[i];
            items[ids[i]].isGenesis = _isGenesis[i];
            items[ids[i]].isSequel = _isSequel[i];
            items[ids[i]].genesisHolderOnlyMint = _genesisHolderOnlyMint[i];
            items[ids[i]].genesisOrSequelHolderOnlyMint = _genesisOrSequelHolderOnlyMint[i];
            items[ids[i]].price = _price[i];
            items[ids[i]].maxSupply = _maxSupply[i];
        }
    }

    // Computes the total supply
    function totalSupply()
        external
        view
        returns (uint)
    {
        uint supply = 0;
        for (uint id = 1; id <= collection.maxId; id++) {
            supply += items[id].currentSupply;
        }
        return supply;
    }

    // Withdraw all the WETH to the current owner's address
    function withdrawFunds()
        external
        onlyArtist
    {
        require (address(this).balance > 0, "Empty balance");
        collection.artist.transfer(address(this).balance);
        emit Withdrawal(msg.sender);
    } 

    // Mint Function For genesis NFTs
    function mintGenesis() external nonReentrant payable  {
        uint _id = collection.nextMint;

        // Is the current step ok ?
        require(collection.step == Step.mintGenesis,
                "Genesis mint is closed !");

        // is id part of the Genesis collection ?
        require(_id >= 1 &&
                _id <= collection.maxId &&
                _id <= collection.maxGenesisId,
                "This NFT is not mintable");

        // Was the price set ?
        require(items[_id].price > 0,
                "Mint price has not been set yet !");

        // Check this item Supply
        require(items[_id].maxSupply == 0 ||
                items[_id].currentSupply < items[_id].maxSupply,
                "Max supply reached for this NFT");
        
        uint _usersFreeMints = userFreemints(msg.sender);
        if ( _usersFreeMints > 0) {
            _setFreemintPerUser(msg.sender, _usersFreeMints - 1 );
        } else {
            require(items[_id].price == 0 ||
                    msg.value >= items[_id].price, "Amount sent is less than NFT price");
        }

        // update current supply of this NFT
        items[_id].currentSupply++;

        // Increase next Mint ID
        collection.nextMint++;

        _mint(msg.sender, _id, 1, "");

        emit ItemMinted(_id, msg.sender);
    }

    // Mint Function For genesis NFTs
    function mintPostGenesis(uint _id) external nonReentrant payable  {
        // Is the current step ok ?
        require(collection.step == Step.mintPostGenesis,
                "PostGenesis mint is closed !");

        // is id part of the Post Genesis items ?
        require(_id > collection.maxGenesisId &&
                _id <= collection.maxId,
                "This NFT is not mintable");

        // Check this item Supply
        require(items[_id].maxSupply == 0 ||
                items[_id].currentSupply < items[_id].maxSupply,
                "Max supply reached for this NFT");
        
        // Do we need a Genesis Holder here ?
        if (items[_id].genesisHolderOnlyMint)   {
            require (userHoldsGenesisItems(msg.sender), "Account must hold a Genesis NFT to mint this one");
        }

        // Do we need a Genesis/Sequel Holder here ?
        if (items[_id].genesisOrSequelHolderOnlyMint)   {
            require (userHoldsSequelOrGenesisItems(msg.sender), "Account must hold a Genesis or Sequel NFT to mint this one");
        }

        // Check account's freemints
        uint _usersFreeMints = userFreemints(msg.sender);
        if ( _usersFreeMints > 0) {
            _setFreemintPerUser(msg.sender, _usersFreeMints - 1 );
        } else {
            require(items[_id].price == 0 ||
                    msg.value >= items[_id].price, "Amount sent is less than NFT price");
        }

        // update current supply of this NFT
        items[_id].currentSupply++;

        _mint(msg.sender, _id, 1, "");

        emit ItemMinted(_id, msg.sender);
    }

    // Owner can mint NFTs here
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        items[id].currentSupply += amount;
        _mint(account, id, amount, data);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}