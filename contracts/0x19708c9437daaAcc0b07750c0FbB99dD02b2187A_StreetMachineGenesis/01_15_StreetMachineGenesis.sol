//SPDX-License-Identifier: MIT
// contracts/ERC721.sol

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IRevealContract is IERC721 {
    function getCid(uint256 tokenId) external view returns (string memory);
}

interface ITransformerKeyContract is IERC721 {}

contract StreetMachineGenesis is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ReentrancyGuard,
    Ownable
{
    string private _baseUri;
    string private _baseCid;
    uint256[] private revealedIds;

    event TokenRevealed(address _from, uint256 _tokenId, string _cid);

    mapping(uint256 => bool) public revealed;
    mapping(address => uint256) public keyAllowList;

    uint256 public maxSupply;

    // previously determined from revealContract via chainlink
    uint256 public constant randomNumber = 4919;

    address public boxContract;
    address public revealContract;
    address public transformerContract;
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    bool public urisLocked = false;
    bool public burnAndMintIsLive = false;
    bool public keyAllowListLive = true;

    constructor(
        address _boxContract,
        address _revealContract,
        uint256 _maxSupply
    ) ERC721("StreetMachineGenesis", "SMC") {
        boxContract = _boxContract;
        revealContract = _revealContract;
        maxSupply = _maxSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getKeyAllowListCount(address minter)
        public
        view
        returns (uint256)
    {
        return keyAllowList[minter];
    }

    function getRevealedIds() public view returns (uint256[] memory) {
        return revealedIds;
    }

    function lockKeyAllowList() public onlyOwner {
        keyAllowListLive = false;
    }

    function setTransformerContract(address contractAddress) public onlyOwner {
        transformerContract = contractAddress;
    }

    function toggleBurnAndMintIsLive() public onlyOwner {
        burnAndMintIsLive = !burnAndMintIsLive;
    }

    function lockURIs() public onlyOwner {
        require(!urisLocked, "URIs have been locked");

        urisLocked = true;
    }

    function setBaseURI(string memory baseUri) public onlyOwner {
        require(!urisLocked, "URIs have been locked");

        _baseUri = baseUri;
    }

    function setBaseCID(string memory baseCid) public onlyOwner {
        require(!urisLocked, "URIs have been locked");

        _baseCid = baseCid;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        IRevealContract revealContractInterface = IRevealContract(
            revealContract
        );
        string memory revealContractCid = revealContractInterface.getCid(
            tokenId
        );

        if (_exists(tokenId) && bytes(revealContractCid).length > 0) {
            return string(abi.encodePacked(_baseUri, revealContractCid));
        }

        return string(abi.encodePacked(_baseUri, _baseCid, "/", tokenId));
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return (_tokensOfOwner);
    }

    function burnAndMint(
        uint256 tokenId,
        uint256 typeOption,
        uint256 transformerKeyTokenId
    ) public nonReentrant {
        require(burnAndMintIsLive, "burnAndMintIsLive is not live");
        require(ownerOf(tokenId) == tx.origin, "must be token owner");

        uint256 newTokenId;

        if (typeOption == 0) {
            newTokenId = transformerKeyTokenId + 8000;
        } else {
            require(typeOption == 1, "invalid typeOption argument");
            newTokenId = transformerKeyTokenId + 16000;
        }

        require(newTokenId <= 23999, "tokenId too high");
        require(!revealed[newTokenId], "already revealed");

        // burn
        ITransformerKeyContract transformerContractInterface = ITransformerKeyContract(
                transformerContract
            );

        address tokenOwner = transformerContractInterface.ownerOf(
            transformerKeyTokenId
        );
        require(tokenOwner == tx.origin, "Not token owner");
        require(
            transformerContractInterface.isApprovedForAll(
                tx.origin,
                address(this)
            ),
            "No permission to transfer"
        );
        transformerContractInterface.transferFrom(
            tx.origin,
            burnAddress,
            transformerKeyTokenId
        );

        revealed[newTokenId] = true;

        revealedIds.push(newTokenId);

        IRevealContract revealContractInterface = IRevealContract(
            revealContract
        );
        string memory newCid = revealContractInterface.getCid(newTokenId);
        require(bytes(newCid).length != 0, "new cid must be set");

        // burn old and mint new
        _burn(tokenId);
        _safeMint(tx.origin, newTokenId);

        emit TokenRevealed(tx.origin, newTokenId, newCid);
    }

    function mint(uint256 existingNftId, address existingContractAddress)
        public
        nonReentrant
    {
        IRevealContract revealContractInterface = IRevealContract(
            revealContract
        );

        uint256 newTokenId;

        if (existingContractAddress == revealContract) {
            // transfer old pfp to burn and mint same id on this contract
            newTokenId = existingNftId;

            address tokenOwner = revealContractInterface.ownerOf(existingNftId);
            require(tokenOwner == msg.sender, "Not token owner");
            require(
                revealContractInterface.isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "No permission to transfer"
            );
            revealContractInterface.transferFrom(
                msg.sender,
                burnAddress,
                existingNftId
            );
        } else {
            require(
                existingContractAddress == boxContract,
                "invalid old collection address"
            );

            // transfer box burn and mint pfp id on this contract
            newTokenId = (existingNftId + randomNumber) % maxSupply;

            IERC721 boxContractInterface = IERC721(boxContract);

            address tokenOwner = boxContractInterface.ownerOf(existingNftId);
            require(tokenOwner == msg.sender, "Not token owner");
            require(
                boxContractInterface.isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "No permission to transfer"
            );
            boxContractInterface.transferFrom(
                msg.sender,
                burnAddress,
                existingNftId
            );
        }

        if (keyAllowListLive) {
            keyAllowList[msg.sender] += 1;
        }

        _mint(_msgSender(), newTokenId);
        revealed[newTokenId] = true;
        revealedIds.push(newTokenId);

        emit TokenRevealed(
            msg.sender,
            newTokenId,
            revealContractInterface.getCid(newTokenId)
        );
    }
}