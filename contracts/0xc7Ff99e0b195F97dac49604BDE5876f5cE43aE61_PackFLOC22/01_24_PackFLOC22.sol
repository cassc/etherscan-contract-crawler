// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PackFLOC22 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2771ContextUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    using SafeMath for uint256;

    struct AVAILABLE_NFT {
        uint256 token_price;
        uint256 token_reward;
        string token_url;
        string redeemed_url;
    }

    struct AVAILABLE_DISCOUNT {
        uint256 token_amount;
        uint256 token_discount;
    }

    struct REDEEMED_NFT {
        uint256 token_id;
        bool token_redeemed;
    }

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    AVAILABLE_NFT[] public AVAILABLE_NFTS;
    AVAILABLE_DISCOUNT[] public AVAILABLE_DISCOUNTS;
    REDEEMED_NFT[] public REDEEMED_NFTS;

    address public discountTokenAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(MinimalForwarderUpgradeable trustedForwarder)
        ERC2771ContextUpgradeable(address(trustedForwarder))
    {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _discountTokenAddress
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();

        discountTokenAddress = _discountTokenAddress;
        _transferOwnership(_owner);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _owner);
        _grantRole(UPDATER_ROLE, _owner);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setAvailableNFT(
        uint256 price,
        uint256 reward,
        string memory metadata,
        string memory _redeem_mt
    ) public onlyRole(UPDATER_ROLE) {
        AVAILABLE_NFTS.push(AVAILABLE_NFT(price, reward, metadata, _redeem_mt));
    }

    function editAvailableNFT(
        uint256 _token,
        uint256 _token_price,
        uint256 _token_reward,
        string memory _token_url,
        string memory _redeem_mt
    ) public onlyRole(UPDATER_ROLE) {
        AVAILABLE_NFTS[_token] = AVAILABLE_NFT(
            _token_price,
            _token_reward,
            _token_url,
            _redeem_mt
        );
    }

    function deleteAvailableNFT(uint256 _index)
        public
        onlyRole(UPDATER_ROLE)
    {
        for (uint256 i = _index; i < AVAILABLE_NFTS.length - 1; i++) {
            AVAILABLE_NFTS[i] = AVAILABLE_NFTS[i + 1];
        }
        AVAILABLE_NFTS.pop();
    }

    function setAvailableDiscount(uint256 _amount, uint256 _discount)
        public
        onlyRole(UPDATER_ROLE)
    {
        require(
            _discount >= 1 && _discount <= 100,
            "1TO100"
        );

        AVAILABLE_DISCOUNTS.push(AVAILABLE_DISCOUNT(
            _amount,
            _discount
        ));
    }

    function editAvailableDiscount(
        uint256 _token,
        uint256 _token_amount,
        uint256 _discount
    ) public onlyRole(UPDATER_ROLE) {
        require(
            _discount >= 1 && _discount <= 100,
            "1TO100"
        );

        AVAILABLE_DISCOUNTS[_token] = AVAILABLE_DISCOUNT(
            _token_amount,
            _discount
        );
    }

    function deleteAvailableDiscount(uint256 _index)
        public
        onlyRole(UPDATER_ROLE)
    {
        for (uint256 i = _index; i < AVAILABLE_DISCOUNTS.length - 1; i++) {
            AVAILABLE_DISCOUNTS[i] = AVAILABLE_DISCOUNTS[i + 1];
        }
        AVAILABLE_DISCOUNTS.pop();
    }

    function safeMint(uint256 ID) public payable whenNotPaused {
        uint256 birrasBalance = getBirrasBalance(_msgSender());

        if (birrasBalance > 0) {
            require(
                msg.value >= getAvailableDiscountForToken(ID, _msgSender()),
                "IP"
            );
        } else {
            require(
                msg.value >= AVAILABLE_NFTS[ID].token_price,
                "IP"
            );
        }

        _tokenIdCounter.increment();
        _safeMint(_msgSender(), ID);
        _setTokenURI(ID, AVAILABLE_NFTS[ID].token_url);
        REDEEMED_NFTS.push(REDEEMED_NFT(ID, false));
    }

    function editMintedNFT(uint256 _token, string memory _url) public onlyRole(UPDATER_ROLE) {
        _setTokenURI(_token, _url);
    }

    function redeemNFT(uint256 _token) public whenNotPaused {
        require(_msgSender() == ownerOf(_token), "OO");

        for (uint256 i = 0; i < REDEEMED_NFTS.length; i++) {
            if (REDEEMED_NFTS[i].token_id == _token) {
              require(REDEEMED_NFTS[i].token_redeemed == false);
              _setTokenURI(_token, AVAILABLE_NFTS[_token].redeemed_url);
              REDEEMED_NFTS[i] = REDEEMED_NFT(_token, true);
            }
        }

        require(
            IERC20Upgradeable(discountTokenAddress).transfer(
                _msgSender(),
                AVAILABLE_NFTS[_token].token_reward
            ),
            "TF"
        );
    } 

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getAvailableDiscountForToken(uint256 _token, address _address)
        public
        view
        returns (uint256)
    {
        uint256 userTokenAmount = getBirrasBalance(_address);

        uint256 tokenPrice = AVAILABLE_NFTS[_token].token_price;

        uint256 discount;

        uint256 priceWithDiscount;

        for (uint256 i = 0; i < AVAILABLE_DISCOUNTS.length; i++) {
            if (userTokenAmount >= AVAILABLE_DISCOUNTS[i].token_amount) {
                discount = AVAILABLE_DISCOUNTS[i].token_discount >= discount
                    ? AVAILABLE_DISCOUNTS[i].token_discount
                    : discount;
            }
        }

        priceWithDiscount = tokenPrice.mul(discount);
        priceWithDiscount = priceWithDiscount.div(100);
        priceWithDiscount = tokenPrice.sub(priceWithDiscount);

        return priceWithDiscount;
    }

    function getBirrasBalance(address _address) public view returns (uint256) {
        return IERC20Upgradeable(discountTokenAddress).balanceOf(_address);
    }

    function getAvailableNFTsLength() public view returns (uint256) {
        return AVAILABLE_NFTS.length;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        AddressUpgradeable.sendValue(payable(msg.sender), balance);
    }

    function withdrawERC20(uint256 _amount) public onlyOwner {
       require(
            IERC20Upgradeable(discountTokenAddress).transfer(
                msg.sender,
                _amount
            ),
            "TF"
        ); 
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        _tokenIdCounter.decrement();
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}