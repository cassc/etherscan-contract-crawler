/**
 * db    db  .d88b.  db    db .d8888.  .d88b.  db    db db      .d8888.
 * 88    88 .8P  Y8. `8b  d8' 88'  YP .8P  Y8. 88    88 88      88'  YP
 * Y8    8P 88    88  `8bd8'  `8bo.   88    88 88    88 88      `8bo.
 * `8b  d8' 88    88  .dPYb.    `Y8b. 88    88 88    88 88        `Y8b.
 *  `8bd8'  `8b  d8' .8P  Y8. db   8D `8b  d8' 88b  d88 88booo. db   8D
 *    YP     `Y88P'  YP    YP `8888Y'  `Y88P'  ~Y8888P' Y88888P `8888Y'
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./signing.sol";

contract VoxSoulsLunchboxes is
    ERC1155,
    Ownable,
    Pausable,
    ReentrancyGuard,
    Signing
{
    // _isMinted[contract][tokenId]=bool
    mapping(address => mapping(uint256 => bool)) private _isMinted;
    mapping(address => uint256) private _allowListCount;
    mapping(address => bool) private _allowList;

    uint256 private constant MAX_LUNCHBOXES = 26664;
    uint256 public maxAvailableLunchboxes = 2664;
    uint256 private currentLunchboxes;
    uint256 private currentSaleCount;
    string private name_ = "VoxSoulsLunchboxes";
    string private symbol_ = "VXSL";
    bool public allowListEvent;
    uint256 public cost = 0;

    event SoulMinted(
        address indexed owner,
        address _conract,
        uint256 tokenId,
        uint256 indexed soulId
    );

    constructor(address _importantAddress, string memory _baseURI)
        ERC1155(_baseURI)
        Signing(_importantAddress)
    {
        importantAddress = _importantAddress;
    }

    /**
     * @notice Add an allow list
     * @param addresses The addresses to add to the allow list
     */
    function setAllowList(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    /**
     * @notice Remove an allow list address.
     * @param addr The address to remove from the allow list.
     */
    function clearAllowList(address[] calldata addr) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            _allowList[addr[i]] = false;
            _allowListCount[addr[i]] = 0;
        }
    }

    /**
     * @notice Set the number of lunchboxes for sale.
     * @param _maxAvailableLunchboxes The number of lunchboxes for sale.
     * @dev The number of lunchboxes can not be more than MAX_LUNCHBOXES.
     * @dev The number of lunchboxes can not be less than 0.
     * @dev The number of lunchboxes for sale cannot be less than the  quantity of lunchboxes already minted.
     */
    function setMaxAvailableLunchboxes(uint256 _maxAvailableLunchboxes)
        public
        onlyOwner
    {
        require(
            _maxAvailableLunchboxes <= MAX_LUNCHBOXES,
            "Lunchboxes must <= 26664"
        );
        require(_maxAvailableLunchboxes >= 0, "Lunchboxes must >= 0");
        require(
            _maxAvailableLunchboxes >= currentLunchboxes,
            "Must >= currentLunchboxes"
        );

        maxAvailableLunchboxes = _maxAvailableLunchboxes;
    }

    /**
     * @notice Set the cost of Mint.
     */
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    /**
     * @notice start for allow list mint event
     */
    function openAllowListMint() public onlyOwner {
        allowListEvent = true;
    }

    /**
     * @notice End allow list mint event
     */
    function closeAllowListMint() public onlyOwner {
        allowListEvent = false;
    }

    /**
     * Set the base URI for the contract.
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice Pause the contract Minting
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract Minting
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Get the base cost for minting a soul.
     */
    function getCost() public view returns (uint256) {
        if (!allowListEvent) {
            return cost;
        }
        return 0;
    }

    /**
     * @notice Internal function to handle the mechanics of minting a new soul.
     * @param _contract The contract address.
     * @param id the VOX ID.
     * @param mintTime the time the VOX was minted.
     */
    function _mintSoul(
        address account,
        address _contract,
        uint256 id,
        uint256 mintTime
    ) private {
        require(!_isMinted[_contract][id], "Lunchbox already minted.");

        require(
            currentLunchboxes + 1 <= MAX_LUNCHBOXES,
            "Max lunchboxes minted."
        );

        // Check to see if we need to take the allowList event into accouont.
        if (allowListEvent) {
            require(_allowList[account], "Please wait for public mint!");
            require(
                _allowListCount[account] <= 0,
                "Only One mint during the event!"
            );

            _allowListCount[account] = 1;
        } else {
            require(
                currentSaleCount + 1 <= maxAvailableLunchboxes,
                "No more lunchboxes for sale."
            );
            currentSaleCount++;
        }

        uint256 voxSign = (mintTime % 60) % 12;

        _isMinted[_contract][id] = true;
        currentLunchboxes++;

        _mint(account, voxSign, 1, "0x0");
        emit SoulMinted(account, _contract, id, voxSign);
    }

    /**
     * @notice Mint a lunchbox!  Create a new soul.
     * @dev Mint a lunchbox for the given mintTime seconds.
     * @dev Mint costs .08 ether.
     * @dev Check to make sure the token for contract has not minted a soul.
     * @param account The account that will own the lunchbox.
     * @param mintTime The mintTime seconds the Vox was minted.
     * @param _contract The Vox contract address.
     * @param id The VOX ID.
     * @param sig The transaction signature.
     */
    function mintLunchbox(
        address account,
        address _contract,
        uint256 id,
        uint256 mintTime,
        bytes memory sig
    ) public payable nonReentrant whenNotPaused {
        bool isValid = isValidData(account, _contract, id, mintTime, sig);

        require(isValid, "Invalid signature");
        require(msg.value == getCost(), "wrong eth value.");
        _mintSoul(account, _contract, id, mintTime);
    }

    /**
     * @notice Batch mint Lunchboxes!
     * @dev Requires valid signature.
     * @dev Requires 0.08 ether fee.
     * @dev Requires that the contract has not minted a soul.
     * @param account The account that will own the lunchbox.
     * @param _contract The Vox contract address.
     * @param id VOX ID.
     * @param mintTime The mintTime seconds the Vox was minted.
     * @param sig The transaction signature.
     */
    function batchMintLunchboxes(
        address account,
        address[] calldata _contract,
        uint256[] calldata id,
        uint256[] calldata mintTime,
        bytes memory sig
    ) public payable nonReentrant whenNotPaused {
        // The signature will be based off of the first entry in the arrays.
        bool isValid = isValidData(
            account,
            _contract[0],
            id[0],
            mintTime[0],
            sig
        );
        require(isValid, "Invalid signature");
        require(msg.value == getCost() * id.length, "Wrong eth value.");

        for (uint256 i = 0; i < id.length; i++) {
            _mintSoul(account, _contract[i], id[i], mintTime[i]);
        }
    }

    /**
     * @notice Mint a lunchbox as an admin without paying the fee.
     * @param _type the type of lunchbox to mint.
     */
    function batchAdminMintLunchboxes(uint256[] calldata _type)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < _type.length; i++) {
            require(_type[i] >= 0 && _type[i] <= 12, "Invalid lunchbox type.");
            _mint(msg.sender, _type[i], 1, "0x0");
        }
    }

    /**
     * @notice Get the name of the token.  Added for OpenSea support.
     */
    function name() public view returns (string memory) {
        return name_;
    }

    /**
     * @notice Get the symbol for the token.  Added for Opensea support.
     */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @notice Get the URI for a luncbox given the Token ID.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }

    /**
     * @notice Withdraw the balance from the contract.
     */
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}