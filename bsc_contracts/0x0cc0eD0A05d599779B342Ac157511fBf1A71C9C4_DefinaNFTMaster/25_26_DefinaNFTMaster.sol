// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {TokenInfo} from "./NewDefinaCardStructs.sol";

interface INewDefinaCard{
    function heroIdMap(uint tokenId_) external view returns (uint);
    function rarityMap(uint tokenId_) external view returns (uint);
}

contract DefinaNFTMaster is Initializable, AccessControlEnumerableUpgradeable,
PausableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event NFTWithdraw(address indexed _who, uint indexed _tokenId);
    event NFTStaked(address indexed _who, uint indexed tokenId);
    event NFTBurned(address indexed _tokenAddres, uint indexed tokenId);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    EnumerableMapUpgradeable.UintToAddressMap private stakeMap;
    IERC721EnumerableUpgradeable public nftToken;
    mapping(address => EnumerableSetUpgradeable.UintSet) private tokensByAddr;

    mapping(uint => uint) public tokenByTimestamp;
    uint public lockTime;

    INewDefinaCard public newDefinaCard;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "DefinaNFTMaster: not eoa");
        _;
    }

    constructor() {}

    function initialize(address nft_) external initializer {
        __AccessControlEnumerable_init();
        __Pausable_init_unchained();
        __ERC721Holder_init_unchained();
        nftToken = IERC721EnumerableUpgradeable(nft_);
        newDefinaCard = INewDefinaCard(nft_);
        lockTime = 86400; //initial lock time set to 24 hours
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function stake(uint tokenId_) public onlyEOA whenNotPaused {
        require(nftToken.ownerOf(tokenId_) == _msgSender(), "tokenId are not owned by the caller");
        nftToken.safeTransferFrom(_msgSender(), address(this), tokenId_);
        stakeMap.set(tokenId_, _msgSender());
        tokenByTimestamp[tokenId_] = block.timestamp;
        tokensByAddr[_msgSender()].add(tokenId_);
        emit NFTStaked(_msgSender(), tokenId_);
    }

    function stakeMulti(uint[] memory tokenIds_) external onlyEOA whenNotPaused {
        require(tokenIds_.length != 0);
        for (uint i = 0; i < tokenIds_.length; i++) {
            stake(tokenIds_[i]);
        }
    }

    function withdraw(uint tokenId_) public onlyEOA whenNotPaused {
        require(nftToken.ownerOf(tokenId_) == address(this), "tokenId is not owned by the contract");
        require(stakeMap.contains(tokenId_), "tokenId was not staked");
        require(stakeMap.get(tokenId_) == _msgSender(), "the tokenId was not staked by the caller");
        require(tokenByTimestamp[tokenId_] + lockTime <= block.timestamp, "the token was not staked for 24 hours");
        stakeMap.remove(tokenId_);
        delete tokenByTimestamp[tokenId_];
        tokensByAddr[_msgSender()].remove(tokenId_);
        nftToken.safeTransferFrom(address(this), _msgSender(), tokenId_);
        emit NFTWithdraw(_msgSender(), tokenId_);
    }

    function withdrawMulti(uint[] memory tokenIds_) external onlyEOA whenNotPaused {
        require(tokenIds_.length != 0);
        for (uint i = 0; i < tokenIds_.length; i++) {
            withdraw(tokenIds_[i]);
        }
    }

    function getAddressStakedToken(uint tokenId_) view external returns(address) {
        require(stakeMap.contains(tokenId_), "tokenId was not staked");
        return stakeMap.get(tokenId_);
    }

    function isStaked(uint tokenId_) view external returns(bool) {
        return stakeMap.contains(tokenId_);
    }

    function getTokensStakedByAddress(address who) view external returns(TokenInfo[] memory) {
        require(who != address(0));
        uint length = tokensByAddr[who].length();

        TokenInfo[] memory tmp = new TokenInfo[](length);
        uint _tokenId;
        for (uint i = 0; i < length; i++) {
            _tokenId = tokensByAddr[who].at(i);
            tmp[i] = TokenInfo({
                tokenId : _tokenId,
                heroId : newDefinaCard.heroIdMap(_tokenId),
                rarity : newDefinaCard.rarityMap(_tokenId)
            });
        }

        return tmp;
    }

    function pause() onlyRole(DEFAULT_ADMIN_ROLE) public {
        _pause();
    }

    function unpause() onlyRole(DEFAULT_ADMIN_ROLE) public {
        _unpause();
    }

    /*
     * @dev Pull out all balance of token or BNB in this contract. When tokenAddress_ is 0x0, will transfer all BNB to the admin owner.
     */
    function pullFunds(address tokenAddress_) onlyRole(DEFAULT_ADMIN_ROLE) external {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function pullNFTs(address tokenAddress, address receivedAddress, uint amount) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(receivedAddress != address(0));
        require(tokenAddress != address(0));
        require(tokenAddress != address(nftToken), "Pulling staked NFT tokens are not allowed");
        uint balance = IERC721Upgradeable(tokenAddress).balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        for (uint i = 0; i < amount; i++) {
            uint tokenId = IERC721EnumerableUpgradeable(tokenAddress).tokenOfOwnerByIndex(address(this), 0);
            IERC721Upgradeable(tokenAddress).safeTransferFrom(address(this), receivedAddress, tokenId);
        }
    }

    function changeTokenAddress(address nft_) onlyRole(DEFAULT_ADMIN_ROLE) external {
        nftToken = IERC721EnumerableUpgradeable(nft_);
    }

    function changeLockTime(uint seconds_) onlyRole(DEFAULT_ADMIN_ROLE) external {
        lockTime = seconds_;
    }
}