// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IDelegationRegistry {
    function checkDelegateForAll(
        address delegate,
        address vault
    ) external view returns (bool);
}

contract GarbageBags is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using BitMaps for BitMaps.BitMap;

    uint16 public constant MAX_SUPPLY = 6500;
    uint16 public constant PHASE1_SUPPLY = 5400;
    uint224 public mintingFee;
    uint256 public minStakeTime = 30 days;
    bool public paused;
    bool public isTokenBasedMintEnabled;
    string public baseTokenURI;
    address public signer;
    address private _allowedCaller;
    BitMaps.BitMap private _isUpgrade;
    BitMaps.BitMap private _isMintedTokenId;

    IERC721 public invisibleFriends;
    IDelegationRegistry public delegationRegistry;

    // staker address to staked ids
    mapping(address => uint256[]) private _stakes;

    // staker address to minte4d token id
    mapping(address => uint256) private _usersMintedId;

    // stakers staked id to index
    mapping(uint256 => uint256) private _stakeIdsIndex;

    // stakers id to stake time
    mapping(address => mapping(uint256 => uint256)) private _userStakeTime;

    // Events
    event Staked(address indexed user, uint256[] tokenIds, uint256 stakeTime);
    event Unstaked(address indexed user, uint256[] tokenIds);

    // Custom error
    error ContractPausedError();
    error IncorrectMintingFeeError();
    error MaxSupplyReachedError();
    error InvalidSignatureError();
    error ZeroBalanceError();
    error WithdrawalFailedError();
    error OnlyAllowedCallerError();
    error ZeroStakeError();
    error NotTokenOwnerError();
    error AlreadyStakedError();
    error NoStakeFoundError();
    error NftStakeError();
    error InvalidPhaseError();
    error Phase1SupplyReachedError();
    error TokenIdAlreadyMintedError();
    error NotDelegatedError();
    error TokenBasedMintDisabledError();

    constructor(
        uint224 _mintingFee,
        uint96 _royaltyFraction,
        string memory _baseTokenURI,
        address _signer,
        address _invisibleFriends,
        address _delegationRegistry
    ) ERC721A("Garbage Bags", "GARBAGEB") {
        mintingFee = _mintingFee;
        paused = true;
        isTokenBasedMintEnabled = true;
        baseTokenURI = _baseTokenURI;
        signer = _signer;
        _setDefaultRoyalty(_msgSender(), _royaltyFraction);
        invisibleFriends = IERC721(_invisibleFriends);
        delegationRegistry = IDelegationRegistry(_delegationRegistry);
        _mintERC2309(_msgSender(), 100);
    }

    // Modifiers

    modifier onlyAllowedCaller() {
        if (_msgSender() != _allowedCaller) revert OnlyAllowedCallerError();
        _;
    }

    modifier verifyPause() {
        if (paused) revert ContractPausedError();
        _;
    }

    modifier verifyMintingFee(uint256 amount) {
        if (msg.value != mintingFee * amount) revert IncorrectMintingFeeError();
        _;
    }

    /**
     *@notice This is an internal function that returns base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Mint token for 'to' address
     * @param amount uint
     * @param phase uint
     * @param sig bytes
     * @param to address
     */
    function mint(
        uint256 amount,
        uint256 phase,
        bytes calldata sig,
        address to
    ) external payable verifyPause verifyMintingFee(amount) {
        if (phase == 0 || phase > 2) revert InvalidPhaseError();
        if (phase == 1) {
            if (_totalMinted() + amount > PHASE1_SUPPLY)
                revert Phase1SupplyReachedError();
        } else {
            if (_totalMinted() + amount > MAX_SUPPLY)
                revert MaxSupplyReachedError();
        }
        uint256 nonce = _getAux(to);
        address sigRecover = keccak256(
            abi.encodePacked(to, amount, nonce, phase)
        ).toEthSignedMessageHash().recover(sig);

        if (sigRecover != signer) revert InvalidSignatureError();
        _setAux(to, uint64(nonce) + 1);
        _mint(to, amount);
    }

    /**
     * @notice Mint token for 'caller' address
     * @param tokenIds uint[]
     * @param phase uint256
     */
    function mintForGarbageFriends(
        uint256[] calldata tokenIds,
        uint256 phase
    ) external payable verifyPause verifyMintingFee(tokenIds.length) {
        if (!isTokenBasedMintEnabled) revert TokenBasedMintDisabledError();
        if (phase != 1) revert InvalidPhaseError();
        if (_totalMinted() + tokenIds.length > PHASE1_SUPPLY)
            revert Phase1SupplyReachedError();

        _checkOwnershipAndMarkIDsMinted(tokenIds, _msgSender());
        _mint(_msgSender(), tokenIds.length);
    }

    /**
     * @notice Mint token for 'vault' address
     * @param vault address
     * @param tokenIds uint[]
     * @param phase uint
     */
    function delegateMintForGarbageFriends(
        address vault,
        uint256[] calldata tokenIds,
        uint256 phase
    ) external payable verifyPause verifyMintingFee(tokenIds.length) {
        if (!isTokenBasedMintEnabled) revert TokenBasedMintDisabledError();
        if (phase != 1) revert InvalidPhaseError();
        if (_totalMinted() + tokenIds.length > PHASE1_SUPPLY)
            revert Phase1SupplyReachedError();
        if (!delegationRegistry.checkDelegateForAll(_msgSender(), vault))
            revert NotDelegatedError();

        _checkOwnershipAndMarkIDsMinted(tokenIds, vault);
        _mint(vault, tokenIds.length);
    }

    /**
     * @notice Internal function to check ownership of token and set minted token
     * @param originalIds unit
     * @param owner address
     */
    function _checkOwnershipAndMarkIDsMinted(
        uint256[] calldata originalIds,
        address owner
    ) private {
        uint256 tokenId;
        for (uint256 i = 0; i < originalIds.length; ) {
            tokenId = originalIds[i];
            if (invisibleFriends.ownerOf(tokenId) != owner)
                revert NotTokenOwnerError();
            if (_isMintedTokenId.get(tokenId))
                revert TokenIdAlreadyMintedError();

            _isMintedTokenId.set(tokenId);
            _usersMintedId[owner]++;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the pause status
     * @param _status bool
     */
    function setPause(bool _status) external onlyOwner {
        paused = _status;
    }

    /**
     * @notice Sets the signer wallet address
     * @param _signer address
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI string
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Update minting fee
     * @param _fee uint
     */
    function setMintingFee(uint224 _fee) external onlyOwner {
        mintingFee = _fee;
    }

    /**
     * @notice Update caller to burn token
     * @param _caller address
     */
    function setAllowedCaller(address _caller) external onlyOwner {
        _allowedCaller = _caller;
    }

    /**
     * @notice Update royalty information
     * @param receiver address
     * @param numerator uint96
     */
    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /**
     * @notice Update minimum staking time to unstake token
     * @param _minStakeTime uint
     */
    function setMinStakeTime(uint256 _minStakeTime) external onlyOwner {
        minStakeTime = _minStakeTime;
    }

    /**
     * @notice Update token based minting status
     * @param status bool
     */
    function setTokenBasedMintStatus(bool status) external onlyOwner {
        isTokenBasedMintEnabled = status;
    }

    /**
     * @notice burn token id
     * @param tokenId uint
     */
    function burn(uint256 tokenId) external onlyAllowedCaller {
        _burn(tokenId);
    }

    /**
     * @notice Owner can withdraw balance
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalanceError();
        (bool success, ) = owner().call{value: balance}("");
        if (!success) revert WithdrawalFailedError();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Override following ERC721a's method to auto restrict marketplace contract

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        if (_stakes[_msgSender()].length > 0) {
            revert NftStakeError();
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        if (_exists(tokenId)) {
            if (_userStakeTime[ownerOf(tokenId)][tokenId] > 0) {
                revert NftStakeError();
            }
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override {
        if (_exists(tokenId)) {
            if (_userStakeTime[ownerOf(tokenId)][tokenId] > 0) {
                revert NftStakeError();
            }
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the URI for `tokenId` token
     * @param tokenId uint
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory base = _baseURI();
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    /**
     * @dev Returns if token ids minted or not
     * @param tokenIds uint[]
     */
    function checkAlreadyMintedIds(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory states = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ) {
            states[i] = _isMintedTokenId.get(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return states;
    }

    /**
     * @dev Stake the token ids
     * @param _tokenIds uint[]
     * @param sig bytes
     */
    function stake(uint256[] calldata _tokenIds, bytes calldata sig) external verifyPause {
        if (_tokenIds.length == 0) revert ZeroStakeError();
        uint256 nonce = _getAux(_msgSender());
        address sigRecover = keccak256(
            abi.encodePacked(_msgSender(), _tokenIds.length, nonce)
        ).toEthSignedMessageHash().recover(sig);

        if (sigRecover != signer) revert InvalidSignatureError();
        _setAux(_msgSender(), uint64(nonce) + 1);

        for (uint256 i; i < _tokenIds.length; ) {
            uint256 tokenId = _tokenIds[i];
            if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwnerError();
            if (_userStakeTime[_msgSender()][tokenId] != 0)
                revert AlreadyStakedError();
            _stakeIdsIndex[tokenId] = _stakes[_msgSender()].length;
            _stakes[_msgSender()].push(tokenId);
            _userStakeTime[_msgSender()][tokenId] = block.timestamp;
            unchecked {
                ++i;
            }
        }

        emit Staked(_msgSender(), _tokenIds, block.timestamp);
    }

    /**
     * @dev Unstake the token ids
     * @param _tokenIds uint[]
     */
    function unstake(uint256[] calldata _tokenIds) external {
        if (_tokenIds.length == 0) revert ZeroStakeError();
        for (uint256 i; i < _tokenIds.length; ) {
            uint256 tokenId = _tokenIds[i];
            if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwnerError();

            uint256 stakeTime = _userStakeTime[_msgSender()][tokenId];
            if (stakeTime == 0) revert NoStakeFoundError();

            uint256 index = _stakeIdsIndex[tokenId];
            uint256 lastIndex = _stakes[_msgSender()].length - 1;
            uint256 lastId = _stakes[_msgSender()][lastIndex];

            _stakes[_msgSender()].pop();

            // Swap last index with removed index if there are still items left
            if (lastIndex != 0) {
                _stakes[_msgSender()][index] = lastId;
                _stakeIdsIndex[lastId] = index;
            }

            if (block.timestamp > stakeTime + minStakeTime) {
                _isUpgrade.set(tokenId);
            }

            delete _stakeIdsIndex[tokenId];
            delete _userStakeTime[_msgSender()][tokenId];

            unchecked {
                ++i;
            }
        }

        emit Unstaked(_msgSender(), _tokenIds);
    }

     /**
     * @dev Returns the users minted token ids
     * @param user address
     */
    function getMintedIds(
        address user
    ) external view returns (uint256) {
        return _usersMintedId[user];
    }

    /**
     * @dev Returns the staked token ids of staker
     * @param user address
     */
    function getStakeIds(
        address user
    ) external view returns (uint256[] memory) {
        return _stakes[user];
    }

    /**
     * @dev Returns the nonce of user
     * @param user address
     */
    function nonces(address user) external view returns (uint256) {
        return _getAux(user);
    }

    /**
     * @dev Returns if token id is upgrade or not
     * @param tokenId uint
     */
    function isUpgradeTokenId(uint256 tokenId) external view returns (bool) {
        return _isUpgrade.get(tokenId);
    }

    /**
     * @dev Returns the staked token ids of staker
     * @param user address
     */
    function getStakeInfo(
        address user
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256 stakesLen = _stakes[user].length;
        uint256[] memory stakeTime = new uint256[](stakesLen);

        for (uint256 i; i < stakesLen; ) {
            uint256 id = _stakes[user][i];
            stakeTime[i] = _userStakeTime[user][id];
            unchecked {
                ++i;
            }
        }
        return (_stakes[user], stakeTime);
    }
}