// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/INFT.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Minter is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    address public collector;
    bool private freemint;
    uint256 public nativePrice;
    uint256 public Remain;
    mapping(address => uint256) public prices;
    event Buy(
        address indexed buyer,
        address indexed token,
        uint256 tokenId,
        uint256 price
    );

    event BuyWithNative(address indexed buyer, uint256 tokenId, uint256 price);
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    mapping(address => bool) public minted;
    INFT public nft;

    constructor(address _nft, address _collector) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nft = INFT(_nft);
        collector = _collector;
        freemint = false;
    }

    function freeMint(bool _freemint) public virtual onlyAdmin {
        freemint = _freemint;
    }

    function mint() external {
        require(Remain > 0, "Sold out");
        require(freemint, "MinterPausable: token mint not free");
        require(!minted[msg.sender], "already minted");

        minted[msg.sender] = true;

        nft.mint(msg.sender);
        Remain = Remain - 1;
    }

    function buy(address _token) external returns (uint256 _tokenId) {
        require(Remain > 0, "Sold out");
        require(prices[_token] != 0, "not supported");

        IERC20(_token).safeTransferFrom(msg.sender, collector, prices[_token]);

        nft.mint(msg.sender);
        Remain = Remain - 1;
        emit Buy(msg.sender, _token, _tokenId, prices[_token]);
    }

    function buyWithNative() external payable returns (uint256 _tokenId) {
        require(Remain > 0, "Sold out");
        require(nativePrice != 0, "not supported");
        require(msg.value >= nativePrice, "not enough");

        (bool _sent, ) = payable(collector).call{value: msg.value}("");
        require(_sent, "Failed to send Ether");

        nft.mint(msg.sender);
        Remain = Remain - 1;
        emit BuyWithNative(msg.sender, _tokenId, msg.value);
    }

    function setPrice(address _token, uint256 _price) external onlyAdmin {
        require(_token != address(0), "invalid token address");
        prices[_token] = _price;
    }

    function setRemain(uint256 _remain) external onlyAdmin {
        Remain = _remain;
    }

    function setNativePrice(uint256 _price) external onlyAdmin {
        nativePrice = _price;
    }

    function setColletor(address _collector) external onlyAdmin {
        collector = _collector;
    }

    function setNFT(address _nft) external onlyAdmin {
        require(_nft != address(0), "zero address");
        nft = INFT(_nft);
    }
}