// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Profile is ERC721("Profile", "Profile"), Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public isMinted;

    uint256 public mintFee;

    IERC20 public immutable babyToken;

    uint256 public immutable startMintTime;

    address public constant hole = 0x000000000000000000000000000000000000dEaD;

    uint256 public supplyHard = 10000;
    uint256 public mintTotal;

    mapping(address => uint256) public avatar;

    mapping(uint256 => address) public mintOwners;

    mapping(address => bool) public isAdmin;

    event Mint(uint256 orderId, address account);
    event Grant(uint256 orderId, address account, uint256 tokenId);
    event SetAvatar(address account, uint256 tokenId);

    constructor(
        IERC20 _babyToken,
        uint256 _mintFee,
        uint256 _startMintTime
    ) {
        babyToken = _babyToken;
        mintFee = _mintFee;
        startMintTime = _startMintTime;
    }

    function setAdmin(address admin, bool enable) external onlyOwner {
        require(admin != address(0), "Profile: address is zero");
        isAdmin[admin] = enable;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    function setSupplyHard(uint256 _supplyHard) external onlyOwner {
        require(
            _supplyHard >= mintTotal,
            "Profile: Supply must not be less than what has been produced"
        );
        supplyHard = _supplyHard;
    }

    function mint() external {
        require(!isMinted[msg.sender], "Profile: mint already involved");
        require(mintTotal <= supplyHard, "Profile: token haven't been minted.");
        require(
            block.timestamp > startMintTime,
            "Profile: It's not the start time"
        );
        isMinted[msg.sender] = true;
        mintTotal = mintTotal + 1;
        mintOwners[mintTotal] = msg.sender;
        babyToken.safeTransferFrom(msg.sender, hole, mintFee);
        emit Mint(mintTotal, msg.sender);
    }

    function grant(uint256 orderId, uint256 tokenId) external onlyAdmin {
        require(!_exists(tokenId), "Profile: token already exists");
        require(
            mintOwners[orderId] != address(0),
            "Profile: token already exists"
        );
        require(tokenId > 0, "Profile: tokenId is invalid");
        _mint(mintOwners[orderId], tokenId);

        emit Grant(orderId, mintOwners[orderId], tokenId);
        delete mintOwners[orderId];
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        _setBaseURI(baseUri);
    }

    function setAvatar(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender || tokenId == 0,
            "set avator of token that is not own"
        );
        avatar[msg.sender] = tokenId;
        emit SetAvatar(msg.sender, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (avatar[from] == tokenId) {
            avatar[from] = 0;
            emit SetAvatar(msg.sender, 0);
        }
        super._transfer(from, to, tokenId);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Profile: caller is not the admin");
        _;
    }
}