pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


error ExceedMintQuantity();
error ExceedMintSupply();
error InvalidAzukiContract();
error WrongValue();
error WithdrawFailed();
error AlreadyDunked();
error InvalidTokenURI();
error NotOwner();

contract Bzuki is ERC721A, Ownable {
    constructor() ERC721A("Bzuki", "BZUKI") {
        updateValidContracts(0xED5AF388653567Af2F388E6224dC7C4b3241C544, true);
        updateValidContracts(0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e, true);
    }

    uint256 public MAX_MINT_PER_WALLET = 3;
    uint256 public MAX_MINTABLE_SUPPLY = 2000;

    uint256 public _mintPrice = 5000000000000000;

    /*
    IERC721 private constant AZUKI_IERC721 = IERC721(0xED5AF388653567Af2F388E6224dC7C4b3241C544);
    IERC721 private constant AZUKI_ELE_IERC721 = IERC721(0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e);
    IERC721 private constant BEANZ_IERC721 = IERC721(0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949);
    IERC721 private constant BEANZ_ELE_IERC721 = IERC721(0x3Af2A97414d1101E2107a70E7F33955da1346305);
    IERC721 private constant DREAMZUKI_IERC721 = IERC721(0xbC4c9777C22fe519fd890BC6961fF1554C3F13Ac);
    IERC721 private constant ZEROXZUKI_IERC721 = IERC721(0x2eb6be120eF111553F768FcD509B6368e82D1661);
    IERC721 private constant DEZUKI_IERC721 = IERC721(0xAd4D85257c815A4B2C7088a664e958b035B24323);
    */

    mapping (address => bool) public _validBucketContracts;

    mapping(address => uint256) public _addressMintedAmount;
    mapping(uint256 => bool) public _hasDunked;
    uint256 public _mintedAmount = 0;

    function mint(uint256 quantity) external payable {

        // cannot mint over total supply.
        if (_mintedAmount + quantity > MAX_MINTABLE_SUPPLY) {
            revert ExceedMintSupply();
        }

        // check for value. 0.005 eth per mint.
        if (msg.value != _mintPrice * quantity) {
            revert WrongValue();
        }

        // maximum 3 mintable per wallet.
        if (quantity > 3 || _addressMintedAmount[msg.sender] + quantity > 3) {
            revert ExceedMintQuantity();
        }

        _mintedAmount += quantity;
        _addressMintedAmount[msg.sender] += quantity;

        _mint(msg.sender, quantity);
    }

    function updateMintPrice(uint256 newMintPrice) external onlyOwner {
        if (_mintPrice != newMintPrice) {
            emit MintPriceChange(_mintPrice, newMintPrice);
            _mintPrice = newMintPrice;
        }
    }

    function updateValidContracts(address contractAddr, bool isBucketable) public onlyOwner {
        _validBucketContracts[contractAddr] = isBucketable;
        emit IsBucketable(contractAddr, isBucketable);
    }

    // dunk your bucket onto an azuki to get a swoll 'bucket hat'.
    // be careful with your azuki ID! can only dunk once, subsequent dunks won't update your metadata.
    // using an invalid azuki ID will result in a un-dunkable bucket, which is also cool.
    function bucketify(uint256 bucketId, address azukiContract, uint256 azukiId) public returns (bool) {
        if (ownerOf(bucketId) != msg.sender) {
            revert NotOwner();
        }

        if (_hasDunked[bucketId]) {
            revert AlreadyDunked();
        }

        if (!_validBucketContracts[azukiContract]) {
            revert InvalidAzukiContract();
        }

        _hasDunked[bucketId] = true;

        // Update metadata.
        emit WearBucket(bucketId, azukiContract, azukiId);

        return true;
    }

    // metadata
    string private _baseTokenURI = "https://ceres-bzuki.onrender.com/api/metadata/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // withdrawals
    function withdraw() public onlyOwner {
        (bool success, ) = (msg.sender).call{value:address(this).balance}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    event WearBucket(uint256 indexed bucketId, address azukiContract, uint256 azukiId);
    event IsBucketable(address contractAddress, bool isBucketable);
    event MintPriceChange(uint256 oldPrice, uint256 newPrice);
}