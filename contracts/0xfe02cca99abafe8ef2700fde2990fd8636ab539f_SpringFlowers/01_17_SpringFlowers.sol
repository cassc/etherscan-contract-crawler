// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "tiny-erc721/contracts/TinyERC721.sol";

import "./Garden.sol";

contract SpringFlowers is TinyERC721, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 2000;

    uint256 public maxPerWallet = 3;
    uint256 public price = 0.004 ether;

    string public contractURIString;

    address public freePass = 0xfdf1f065ED5097D84CB3b36695D9D70153a8056C;

    constructor() TinyERC721("Spring Flowers", "SPFLOWER", 0) {
        _pause();
    }

    function _calculateAux(
        address from,
        address to,
        uint256 tokenId,
        bytes12 current
    ) internal view virtual override returns (bytes12) {
        return
            from == address(0)
                ? bytes12(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            to,
                            block.difficulty,
                            block.timestamp
                        )
                    )
                )
                : current;
    }

    function flowerHash(uint256 tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, _tokenData(tokenId).aux));
    }

    function mint(uint256 amount) external payable whenNotPaused {
        require(totalSupply() + amount <= MAX_SUPPLY);
        require(amount <= maxPerWallet);
        require(
            balanceOf(msg.sender) + amount <= maxPerWallet,
            "Max mint limit"
        );
        
        if(IERC721(freePass).balanceOf(msg.sender) == 0){
            checkValue(price * amount);
        }

        _mint(msg.sender, amount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Flower #',
                                Strings.toString(tokenId),
                                '", "description": "Spring Flowers is a collection of 100% on-chain generative flowers! The flower traits are randomly generated at mint, partially seeded with the minters address.", "image": "data:image/svg+xml;base64,',
                                Base64.encode(
                                    bytes(
                                        Garden.getFlowerSVG(flowerHash(tokenId))
                                    )
                                ),
                                '", "attributes":',
                                Garden.getFlowerTraits(flowerHash(tokenId)),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function getSVG(uint256 tokenId) external view returns (string memory){
        return Garden.getFlowerSVG(flowerHash(tokenId));
    }

    function contractURI() external view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function tokensOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY
        ) {
            // -1 for 0-based token count
            address currentTokenOwner = ownerOf(currentTokenId - 1);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId-1;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    //// Private
    function checkValue(uint256 value) private {
        if (msg.value > value) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - value)
            }("");
            require(succ);
        } else if (msg.value < value) {
            revert();
        }
    }

    /// Admin
    function mintTo(address to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY);

        _mint(to, _amount);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setFreePass(address _freePass) external onlyOwner {
        freePass = _freePass;
    }
    
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ, ) = payable(msg.sender).call{value: balance}("");
        require(succ);
    }
}

///[email protected]_ved