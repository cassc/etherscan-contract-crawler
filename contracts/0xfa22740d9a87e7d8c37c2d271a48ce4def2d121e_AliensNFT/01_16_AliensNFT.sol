// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AliensNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    
    // Maximum count of tokens
    uint256 MAX_SUPPLY = 14185;

    // A variable that determines whether the game is going on or not
    bool GAME_IN_PROCESS = true;

    // Price increase step in percent
    uint256 PRICE_INCREASE_STEP = 35;

    // Royalty sum on percent
    uint256 OWNER_GET_PERCENT = 4;

    // First staff address
    address FIRST_STAFF_ADDRESS = 0xBc8b3d14dDd6bc2F458DF4d56C841BA67C7cdafa;

    // Second staff address
    address SECOND_STAFF_ADDRESS = 0xFc2F388De174ba3469a2D05526283b595b79F2be;

    // First admin address
    address FIRST_ADMIN_ADDRESS = 0x1fC6012a2F7cb16e10af4aEcc4Cb54DBF3905077;

    // Second admin address
    address SECOND_ADMIN_ADDRESS = 0x45704cC93b2eb9F2557b534a1b3781e63B40b2ae;

    // Boss ID
    uint256 BOSS_ID = 0;

    // Gems start ID
    uint256 GEMS_START_ID = 1;

    // Gems end ID
    uint256 GEMS_END_ID = 9;
    
    // Mapping from token ID to price
    mapping(uint256 => uint256) private _prices;

    // Struct for Holder
    struct Holder {
        uint256 tokenId;
        address holderAddress;
    }

    // Mapping for storage holders
    Holder[] private _holders;

    constructor() ERC721("Aliens NFT", "ALIENS") {}

    receive() external payable {}

    modifier isAdmin() {
        require(
            msg.sender == FIRST_ADMIN_ADDRESS || msg.sender == SECOND_ADMIN_ADDRESS,
             "Aliens NFT: You are not an admin of the game"
            );
        _;
    }

    function deposit() public payable {}

    function safeMint(address to, string memory uri, uint256 quantity, uint256 price) public onlyOwner {
        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId < MAX_SUPPLY, "All NFTs have been minted");
            
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            _prices[tokenId] = price; // Set price for token Id
            _setHolder(tokenId, to); // Set holder
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        if (GAME_IN_PROCESS) {
            _transfer(ownerOf(tokenId), _toTransfer(tokenId), tokenId);
            _enrollRoyalties(tokenId); // Enroll royalties to current tokenId holder and to Boss Owner
            _setHolder(tokenId, to); // Set new holder
            _increasePrice(tokenId); // Increase the price by the number of percentages
        } else {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
            
            _transfer(from, to, tokenId);
        }
    }

    // Get the price of the token Id
    function priceOf(uint256 tokenId) public view returns (uint256) {
        uint256 price = _prices[tokenId];

        require(price != 0, "Aliens NFT: invalid token ID");

        return price;
    }

    // Turn the game off (only for admin)
    function switchGameStatus() public isAdmin {
        require(getStatusGame(), "Aliens NFT: The game has already stopped");

        for (uint i = 0; i < _holders.length; i++) {
            uint tokenId = _holders[i].tokenId;
            address to = _holders[i].holderAddress;

            _transfer(ownerOf(tokenId), to, tokenId);
        }

        GAME_IN_PROCESS = false;
    }

    // Transfer money from balance (only for admin)
    function transferBalance(address payable to, uint256 amount) public isAdmin {
        to.transfer(amount);
    }

    // Get status game
    function getStatusGame() public view returns (bool) { 
        return GAME_IN_PROCESS;
    }

    // Get holder by token id
    function holdefOf(uint256 tokenId) public view returns (address) {
        address holder = 0x0000000000000000000000000000000000000000;

        for (uint i = 0; i < _holders.length; i++) {
            if (_holders[i].tokenId == tokenId) {
                holder = _holders[i].holderAddress;
                break;
            }
        }

        require(holder != 0x0000000000000000000000000000000000000000, "Aliens NFT: invalid token ID holderOf");

        return holder;
    }

    function changeFirstAdminAddress(address _address) onlyOwner public {
        FIRST_ADMIN_ADDRESS = _address;
    }

    function changeSecondAdminAddress(address _address) onlyOwner public {
        SECOND_ADMIN_ADDRESS = _address;
    }

    function _increasePrice(uint256 tokenId) private {
        uint256 _collectionPrice = 0;

        for (uint256 i = 0; i < totalSupply(); i++) {
            _collectionPrice = _collectionPrice.add(priceOf(i));
        }

        uint256 _increaseValue = (_prices[tokenId].mul(PRICE_INCREASE_STEP)).div(100);

        _prices[tokenId] = _prices[tokenId].add(_increaseValue); // increase tokenId price

        uint256 _gemIncreaseValue = (_collectionPrice.mul(3)).div(1000);

        for (uint256 i = GEMS_START_ID; i <= GEMS_END_ID; i++) {
            _prices[i] = _prices[i].add(_gemIncreaseValue); // increase gems prices
            
            if (tokenId != i) {
                _transfer(ownerOf(i), _toTransfer(i), i);
            }
        }

        uint256 _bossIncreaseValue = (_collectionPrice.mul(1)).div(100);

        _prices[BOSS_ID] = _prices[BOSS_ID].add(_bossIncreaseValue); // increase boss price

        if (tokenId != BOSS_ID) {
            _transfer(ownerOf(BOSS_ID), _toTransfer(BOSS_ID), BOSS_ID);
        }
    }

    function _setHolder(uint256 tokenId, address newHolderAddress) private {
        bool found = false;

        for (uint i = 0; i < _holders.length; i++) {
            if (_holders[i].tokenId == tokenId) {
                _holders[i].holderAddress = newHolderAddress;
                found = true;

                break;
            }
        }

        if (!found) {
            Holder memory newHolder = Holder(tokenId, newHolderAddress);

            _holders.push(newHolder);
        }
    }

    function _toTransfer(uint256 tokenId) private view returns (address) {
        address currentOwner = ownerOf(tokenId);

        if (currentOwner == FIRST_STAFF_ADDRESS) {
            return SECOND_STAFF_ADDRESS;
        } else {
            return FIRST_STAFF_ADDRESS;
        }
    }

    function _enrollRoyalties(uint256 tokenId) private {
        uint256 ownerReceived = (priceOf(tokenId).mul(OWNER_GET_PERCENT)).div(100);
        uint256 royaltyToCurrentHolder = (ownerReceived.mul(912)).div(1000);
        uint256 royaltyToBossOwner = (ownerReceived.mul(1)).div(100);

        payable(holdefOf(tokenId)).transfer(royaltyToCurrentHolder); // enroll royalty to current holder
        payable(holdefOf(BOSS_ID)).transfer(royaltyToBossOwner); // enroll royalty to current boss owner
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}