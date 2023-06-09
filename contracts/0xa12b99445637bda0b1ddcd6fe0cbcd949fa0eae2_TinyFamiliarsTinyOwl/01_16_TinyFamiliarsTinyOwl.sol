// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ITinyFamiliarV2.sol";
import "../interfaces/ITinyFamiliarMetadata.sol";

contract TinyFamiliarsTinyOwl is
ERC721Enumerable,
Ownable,
ITinyFamiliarV2,
ITinyFamiliarMetadata
{
    using Strings for uint256;
    uint256 public TF_MAX;
    uint256 public mintPrice;
    uint256 public whiteListMintPrice;
    bool public isActive;
    bool public isPresaleActive;
    string public baseExtension;
    string public proof;
    mapping(address => uint256) private _presaleList;
    mapping(address => uint256) private _presaleClaimed;
    string private _contractURI;
    string private _tokenBaseURI;
    address constant t1 = 0x1496961c0DA108BE9689407EDAa90cf417fdC41C;    // .25
    address constant t2 = 0xeA2a9ca3d62BEF63Cf562B59c5709B32Ed4c0eca;    //

    constructor(string memory initBaseURI) ERC721("Tiny Familiars s03: Tiny Owls", "TFO") {
        TF_MAX = 100;
        _tokenBaseURI = initBaseURI;
        _contractURI = "https://tinyfamiliars.com/tinyFamiliarss03TinyOwls.json";
        whiteListMintPrice = 0.06 ether;
        mintPrice = 0.08 ether;
        isActive = false;
        isPresaleActive = false;
        baseExtension = ".json";
    }

    // << Presale functionality
    function addToPresale(address[] calldata addresses, uint256 numAllowedToMint)
    external
    override
    onlyOwner
    {
        require(numAllowedToMint > 0, "numAllowedToMint !> 0");
        uint256 aCnt = addresses.length;
        for (uint256 i; i < aCnt; i++) {
            require(addresses[i] != address(0), "Null address");

            _presaleList[addresses[i]] = numAllowedToMint;
            _presaleClaimed[addresses[i]] > 0
            ? _presaleClaimed[addresses[i]]
            : 0;
        }
    }

    function presaleMintQty(address addr) external view override returns (uint256) {
        return _presaleList[addr] > 0 ? _presaleList[addr] : 0;
    }

    function onPresaleList(address addr) external view override returns (bool) {
        return _presaleList[addr] > 0;
    }

    function removeFromPresale(address[] calldata addresses)
    external
    override
    onlyOwner
    {
        uint256 aCnt = addresses.length;
        for (uint256 i; i < aCnt;) {
            require(addresses[i] != address(0), "Null address");

            _presaleList[addresses[i]] = 0;
            unchecked {
                i++;
            }
        }
    }

    function presaleClaimedBy(address owner)
    external
    view
    override
    returns (uint256)
    {
        require(owner != address(0), "Null address");

        return _presaleClaimed[owner];
    }
    // Presale functionality >>

    function mintPublic(uint256 numberOfTokens)
    external
    payable
    override
    {
        require(isActive, "!Active");
        require(!isPresaleActive, "Presale");
        require(
            totalSupply() + numberOfTokens <= TF_MAX,
            "Not enough tokens left"
        );
        require(
            mintPrice * numberOfTokens <= msg.value,
            "Pay more"
        );

        for (uint256 i = 0; i < numberOfTokens;) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
            unchecked {
                i++;
            }
        }
    }

    function mintPresale(uint256 numberOfTokens)
    external
    payable
    override
    {
        require(isActive, "!Active");
        require(isPresaleActive, "!Presale");
        require(numberOfTokens + _presaleClaimed[msg.sender] <= _presaleList[msg.sender], "You cannot mint any more Presale tokens");
        require(
            totalSupply() + numberOfTokens <= TF_MAX,
            "Pay more"
        );
        require(
            whiteListMintPrice * numberOfTokens <= msg.value,
            "Pay more"
        );

        for (uint256 i = 0; i < numberOfTokens;) {
            /**
             * We don't want our tokens to start at 0 but at 1.
             */
            uint256 tokenId = totalSupply() + 1;
            _presaleClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
            unchecked {
                i++;
            }
        }
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        require(_exists(tokenId), "!Token");

        string memory currentBaseURI = _baseURI();
        return
        string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                baseExtension
            )
        );
    }

    function walletOfOwner(address _owner)
    public
    view
    override
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount;) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            unchecked {
                i++;
            }
        }
        return tokenIds;
    }

    // Admin methods
    function ownerMint(uint256 quantity) external override onlyOwner {
        require(
            totalSupply() + quantity <= TF_MAX,
            "Not enough tokens left"
        );
        for (uint256 i = 0; i < quantity;) {
            _mintInternal(msg.sender);
            unchecked {
                i++;
            }
        }
    }

    function gift(address[] calldata to) external override onlyOwner {
        require(
            totalSupply() + to.length <= TF_MAX,
            "Not enough tokens left"
        );

        for (uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(to[i], tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsPresaleActive(bool _isActive) external override onlyOwner
    {
        isPresaleActive = _isActive;
        if (_isActive) {
            isActive = _isActive;
        }
    }

    function setContractURI(string calldata URI)
    external
    override
    onlyOwner
    {
        _contractURI = URI;
    }


    function setTFMAX(uint256 _TF_MAX)
    external
    onlyOwner
    {
        TF_MAX = _TF_MAX;
    }

    function setBaseURI(string calldata URI)
    external
    override
    onlyOwner
    {
        _tokenBaseURI = URI;
    }


    function emergencyWithdraw() external payable override {
        require(msg.sender == t1, "Wrong sender address");
        (bool success,) = payable(t1).call{value : address(this).balance}("");
        require(success);
    }

    function withdrawForAll() external payable override onlyOwner {
        uint256 _quarter = address(this).balance / 4;
        require(payable(t1).send(_quarter));
        require(payable(t2).send(_quarter * 3));
    }

    function setMintPrice(uint256 price) external override onlyOwner {
        mintPrice = price;
    }


    function setWhiteListMintPrice(uint256 price) external override onlyOwner {
        whiteListMintPrice = price;
    }

    function setBaseExtension(string memory _newBaseExtension)
    public
    onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mintInternal(address owner) private {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(owner, tokenId);
    }
}