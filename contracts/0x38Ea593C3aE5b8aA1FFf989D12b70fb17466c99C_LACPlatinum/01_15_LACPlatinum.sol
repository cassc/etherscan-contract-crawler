//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinter.sol";

contract LACPlatinum is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 4444;

    address erc20Contract = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC ethereum mainnet
    uint256 public constant UPGRADE_PRICE = 3500 * 10 ** 6; // 3500 USDC (mainnet value)

    // address erc20Contract = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; 
    // uint256 public constant UPGRADE_PRICE = 3 * 10 ** 4; // 0.03 USDC (testnet value)

    address public administratorAddress;
    address public minterAddress;

    bool public operational = true;

    uint256 public burnedTokenCount = 0;

    constructor(
        string memory baseURI_
    ) ERC721("LACPlatinum", "LACPlatinum") {
        _baseTokenURI = baseURI_;
    }

    function devMint(uint256 _mintQty) external onlyOwner {
        uint256 supply = totalSupply();

        require(burnedTokenCount + supply + _mintQty <= MAX_SUPPLY, "Exceeds maximum token supply");
        
        for (uint256 i = 1; i <= _mintQty; i++) {
            _safeMint(msg.sender, burnedTokenCount + supply + i);
        }
    }

    function mint(address _to) external {
        uint256 supply = totalSupply();
        require(msg.sender == administratorAddress, "You are not authorized to execute this method");
        require(operational, "Operation is paused");
        require(burnedTokenCount + supply + 1 <= MAX_SUPPLY, "Exceeds maximum token supply");

        _safeMint(_to, burnedTokenCount + supply + 1);
    }

    function upgrade(uint256[2] calldata tokenIds) external {
        IMinter minter = IMinter(minterAddress);
        IERC20 tokenContract = IERC20(erc20Contract);

        bool canUpgrade = false;
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), UPGRADE_PRICE);

        require(transferred, "ERC20 tokens failed to transfer");

        for (uint256 i = 0; i < 2; i++) {
            address owner = ERC721.ownerOf(tokenIds[i]);
            if (msg.sender == owner) {
                canUpgrade = true;
            } else {
                canUpgrade = false;
            }
        }

        if (canUpgrade) {
            for (uint256 i = 0; i < 2; i++) {
                _burn(tokenIds[i]);
            }

            burnedTokenCount += 2;
            minter.mint(msg.sender);
        }
    }

    function setAdministrator(address _administratorAddress) external onlyOwner {
        administratorAddress = _administratorAddress;
    }

    function setMinter(address _minterAddress) external onlyOwner {
        minterAddress = _minterAddress;
    }

    function toggleOperational() external onlyOwner {
        operational = !operational;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    address private constant creatorAddress = 0x24D76404CC8A641E74D06beE456587D11bE4B87D;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20() external onlyOwner
    {
        IERC20 tokenContract = IERC20(erc20Contract);
        bool transfer = tokenContract.transfer(payable(creatorAddress), tokenContract.balanceOf(address(this)));
        require(transfer, "Transfer failed");
    }
}