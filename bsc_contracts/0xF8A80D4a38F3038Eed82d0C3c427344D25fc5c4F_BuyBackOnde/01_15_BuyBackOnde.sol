pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC721RewardByTier.sol";

contract BuyBackOnde is UUPSUpgradeable, OwnableUpgradeable {
    IERC721RewardByTier private onde;
    IERC20 private token;

    address public nftReceived;
    uint256[] public priceList;
    mapping(uint256 => bool) public tokenIdWhitelist;

    event BuyBack(address indexed who, uint256 indexed tokenId, uint256 indexed amountToken);

    function initialize(address _ondeAddress, address _tokenAddress, address _nftReceived) public initializer {
        __Ownable_init();
        priceList = [90e18, 180e18, 450e18, 900e18];
        onde = IERC721RewardByTier(_ondeAddress);
        token = IERC20(_tokenAddress);
        nftReceived = _nftReceived;
    }

    function _authorizeUpgrade(address) internal override onlyOwner { }

    function addWhitelist(uint256[] memory _tokenIdWhitelist, bool _setState) external onlyOwner {
        for (uint256 i = 0; i < _tokenIdWhitelist.length; i++) {
            tokenIdWhitelist[_tokenIdWhitelist[i]] = _setState;
        }
    }

    function updateNftReceived(address _newNftReceived) external onlyOwner {
        nftReceived = _newNftReceived;
    }

    function deposit(uint256 amount) external onlyOwner {
        token.transferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    function buyback(uint256 _tokenId) external {
        require(tokenIdWhitelist[_tokenId], "TokenId is not whitelist");
        address who = onde.ownerOf(_tokenId);
        onde.transferFrom(who, nftReceived, _tokenId);
        uint256 amountToken = priceList[onde.tierOf(_tokenId)];
        token.transfer(who, amountToken);
        emit BuyBack(who, _tokenId, amountToken);
    }
}