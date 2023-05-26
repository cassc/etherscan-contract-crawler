// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

// library
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Errors } from "./types/Errors.sol";
import { Constants } from "./Constants.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721RandomlyAssignVandalzTier.sol";

interface IGoodKarmaToken {
    function burnTokenForVandal(address holderAddress) external;
}

// solhint-disable

// // // // // // // // // // // // // // // // // // // // // //
// ██╗   ██╗ █████╗ ███╗   ██╗██████╗  █████╗ ██╗     ███████╗ //
// ██║   ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██║     ╚══███╔╝ //
// ██║   ██║███████║██╔██╗ ██║██║  ██║███████║██║       ███╔╝  //
// ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║  ██║██╔══██║██║      ███╔╝   //
//  ╚████╔╝ ██║  ██║██║ ╚████║██████╔╝██║  ██║███████╗███████╗ //
//   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ //
// // // // // // // // // // // // // // // // // // // // // //

// solhint-enable

/**
 * @title tirewise random assignment contract for vandalz
 * @author
 */
contract WhIsBeVandalz is
    ERC721,
    Ownable,
    ERC721RandomlyAssignVandalzTier,
    ERC721Holder,
    ERC721Burnable,
    ERC165Storage,
    IERC2981
{
    //==Type declarations==//

    using Strings for uint256;
    using SafeERC20 for IERC20;

    //==state variables==//
    /**
     * @notice
     * @dev
     */
    uint256 public publicSalePrice;

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
    bool public revealed = true;

    /**
     * @notice
     * @dev
     */
    bool public redeemPaused = true;

    /**
     * @notice
     * @dev
     */
    bool public includeTier1 = false;

    /**
     * @notice list of allowlist address hashed
     * @dev the merkle root hash allowlist
     */
    bytes32 public merkleRoot;

    address public royaltyAddress;
    uint256 public royaltyPercent;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier15678Indexes;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier5678Indexes;

    /**
     * @notice
     * @dev
     */
    string public baseURI;

    /**
     * @notice
     * @dev
     */
    string public baseExtension = ".json";

    /**
     * @notice
     * @dev
     */
    string public notRevealedUri;

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

    //==Constants==//

    // bytes4 constants for ERC165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_IERC721Metadata = 0x5b5e139f;

    /**
     * @notice number of tiers
     * @dev the length of `_tiers` array in constructor should exactly match this number
     */
    uint256 public constant TIERS = uint256(8);

    //==events==//
    event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);

    //==Modifiers==//

    /**
     * @dev Throws if timestamp already set.
     */
    modifier publicMintNotPaused() {
        require(publicMintPaused == false, "Public mint is paused");
        _;
    }

    /**
     * @dev Throws if timestamp already set.
     */
    modifier redeemNotPaused() {
        require(redeemPaused == false, "Redeem is paused");
        _;
    }

    //===Constructor===//

    /**
     * @notice
     * @dev
     * @param _name name of the collection
     * @param _symbol symbol of the collection
     * @param _totalSupply maximum pieces if the collection
     * @param _startFrom first token ID of collection
     * @param _tiers list of tier details
     * @param _initBaseURI x
     * @param _initNotRevealedUri v
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _startFrom,
        DataTypes.Tier[] memory _tiers,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) ERC721RandomlyAssignVandalzTier(_totalSupply, _startFrom) {
        uint256 _tiersLen = _tiers.length;
        if (_tiersLen != TIERS) {
            revert Errors.WhisbeVandalz__EightTiersRequired(_tiersLen);
        }

        baseURI = _initBaseURI;

        // no reveal uri
        notRevealedUri = _initNotRevealedUri;

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

        // custom : group tiers 5,6,7,& 8
        groupTier5678Indexes.push(4); // tier5 , group index -> 0
        groupTier5678Indexes.push(5); // tier6 , group index -> 1
        groupTier5678Indexes.push(6); // tier7 , group index -> 2
        groupTier5678Indexes.push(7); // tier8 , group index -> 3

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_IERC2981);
        _registerInterface(_INTERFACE_ID_IERC721Metadata);
        _setRoyalties(msg.sender, 1100); // 11% royalty
    }

    //===receive function===//

    receive() external payable {
        publicMint(new bytes32[](0));
    }

    //===External functions===//

    /**
     * @notice
     * @dev
     */
    function redeem(address[] memory _collections, uint256[][] memory _tokenIds) external redeemNotPaused {
        uint256 _collectionsLen = _collections.length;
        require(_collectionsLen == _tokenIds.length, "");
        for (uint256 _j; _j < _collectionsLen; _j++) {
            if (!acceptedCollections[_collections[_j]]) {
                revert Errors.WhisbeVandalz__InvalidCollection(_collections[_j]);
            }
            uint256 _tokenIdsLen = _tokenIds[_j].length;
            burnCounter[_collections[_j]] += _tokenIdsLen;
            for (uint256 _i; _i < _tokenIdsLen; _i++) {
                // transfer ownership or burn
                if (_collections[_j] == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
                    ERC721Burnable(_collections[_j]).safeTransferFrom(msg.sender, address(this), _tokenIds[_j][_i]);
                } else if (_collections[_j] == Constants.GOOD_KARMA_TOKEN) {
                    IGoodKarmaToken(_collections[_j]).burnTokenForVandal(msg.sender);
                } else {
                    ERC721Burnable(_collections[_j]).burn(_tokenIds[_j][_i]);
                }
                // mint Vandalz
                _mintRandomVandalz(msg.sender, _collections[_j]);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function airDropToOG(address[] memory _tos) external onlyOwner {
        if (includeTier1) {
            for (uint256 _i; _i < _tos.length; _i++) {
                _handleMintRandomlyFromTierGroup15678(_tos[_i], 1);
            }
        } else {
            for (uint256 _i; _i < _tos.length; _i++) {
                _handleMintRandomlyFromTierGroup5678(_tos[_i], 1);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function creatorMint(address _to, uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 _i; _i < _tokenIds.length; _i++) {
            _internalCreatorMint(_to, _tokenIds[_i]);
        }
    }

    /**
     * @notice
     * @dev
     */
    function _internalCreatorMint(address _to, uint256 _tokenId) internal ensureAvailability {
        _updateTierTokenCount(_tokenId);
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice
     * @dev
     */
    function setSupply(uint256 _supply) external onlyOwner {
        _setSupply(_supply);
    }

    /**
     * @notice
     * @dev
     */
    function setTier(
        uint256[] memory _tierIndex,
        uint256[] memory _from,
        uint256[] memory _to
    ) external onlyOwner {
        require(
            _tierIndex.length == _from.length && _from.length == _to.length,
            "WhisbeVandalz: tier details length mismatch"
        );
        for (uint256 _i; _i < _tierIndex.length; _i++) {
            require(_tierIndex[_i] < TIERS, "WhisbeVandalz: tierIndex exceeds max permitted tiers");
            _setTier(_tierIndex[_i], _from[_i], _to[_i]);
        }
    }

    /**
     * @notice
     * @dev
     */
    function reveal() external onlyOwner {
        revealed = true;
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
    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
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
    function pausePublicMint(bool _state) external onlyOwner {
        publicMintPaused = _state;
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
    function setIncludeTier1(bool _includeTier1) external onlyOwner {
        includeTier1 = _includeTier1;
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
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice
     * @dev
     */
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @notice
     * @dev
     */
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Transfer accidentally locked ERC20 tokens
     * @dev can be called by owner only.
     * @param _token - ERC20 token address.
     * @param _amount - ERC20 token amount.
     */
    function transferAccidentallyLockedTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        require(address(_token) != address(0), "Token address can not be zero");
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        _token.safeTransfer(msg.sender, _amount);
    }

    function setRoyaltyInfo(address $royaltyAddress, uint256 $percentage) external onlyOwner {
        _setRoyalties($royaltyAddress, $percentage);
        emit UpdatedRoyalties($royaltyAddress, $percentage);
    }

    //===Public functions===//

    /**
     * @notice
     * @dev
     * @param _proof a
     */
    function publicMint(bytes32[] memory _proof) public payable publicMintNotPaused {
        // Notes: 1592 will be comprised of Tier 3 pieces (approximately 650pieces)
        // Remaining pieces chosen from Tier 1/5/6/7/8

        // cannot mint more than two Vandalz
        if (publicMintCounter[msg.sender] >= 2) {
            revert Errors.WhisbeVandalz__PublicMintUpToTwoPerWallet();
        }

        require(msg.value == publicSalePrice, "WhisbeVandalz: eth value should be equal to publicSalePrice");
        if (whitelistState) {
            _isWhitelistedAddress(_proof);
        }
        _safeMint(msg.sender, _nextToken());
        publicMintCounter[msg.sender] += 1;
    }

    //===Public view functions===//

    function royaltyInfo(uint256, uint256 $salePrice)
        public
        view
        override(IERC2981)
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = royaltyAddress;

        // This sets percentages by price * percentage / 10000
        _royaltyAmount = ($salePrice * royaltyPercent) / 10000;
    }

    function supportsInterface(bytes4 $interfaceId)
        public
        view
        override(ERC165Storage, ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface($interfaceId);
    }

    /**
     * @notice
     * @dev
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    /**
     * @notice
     * @dev
     */
    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    //===Internal functions===//

    function _setRoyalties(address $receiver, uint256 $percentage) internal {
        royaltyAddress = $receiver;
        royaltyPercent = $percentage;
    }

    /**
     * @notice
     * @dev
     */
    function _mintRandomVandalz(address _to, address _collection) internal {
        if (_collection == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
            _handleMintForExtinctionOpenEditionByWhisbe(_to);
        } else if (_collection == Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE) {
            _handleMintForTheHornedKarmaChamaleonBurnRedemptionByWhisbe(_to);
        } else if (_collection == Constants.KARMA_KEY_BLACK_BY_WHISBE) {
            _handleMintForKarmaKeyBlackByWhisbe(_to);
        } else if (_collection == Constants.KARMA_KEYS_BY_WHISBE) {
            _handleMintForKarmaKeysByWhisbe(_to);
        } else if (_collection == Constants.GOOD_KARMA_TOKEN) {
            _handleMintForGoodKarmaToken(_to);
        } else {
            revert Errors.WhisbeVandalz__MintNotAvailable();
        }
    }

    //===Internal view functions===//

    /**
     * @notice function to check via merkle proof whether an address is whitelisted
     * @param _proof the nodes required for the merkle proof
     */
    function _isWhitelistedAddress(bytes32[] memory _proof) internal view {
        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, addressHash), "Whitelist: caller is not whitelisted");
    }

    /**
     * @inheritdoc ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //===Private functions===//

    /**
     * @notice
     * @dev
     */
    function _handleMintForExtinctionOpenEditionByWhisbe(address _to) private {
        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, 1);
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, 1);
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForTheHornedKarmaChamaleonBurnRedemptionByWhisbe(address _to) private {
        // 1 from tier 2
        _safeMint(_to, _nextTokenFromTier(1));

        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 8 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(8));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(8));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForKarmaKeyBlackByWhisbe(address _to) private {
        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForKarmaKeysByWhisbe(address _to) private {
        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForGoodKarmaToken(address _to) private {
        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintRandomlyFromTierGroup15678(address _to, uint256 _count) private {
        uint256 _groupTier15678IndexesLen = groupTier15678Indexes.length;
        if (_groupTier15678IndexesLen == 0) {
            revert Errors.WhisbeVandalz__NoGroupTier15678Group();
        }
        uint256 _randomTier15678GroupIndex;
        for (uint256 _i; _i < _count; _i++) {
            // get random tier index from tier group
            _randomTier15678GroupIndex = _getRandomNumber() % _groupTier15678IndexesLen;

            // mint
            _safeMint(_to, _nextTokenFromTier(groupTier15678Indexes[_randomTier15678GroupIndex]));

            // check and update tier group based on each tier's token availability
            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier15678GroupIndex);
            if (_randomTier15678GroupIndex != 0) {
                _checkAndUpdateGroupTier5678TokenAvailability(_randomTier15678GroupIndex - 1);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintRandomlyFromTierGroup5678(address _to, uint256 _count) private {
        uint256 _groupTier5678IndexesLen = groupTier5678Indexes.length;
        if (_groupTier5678IndexesLen == 0) {
            revert Errors.WhisbeVandalz__NoGroupTier5678Group();
        }
        uint256 _randomTier5678GroupIndex;
        for (uint256 _i; _i < _count; _i++) {
            // get random tier index from tier group
            _randomTier5678GroupIndex = _getRandomNumber() % _groupTier5678IndexesLen;

            // mint
            _safeMint(_to, _nextTokenFromTier(groupTier5678Indexes[_randomTier5678GroupIndex]));

            // check and update tier group based on each tier's token availability
            _checkAndUpdateGroupTier5678TokenAvailability(_randomTier5678GroupIndex);
            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier5678GroupIndex + 1);
        }
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
    function _checkAndUpdateGroupTier5678TokenAvailability(uint256 _index) private {
        if (availableTierTokenCount(groupTier5678Indexes[_index]) == 0) {
            groupTier5678Indexes[_index] = groupTier5678Indexes[groupTier5678Indexes.length - 1];
            groupTier5678Indexes.pop();
        }
    }
}