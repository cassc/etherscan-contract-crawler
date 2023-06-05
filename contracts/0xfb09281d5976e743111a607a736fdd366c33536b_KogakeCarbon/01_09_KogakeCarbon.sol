// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Mintable {
    function mint(address account_, uint256 amount_) external;

    function decimals() external view returns (uint8);
}

contract KogakeCarbon is ERC721A, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public mintStarted = false;
    bool public mintWhitelistStarted = false;

    mapping(address => bool) public blacklist;
    mapping(address => uint16) public whitelist;

    uint256 internal batchLimit = 5;
    uint256 public constant mintPrice = 0.055 ether;
    uint256 private constant maxNFTs = 5555;
    uint256 private constant fee = 20;
    string private URI = "https://api.kogakecarbon.com/nft/";

    address public treasuryAddr;
    address public tokenAddr;

    constructor(address _treasury, address _token)
        ERC721A("Kogake Carbon", "KogakeCarbon")
    {
        require(_treasury != address(0) && _token != address(0), "zero addr");
        treasuryAddr = _treasury;
        tokenAddr = _token;
    }

    function mint(uint256 amount) public payable {
        require(blacklist[msg.sender] != true, "User is blacklisted");
        require(mintStarted, "Mint is not started");
        require(amount <= batchLimit && amount != 0, "Not in batch limit");
        require(msg.value >= mintPrice * amount, "Not enough ether");
        require(_totalMinted() + amount < maxNFTs, "Too much to mint");

        _mintLogic(amount);
    }

    function whitelistMint(uint256 amount) public {
        require(blacklist[msg.sender] != true, "User is blacklisted");
        require(mintWhitelistStarted, "Mint for whitelist is not started");
        require(_totalMinted() + amount < maxNFTs, "Too much to mint");
        require(
            whitelistMintable() >= amount && amount != 0,
            "Over minting limit"
        );

        _mintLogic(amount);

        whitelist[msg.sender] -= uint16(amount);
    }

    function _mintLogic(uint256 amount) internal nonReentrant {
        _safeMint(msg.sender, amount);

        IERC20Mintable(tokenAddr).mint(
            msg.sender,
            10**IERC20Mintable(tokenAddr).decimals() * amount
        );
    }

    function whitelistMintable() public view returns (uint256) {
        return whitelist[msg.sender];
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        URI = newBaseURI;
    }

    function mintedTotal() public view returns (uint256) {
        return _totalMinted();
    }

    function totalMintable() public pure returns (uint256) {
        return maxNFTs;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function pauseMint() external onlyOwner {
        mintStarted = false;
    }

    function startWhitelistMint() external onlyOwner {
        mintWhitelistStarted = true;
    }

    function pauseWhitelistMint() external onlyOwner {
        mintWhitelistStarted = false;
    }

    function updateBlacklist(address[] memory users, bool[] memory blackListed)
        external
        onlyOwner
    {
        uint256 length = users.length;
        require(length == blackListed.length);
        for (uint256 i = 0; i < length; i++) {
            blacklist[users[i]] = blackListed[i];
        }
    }

    function updateWhitelist(
        address[] memory users,
        uint16[] memory allowedMechs
    ) external onlyOwner {
        uint256 length = users.length;
        require(length == allowedMechs.length);
        for (uint256 i = 0; i < length; i++) {
            whitelist[users[i]] = allowedMechs[i];
        }
    }

    function withdraw() public onlyOwner {
        uint256 value = address(this).balance;
        uint256 feeToSend = (value * fee) / 100;
        uint256 treasuryPayout = value - feeToSend;
        (bool success, ) = payable(treasuryAddr).call{value: treasuryPayout}(
            ""
        );
        require(success, "Transfer to treasury failed");

        (success, ) = payable(owner()).call{value: feeToSend}("");
        require(success, "Fee transfer failed");

        payable(owner()).transfer(address(this).balance);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }
}