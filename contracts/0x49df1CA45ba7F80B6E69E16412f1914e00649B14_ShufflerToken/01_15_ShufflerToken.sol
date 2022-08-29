// SPDX-License-Identifier: GPL-3.0
// Modified from nouns.wtf

/// @title The Onchain Shuffler ERC-721A token

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IERC721 } from '@openzeppelin/contracts/interfaces/IERC721.sol';
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { IShufflerToken } from './interfaces/IShufflerToken.sol';
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IShufflerDescriptor } from './interfaces/IShufflerDescriptor.sol';
import { Base64 } from './libs/base64.sol';
import { OriginalPunkProxy } from "./OriginalPunkProxy.sol";

contract ShufflerToken is ERC721A, IShufflerToken, Ownable, ReentrancyGuard {
    // The treasury address (creators org)
    address payable public treasury;

    // The token URI descriptor
    IShufflerDescriptor public descriptor;

    // merkle root for whitelisting
    bytes32 public merkleRoot;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked = false;

    // whether the seeds are locked(fully populated)
    bool public override areSeedsLocked = false;

    // whether the blind box is revealed
    bool public isRevealed = false;

    bool public isPublicSaleStarted = false;

    bool public isWhitelistSaleStarted = false;

    uint64 private seedsOffset;

    uint256 public composePrice = 0.01 ether;

    // a few more constants for minting
    uint64 public constant MAX_SUPPLY = 10000;
    uint64 public constant MAX_PER_MINT = 20;
    uint64 public constant MAX_PRESALE_SUPPLY = 3000;
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 public constant WHITELIST_MINT_PRICE = 0.06 ether;
    // contracts constants
    address public constant PUNK_ORIGINAL_CONTRACT = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    // mint count by owner
    mapping(address => uint256) private _alreadyMinted;
    // seeds for tokens
    Seed[] private seeds;
    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'bafkreigxg3pqah7tlc2ny2hyffjwm7qttxloctuhmabzzklkovgrnaxuya';

    /**
     * @notice Require that the seeds has not been locked.
     */
    modifier whenSeedsNotLocked() {
        require(!areSeedsLocked, 'Seeds are locked');
        _;
    }
    /**
 * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    constructor(
        address payable _treasury,
        IShufflerDescriptor _descriptor
    ) ERC721A('Onchain Shufflers', 'ONCHAIN SHUFFLERS') {
        treasury = _treasury;
        descriptor = _descriptor;
    }

    /**
     * @notice update treasury address
     */
    function setTreasury(address payable _treasury) external override onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Lock the seeds
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeds() external override onlyOwner whenSeedsNotLocked {
        areSeedsLocked = true;

        emit SeedsLocked();
    }

    /**
     * @notice Batch add seeds
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySeeds(uint256[] calldata _seeds) external override onlyOwner whenSeedsNotLocked {
        for (uint256 i = 0; i < _seeds.length; i++) {
            Seed memory seed = Seed({
                background: uint48(
                    uint48(_seeds[i])
                ),
                card: uint48(
                    uint48(_seeds[i] >> 48)
                ),
                side: uint48(
                    uint48(_seeds[i] >> 96)
                ),
                corner: uint48(
                    uint48(_seeds[i] >> 144)
                ),
                center: uint48(
                    uint48(_seeds[i] >> 192)
                ),
                override_contract: address(0),
                override_token_id: 0
            });
            seeds.push(seed);
        }
        emit SeedsAdded(_seeds);
    }

    function seedCount() external view override returns (uint256) {
        return seeds.length;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice toggle on/off the public sale switch
     */
    function setPublicSaleStatus(bool status) external onlyOwner {
        isPublicSaleStarted = status;
    }

    /**
     * @notice toggle on/off the whitelist sale switch
     */
    function setWhitelistSaleStatus(bool status) external onlyOwner {
        isWhitelistSaleStarted = status;
    }

    /**
     * @notice update merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice reveal all blind boxes
     */
    function reveal() external override onlyOwner {
        require(!isRevealed, "already revealed");
        require(areSeedsLocked, "can't reveal before seeds are locked");
        isRevealed = true;
        // start from a random position to assign randomness when revealing the cards
        seedsOffset = uint64(uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))) % MAX_SUPPLY;
        emit Reveal(seedsOffset);
        // enable rendering svg images instead of showing the blind box
        descriptor.toggleDataURIEnabled();
    }

    /**
     * @notice Mint a Shuffler token to the messenger sender
     */
    function mint(uint256 count) external payable nonReentrant override {
        require(isPublicSaleStarted, "Public sale not started yet");
        require(count > 0 && count <= MAX_PER_MINT, "Invalid number to mint");
        require(count * MINT_PRICE <= msg.value, "Incorrect amount of ether sent");

        _internalMint(_msgSenderERC721A(), count);
    }

    /**
      * @notice Mint by owner for free
     */
    function ownerMint(address to, uint256 count) external onlyOwner override{
        _internalMint(to, count);
    }

    /**
     * @notice Mint by whitelisted users
     */
    function mintWhiteList(
        uint256 count,
        uint256 maxCount,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant override {
        address sender = _msgSenderERC721A();

        require(isWhitelistSaleStarted, "Whitelist sale not started");
        require(_verify(merkleProof, sender, maxCount), "Wallet not whitelisted");
        require(_nextTokenId() + count <= MAX_PRESALE_SUPPLY, "Will exceed maximum presale supply");
        require(count <= maxCount - _alreadyMinted[sender], "Insufficient mints left");
        require(count * WHITELIST_MINT_PRICE <= msg.value, "Incorrect payable amount");

        _alreadyMinted[sender] += count;
        _internalMint(sender, count);
    }

    function _internalMint(address to, uint256 count) private {
        require(_nextTokenId() + count <= MAX_SUPPLY, "Will exceed maximum supply");

        uint256 startTokenId = _nextTokenId();
        _mint(to, count);
        emit ShufflerCreated(_msgSenderERC721A(), startTokenId, startTokenId + count - 1);
    }

    function _verify(
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxCount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, maxCount));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function seedId(uint256 tokenId) internal view returns (uint256) {
        require(seeds.length > 0, "Seeds not ready");
        return (tokenId + seedsOffset) % seeds.length;
    }

    function getSeed(uint256 tokenId) external view returns (Seed memory) {
        require(_exists(tokenId), 'ShufflerToken: URI query for nonexistent token');
        return seeds[seedId(tokenId)];
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ShufflerToken: URI query for nonexistent token');
        if (isRevealed) {
            return descriptor.tokenURI(tokenId, seeds[seedId(tokenId)]);
        } else {
            return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked('{"name":"Shuffler #', Strings.toString(tokenId), '", "image": "', descriptor.baseURI(), '"}')
                        )
                    )
                )
            );
        }
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IShufflerDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice withdraw the contract assets to treasury
     */
    function withdraw() external override {
        uint amount = address(this).balance;
        require(amount > 0, "no ethers to withdraw");
        treasury.transfer(amount);
    }

    /**
     * @notice set new compose price
     */
    function setComposePrice(uint256 _price) external override onlyOwner {
        composePrice = _price;
    }

    /**
     * @notice override the center part of card with a third-party nft specified by its
     * contract address and token id
     */
    function setOverrideNft(uint256 tokenId, address overrideContract, uint64 overrideTokenId) external payable override {
        require(_exists(tokenId), 'Nonexistent token can not be modified');
        require(isRevealed, 'Token not revealed yet');
        require(_msgSenderERC721A() == ownerOf(tokenId), 'Only owner can update the shuffler');
        require(msg.value >= composePrice, 'Invalid amount paid for composing');
        require(descriptor.isComposable(overrideContract), 'Unsupported contract for composing');
        require(_verifyOwnerOfOverride(overrideContract, overrideTokenId), 'Only owner of the target token can compose');

        _updateNftOverride(tokenId, overrideContract, overrideTokenId);
    }

    function removeOverrideNft(uint256 tokenId) external override {
        require(_exists(tokenId), 'Nonexistent token can not be modified');
        require(isRevealed, 'Token not revealed yet');
        require(_msgSenderERC721A() == ownerOf(tokenId), 'Only owner can update the shuffler');

        _updateNftOverride(tokenId, address(0x0), 0);
    }

    function _updateNftOverride(uint256 tokenId, address overrideContract, uint64 overrideTokenId) private {
        uint256 curSeedId = seedId(tokenId);
        seeds[curSeedId].override_contract = overrideContract;
        seeds[curSeedId].override_token_id = overrideTokenId;

        emit NftOverridden(tokenId, overrideContract, overrideTokenId);
    }

    function _verifyOwnerOfOverride(address overrideContract, uint64 overrideTokenId) internal view returns (bool) {
        if (overrideContract == PUNK_ORIGINAL_CONTRACT) {
            // original punk contract is not ERC721
            OriginalPunkProxy otherContract = OriginalPunkProxy(overrideContract);
            return otherContract.punkIndexToAddress(overrideTokenId) == _msgSenderERC721A();
        } else {
            IERC721 otherContract = IERC721(overrideContract);
            return otherContract.ownerOf(overrideTokenId) == _msgSenderERC721A();
        }
    }
}