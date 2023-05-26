// SPDX-License-Identifier: MIT

// @title: Thingies
// @author: Non Fungible Labs

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Thingies is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard
{
    using Address for address payable;
    using SafeMath for uint256;

    uint256 public constant MAX_THINGIES = 10000;
    uint256 public constant MAX_MINT = 10;
    uint256 public RENAME_PRICE = 9E15; // 0.009ETH

    enum State {
        Setup,
        Party
    }

    mapping(uint256 => bool) private _nameChanged;

    mapping(uint256 => bool) public _thingieForFluf;

    State private _state;

    string private _immutableIPFSBucket;
    string private _mutableIPFSBucket;
    string private _tokenUriBase;
    address public _flufAddress;

    event NameAndDescriptionChanged(
        uint256 indexed _tokenId,
        string _name,
        string _description
    );

    constructor() ERC721("FLUF World: Thingies", "THINGIES") {
        _state = State.Setup;
        _flufAddress = 0xCcc441ac31f02cD96C153DB6fd5Fe0a2F4e6A68d;
        _tokenUriBase = "https://thingies-api.fluf.world/api/token/";
    }

    function setImmutableIPFSBucket(string memory immutableIPFSBucket_)
        public
        onlyOwner
    {
        require(
            bytes(_immutableIPFSBucket).length == 0,
            "This IPFS bucket is immuable and can only be set once."
        );
        _immutableIPFSBucket = immutableIPFSBucket_;
    }

    function setMutableIPFSBucket(string memory mutableIPFSBucket_)
        public
        onlyOwner
    {
        _mutableIPFSBucket = mutableIPFSBucket_;
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function setFlufAddress(address flufAddress) public onlyOwner {
        _flufAddress = flufAddress;
    }

    function changeNameAndDescription(
        uint256 tokenId,
        string memory newName,
        string memory newDescription
    ) public payable {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "This isn't your Thingie.");

        uint256 amountPaid = msg.value;

        if (_nameChanged[tokenId]) {
            require(
                amountPaid == RENAME_PRICE,
                "It costs to create a new identity."
            );
        } else {
            require(
                amountPaid == 0,
                "First time's free my fluffy little friend."
            );
            _nameChanged[tokenId] = true;
        }

        emit NameAndDescriptionChanged(tokenId, newName, newDescription);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _tokenUriBase;
    }

    function state() public view virtual returns (State) {
        return _state;
    }

    function immutableIPFSBucket() public view virtual returns (string memory) {
        return _immutableIPFSBucket;
    }

    function mutableIPFSBucket() public view virtual returns (string memory) {
        return _mutableIPFSBucket;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    function isFlufOwner(uint256 tokenId, address _address)
        public
        view
        returns (bool)
    {
        address owner = IERC721(_flufAddress).ownerOf(tokenId);
        if (owner == _address) {
            return true;
        } else {
            return false;
        }
    }

    function isFlufBatchOwner(uint256[] calldata tokenId, address _address)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(
                isFlufOwner(tokenId[i], _address),
                "Address is not owner of FLUF batch"
            );
        }
        return true;
    }

    function getFlufMintedStatus(uint256[] calldata tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory flufStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            flufStatus[i] = _thingieForFluf[tokenIds[i]];
        }
        return flufStatus;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setStateToParty() public onlyOwner {
        _state = State.Party;
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }

    function mintThingie(uint256 flufId)
        public
        virtual
        nonReentrant
        returns (uint256)
    {
        address human = msg.sender;
        if (human != owner()) {
            require(_state != State.Setup, "THINGIES aren't ready yet!");
            require(
                isFlufOwner(flufId, human),
                "You are not the owner of this FLUF"
            );
        }
        require(
            !_thingieForFluf[flufId],
            "The Thingie for this FLUF has already been minted."
        );
        require(
            totalSupply().add(1) <= MAX_THINGIES,
            "Sorry, there's not that many THINGIES left."
        );

        uint256 thingieRecieved = flufId;

        _safeMint(human, flufId);
        _thingieForFluf[flufId] = true;

        return thingieRecieved;
    }

    function mintThingieBatch(uint256[] memory flufId)
        public
        virtual
        nonReentrant
        returns (uint256)
    {
        address human = msg.sender;
        if (human != owner()) {
            require(_state != State.Setup, "THINGIES aren't ready yet!");
        }
        require(
            totalSupply().add(1) <= MAX_THINGIES,
            "Sorry, there's not that many THINGIES left."
        );
        require(
            flufId.length <= MAX_MINT,
            "You can only mint 10 THINGIES at a time."
        );

        uint256 firstThingieRecieved = flufId[0];

        for (uint256 i = 0; i < flufId.length; i++) {
            require(
                !_thingieForFluf[flufId[i]],
                "The Thingie for this FLUF has already been minted."
            );
            if (msg.sender == owner()) {
                _safeMint(human, flufId[i]);
                _thingieForFluf[flufId[i]] = true;
            } else {
                require(
                    isFlufOwner(flufId[i], human),
                    "You are not the owner of this FLUF"
                );
                _safeMint(human, flufId[i]);
                _thingieForFluf[flufId[i]] = true;
            }
        }

        return firstThingieRecieved;
    }

    function withdrawAllEth(address payable payee) public virtual onlyOwner {
        payee.sendValue(address(this).balance);
    }

    function setRenamePrice(uint256 newPrice) public onlyOwner {
        RENAME_PRICE = newPrice;
    }
}