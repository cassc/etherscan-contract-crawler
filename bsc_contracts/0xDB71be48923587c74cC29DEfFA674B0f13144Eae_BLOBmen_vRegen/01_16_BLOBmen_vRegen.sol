// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BLOBmen_vRegen is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant maxSupply = 2023;
    uint256 public constant maxSupplyPrivate = 1700;
    uint256 public constant maxMintPrivate = 3;
    uint256 public constant maxMintPublic = 5;
    uint256 public constant price = 0;

    string private baseURI;

    uint256 public privateMintStartsAt = 1672387200;
    uint256 public publicMintStartsAt = 1672430400;

    mapping(address => uint256) public privateMintSpotsAvailable;
    mapping(address => uint256) public publicMinted;


    Counters.Counter private _tokenIds;

    constructor()
        ERC721("BLOBmen vRegen", "BLOBR")
    {
    }

    function mint(address to, uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "zero amount");
        uint256 current = totalSupply();

        if (msg.sender == owner()) {
            // no restriction
        } else if (block.timestamp > publicMintStartsAt) {
            require(
                publicMinted[to] + _amount <= maxMintPublic,
                "Exeeds public mint spots"
            );
            publicMinted[to] += _amount;
        } else if (block.timestamp > privateMintStartsAt){
            require(
                current + _amount <= maxSupplyPrivate,
                "Max private supply exceeded"
            );
            
            require(
                privateMintSpotsAvailable[to] >= _amount,
                "Exeeds private mint spots"
            );
            privateMintSpotsAvailable[to] -= _amount;
        } else {
            revert("Mint not started yet");
        }

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );

        for (uint256 i = 0; i < _amount; ++i) {
            _mintInternal(to);
        }
    }

    function grantPresaleSpots(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; ++i) {
            privateMintSpotsAvailable[_users[i]] += maxMintPrivate;
        }
    }

    function scheduleMint(uint256 _privateMintStartsAt, uint256 _publicMintStartsAt) external onlyOwner {
        privateMintStartsAt = _privateMintStartsAt;
        publicMintStartsAt = _publicMintStartsAt;
    }

    function setBaseURI(string memory _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function _mintInternal(address to) internal {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString()
                    )
                )
                : "";
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function tokensOfOwnerBySize(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > balanceOf(user) - cursor) {
            length = balanceOf(user) - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = tokenOfOwnerByIndex(user, cursor + i);
        }

        return (values, cursor + length);
    }

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, "Cannot recover zero balance");

        IERC20(_token).transfer(address(msg.sender), balance);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}