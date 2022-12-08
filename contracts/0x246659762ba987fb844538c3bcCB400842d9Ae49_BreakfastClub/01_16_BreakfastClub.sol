// SPDX-License-Identifier: MIT
// CroDoo Contracts v1.0.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract BreakfastClub is ERC721Enumerable, Ownable, ReentrancyGuard, ERC2981 {
    // CroDodPad
    address private immutable croDooWallet;
    uint256 private immutable croDooRoyalties = 5;
    string private baseTokenURI;

    // Project
    address public projectWallet;

    // Mint
    uint256 public immutable maxSupply = 5000;
    uint256 public maxMint = 5;
    uint256 public price = 0.015 ether;

    uint256 public publicTimestamp = 1670688000;

    mapping(uint256 => uint256) private tokensMatrix;

    // Errors
    error PausedMint();
    error InsufficientPayment();
    error OverMint();
    error MintLimit();

    // Structs
    struct MintInfo {
        uint256 mintPrice;
        uint256 supply;
        uint256 maxSupply;
        uint256 maxMint;
        uint256 publicTimestamp;
    }

    constructor(
        string memory baseTokenURI_,
        address projectWallet_,
        address croDooWallet_
    ) ERC721("BreakfastClub", "BREAKCLUB") {
        baseTokenURI = baseTokenURI_;
        projectWallet = projectWallet_;
        croDooWallet = croDooWallet_;

        setDefaultRoyalty(projectWallet_, 1000);
    }

    // Manage
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setPublicTimestamp(uint256 publicTimestamp_) public onlyOwner {
        publicTimestamp = publicTimestamp_;
    }

    function setProjectWallet(address projectWallet_) public onlyOwner {
        projectWallet = projectWallet_;
    }

    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
    }

    function teamMint(uint256 amount, address to) external onlyOwner {
        uint currentSupply = totalSupply();

        if (currentSupply + amount > maxSupply) revert OverMint();

        for (uint256 i = 1; i <= amount; ) {
            uint256 tokenId = randomTokenId();

            _safeMint(to, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    // Mint
    function mint(uint256 amount) external payable nonReentrant {
        if (block.timestamp < publicTimestamp) revert PausedMint();
        if (amount > maxMint) revert MintLimit();

        uint256 totalPrice = price * amount;
        uint currentSupply = totalSupply();

        if (currentSupply + amount > maxSupply) revert OverMint();
        if (msg.value != totalPrice) revert InsufficientPayment();

        for (uint256 i = 1; i <= amount; ) {
            uint256 tokenId = randomTokenId();
            _safeMint(_msgSender(), tokenId);
            unchecked {
                ++i;
            }
        }

        payout(msg.value);
    }

    function randomTokenId() internal returns (uint256) {
        uint256 maxIndex = maxSupply - totalSupply();

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % maxIndex;

        uint256 value = 0;
        if (tokensMatrix[random] == 0) {
            value = random;
        } else {
            value = tokensMatrix[random];
        }

        if (tokensMatrix[maxIndex - 1] == 0) {
            tokensMatrix[random] = maxIndex - 1;
        } else {
            tokensMatrix[random] = tokensMatrix[maxIndex - 1];
        }

        return value + 1;
    }

    // Info
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokensOfWallet(
        address _address
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokenIds;
    }

    function getMintInfo() external view returns (MintInfo memory) {
        return
            MintInfo(price, totalSupply(), maxSupply, maxMint, publicTimestamp);
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Helpers
    function payout(uint256 amount) internal {
        uint256 fee = (amount * croDooRoyalties) / 100;
        _payoutProjectEarnings(amount - fee);
        _payoutLaunchpadFee(fee);
    }

    function _payoutLaunchpadFee(uint256 _amount) private {
        (bool success, ) = payable(croDooWallet).call{
            value: _amount,
            gas: 50000
        }("");
        require(success);
    }

    function _payoutProjectEarnings(uint256 _amount) private {
        (bool success, ) = payable(projectWallet).call{
            value: _amount,
            gas: 50000
        }("");
        require(success);
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory _tokenURI = string(
            abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), ".json")
        );

        return _tokenURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}