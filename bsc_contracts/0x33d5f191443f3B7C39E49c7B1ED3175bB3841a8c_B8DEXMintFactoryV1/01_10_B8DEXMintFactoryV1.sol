// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '../lib/IB8DEXMintFactory.sol';
import '../lib/IB8DEXMainCollection.sol';
import '../lib/IB8DEXMintingStation.sol';

contract B8DEXMintFactoryV1 is IB8DEXMintFactory, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IB8DEXMainCollection public b8dMainCollection;
    IB8DEXMintingStation public b8dMintingStation;

    IERC20 public b8dToken;

    // end block number to get collectibles
    uint256 public endBlockNumber;

    // starting block
    uint256 public startBlockNumber;

    // Number of CAKEs a user needs to pay to acquire a token
    uint256 public tokenPrice;

    // Map if address has already claimed a NFT
    mapping(address => bool) public hasClaimed;

    // IPFS hash for new json
    string private ipfsHash;

    // number of total series (i.e. different visuals)
    uint8 private numberNFTIds = 1;

    // number of previous series (i.e. different visuals)
    uint8 private previousNumberNFTIds = 1;

    // Map the token number to URI
    mapping(uint8 => string) private nftIdURIs;

    // Event to notify when NFT is successfully minted
    event NFTMint(address indexed to, uint256 indexed tokenId, uint8 indexed nftId);

    /**
     * @dev
     */
    constructor(
        IB8DEXMainCollection _b8dMainCollection,
        IB8DEXMintingStation _b8dMintingStation,
        IERC20 _b8dToken,
        uint256 _tokenPrice,
        string memory _ipfsHash,
        uint256 _startBlockNumber,
        uint256 _endBlockNumber
    ) public {
        b8dMainCollection = _b8dMainCollection;
        b8dMintingStation = _b8dMintingStation;
        b8dToken = _b8dToken;
        tokenPrice = _tokenPrice;
        ipfsHash = _ipfsHash;
        startBlockNumber = _startBlockNumber;
        endBlockNumber = _endBlockNumber;
    }

    /**
     * @dev Mint NFTs from the b8dMainCollection contract.
     * Users can specify what nftId they want to mint. Users can claim once.
     * There is a limit on how many are distributed. It requires B8D balance to be > 0.
     */
    function mintNFT(uint8 _nftId) external {
        address senderAddress = _msgSender();

        // Check _msgSender() has not claimed
        require(!hasClaimed[senderAddress], "Has claimed");
        // Check block time is not too late
        require(block.number > startBlockNumber, "too early");
        // Check block time is not too late
        require(block.number < endBlockNumber, "too late");
        // Check that the _nftId is within boundary:
        require(_nftId >= previousNumberNFTIds, "nftId too low");
        // Check that the _nftId is within boundary:
        require(_nftId < numberNFTIds, "nftId too high");

        // Update that _msgSender() has claimed
        hasClaimed[senderAddress] = true;

        // Send CAKE tokens to this contract
        b8dToken.transferFrom(senderAddress, address(this), tokenPrice);

        string memory tokenURI = nftIdURIs[_nftId];

        uint256 tokenId = b8dMintingStation.mintCollectible(senderAddress, tokenURI, _nftId);

        emit NFTMint(_msgSender(), tokenId, _nftId);
    }

    /**
     * @dev It transfers the ownership of the NFT contract
     * to a new address.
     */
    function changeOwnershipNFTContract(address _newOwner) external onlyOwner {
        b8dMainCollection.transferOwnership(_newOwner);
    }

    /**
     * @dev It transfers the B8D tokens back to the chef address.
     * Only callable by the owner.
     */
    function claimFee(uint256 _amount) external onlyOwner {
        b8dToken.transfer(_msgSender(), _amount);
    }

    /**
     * @dev Set up json extensions for NFTs 5-9
     * Assign tokenURI to look for each nftId in the mint function
     * Only the owner can set it.
     */
    function setNFTJson(
        uint8 _nftIndex,
        string calldata _nftJson
    ) external onlyOwner {
        nftIdURIs[_nftIndex] = string(abi.encodePacked(ipfsHash, _nftJson));
        numberNFTIds = numberNFTIds + 1;
    }

    /**
     * @dev Set up names for nft 5-9
     * Only the owner can set it.
     */
    function setNFTNames(
        uint8 _nftId,
        string calldata _nftName
    ) external onlyOwner {
        b8dMintingStation.setNFTName(_nftId, _nftName);
    }

    /**
     * @dev Set up json extensions for NFTs 5-9
     * Assign tokenURI to look for each nftId in the mint function
     * Only the owner can set it.
     */
    function setNFTJsonArray(
        uint8[] memory _nftId,
        string[] memory _nftJsons
    ) external onlyOwner {
        require(_nftId.length == _nftJsons.length, "arrays of the same length");

        for (uint8 i; i < _nftId.length; i++) {
            nftIdURIs[_nftId[i]] = string(abi.encodePacked(ipfsHash, _nftJsons[i]));
            numberNFTIds = numberNFTIds + 1;
        }
    }

    /**
     * @dev Set up names for nft 5-9
     * Only the owner can set it.
     */
    function setNFTNamesArray(
        uint8[] memory _nftIds,
        string[] memory _nftNames
    ) external onlyOwner {
        require(_nftIds.length == _nftNames.length, "arrays of the same length");

        for (uint8 i; i < _nftIds.length; i++) {
            b8dMintingStation.setNFTName(_nftIds[i], _nftNames[i]);
        }
    }

    /**
     * @dev Allow to set up the start number
     * Only the owner can set it.
     */
    function setStartBlockNumber(uint256 _newStartBlockNumber) external onlyOwner {
        require(_newStartBlockNumber > block.number, "too short");
        startBlockNumber = _newStartBlockNumber;
    }

    /**
     * @dev Allow to set up the end block number
     * Only the owner can set it.
     */
    function setEndBlockNumber(uint256 _newEndBlockNumber) external onlyOwner {
        require(_newEndBlockNumber > block.number, "too short");
        require(_newEndBlockNumber > startBlockNumber, "must be > startBlockNumber");
        endBlockNumber = _newEndBlockNumber;
    }

    /**
     * @dev setNumberNFTIds
     */
    function setNumberNFTIds(uint8 _newNumberNFTIds) external onlyOwner {
        numberNFTIds = _newNumberNFTIds;
    }

    /**
     * @dev setPreviousNumberNFTIds
     */
    function setPreviousNumberNFTIds(uint8 _newPreviousNumberNFTIds) external onlyOwner {
        previousNumberNFTIds = _newPreviousNumberNFTIds;
    }

    /**
     * @dev Allow to change the token price
     * Only the owner can set it.
     */
    function updateTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    /**
     * @dev Can user mint
     */
    function canMint(address userAddress) external view returns (bool) {
        if (hasClaimed[userAddress]) {
            return false;
        } else {
            return true;
        }
    }
}