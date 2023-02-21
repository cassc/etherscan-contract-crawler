// SPDX-License-Identifier: MIT

/*

██╗░░██╗███████╗██╗░░░░░██╗░░░░░░█████╗░  ██╗░░░██╗░█████╗░██╗░░░██╗  ░█████╗░██╗░░░██╗███╗░░██╗████████╗
██║░░██║██╔════╝██║░░░░░██║░░░░░██╔══██╗  ╚██╗░██╔╝██╔══██╗██║░░░██║  ██╔══██╗██║░░░██║████╗░██║╚══██╔══╝
███████║█████╗░░██║░░░░░██║░░░░░██║░░██║  ░╚████╔╝░██║░░██║██║░░░██║  ██║░░╚═╝██║░░░██║██╔██╗██║░░░██║░░░
██╔══██║██╔══╝░░██║░░░░░██║░░░░░██║░░██║  ░░╚██╔╝░░██║░░██║██║░░░██║  ██║░░██╗██║░░░██║██║╚████║░░░██║░░░
██║░░██║███████╗███████╗███████╗╚█████╔╝  ░░░██║░░░╚█████╔╝╚██████╔╝  ╚█████╔╝╚██████╔╝██║░╚███║░░░██║░░░
╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░╚════╝░  ░░░╚═╝░░░░╚════╝░░╚═════╝░  ░╚════╝░░╚═════╝░╚═╝░░╚══╝░░░╚═╝░░░

*/

pragma solidity ^0.8.17;

import "./ERC721/ERC721AQueryableWithOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error TradingInsultsPOIRequired();
error InsufficientFunds(uint256 fundsRequired);
error SaleStateAlreadyActive(bool IsSaleStateOpen);
error SaleAlreadyStarted();
error SaleExpired(uint256 expiryTime);
error SaleNotExpired(uint256 expiryTime);
error SaleClosed();
error NoBalanceDue(address account);

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);

    function mint(address insulter, uint256 quantity) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalMinted() external view returns (uint256);
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

contract TradingInsults is ERC721A, IERC2981, Ownable {
    event Insult(
        address indexed insulter,
        address indexed insultee,
        uint256 quantity
    );

    event NewKing(address indexed newKing, bytes32 newKingMessage);

    enum SaleType {
        standardInsult,
        doubleInsult,
        greedyInsult,
        boostInsult,
        boosterInsult,
        boostestInsult,
        kingInsult
    }

    struct PriceConfig {
        uint64 standardInsult;
        uint64 doubleInsult;
        uint64 greedyInsult;
        uint64 boostInsult;
        uint64 boosterInsult;
        uint64 boostestInsult;
        uint64 kingInsult;
    }

    struct TimerConfig {
        uint32 extensionSeconds;
        uint32 boostReductionBps;
        uint32 boosterReductionBps;
        uint32 boostestReductionBps;
    }

    struct Shares {
        uint32 kingShares;
        uint32 lastMinterShares;
        uint32 deployerShares;
    }

    struct Config {
        bool isSaleStateOpen;
        uint32 saleDuration;
        uint32 saleExpiry;
        uint32 royaltyBps;
        Shares shares;
        TimerConfig timerConfig;
        PriceConfig priceConfig;
        address treasury;
    }

    struct KingOfTheHill {
        bytes32 message;
        address king;
    }


    string private _baseTokenURI;
    Config private _config;
    bytes32 private _kingMessage;
    IERC721 private _tradingInsultsPOIs;

    constructor(
        string memory baseTokenURI,
        PriceConfig memory priceConfig,
        TimerConfig memory timerConfig,
        Shares memory shares,
        uint32 saleDuration,
        uint32 royaltyBps,
        address treasury
    ) ERC721A("TradingInsults", "WTF") {
        _baseTokenURI = baseTokenURI;
        _config.priceConfig = priceConfig;
        _config.timerConfig = timerConfig;
        _config.shares = shares;
        _config.saleDuration = saleDuration;
        _config.royaltyBps = royaltyBps;
        _config.treasury = treasury;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setTradingInsultsPOIs(address addr) external onlyOwner {
        _tradingInsultsPOIs = IERC721(addr);
    }

    function setPrices(PriceConfig calldata priceConfig) external onlyOwner {
        _config.priceConfig = priceConfig;
    }

    function setTimes(TimerConfig calldata timerConfig) external onlyOwner {
        _config.timerConfig = timerConfig;
    }

    function setSaleDuration(uint32 saleDuration) external onlyOwner {
        if (_config.saleExpiry != 0) revert SaleAlreadyStarted();
        _config.saleDuration = saleDuration;
    }

    function setSaleState(bool isSaleStateOpen) external onlyOwner {
        if (_config.isSaleStateOpen == isSaleStateOpen)
            revert SaleStateAlreadyActive(_config.isSaleStateOpen);
        if (_config.saleExpiry == 0)
            _config.saleExpiry = uint32(block.timestamp) + _config.saleDuration;
        _config.isSaleStateOpen = isSaleStateOpen;
    }

    function setKingMessage(bytes32 message) external onlyOwner {
        _kingMessage = message;
    }

    function _mintHelper(
        address insultee,
        uint256 insultsCount,
        uint256 POIs
    ) private {
        _tradingInsultsPOIs.mint(msg.sender, POIs);
        _mint(insultee, insultsCount);
        emit Insult(msg.sender, insultee, insultsCount);
    }

    function _checkMinimumExpiry() private {
        if (
            _config.saleExpiry < block.timestamp ||
            _config.saleExpiry - block.timestamp <
            _config.timerConfig.extensionSeconds
        )
            _config.saleExpiry =
                uint32(block.timestamp) +
                _config.timerConfig.extensionSeconds;
    }

    function mint(
        address insultee,
        SaleType saleType,
        bytes32 kingMessage
    ) external payable {
        if (!_config.isSaleStateOpen) revert SaleClosed();

        if (_config.saleExpiry < block.timestamp)
            revert SaleExpired(_config.saleExpiry);

        if (SaleType.standardInsult == saleType) {
            if (_config.priceConfig.standardInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.standardInsult);
            _mintHelper(insultee, 1, 1);
            _config.saleExpiry += _config.timerConfig.extensionSeconds;
        } else if (SaleType.doubleInsult == saleType) {
            if (_config.priceConfig.doubleInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.doubleInsult);
            _mintHelper(insultee, 2, 1);
            _config.saleExpiry += _config.timerConfig.extensionSeconds;
        } else if (SaleType.greedyInsult == saleType) {
            if (_config.priceConfig.greedyInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.greedyInsult);
            _mintHelper(insultee, 1, 2);
            _config.saleExpiry += _config.timerConfig.extensionSeconds;
        } else if (SaleType.boostInsult == saleType) {
            if (_config.priceConfig.boostInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.boostInsult);
            _mintHelper(insultee, 1, 1);
            _config.saleExpiry -=
                ((_config.saleExpiry - uint32(block.timestamp)) *
                    _config.timerConfig.boostReductionBps) /
                10000;
            _checkMinimumExpiry();
        } else if (SaleType.boosterInsult == saleType) {
            if (_config.priceConfig.boosterInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.boosterInsult);
            _mintHelper(insultee, 1, 1);
            _config.saleExpiry -=
                ((_config.saleExpiry - uint32(block.timestamp)) *
                    _config.timerConfig.boosterReductionBps) /
                10000;
            _checkMinimumExpiry();
        } else if (SaleType.boostestInsult == saleType) {
            if (_config.priceConfig.boostestInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.boostestInsult);
            _mintHelper(insultee, 1, 1);
            _config.saleExpiry -= _config.timerConfig.boostestReductionBps;
            _checkMinimumExpiry();
        } else if (SaleType.kingInsult == saleType) {
            if (_config.priceConfig.kingInsult > msg.value)
                revert InsufficientFunds(_config.priceConfig.kingInsult);
            _mintHelper(insultee, 1, 1);
            _config.saleExpiry += _config.timerConfig.extensionSeconds;
            _kingMessage = kingMessage;
            _tradingInsultsPOIs.transferFrom(
                _tradingInsultsPOIs.ownerOf(1),
                msg.sender,
                1
            );
            emit NewKing(msg.sender, kingMessage);
        }
    }

    function dropMint(address insultee) external onlyOwner {
        if (_config.saleExpiry < block.timestamp)
            revert SaleExpired(_config.saleExpiry);
        _mint(insultee, 1);
        emit Insult(msg.sender, insultee, 1);
    }

    function isTransferable(uint256 tokenId) external view returns (bool) {
         return _tradingInsultsPOIs.balanceOf(ownerOf(tokenId)) > 0;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function getConfig() external view returns (Config memory) {
        return _config;
    }

    function getKing() external view returns (KingOfTheHill memory) {
        return KingOfTheHill({
            king: _tradingInsultsPOIs.ownerOf(1),
            message: _kingMessage
        });
    }

    function getLastTokenOwner() public view returns (address) {
        return _tradingInsultsPOIs.ownerOf(_tradingInsultsPOIs.totalMinted());
    }

    function sharesBps(address account) public view returns (uint256) {
        uint256 shares = 0;
        if (_config.shares.lastMinterShares != 0) {
            if (account == getLastTokenOwner())
                shares += _config.shares.lastMinterShares;
        }
        if (_config.shares.kingShares != 0) {
            if (account == _tradingInsultsPOIs.ownerOf(1))
                shares += _config.shares.kingShares;
        }
        if (account == owner()) {
            shares += _config.shares.deployerShares;
        }
        return shares;
    }

    function releasable(address account) public view returns (uint256) {
        if (_config.saleExpiry == 0) revert SaleClosed();
        if (_config.saleExpiry > block.timestamp)
            revert SaleNotExpired(_config.saleExpiry);
        return
            ((address(this).balance) * sharesBps(account)) /
            (_config.shares.lastMinterShares +
                _config.shares.kingShares +
                _config.shares.deployerShares);
    }

    function release(address payable account) external {
        uint256 payment = releasable(account);
        if (payment == 0) revert NoBalanceDue(account);
        if (_config.shares.lastMinterShares != 0) {
            if (account == getLastTokenOwner())
                _config.shares.lastMinterShares = 0;
        }
        if (_config.shares.kingShares != 0) {
            if (account == _tradingInsultsPOIs.ownerOf(1)) _config.shares.kingShares = 0;
        }
        if (account == owner()) {
            if (_config.shares.kingShares != 0 || _config.shares.lastMinterShares != 0) revert NoBalanceDue(account);
        }
        Address.sendValue(account, payment);
    }

    function emergencyRelease() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function releaseERC20(IERC20 token) public {
        uint256 payment = token.balanceOf(address(this));
        if (payment == 0) revert NoBalanceDue(owner());
        token.transfer(owner(), payment);
    }

    function releaseERC721(IERC721 token, uint256 tokenId) public {
        if (address(this) != token.ownerOf(tokenId))
            revert NoBalanceDue(owner());
        token.transferFrom(address(this), owner(), tokenId);
    }

    function getTradingInsultsPOIAddress() external view returns (address) {
        return address(_tradingInsultsPOIs);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if (from != address(0)) {
            if (_tradingInsultsPOIs.balanceOf(from) == 0)
                revert TradingInsultsPOIRequired();
        }
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        return (_config.treasury, ((_salePrice * _config.royaltyBps) / 10000));
    }

    function setRoyaltyBps(uint32 royaltyBps) external onlyOwner {
        _config.royaltyBps = royaltyBps;
    }

    function setTreasury(address treasury) external onlyOwner {
        _config.treasury = treasury;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(_interfaceId);
    }
}