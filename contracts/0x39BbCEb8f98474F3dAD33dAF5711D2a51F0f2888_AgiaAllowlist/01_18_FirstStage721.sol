// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AgiaAllowlist is ERC721, ERC721Enumerable, Pausable, ReentrancyGuard, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    string private constant NAME = "AgiaAllowlist";
    string private constant SYMBOL = "AGIAA";
    uint256 private constant MAX_SUPPLY = 60;
    uint256 private constant MIN_PRICE = 1 ether;
    uint256 private totalMinted;
    uint256[MAX_SUPPLY] private prices;
    string private baseURI;
    EnumerableSet.AddressSet private whitelistedContracts;

    bool public whiteListedOnly;
    mapping(address => bool) public isWhitelisted;

    event BoughtToken(address indexed buyer, uint8 tokenId);
    event PriceUpdated(address indexed admin, uint8 tokenId, uint256 newPrice);
    event BaseURIUpdated(address indexed admin, string newUri);
    event WhitelistedStatusUpdated(address indexed admin, bool isWhitelistedOnly);
    event WhitelistUpdated(address indexed admin, address[] users, bool removed);
    event WhitelistContractsUpdated(address indexed admin, address[] contracts, bool removed);
    event WithdrawFunds(address indexed admin, uint256 total, uint256 date, address token);
    event StatusUpdated(address indexed admin, bool isPaused);
    event AirdroppedToken(address indexed to, uint8 tokenId);

    modifier callerIsUser() {
        require(!msg.sender.isContract(), "The caller is contract");
        _;
    }

    constructor(uint256[MAX_SUPPLY] memory _prices) ERC721(NAME, SYMBOL) {
        prices = _prices;
        whiteListedOnly = true;
    }

    function buyToken(uint8 tokenId) external payable nonReentrant whenNotPaused callerIsUser {
        if (whiteListedOnly) {
            require(
                isWhitelisted[msg.sender] || ownWhitelistToken(msg.sender),
                "Error: you are not whitelisted"
            );
        }
        require(totalMinted <= MAX_SUPPLY, "Error: cant mint more than total supply");
        require(getTokenPrice(tokenId) == msg.value, "Error: invalid price");
        _safeMint(msg.sender, tokenId);
        totalMinted++;
        emit BoughtToken(msg.sender, tokenId);
    }

    function airdropToken(uint8 tokenId, address to) external onlyOwner {
        require(totalMinted <= MAX_SUPPLY, "Error: cant mint more than total supply");
        _safeMint(to, tokenId);
        prices[tokenId] = 0;
        totalMinted++;
        emit AirdroppedToken(to, tokenId);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(msg.sender, newBaseURI);
    }

    function flipWhitelistedStatus() external onlyOwner {
        whiteListedOnly = !whiteListedOnly;
        emit WhitelistedStatusUpdated(msg.sender, whiteListedOnly);
    }

    function addWhitelistedUsers(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;
        require(len > 0, "Error: invalid user list");
        for (uint256 i = 0; i < len; ++i) {
            isWhitelisted[_users[i]] = true;
        }
        emit WhitelistUpdated(msg.sender, _users, false);
    }

    function removeWhitelistedUsers(address[] calldata _users) external onlyOwner {
        uint256 len = _users.length;
        require(len > 0, "Error: invalid user list");
        for (uint256 i = 0; i < len; ++i) {
            isWhitelisted[_users[i]] = false;
        }
        emit WhitelistUpdated(msg.sender, _users, true);
    }

    function addWhitelistedContracts(address[] calldata _contracts) external onlyOwner {
        uint256 len = _contracts.length;
        require(len > 0, "Error: invalid contract list");
        for (uint256 i = 0; i < len; ++i) {
            if (!whitelistedContracts.contains(_contracts[i])) {
                whitelistedContracts.add(_contracts[i]);
            }
        }
        emit WhitelistContractsUpdated(msg.sender, _contracts, false);
    }

    function removeWhitelistedContracts(address[] calldata _contracts) external onlyOwner {
        uint256 len = _contracts.length;
        require(len > 0, "Error: invalid contract list");
        for (uint256 i = 0; i < len; ++i) {
            if (!whitelistedContracts.contains(_contracts[i])) {
                whitelistedContracts.remove(_contracts[i]);
            }
        }
        emit WhitelistContractsUpdated(msg.sender, _contracts, true);
    }

    function flipPausedStatus() external onlyOwner {
        paused() ? _unpause() : _pause();
        emit StatusUpdated(msg.sender, paused());
    }

    function setTokenPrice(uint8 tokenId, uint256 price) external onlyOwner {
        require(tokenId < MAX_SUPPLY, "Error: invald tokenID");
        require(price >= MIN_PRICE, "Error: price must be higher than MIN_PRICE");
        prices[tokenId] = price;
        emit PriceUpdated(msg.sender, tokenId, price);
    }

    function withdraw() external onlyOwner {
        uint256 _amount = address(this).balance;
        require(_amount > 0, "Error: insufficient coin balance");
        payable(msg.sender).transfer(_amount);
        emit WithdrawFunds(msg.sender, _amount, block.timestamp, address(0));
    }

    function withdrawTokens(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 _amount = tokenContract.balanceOf(address(this));
        require(_amount > 0, "Error: insufficient token balance");
        tokenContract.transfer(owner(), _amount);
        emit WithdrawFunds(msg.sender, _amount, block.timestamp, _tokenContract);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getTokenPrice(uint8 tokenId) public view returns (uint256) {
        require(tokenId >= 0 && tokenId < MAX_SUPPLY, "Error: invalid tokenID");
        return prices[tokenId];
    }

    function Owned(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; ++index) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function ownWhitelistToken(address _buyer) internal view returns (bool) {
        uint256 len = whitelistedContracts.length();
        for (uint256 i = 0; i < len; i++) {
            address collectionAddress = whitelistedContracts.at(i);
            IERC721 collectionContract = IERC721(collectionAddress);
            if (collectionContract.balanceOf(_buyer) > 0) {
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}