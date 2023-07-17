pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interfaces/IMuseToken.sol";
import "./interfaces/IVNFT.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/introspection/IERC165.sol";

// Extending IERC1155 with mint and burn
interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}

// @TODO add "health" system basde on a level time progression algorithm.
// @TODO continue developing V1.sol with multi feeding, multi mining and battlers, challenges, etc.

contract VNFTx is Ownable, ERC1155Holder {
    using SafeMath for uint256;

    bool paused = false;
    //for upgradability
    address public delegateContract;
    address[] public previousDelegates;
    uint256 public total = 1;

    IVNFT public vnft;
    IMuseToken public muse;
    IERC1155 public addons;

    uint256 public artistPct = 5;

    struct Addon {
        string name;
        uint256 price;
        uint256 rarity;
        string artistName;
        address artist;
        uint256 quantity;
        uint256 used;
    }

    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint256 => Addon) public addon;

    mapping(uint256 => EnumerableSet.UintSet) private addonsConsumed;

    //nftid to rarity points
    mapping(uint256 => uint256) public rarity;

    using Counters for Counters.Counter;
    Counters.Counter private _addonId;

    event DelegateChanged(address oldAddress, address newAddress);
    event BuyAddon(uint256 nftId, uint256 addon, address player);
    event CreateAddon(uint256 addonId, string name, uint256 rarity);
    event EditAddon(uint256 addonId, string name, uint256 price);

    constructor(
        IVNFT _vnft,
        IMuseToken _muse,
        address _mainContract,
        IERC1155 _addons
    ) public {
        vnft = _vnft;
        muse = _muse;
        addons = _addons;
        delegateContract = _mainContract;
        previousDelegates.push(delegateContract);
    }

    modifier tokenOwner(uint256 _id) {
        require(
            vnft.ownerOf(_id) == msg.sender ||
                vnft.careTaker(_id, vnft.ownerOf(_id)) == msg.sender,
            "You must own the vNFT or be a care taker to buy addons"
        );
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract paused!");
        _;
    }

    // get how many addons a pet is using
    function addonsBalanceOf(uint256 _nftId) public view returns (uint256) {
        return addonsConsumed[_nftId].length();
    }

    // get a specific addon
    function addonsOfNftByIndex(uint256 _nftId, uint256 _index)
        public
        view
        returns (uint256)
    {
        return addonsConsumed[_nftId].at(_index);
    }

    /*Addons */
    // buys initial addon distribution for muse
    function buyAddon(uint256 _nftId, uint256 addonId)
        public
        tokenOwner(_nftId)
        notPaused
    {
        Addon storage _addon = addon[addonId];

        require(
            _addon.used <= addons.balanceOf(address(this), addonId),
            "Addon not available"
        );

        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(addonId);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        uint256 artistCut = _addon.price.mul(artistPct).div(100);

        muse.transferFrom(msg.sender, _addon.artist, artistCut);
        muse.burnFrom(msg.sender, _addon.price.sub(artistCut));
        emit BuyAddon(_nftId, addonId, msg.sender);
    }

    // to use addon bought on opensea on your specific pet
    function useAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
        notPaused
    {
        require(
            addons.balanceOf(msg.sender, _addonID) >= 1,
            "!own the addon to use it"
        );

        Addon storage _addon = addon[_addonID];
        _addon.used = _addon.used.add(1);

        addonsConsumed[_nftId].add(_addonID);

        rarity[_nftId] = rarity[_nftId].add(_addon.rarity);

        addons.safeTransferFrom(
            msg.sender,
            address(this),
            _addonID,
            1, //the amount of tokens to transfer which always be 1
            "0x0"
        );
    }

    // @TODO function for owner to transfer addon from owned pet to owned pet without unwrapping.
    function transferAddon(
        uint256 _nftId,
        uint256 _addonID,
        uint256 _toId
    ) external tokenOwner(_nftId) {
        Addon storage _addon = addon[_addonID];

        // remove addon and rarity points from pet
        addonsConsumed[_nftId].remove(_addonID);
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        // add addon and rarity points to new pet
        addonsConsumed[_toId].add(_addonID);
        rarity[_toId] = rarity[_toId].add(_addon.rarity);
    }

    // unwrap addon from game to get erc1155 for trading. (losed rarity points)
    function removeAddon(uint256 _nftId, uint256 _addonID)
        public
        tokenOwner(_nftId)
    {
        Addon storage _addon = addon[_addonID];
        rarity[_nftId] = rarity[_nftId].sub(_addon.rarity);

        addonsConsumed[_nftId].remove(_addonID);
        addons.safeTransferFrom(
            address(this),
            msg.sender,
            _addonID,
            1, //the amount of tokens to transfer which always be 1
            "0x0"
        );
    }

    function removeMultiple(
        uint256[] calldata nftIds,
        uint256[] calldata addonIds
    ) external {
        for (uint256 i = 0; i < addonIds.length; i++) {
            removeAddon(nftIds[i], addonIds[i]);
        }
    }

    function useMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        require(addonIds.length == nftIds.length, "Should match 1 to 1");
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    function buyMultiple(uint256[] calldata nftIds, uint256[] calldata addonIds)
        external
    {
        require(addonIds.length == nftIds.length, "Should match 1 to 1");
        for (uint256 i = 0; i < addonIds.length; i++) {
            useAddon(nftIds[i], addonIds[i]);
        }
    }

    /* end Addons */

    // perform an action on delegated contract (battles, killing, etc)
    function action(string memory _signature, uint256 nftId) public notPaused {
        (bool success, ) = delegateContract.delegatecall(
            abi.encodeWithSignature(_signature, nftId)
        );

        require(success, "Action error");
    }

    /* ADMIN FUNCTIONS */

    // withdraw dead pets accessories
    function withdraw(uint256 _id, address _to) external onlyOwner {
        addons.safeTransferFrom(address(this), _to, _id, 1, "");
    }

    function changeDelegate(address _newDelegate) external onlyOwner {
        require(
            _newDelegate != delegateContract,
            "New delegate should be diff"
        );
        previousDelegates.push(delegateContract);
        address oldDelegate = delegateContract;
        delegateContract = _newDelegate;
        total = total++;
        DelegateChanged(oldDelegate, _newDelegate);
    }

    function createAddon(
        string calldata name,
        uint256 price,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity
    ) external onlyOwner {
        _addonId.increment();
        uint256 newAddonId = _addonId.current();

        addon[newAddonId] = Addon(
            name,
            price,
            _rarity,
            _artistName,
            _artist,
            _quantity,
            0
        );
        addons.mint(address(this), newAddonId, _quantity, "");

        emit CreateAddon(newAddonId, name, _rarity);
    }

    function editAddon(
        uint256 _id,
        string calldata name,
        uint256 price,
        uint256 _rarity,
        string calldata _artistName,
        address _artist,
        uint256 _quantity,
        uint256 _used
    ) external onlyOwner {
        Addon storage _addon = addon[_id];

        _addon.name = name;
        _addon.price = price * 10**18;
        _addon.rarity = _rarity;
        _addon.artistName = _artistName;
        _addon.artist = _artist;
        _addon.quantity = _quantity;
        _addon.used = _used;
        emit EditAddon(_id, name, price);
    }

    function setArtistPct(uint256 _newPct) external onlyOwner {
        artistPct = _newPct;
    }

    function pause(bool _paused) public onlyOwner {
        paused = _paused;
    }
}