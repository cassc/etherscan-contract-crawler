// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

// library
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Constants } from "./Constants.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { DataTypes } from "./types/DataTypes.sol";
import { Errors } from "./types/Errors.sol";

// contracts
import { ERC721RandomlyAssignVandalzTierPeriphery } from "./ERC721RandomlyAssignVandalzTierPeriphery.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IWhIsBeVandalz {
    function creatorMint(address _to, uint256[] memory _tokenIds) external;

    function TIERS() external view returns (uint256);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function setTier(
        uint256[] memory _tierIndex,
        uint256[] memory _from,
        uint256[] memory _to
    ) external;

    function setSupply(uint256 _supply) external;

    function reveal() external;

    function setBaseExtension(string memory _newBaseExtension) external;

    function setBaseURI(string memory _newBaseURI) external;

    function setNotRevealedURI(string memory _notRevealedURI) external;

    function withdrawETH() external;

    function transferAccidentallyLockedTokens(IERC20 _token, uint256 _amount) external;

    function setRoyaltyInfo(address $royaltyAddress, uint256 $percentage) external;
}

interface IGoodKarmaToken {
    function burnTokenForVandal(address holderAddress) external;
}

struct MintDetails {
    address collectionAddress;
    address beneficiary;
    uint256 tokenId;
}

contract WhIsBeVandalzPeriphery is
    ERC721RandomlyAssignVandalzTierPeriphery,
    ERC721Holder,
    ERC165Storage,
    ERC1155Holder,
    VRFConsumerBaseV2,
    Ownable
{
    //==Constants==//

    // bytes4 constants for ERC165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_IERC721Metadata = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_IERC1155 = 0xf23a6e61;

    /**
     * @notice
     * @dev
     */
    VRFCoordinatorV2Interface public COORDINATOR;

    /**
     * @notice
     * @dev
     */
    LinkTokenInterface public immutable LINKTOKEN;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier15678Indexes;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier135678Indexes;

    /**
     * @notice
     * @dev
     */
    address public whisbeVandalz;

    /**
     * @notice
     * @dev
     */
    bool public redeemPaused = true;

    /**
     * @notice
     * @dev
     */
    bool public publicMintPaused = true;

    /**
     * @notice
     * @dev
     */
    bool public whitelistState = true;

    /**
     * @notice
     * @dev
     */
    uint64 public s_subscriptionId;

    /**
     * @notice list of allowlist address hashed
     * @dev the merkle root hash allowlist
     */
    bytes32 public merkleRoot;

    /**
     * @notice
     * @dev
     */
    uint256 public publicSalePrice = 0.1 ether;

    /**
     * @notice
     * @dev
     */
    uint256 public vrnfRequestCounter;

    /**
     * @notice
     * @dev
     */
    uint256 public publicMintTier3Counter;

    /**
     * @notice
     * @dev
     */
    uint256 public publicMintTierGroup15678Counter;

    /**
     * @notice
     * @dev
     */
    uint256 public publicMintTier3Cap = 600;

    /**
     * @notice
     * @dev
     */
    uint256 public publicMintTierGroup15678Cap = 992;

    /**
     * @notice The gas lane to use, which specifies the maximum gas price to bump to.
     */
    bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    /**
     * @notice estimate gas used by fulfillRandomWords()
     */
    uint32 public callbackGasLimit = 1000000;

    /**
     * @notice The minimum number of confirmation blocks on VRF requests before oracles respond
     */
    uint16 public requestConfirmations = 3;

    /**
     * @notice
     * @dev
     */
    mapping(address => bool) public acceptedCollections;

    /**
     * @notice nft burn tracker
     * @dev increments the counter whenever nft is redeemed
     */
    mapping(address => uint256) public burnCounter;

    /**
     * @notice public mint tracker per wallet
     * @dev maps amount of "publicly" minted vandalz per wallet
     */
    mapping(address => uint256) public publicMintCounter;

    /**
     * @notice
     * @dev
     */
    mapping(uint256 => MintDetails[]) public s_requestIdToMintDetails;

    /**
     * @notice
     * @dev
     */
    mapping(uint256 => mapping(uint256 => uint256[])) public s_requestIdToTierIndexes;

    /**
     * @dev Throws if timestamp already set.
     */
    modifier redeemNotPaused() {
        require(redeemPaused == false, "Redeem is paused");
        _;
    }

    /**
     * @dev Throws if timestamp already set.
     */
    modifier publicMintNotPaused() {
        require(publicMintPaused == false, "Public mint is paused");
        _;
    }

    //===Constructor===//

    /**
     * @notice
     * @dev
     * @param _whisbeVandalz address of WhIsBeVandalz NFT
     * @param _totalSupply maximum pieces if the collection
     * @param _tiers list of tier details
     */
    constructor(
        address _whisbeVandalz,
        address _vrfCoordinator, // mainnet - 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        address _link_token_contract, // mainnet - 0x514910771AF9Ca656af840dff83E8264EcF986CA
        uint256 _totalSupply,
        DataTypes.Tier[] memory _tiers
    ) VRFConsumerBaseV2(_vrfCoordinator) ERC721RandomlyAssignVandalzTierPeriphery(_totalSupply, 1) {
        uint256 _tiersLen = _tiers.length;
        whisbeVandalz = _whisbeVandalz;
        if (_tiersLen != IWhIsBeVandalz(whisbeVandalz).TIERS()) {
            revert Errors.WhisbeVandalzPeriphery__EightTiersRequired(_tiersLen);
        }

        // whitelisted collections
        acceptedCollections[address(Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.KARMA_KEY_BLACK_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.KARMA_KEYS_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.GOOD_KARMA_TOKEN)] = true;

        // tiers
        for (uint256 _i; _i < _tiersLen; _i++) {
            tiers.push(_tiers[_i]);
        }

        // custom : group tiers 1,5,6,7,& 8
        groupTier15678Indexes.push(0); // tier1 , group index -> 0
        groupTier15678Indexes.push(4); // tier5 , group index -> 1
        groupTier15678Indexes.push(5); // tier6 , group index -> 2
        groupTier15678Indexes.push(6); // tier7 , group index -> 3
        groupTier15678Indexes.push(7); // tier8 , group index -> 4

        // group tiers 1,3,5,6,7,& 8
        groupTier135678Indexes.push(0); // tier1 , group index -> 0
        groupTier135678Indexes.push(2); // tier3 , group index -> 1
        groupTier135678Indexes.push(4); // tier5 , group index -> 2
        groupTier135678Indexes.push(5); // tier6 , group index -> 3
        groupTier135678Indexes.push(6); // tier7 , group index -> 4
        groupTier135678Indexes.push(7); // tier8 , group index -> 5

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_IERC2981);
        _registerInterface(_INTERFACE_ID_IERC721Metadata);
        _registerInterface(_INTERFACE_ID_IERC165);
        _registerInterface(_INTERFACE_ID_IERC1155);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link_token_contract);
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
    }

    receive() external payable {}

    /**
     * @notice
     * @dev
     */
    function setWhIsBeVandalz(address _whisbeVandalz) external onlyOwner {
        whisbeVandalz = _whisbeVandalz;
    }

    /**
     * @notice top up subscription with $LINK
     * @dev can be accessed by owner only
     * @param _amount $LINK amount to top up
     */
    function topUpSubscription(uint256 _amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), _amount, abi.encode(s_subscriptionId));
    }

    /**
     * @notice add a consumer to the subscription.
     * @dev can be accessed by owner only
     * @param _consumerAddress consumer address
     */
    function addConsumer(address _consumerAddress) external onlyOwner {
        COORDINATOR.addConsumer(s_subscriptionId, _consumerAddress);
    }

    /**
     * @notice remove a consumer from subscription.
     * @dev can be accessed by owner only
     * @param _consumerAddress consumer address
     */
    function removeConsumer(address _consumerAddress) external onlyOwner {
        COORDINATOR.removeConsumer(s_subscriptionId, _consumerAddress);
    }

    /**
     * @notice cancel the subscription and send the remaining LINK to a wallet address.
     * @dev can be accessed by owner only
     * @param _receivingWallet receiving wallet address
     */
    function cancelSubscription(address _receivingWallet) external onlyOwner {
        COORDINATOR.cancelSubscription(s_subscriptionId, _receivingWallet);
        s_subscriptionId = 0;
    }

    /**
     * @notice transfer this contract's $LINK fund to an address.
     * @dev 1000000000000000000 = 1 LINK, can be accessed by owner only
     * @param _amount $LINK amount
     * @param _to address of recipient
     */
    function withdraw(uint256 _amount, address _to) external onlyOwner {
        LINKTOKEN.transfer(_to, _amount);
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setCallbackGaslimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function redeem(address[] memory _collections, uint256[][] memory _tokenIds) external redeemNotPaused {
        uint256 _collectionsLen = _collections.length;
        require(_collectionsLen == _tokenIds.length, "");
        uint32 _numWords;
        for (uint256 _j; _j < _collectionsLen; _j++) {
            if (!acceptedCollections[_collections[_j]]) {
                revert Errors.WhisbeVandalzPeriphery__InvalidCollection(_collections[_j]);
            }
            uint256 _tokenIdsLen = _tokenIds[_j].length;
            for (uint256 _i; _i < _tokenIdsLen; _i++) {
                // escrow
                if (_collections[_j] == Constants.GOOD_KARMA_TOKEN) {
                    IERC1155(_collections[_j]).safeTransferFrom(msg.sender, address(this), 0, 1, "");
                    // 1 from tier 15678
                    _numWords += 1;
                } else {
                    ERC721Burnable(_collections[_j]).safeTransferFrom(msg.sender, address(this), _tokenIds[_j][_i]);
                    if (_collections[_j] == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
                        // 1 from tier 4
                        // 1 from tier 15678
                        _numWords += 2;
                    } else if (_collections[_j] == Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE) {
                        // 1 from tier 2
                        // 1 from tier 4
                        // 8 from tier 1,5,6,7,8
                        _numWords += 10;
                    } else if (_collections[_j] == Constants.KARMA_KEY_BLACK_BY_WHISBE) {
                        // 1 from tier 4
                        // 1 from tier 1,5,6,7,8
                        _numWords += 2;
                    } else if (_collections[_j] == Constants.KARMA_KEYS_BY_WHISBE) {
                        // 1 from tier 1,5,6,7,8
                        _numWords += 1;
                    }
                }
            }
        }
        uint256 _requestId =
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                _numWords
            );
        vrnfRequestCounter += 1;
        uint256 _index;
        for (uint256 _j; _j < _collectionsLen; _j++) {
            uint256 _tokenIdsLen = _tokenIds[_j].length;
            for (uint256 _i; _i < _tokenIdsLen; _i++) {
                // construct mint details
                if (_collections[_j] == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
                    // 1 from tier 4
                    // 1 from tier 15678
                    s_requestIdToMintDetails[_requestId].push(
                        MintDetails({
                            collectionAddress: _collections[_j],
                            beneficiary: msg.sender,
                            tokenId: _tokenIds[_j][_i]
                        })
                    );
                    _index = s_requestIdToMintDetails[_requestId].length - 1;
                    s_requestIdToTierIndexes[_requestId][_index].push(3);
                    s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                } else if (_collections[_j] == Constants.GOOD_KARMA_TOKEN) {
                    // 1 from tier 15678
                    s_requestIdToMintDetails[_requestId].push(
                        MintDetails({
                            collectionAddress: _collections[_j],
                            beneficiary: msg.sender,
                            tokenId: _tokenIds[_j][_i]
                        })
                    );
                    _index = s_requestIdToMintDetails[_requestId].length - 1;
                    s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                } else {
                    if (_collections[_j] == Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE) {
                        // 1 from tier 2
                        // 1 from tier 4
                        // 8 from tier 1,5,6,7,8
                        s_requestIdToMintDetails[_requestId].push(
                            MintDetails({
                                collectionAddress: _collections[_j],
                                beneficiary: msg.sender,
                                tokenId: _tokenIds[_j][_i]
                            })
                        );
                        _index = s_requestIdToMintDetails[_requestId].length - 1;
                        s_requestIdToTierIndexes[_requestId][_index].push(1);
                        s_requestIdToTierIndexes[_requestId][_index].push(3);
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                    } else if (_collections[_j] == Constants.KARMA_KEY_BLACK_BY_WHISBE) {
                        // 1 from tier 4
                        // 1 from tier 1,5,6,7,8
                        s_requestIdToMintDetails[_requestId].push(
                            MintDetails({
                                collectionAddress: _collections[_j],
                                beneficiary: msg.sender,
                                tokenId: _tokenIds[_j][_i]
                            })
                        );
                        _index = s_requestIdToMintDetails[_requestId].length - 1;
                        s_requestIdToTierIndexes[_requestId][_index].push(3);
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                    } else if (_collections[_j] == Constants.KARMA_KEYS_BY_WHISBE) {
                        // 1 from tier 1,5,6,7,8
                        s_requestIdToMintDetails[_requestId].push(
                            MintDetails({
                                collectionAddress: _collections[_j],
                                beneficiary: msg.sender,
                                tokenId: _tokenIds[_j][_i]
                            })
                        );
                        _index = s_requestIdToMintDetails[_requestId].length - 1;
                        s_requestIdToTierIndexes[_requestId][_index].push(8); // 8 means tier group 15678
                    }
                }
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function migrateTokenMatrix(
        uint256[] memory _tierIndexes,
        uint256[] memory _offsets,
        uint256[] memory _tokenIndexes
    ) external onlyOwner {
        _updateTokenMatrix(_tierIndexes, _offsets, _tokenIndexes);
    }

    /**
     * @notice
     * @dev
     */
    function airDropWhisbeVandalzToOG(address _to) external onlyOwner {
        uint256 _requestId =
            COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, 1);
        vrnfRequestCounter += 1;
        s_requestIdToMintDetails[_requestId].push(
            MintDetails({ collectionAddress: address(0), beneficiary: _to, tokenId: 0 })
        );
        s_requestIdToTierIndexes[_requestId][s_requestIdToMintDetails[_requestId].length - 1].push(8); // 8 means tier group 15678
    }

    /**
     * @notice
     * @dev
     */
    function creatorMintWhisbeVandalz(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _tierIndexes,
        uint256[] memory _offsets,
        uint256[] memory _tokenIndexes
    ) external onlyOwner {
        uint256 _tokenIdlen = _tokenIds.length;
        uint256 _tierIndexesLen = _tierIndexes.length;
        require(_tokenIdlen == _tierIndexesLen, "creatorMintWhisbeVandalz: length mismatch");
        IWhIsBeVandalz(whisbeVandalz).creatorMint(_to, _tokenIds);
        for (uint256 _i; _i < _tierIndexesLen; _i++) {
            if (_tierIndexes[_i] == 0) {
                _checkAndUpdateGroupTier15678TokenAvailability(0);
                _checkAndUpdateGroupTier135678TokenAvailability(0);
            }
            if (_tierIndexes[_i] == 2) {
                _checkAndUpdateGroupTier135678TokenAvailability(2);
            }
            if (_tierIndexes[_i] >= 4 && _tierIndexes[_i] <= 7) {
                _checkAndUpdateGroupTier15678TokenAvailability(_tierIndexes[_i] - 3);
                _checkAndUpdateGroupTier135678TokenAvailability(_tierIndexes[_i] - 2);
            }
        }
        _updateTokenMatrix(_tierIndexes, _offsets, _tokenIndexes);
    }

    /**
     * @notice
     * @dev
     */
    function pauseRedeem(bool _state) external onlyOwner {
        redeemPaused = _state;
    }

    /**
     * @notice
     * @dev
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice
     * @dev
     */
    function pausePublicMint(bool _state) external onlyOwner {
        publicMintPaused = _state;
    }

    /**
     * @notice
     * @dev
     */
    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    /**
     * @notice
     * @dev
     */
    function setWhitelistState(bool _state) external onlyOwner {
        whitelistState = _state;
    }

    /**
     * @notice
     * @dev
     */
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice
     * @dev
     */
    function renounceWhisbeVandalzOwnership() external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).renounceOwnership();
    }

    /**
     * @notice
     * @dev
     */
    function transferWhisbeVandalzOwnership(address newOwner) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).transferOwnership(newOwner);
    }

    function setWhisbeVandalzTier(
        uint256[] memory _tierIndex,
        uint256[] memory _from,
        uint256[] memory _to
    ) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setTier(_tierIndex, _from, _to);
    }

    function setWhisbeVandalzSupply(uint256 _supply) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setSupply(_supply);
    }

    function revealWhisbeVandalz() external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).reveal();
    }

    function setWhisbeVandalzBaseExtension(string memory _newBaseExtension) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setBaseExtension(_newBaseExtension);
    }

    function setWhisbeVandalzBaseURI(string memory _newBaseURI) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setBaseURI(_newBaseURI);
    }

    function setWhisbeVandalzNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setNotRevealedURI(_notRevealedURI);
    }

    function withdrawWhisbeVandalzETH() external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).withdrawETH();
    }

    function transferWhisbeVandalzAccidentallyLockedTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).transferAccidentallyLockedTokens(_token, _amount);
    }

    function setWhisbeVandalzRoyaltyInfo(address $royaltyAddress, uint256 $percentage) external onlyOwner {
        IWhIsBeVandalz(whisbeVandalz).setRoyaltyInfo($royaltyAddress, $percentage);
    }

    function setPublicMintTier3Cap(uint256 _amount) external onlyOwner {
        publicMintTier3Cap = _amount;
    }

    function setPublicMintTierGroup15678Cap(uint256 _amount) external onlyOwner {
        publicMintTierGroup15678Cap = _amount;
    }

    function inCaseNftGetStuck(
        address _beneficiary,
        address _collection,
        uint256 _tokenId
    ) external onlyOwner {
        if (_collection == Constants.GOOD_KARMA_TOKEN) {
            IERC1155(_collection).safeTransferFrom(address(this), _beneficiary, 0, 1, "");
        } else {
            ERC721Burnable(_collection).safeTransferFrom(address(this), _beneficiary, _tokenId);
        }
    }

    function getMintDetails(uint256 _requestId) external view returns (MintDetails[] memory) {
        return s_requestIdToMintDetails[_requestId];
    }

    function getTierIndexes(uint256 _requestId, uint256 _index) external view returns (uint256[] memory) {
        return s_requestIdToTierIndexes[_requestId][_index];
    }

    function supportsInterface(bytes4 $interfaceId)
        public
        view
        override(ERC165Storage, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface($interfaceId);
    }

    /**
     * @notice
     * @dev
     * @param _proof a
     */
    function publicMint(bytes32[] memory _proof) public payable publicMintNotPaused {
        // Notes: 1592 will be comprised of Tier 3 pieces (625 pieces)
        // Remaining pieces chosen from Tier 1/5/6/7/8

        if (
            publicMintTier3Counter >= publicMintTier3Cap &&
            publicMintTierGroup15678Counter >= publicMintTierGroup15678Cap
        ) {
            revert Errors.WhisbeVandalzPeriphery__PublicMintOver();
        }

        // cannot mint more than two Vandalz
        if (publicMintCounter[msg.sender] >= 2) {
            revert Errors.WhisbeVandalzPeriphery__PublicMintUpToTwoPerWallet();
        }

        if (msg.value != publicSalePrice) {
            revert Errors.WhisbeVandalzPeriphery__IncorrectPublicSalePrice();
        }
        if (whitelistState) {
            _isWhitelistedAddress(_proof);
        }

        uint256 _requestId =
            COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, 1);
        vrnfRequestCounter += 1;

        s_requestIdToMintDetails[_requestId].push(
            MintDetails({ collectionAddress: address(0), beneficiary: msg.sender, tokenId: 0 })
        );
        s_requestIdToTierIndexes[_requestId][s_requestIdToMintDetails[_requestId].length - 1].push(9); // 9 means tier group 135678
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 _nftLen = s_requestIdToMintDetails[_requestId].length;
        uint256[] memory _ids = new uint256[](_randomWords.length);
        uint256 _tierIndexesLen;
        uint256 _ranCounter;
        for (uint256 _i; _i < _nftLen; _i++) {
            if (s_requestIdToMintDetails[_requestId][_i].collectionAddress != address(0)) {
                _burnNFT(s_requestIdToMintDetails[_requestId][_i]);
            }
            _tierIndexesLen = s_requestIdToTierIndexes[_requestId][_i].length;
            for (uint256 _j; _j < _tierIndexesLen; _j++) {
                uint256 _tierIndex = s_requestIdToTierIndexes[_requestId][_i][_j];
                if (_tierIndex == 8) {
                    // tier group 15678
                    uint256 _groupTier15678IndexesLen = groupTier15678Indexes.length;
                    if (_groupTier15678IndexesLen == 0) {
                        revert Errors.WhisbeVandalzPeriphery__NoGroupTier15678Group();
                    }
                    uint256 _randomTier15678GroupIndex = _randomWords[_ranCounter] % _groupTier15678IndexesLen;
                    // check and update tier group based on each tier's token availability
                    _checkAndUpdateGroupTier15678TokenAvailability(_randomTier15678GroupIndex);

                    if (_randomTier15678GroupIndex == 0) {
                        _checkAndUpdateGroupTier135678TokenAvailability(_randomTier15678GroupIndex);
                    } else {
                        _checkAndUpdateGroupTier135678TokenAvailability(_randomTier15678GroupIndex + 1);
                    }
                    _ids[_ranCounter] = _nextTokenFromTier(
                        _randomWords[_ranCounter],
                        groupTier15678Indexes[_randomTier15678GroupIndex]
                    );
                } else if (_tierIndex == 9) {
                    // public mint
                    if (
                        publicMintTier3Counter >= publicMintTier3Cap &&
                        publicMintTierGroup15678Counter >= publicMintTierGroup15678Cap
                    ) {
                        revert Errors.WhisbeVandalzPeriphery__PublicMintOver();
                    }
                    if (
                        publicMintTier3Counter < publicMintTier3Cap &&
                        publicMintTierGroup15678Counter < publicMintTierGroup15678Cap
                    ) {
                        uint256 _groupTier135678IndexesLen = groupTier135678Indexes.length;
                        if (_groupTier135678IndexesLen == 0) {
                            revert Errors.WhisbeVandalzPeriphery__NoGroupTier135678Group();
                        }
                        // get random tier index from tier group
                        uint256 _randomTier135678GroupIndex = _randomWords[_ranCounter] % _groupTier135678IndexesLen;

                        if (groupTier135678Indexes[_randomTier135678GroupIndex] == 2) {
                            publicMintTier3Counter += 1;
                        } else {
                            publicMintTierGroup15678Counter += 1;
                        }

                        // check and update tier group based on each tier's token availability
                        _checkAndUpdateGroupTier135678TokenAvailability(_randomTier135678GroupIndex);

                        if (_randomTier135678GroupIndex == 0) {
                            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier135678GroupIndex);
                        } else if (_randomTier135678GroupIndex >= 2 && _randomTier135678GroupIndex <= 5) {
                            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier135678GroupIndex - 1);
                        }
                        _ids[_ranCounter] = _nextTokenFromTier(
                            _randomWords[_ranCounter],
                            groupTier135678Indexes[_randomTier135678GroupIndex]
                        );
                    } else if (publicMintTierGroup15678Counter < publicMintTierGroup15678Cap) {
                        uint256 _groupTier15678IndexesLen = groupTier15678Indexes.length;
                        if (_groupTier15678IndexesLen == 0) {
                            revert Errors.WhisbeVandalzPeriphery__NoGroupTier15678Group();
                        }
                        uint256 _randomTier15678GroupIndex = _randomWords[_ranCounter] % _groupTier15678IndexesLen;
                        // check and update tier group based on each tier's token availability
                        _checkAndUpdateGroupTier15678TokenAvailability(_randomTier15678GroupIndex);
                        publicMintTierGroup15678Counter += 1;
                        if (_randomTier15678GroupIndex == 0) {
                            _checkAndUpdateGroupTier135678TokenAvailability(_randomTier15678GroupIndex);
                        } else {
                            _checkAndUpdateGroupTier135678TokenAvailability(_randomTier15678GroupIndex + 1);
                        }
                        _ids[_ranCounter] = _nextTokenFromTier(
                            _randomWords[_ranCounter],
                            groupTier15678Indexes[_randomTier15678GroupIndex]
                        );
                    }
                    publicMintCounter[s_requestIdToMintDetails[_requestId][_i].beneficiary] += 1;
                } else {
                    _ids[_ranCounter] = _nextTokenFromTier(_randomWords[_ranCounter], _tierIndex);
                    if (_tierIndex == 0 || _tierIndex == 4 || _tierIndex == 5 || _tierIndex == 6 || _tierIndex == 7) {
                        _checkAndUpdateGroupTier15678TokenAvailability(_tierIndex);
                    }
                    if (
                        _tierIndex == 0 ||
                        _tierIndex == 2 ||
                        _tierIndex == 4 ||
                        _tierIndex == 5 ||
                        _tierIndex == 6 ||
                        _tierIndex == 7
                    ) {
                        _checkAndUpdateGroupTier135678TokenAvailability(_tierIndex);
                    }
                }
                _ranCounter += 1;
            }
        }
        IWhIsBeVandalz(whisbeVandalz).creatorMint(s_requestIdToMintDetails[_requestId][0].beneficiary, _ids);
    }

    /**
     * @notice function to check via merkle proof whether an address is whitelisted
     * @param _proof the nodes required for the merkle proof
     */
    function _isWhitelistedAddress(bytes32[] memory _proof) internal view {
        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, addressHash), "Whitelist: caller is not whitelisted");
    }

    /**
     * @dev
     * @param _index
     */
    function _checkAndUpdateGroupTier15678TokenAvailability(uint256 _index) private {
        if (availableTierTokenCount(groupTier15678Indexes[_index]) == 0) {
            groupTier15678Indexes[_index] = groupTier15678Indexes[groupTier15678Indexes.length - 1];
            groupTier15678Indexes.pop();
        }
    }

    /**
     * @dev
     * @param _index
     */
    function _checkAndUpdateGroupTier135678TokenAvailability(uint256 _index) private {
        if (availableTierTokenCount(groupTier135678Indexes[_index]) == 0) {
            groupTier135678Indexes[_index] = groupTier135678Indexes[groupTier135678Indexes.length - 1];
            groupTier135678Indexes.pop();
        }
    }

    /**
     * @dev Create a new subscription when the contract is initially deployed.
     */
    function createNewSubscription() private onlyOwner {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    function _burnNFT(MintDetails memory _mintDetails) private {
        if (_mintDetails.collectionAddress == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
            ERC721Burnable(_mintDetails.collectionAddress).safeTransferFrom(
                address(this),
                whisbeVandalz,
                _mintDetails.tokenId
            );
        } else if (_mintDetails.collectionAddress == Constants.GOOD_KARMA_TOKEN) {
            IGoodKarmaToken(_mintDetails.collectionAddress).burnTokenForVandal(address(this));
        } else {
            ERC721Burnable(_mintDetails.collectionAddress).burn(_mintDetails.tokenId);
        }
    }
}