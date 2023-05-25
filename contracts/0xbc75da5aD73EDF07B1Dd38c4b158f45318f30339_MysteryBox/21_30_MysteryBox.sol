// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IPotions.sol";
import "./interfaces/IBenefits.sol";
import "./interfaces/IMysteryBox.sol";
import "../utils/Claimable.sol";
import "../utils/EIP2981.sol";
import "../utils/GuardExtension.sol";
import {
    OperatorFiltererERC721,
    ERC721
} from "../utils/OperatorFiltererERC721.sol";

contract MysteryBox is
    GuardExtension,
    OperatorFiltererERC721,
    EIP2981,
    Claimable,
    IMysteryBox
{
    using Address for address;
    using Address for address payable;
    using Strings for uint256;
    uint256 private _tokenIds;
    uint256 private _total;
    uint256 private _commonLimit;
    uint256 private _rareLimit;
    uint256 private _commonPrice;
    uint256 private _rarePrice;
    uint256 private _rarePriceIncrease;
    mapping(address => uint256) private _commonIssued;
    mapping(address => uint256) private _rareIssued;
    IPotions private _potion;
    IBenefits private _benefits;
    mapping(address => uint256) private _commonLimits;
    mapping(address => uint256) private _rareLimits;
    mapping(uint256 => bool) private _rare;
    string private constant INCORRECT_PRICE = "MysteryBox: incorrect price";
    string private constant SOLD_OUT = "MysteryBox: sold out";
    string private constant NO_MORE_RARE =
        "MysteryBox: no more rare tokens allowed for user";
    string private constant NO_MORE_COMMON =
        "MysteryBox: no more common tokens allowed for user";
    string private constant SOLD_OUT_RARE = "MysteryBox: sold out rare tokens";
    string private constant SOLD_OUT_COMMON =
        "MysteryBox: sold out common tokens";
    string private constant WRONG_OWNER = "MysteryBox: wrong owner";
    string private constant WRONG_ID = "MysteryBox: wrong id";
    string private constant SAME_VALUE = "MysteryBox: same value";
    string private constant ZERO_ADDRESS = "MysteryBox: zero address";
    string private constant BASE_META_HASH =
        "ipfs://QmVUH44vewH4iF93gSMez3qB4dUxc7DowXPztiG3uRXFWS/";

    /// @notice validate the id
    modifier correctId(uint256 id_) {
        require(_exists(id_), WRONG_ID);
        _;
    }

    /**
@notice Constructor
@param name_ The name
@param symbol_ The symbol
@param rights_ The rights address
@param potion_ The potion address
@param benefits_ The benefits address
@param commonLimit_ The maximum number of the common potions saled for one account
@param rareLimit_ The maximum number of the rare potions saled for one account
@param commonPrice_ The price of the common potion
@param rarePrice_ The price of the rare potion
@param rarePriceIncrease_ The increase of the price for each bought rare box
*/
    constructor(
        string memory name_,
        string memory symbol_,
        address rights_,
        address potion_,
        address benefits_,
        uint256 commonLimit_,
        uint256 rareLimit_,
        uint256 commonPrice_,
        uint256 rarePrice_,
        uint256 rarePriceIncrease_
    ) Guard() ERC721(name_, symbol_) GuardExtension(rights_) {
        require(potion_ != address(0), ZERO_ADDRESS);
        require(benefits_ != address(0), ZERO_ADDRESS);

        _commonLimit = commonLimit_;
        _rareLimit = rareLimit_;
        _commonPrice = commonPrice_;
        _rarePrice = rarePrice_;
        _rarePriceIncrease = rarePriceIncrease_;
        _potion = IPotions(potion_);
        _benefits = IBenefits(benefits_);
        emit CommonLimitDefined(_commonLimit);
        emit CommonPriceDefined(_commonPrice);
        emit RareLimitDefined(_rareLimit);
        emit RarePriceDefined(_rarePrice);
        emit RarePriceIncreaseDefined(_rarePriceIncrease);
    }

    /**
@notice Get a total amount of issued tokens
@return The number of tokens minted
*/
    function total() external view override returns (uint256) {
        return _total;
    }

    /**
@notice Set the maximum amount of the common potions saled for one account
@param value_ New amount
*/
    function setCommonLimit(uint256 value_) external override haveRights {
        _commonLimit = value_;
        emit CommonLimitDefined(value_);
    }

    /**
@notice Set the price of the common potions for the account
@param value_ New price
*/
    function setCommonPrice(uint256 value_) external override haveRights {
        _commonPrice = value_;
        emit CommonPriceDefined(value_);
    }

    /**
@notice Set new address of Potion contract
@param value_ New address value
*/
    function setPotion(address value_) external haveRights {
        require(address(_potion) != value_, SAME_VALUE);
        require(value_ != address(0), ZERO_ADDRESS);
        _potion = IPotions(value_);
    }

    /**
@notice Set new address of Benefits contract
@param value_ New address value
*/
    function setBenefits(address value_) external haveRights {
        require(address(_benefits) != value_, SAME_VALUE);
        require(value_ != address(0), ZERO_ADDRESS);
        _benefits = IBenefits(value_);
    }

    /**
@notice Set the maximum amount of the rare potions saled for one account
@param value_ New amount
*/
    function setRareLimit(uint256 value_) external override haveRights {
        _rareLimit = value_;
        emit RareLimitDefined(value_);
    }

    /**
@notice Set the maximum amount of the common potions saled for one account
@param value_ New amount
*/
    function setRarePrice(uint256 value_) external override haveRights {
        _rarePrice = value_;
        emit RarePriceDefined(value_);
    }

    /**
@notice Set the increase of the rare price
@param value_ New amount
*/
    function setRarePriceIncrease(uint256 value_) external override haveRights {
        _rarePriceIncrease = value_;
        emit RarePriceIncreaseDefined(_rarePriceIncrease);
    }

    /**
@notice Get the current rare price
@return Current rare price level
*/
    function getRarePrice() external view override returns (uint256) {
        return _rarePrice;
    }

    /**
@notice Get the amount of the tokens account can buy
@return The two uint's - amount of the common potions and amount of the rare potions
*/

    function getIssued(address account_)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (_commonIssued[account_], _rareIssued[account_]);
    }

    /**
@notice Create the packed id with rare or not (admin only)
@param target_ The box owner
@param rare_ The rarity flag
@return The new box id
*/
    function create(address target_, bool rare_)
        external
        override
        haveRights
        returns (uint256)
    {
        return _create(target_, rare_ ? 1 : 0);
    }

    function _create(address account_, uint8 level_) private returns (uint256) {
        return _create(account_, level_, account_, 0, false, 0);
    }

    /**
    @notice Get the rarity of the box
    @param tokenId_ The id of the token
    @return The rarity flag
    */
    function rarity(uint256 tokenId_)
        external
        view
        override
        correctId(tokenId_)
        returns (bool)
    {
        return _rare[tokenId_];
    }

    /**
@notice Deposit the funds (payable function)
*/
    function deposit() external payable override haveRights {}

    /**
@notice Receive the funds and give the box with rarity according to the amount of funds transferred
Look the event to get the ID (receive functions cannot return values)
*/
    receive() external payable {
        (
            address target,
            uint256 benId,
            uint256 price,
            uint16 tokenId,
            uint8 level,
            bool isBenFound
        ) = _benefits.get(msg.sender, 0, msg.value);

        // found benefit with custom price
        if (price > 0) {
            require(price == msg.value, INCORRECT_PRICE);
            if (target == address(0) && level == 0) {
                require(_commonLimit > _commonIssued[msg.sender], NO_MORE_COMMON);
            }
            // here the first reserved item must be
            _create(msg.sender, level, target, benId, isBenFound, tokenId);
            return;
        }
        require(
            _rarePrice == msg.value || _commonPrice == msg.value,
            INCORRECT_PRICE
        );

        if (isBenFound) {
            if (level > 0) {
                require(_rarePrice == msg.value, INCORRECT_PRICE);
                _create(msg.sender, level, target, benId, isBenFound, tokenId);
            } else {
                require(_commonPrice == msg.value, INCORRECT_PRICE);
                _create(
                    msg.sender,
                    level,
                    target,
                    benId,
                    isBenFound,
                    tokenId == 0 ? _tokenIds : tokenId
                );
            }
            return;
        }

        // nothing found, let's check ordinary
        if (_rarePrice == msg.value) {
            _create(msg.sender, level, target, benId, false, tokenId);
        } else {
            require(_commonLimit > _commonIssued[msg.sender], NO_MORE_COMMON);
            _create(msg.sender, level, target, benId, false, tokenId);
        }
    }

    function _create(
        address account_,
        uint8 level_,
        address benTarget_,
        uint256 benId_,
        bool benIsFound_,
        uint256 newTokenId_
    ) private returns (uint256) {
        bool isRare = level_ > 0;
        if (isRare && newTokenId_ != 1) {
            _rarePrice = _rarePrice + _rarePriceIncrease;
        }
        IBenefits benefits = _benefits;
        if (isRare) {
            require(_rareLimit > _rareIssued[account_], NO_MORE_RARE);
            require(_potion.decreaseAmount(true), SOLD_OUT_RARE);
            _rareIssued[account_] = _rareIssued[account_] + 1;
        } else {
            require(_potion.decreaseAmount(false), SOLD_OUT_COMMON);
            _commonIssued[account_] = _commonIssued[account_] + 1;
        }
        uint256 newId = newTokenId_ == 0 ? _tokenIds : newTokenId_;
        if (newTokenId_ == 0) {
            do {
                newId = newId + 1;
            } while (benefits.denied(newId));
            _tokenIds = newId;
        }

        _rare[newId] = isRare;
        _mint(account_, newId);
        if (benIsFound_) {
            benefits.set(benTarget_, benId_);
        }
        emit Created(account_, newId, isRare);
        _total += 1;
        return newId;
    }

    /**
@notice Open the packed box 
@param id_ The box id
@return The new potion id
*/
    function open(uint256 id_)
        external
        override
        correctId(id_)
        returns (uint256)
    {
        require(ownerOf(id_) == msg.sender, WRONG_OWNER);
        uint256 newId = _potion.create(msg.sender, _rare[id_], id_);
        delete _rare[id_];
        _burn(id_);
        emit Opened(msg.sender, newId);
        return newId;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 id_)
        public
        view
        override(ERC721, IERC721Metadata)
        correctId(id_)
        returns (string memory)
    {
        if (id_ < 12) {
            return
                string(
                    abi.encodePacked(
                        BASE_META_HASH,
                        "legendary/",
                        id_.toString(),
                        "/meta.json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        BASE_META_HASH,
                        "mystery/",
                        id_.toString(),
                        "/meta.json"
                    )
                );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}