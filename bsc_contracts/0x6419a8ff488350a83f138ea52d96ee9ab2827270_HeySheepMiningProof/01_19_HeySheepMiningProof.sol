// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract HeySheepMiningProof is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address public constant BLACK_HOLE = address(0xdead);

    address public immutable USDT_ADDRESS;
    address public CGKDAO_ADDRESS;

    uint256 public mintPrice;
    uint256 public mintStartTime;
    address public recipient;
    
    string public baseTokenURI;
    string public fullTokenURI;

    CountersUpgradeable.Counter public currentEpoch;

    mapping (uint256 => FlashSaleData) public rounds;
    mapping (address => bool) public isBought;

    CountersUpgradeable.Counter public nextTokenId;

    struct FlashSaleData {
        uint256 flashSalePrice;
        uint256 flashSaleSoldNumber;
        uint256 flashSaleMaxSoldNumber;
        uint256 flashSaleStartTime;
    }

    constructor(
        address usdtAddress,
        address cgkDAOAddress
    ) {
        USDT_ADDRESS = usdtAddress;
        CGKDAO_ADDRESS = cgkDAOAddress;
    }

    function initialize(
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
    }

    function mintSetting (
        uint256 mintPrice_,
        uint256 mintStartTime_,
        address recipient_
    ) external onlyOwner {
        _mintSetting(mintPrice_, mintStartTime_, recipient_);
    }

    function flashSaleSetting (
        uint256 flashSalePrice_,
        uint256 flashSaleMaxSoldNumber_,
        uint256 flashSaleStartTime_
    ) external onlyOwner {
        currentEpoch.increment();
        uint256 _epoch = currentEpoch.current();
        rounds[_epoch].flashSalePrice = flashSalePrice_;
        rounds[_epoch].flashSaleMaxSoldNumber = flashSaleMaxSoldNumber_;
        rounds[_epoch].flashSaleStartTime = flashSaleStartTime_;
    }

    /// @dev Sets the token URI.
    function setTokenURI(
        string memory baseTokenURI_,
        string memory fullTokenURI_
    ) public onlyOwner {
        baseTokenURI = baseTokenURI_;
        fullTokenURI = fullTokenURI_;
    }

    function setmintprice(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_;
    }

    function setrecipient(address recipient_) public onlyOwner {
        recipient = recipient_;
    }

    function getCurrentEpoch() public view returns (FlashSaleData memory) {
        uint256 _epoch = currentEpoch.current();
        return rounds[_epoch];
    }

    function getMintStatus() public view returns (uint256) {
        if (mintStartTime == 0) return 0;
        if (mintStartTime > block.timestamp) return 0;

        return 1;
    }

    function mint(uint256 num_) external {
        require(tx.origin == msg.sender, 'HeySheepii: unsupported contract caller.');
        require(getMintStatus() == 1, 'HeySheepii: not start.');

        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(USDT_ADDRESS), 
            msg.sender, 
            recipient, 
            mintPrice * num_
        );
        for (uint256 _index; _index < num_; _index++) {
            uint256 _currentTokenId = nextTokenId.current();
            nextTokenId.increment();
            ERC721Upgradeable._mint(msg.sender, _currentTokenId);
        }
    }

    function getFlashSaleStatus() public view returns (uint256) {
        uint256 _epoch = currentEpoch.current();
        if (_epoch == 0) return 0;
        if (rounds[_epoch].flashSaleStartTime == 0) return 0;
        if (rounds[_epoch].flashSalePrice == 0) return 0;
        if (rounds[_epoch].flashSaleMaxSoldNumber == 0) return 0;
        if (rounds[_epoch].flashSaleStartTime > block.timestamp) return 0;
        if (rounds[_epoch].flashSaleSoldNumber >= rounds[_epoch].flashSaleMaxSoldNumber) return 0;

        return 1;
    }

    function flashSale() external {
        uint256 _epoch = currentEpoch.current();

        require(tx.origin == msg.sender, 'HeySheepii: unsupported contract caller.');
        require(getFlashSaleStatus() == 1, 'HeySheepii: close.');
        require(!isBought[msg.sender], 'HeySheepii: already bought.');

        rounds[_epoch].flashSaleSoldNumber++;
        isBought[msg.sender] = true;

        // send CGK to black hole
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(CGKDAO_ADDRESS), 
            msg.sender, 
            BLACK_HOLE,
            rounds[_epoch].flashSalePrice
        );

        uint256 _currentTokenId = nextTokenId.current();
        nextTokenId.increment();
        ERC721Upgradeable._mint(msg.sender, _currentTokenId);
    }

    function airdrop(address[] calldata _addresses) external onlyOwner {
        uint256 _length = _addresses.length;
        require(_length > 0, 'HeySheepii: airdrop array length cannot be 0.');

        for (uint256 _indexAddr = 0; _indexAddr < _length; _indexAddr++) {
            uint256 _currentTokenId = nextTokenId.current();
            nextTokenId.increment();
            ERC721Upgradeable._mint(_addresses[_indexAddr], _currentTokenId);
        }
    }

    function _mintSetting (
        uint256 mintPrice_,
        uint256 mintStartTime_,
        address recipient_
    ) private {
        mintPrice = mintPrice_;
        mintStartTime = mintStartTime_;
        recipient = recipient_;
    }

    function setcgkDAOAddress(address adr) external onlyOwner {
        CGKDAO_ADDRESS = adr;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        string memory _baseTokenURI = baseTokenURI;
        string memory _fullTokenURI = fullTokenURI;

        if (bytes(_fullTokenURI).length > 0) return _fullTokenURI;
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, tokenId_, ".json")) : "";
    }
}