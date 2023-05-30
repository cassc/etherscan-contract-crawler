// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface IDoriStaking {
    function getStakedTokens(
        address _owner,
        address _contract
    ) external view returns (uint256[] memory);
}

interface IDori1776 {
    function tokensOfOwner(
        address _owner
    ) external view returns (uint256[] memory);

    function lockStatus(uint256 _tokenId) external view returns (bool);
}

contract DoriComic is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    mapping(address => bool) public whitelistClaimed;
    mapping(uint256 => bool) public genesisTokenClaimed;
    mapping(uint256 => bool) public tokenClaimed;
    mapping(address => uint256) public publicMinted;

    string public baseURI =
        "ipfs://QmNsCuESKA4fLvDNF4bfHb4tX8Dc1h4B1tKvAvy4sT9BC7/";

    uint256 public cost = 0.5 ether;
    uint256 public maxSupply = 100;
    uint256 public maxMintPublic = 2;

    address public doriGenesis = 0x6d9c17bc83a416bB992ccc671BEbd98d7A76cfc3;
    address public doriStaking = 0x832EA9dAdf3BA29aAFf64E82f5c48C149920862F;
    address public dori1776 = 0x65A926fEB70DACBC31E22494026b1c8a1a11Ca47;

    bool public paused = true;
    bool public claimEnabled = false;

    constructor() ERC721A("DoriComic", "DORICOMIC") {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function mint(
        uint256 _mintAmount
    )
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(
            publicMinted[_msgSender()] + _mintAmount <= maxMintPublic,
            "Max mint amount exceeded!"
        );
        publicMinted[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function claim(
        uint256[] calldata _tokenIdsGenesis,
        uint256[] calldata _tokenIds1776,
        uint256 _mintAmount
    ) public {
        require(claimEnabled, "Claim is not enabled!");
        require(
            _tokenIdsGenesis.length == 3 * _mintAmount,
            "Invalid genesis token amount!"
        );
        require(
            _tokenIds1776.length == 6 * _mintAmount,
            "Invalid 1776 token amount!"
        );

        uint256[] memory stakedTokens = IDoriStaking(doriStaking)
            .getStakedTokens(_msgSender(), doriGenesis);
        require(stakedTokens.length > 0, "No staked tokens found!");

        uint256[] memory ownedTokens = IDori1776(dori1776).tokensOfOwner(
            _msgSender()
        );

        for (uint256 i = 0; i < _tokenIdsGenesis.length; i++) {
            require(
                _tokenIdsGenesis[i] <= 888,
                "Dori Genesis Token ID is not eligible for claim!"
            );
            require(
                !genesisTokenClaimed[_tokenIdsGenesis[i]],
                "Token already claimed!"
            );

            bool found = false;
            for (uint256 j = 0; j < stakedTokens.length; j++) {
                if (stakedTokens[j] == _tokenIdsGenesis[i]) {
                    found = true;
                    break;
                }
            }
            require(found, "Token not found in staked tokens!");

            genesisTokenClaimed[_tokenIdsGenesis[i]] = true;
        }

        for (uint256 i = 0; i < _tokenIds1776.length; i++) {
            require(
                _tokenIds1776[i] <= 1776,
                "Dori1776 Token ID is not eligible for claim!"
            );
            require(!tokenClaimed[_tokenIds1776[i]], "Token already claimed!");

            bool found = false;
            for (uint256 j = 0; j < ownedTokens.length; j++) {
                if (ownedTokens[j] == _tokenIds1776[i]) {
                    found = true;
                    break;
                }
            }
            require(found, "Token not found in owned tokens!");

            require(
                IDori1776(dori1776).lockStatus(_tokenIds1776[i]),
                "Dori1776 Token is not locked"
            );
            tokenClaimed[_tokenIds1776[i]] = true;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        virtual
        override(ERC721A, IERC721Metadata)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _baseURI();
    }

    function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPublic(uint256 _maxMintPublic) public onlyOwner {
        maxMintPublic = _maxMintPublic;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setClaimEnabled(bool _state) public onlyOwner {
        claimEnabled = _state;
    }

    function setDoriGenesis(address _doriGenesis) public onlyOwner {
        doriGenesis = _doriGenesis;
    }

    function setDoriStaking(address _doriStaking) public onlyOwner {
        doriStaking = _doriStaking;
    }

    function setDori1776(address _dori1776) public onlyOwner {
        dori1776 = _dori1776;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}