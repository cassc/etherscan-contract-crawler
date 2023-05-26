//SPDX-License-Identifier: MIT

/// @title The NOMO NOUNS main contract

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {INounsAuctionHouseExtra} from './interfaces/INounsAuctionHouseExtra.sol';
import {INomoNounsSeeder} from "./interfaces/INomoNounsSeeder.sol";
import {INomoNounsDescriptor} from "./interfaces/INomoNounsDescriptor.sol";

contract NomoNounsToken is ERC721A, ERC721AQueryable, EIP712, Ownable {
    using ECDSA for bytes32;

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error WITHDRAW_NO_BALANCE();
    error WITHDRAW_NOT_SUCCESS();

    /// events
    event NomoCreated(uint256 indexed nounId, INomoNounsSeeder.Seed seed);

    // The Nomo Nouns token URI descriptor
    INomoNounsDescriptor public descriptor;

    // The Nouns token seeder
    INomoNounsSeeder public seeder;

    // The Nouns token seeder
    INounsAuctionHouseExtra public auctionHouse;

    // The noun seeds
    mapping(uint256 => INomoNounsSeeder.Seed) public seeds;

    // The nounId of a tokenId
    mapping(uint256 => uint256) public nounIdOfNomo;

    // The withdraw wallet
    address public withdrawWallet;

    // minting start price
    uint256 public mintingStartPrice;

    // minting increase interval (minutes)
    uint256 public mintingIncreaseInterval;

    // minting price increase per interval (ether)
    uint256 public mintingPriceIncreasePerInterval;

    // signer address
    address public signer;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash;

    constructor(
        uint256 _mintingStartPrice,
        uint256 _mintingIncreaseInterval,
        uint256 _mintingPriceIncreasePerInterval,
        address _withdrawWallet,
        address _signer,
        INounsAuctionHouseExtra _auctionHouse,
        INomoNounsSeeder _seeder,
        INomoNounsDescriptor _descriptor
    ) ERC721A('Nomo Nouns', 'NOMO') EIP712('NOMONOUNS', '1') {
        mintingStartPrice = _mintingStartPrice;
        mintingIncreaseInterval = _mintingIncreaseInterval;
        mintingPriceIncreasePerInterval = _mintingPriceIncreasePerInterval;
        withdrawWallet = _withdrawWallet;
        signer = _signer;
        auctionHouse = _auctionHouse;
        seeder = _seeder;
        descriptor = _descriptor;
    }

    /// @notice minting logic
    /// @param nounId nounsId
    /// @param blockNumber block number for seeds
    function mint(
        uint256 nounId,
        uint256 blockNumber,
        uint256 quantity,
        bytes calldata _signature
    ) public payable returns (uint256) {
        // validate signature
        require(signer == _verify(nounId, blockNumber, _signature), 'Invalid signature');

        // check endTime minting
        require(block.timestamp < auctionHouse.auction().endTime, 'Minting expired');

        // nounId parameter must be same as nounId in auction
        require(nounId == auctionHouse.auction().nounId, 'NounId invalid');

        // check ETH being paid is sufficient
        uint256 mintingStartTime = auctionHouse.auction().startTime;
        uint256 totalCost = getMintingPrice(mintingStartTime) * quantity;
        require(msg.value >= totalCost, 'Not enough ETH to pay');

        return _mintTo(msg.sender, nounId, blockNumber, quantity);
    }

    /// @notice Calculate minting price
    /// @param startTime start time in timestamp
    function getMintingPrice(uint256 startTime) public view returns (uint256) {
        if (block.timestamp < startTime) {
            return mintingStartPrice;
        }
        return
        mintingStartPrice +
        (((block.timestamp - startTime) / mintingIncreaseInterval) * mintingPriceIncreasePerInterval);
    }

    /// @notice withdraw all ETH
    function withdraw() external onlyOwner {
        if (address(this).balance == 0) revert WITHDRAW_NO_BALANCE();
        (bool success,) = withdrawWallet.call{value : address(this).balance}('');
        if (!success) revert WITHDRAW_NOT_SUCCESS();
    }

    /// @notice The IPFS URI of contract-level metadata.
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_contractURIHash));
    }

    //*********************************************************************//
    // ------------------------- URI functions --------------------------- //
    //*********************************************************************//

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev See {IERC721Metadata-tokenURI}
    function tokenURI(uint256 tokenId) public view override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), 'Token: URI query for nonexistent token');
        uint256 nounId = getNounId(tokenId);
        return descriptor.tokenURI(tokenId, seeds[nounId]);
    }

    /// @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
    /// @notice with the JSON contents directly inlined.
    function dataURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), 'Token: URI query for nonexistent token');
        uint256 nounId = getNounId(tokenId);
        return descriptor.dataURI(tokenId, seeds[nounId]);
    }

    //*********************************************************************//
    // ------------------------ Update Settings -------------------------- //
    //*********************************************************************//

    /// @notice Set the token URI descriptor.
    function setDescriptor(INomoNounsDescriptor _descriptor) external onlyOwner {
        descriptor = _descriptor;
    }

    /// @notice Set the token seeder.
    function setSeeder(INomoNounsSeeder _seeder) external onlyOwner {
        seeder = _seeder;
    }

    /// @notice Set the withdrawl wallet address.
    function setWithdrawWallet(address _withdrawWallet) external onlyOwner {
        withdrawWallet = _withdrawWallet;
    }

    /// @notice Set the minting start price.
    function setMintingStartPrice(uint256 _mintingStartPrice) external onlyOwner {
        mintingStartPrice = _mintingStartPrice;
    }

    /// @notice Set the minting increase interval in seconds.
    function setMintingIncreaseInterval(uint256 _mintingIncreaseInterval) external onlyOwner {
        mintingIncreaseInterval = _mintingIncreaseInterval;
    }

    /// @notice Set the minting price increase per inteval in wei.
    function setMintingPriceIncreasePerInterval(uint256 _mintingPriceIncreasePerInterval) external onlyOwner {
        mintingPriceIncreasePerInterval = _mintingPriceIncreasePerInterval;
    }

    /// @notice Set signer address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice Set the _contractURIHash.
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    //*********************************************************************//
    // ----------------------- Internal Funtions ------------------------- //
    //*********************************************************************//

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Mint a Noun with `nounId` to the provided `to` address.
    function getNounId(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 currentTokenId = tokenId;
        while (currentTokenId > 0) {
            if (nounIdOfNomo[currentTokenId] != 0) {
                return nounIdOfNomo[currentTokenId];
            }
            currentTokenId--;
        }

        revert("No nounId found for tokenId");
    }

    /// @notice Mint a Noun with `nounId` to the provided `to` address.
    function _mintTo(
        address to,
        uint256 nounId,
        uint256 blockNumber,
        uint256 quantity
    ) internal returns (uint256) {
        if (seeds[nounId].nounId == 0) {
            nounIdOfNomo[_nextTokenId()] = nounId;
            seeds[nounId] = seeder.generateSeed(nounId, blockNumber, descriptor);
            emit NomoCreated(nounId, seeds[nounId]);
        }

        _mint(to, quantity);

        return nounId;
    }

    function _verify(
        uint256 nounsId,
        uint256 blockNumber,
        bytes calldata signature
    ) public view returns (address) {
        bytes32 TYPEHASH = keccak256('Minter(uint256 nounsId,uint256 blockNumber)');
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(TYPEHASH, nounsId, blockNumber)));
        return ECDSA.recover(digest, signature);
    }
}