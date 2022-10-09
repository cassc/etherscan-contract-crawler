// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IAgiaWhitelist is IERC721 {
    function getTokenPrice(uint8 tokenId) external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);
}

contract AgiaRTP is
    ERC721,
    ERC721Enumerable,
    Pausable,
    ERC721Burnable,
    ReentrancyGuard,
    Ownable
{
    using Address for address;

    string private constant NAME = "AgiaRTP";
    string private constant SYMBOL = "AGIAR";
    uint256 private constant MAX_SUPPLY = 60;
    uint256 private MIN_PRICE = 800 ether;
    uint256 private totalMinted;
    uint256[MAX_SUPPLY] private prices;
    string private baseURI;
    uint256 public baseDelta;

    mapping(uint8 => uint256) public extraWhitelistPeriod;
    mapping(address => uint256) public ethDeposited;
    IAgiaWhitelist public immutable stageOneContract;

    event BoughtToken(address indexed buyer, uint8 tokenId);
    event PriceUpdated(address indexed admin, uint8 tokenId, uint256 newPrice);
    event MinPriceUpdated(address indexed admin, uint256 newMinPrice);
    event WhitelistedStatusUpdated(address indexed admin, bool isWhitelistedOnly);
    event WhitelistUpdated(address indexed admin, uint256 tokenId);
    event BaseURIUpdated(address indexed admin, string newUri);
    event WhitelistBaseDeltaUpdated(address indexed admin);
    event WithdrawFunds(address indexed admin, uint256 total, uint256 date, address token);
    event StatusUpdated(address indexed admin, bool isPaused);
    event EthDeposited(address indexed depositor, uint256 amount, uint256 totalDeposited);
    event AirdropToken(address indexed admin, address receiver, uint8 tokenId);

    modifier callerIsUser() {
        require(!msg.sender.isContract(), "The caller is contract");
        _;
    }

    constructor(
        uint256[MAX_SUPPLY] memory _prices,
        address stageOneContractAddress,
        uint256 _baseDelta
    ) ERC721(NAME, SYMBOL) {
        prices = _prices;
        baseDelta = _baseDelta;
        stageOneContract = IAgiaWhitelist(stageOneContractAddress);
    }

    receive() external payable {
        ethDeposited[msg.sender] += msg.value;
        uint256 totalDeposited = ethDeposited[msg.sender];
        emit EthDeposited(msg.sender, msg.value, totalDeposited);
    }

    function buyToken(uint8 tokenId) external payable nonReentrant whenNotPaused callerIsUser {
        if (getWhitelistPeriod(tokenId) >= block.timestamp)
            require(
                msg.sender == owner() || stageOneContract.ownerOf(tokenId) == msg.sender,
                "Error: you dont own whitelist nft"
            );
        require(totalMinted <= MAX_SUPPLY, "Error: cant mint more than total supply");
        uint256 tokenPrice = getTokenPrice(tokenId, msg.sender);
        uint256 totalDeposited = ethDeposited[msg.sender];
        if (totalDeposited >= tokenPrice) {
            ethDeposited[msg.sender] -= tokenPrice;
        } else require(tokenPrice == msg.value, "Error: invalid price");
        _safeMint(msg.sender, tokenId);
        totalMinted++;
        emit BoughtToken(msg.sender, tokenId);
    }

    function airdropToken(uint8 tokenId, address to) external nonReentrant onlyOwner {
        require(!_exists(tokenId), "Error: token already exists");
        require(to != address(0), "Error: invalid address");

        _safeMint(to, tokenId);
        emit AirdropToken(msg.sender, to, tokenId);
    }

    function setTokenPrice(uint8 tokenId, uint256 price) external onlyOwner {
        require(tokenId < MAX_SUPPLY, "Error: invald tokenID");
        require(price >= MIN_PRICE, "Error: price must be higher than MIN_PRICE");
        prices[tokenId] = price;
        emit PriceUpdated(msg.sender, tokenId, price);
    }

    function setMinPrice(uint256 newMinPrice) external onlyOwner {
        require(newMinPrice > 0, "Error: new min price must be higher than 0");
        MIN_PRICE = newMinPrice;
        emit MinPriceUpdated(msg.sender, MIN_PRICE);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIUpdated(msg.sender, newBaseURI);
    }

    function flipPausedStatus() external onlyOwner {
        paused() ? _unpause() : _pause();
        emit StatusUpdated(msg.sender, paused());
    }

    function setWhitelistPeriod(uint8 tokenId, uint256 time) external onlyOwner {
        require(!_exists(tokenId), "Invalid token");
        extraWhitelistPeriod[tokenId] = time;
        emit WhitelistUpdated(msg.sender, tokenId);
    }

    function setWhitelistBaseDelta(uint256 timestamp) external onlyOwner {
        baseDelta = timestamp;
        emit WhitelistBaseDeltaUpdated(msg.sender);
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

    function getTokenPrice(uint8 tokenId, address buyer) public view returns (uint256) {
        require(tokenId >= 0 && tokenId < MAX_SUPPLY, "Error: invalid tokenID");
        uint256 tempPrice = prices[tokenId];
        if (
            buyer != address(0) &&
            stageOneContract.exists(tokenId) &&
            stageOneContract.ownerOf(tokenId) == buyer
        ) {
            uint256 phaseOneTokenPrice = stageOneContract.getTokenPrice(tokenId);
            return tempPrice > phaseOneTokenPrice ? tempPrice - phaseOneTokenPrice : 0;
        }
        return tempPrice;
    }

    function getWhitelistPeriod(uint8 tokenId) public view returns (uint256) {
        require(tokenId >= 0 && tokenId < MAX_SUPPLY, "Error: invalid tokenId");
        return baseDelta + extraWhitelistPeriod[tokenId];
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

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        address tokenOwner = ERC721.ownerOf(tokenId);
        return (spender == tokenOwner ||
            isApprovedForAll(tokenOwner, spender) ||
            getApproved(tokenId) == spender ||
            spender == owner());
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}