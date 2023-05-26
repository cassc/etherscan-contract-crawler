// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Eiba

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CharaDaoEventNft is ERC1155, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public ADMIN = "ADMIN";

    modifier onlyAdmin() {
        if (!hasRole(ADMIN, msg.sender)) revert("not admin");
        _;
    }

    Counters.Counter private _tokenCounter;

    struct Nft {
        string name;
        string uri;
        uint16 tokenMax;
        uint256 minimumPrice;
        Counters.Counter amount;
        address payable creator;
    }

    bool public paused = false;

    mapping(uint256 => Nft) public nfts;
    mapping(address => uint256[]) public MintCount;

    constructor(address[] memory admins) ERC1155("") {
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(ADMIN, admins[i]);
        }
        _tokenCounter.reset();
    }

    function createNft(
        string memory _name,
        string memory _uri,
        uint16 _tokenMax,
        uint16 _mintForCreator,
        uint256 _minimumPrice,
        address payable _creator
    ) public onlyAdmin {
        _tokenCounter.increment();
        Counters.Counter memory _amount;
        nfts[_tokenCounter.current()] = Nft(
            _name,
            _uri,
            _tokenMax,
            _minimumPrice,
            _amount,
            _creator
        );

        if (_mintForCreator > 0) {
            _mint(_creator, _tokenCounter.current(), _mintForCreator, "");
            for (uint16 i = 0; i < _mintForCreator; i++) {
                nfts[_tokenCounter.current()].amount.increment();
            }
        }
    }

    function mint(uint256 _tokenId) public payable {
        if (nfts[_tokenId].tokenMax == 0) revert("_tokenId is not exists");

        for (uint256 i = 0; i < MintCount[msg.sender].length; i++) {
            if (_tokenId == MintCount[msg.sender][i])
                revert("can mint only one token");
        }

        if (nfts[_tokenId].amount.current() + 1 > nfts[_tokenId].tokenMax)
            revert("tokenId had reached max count");
        if (
            nfts[_tokenId].minimumPrice > 0 &&
            msg.value < nfts[_tokenId].minimumPrice
        ) revert("Insufficient payment");

        _mint(msg.sender, _tokenId, 1, "");
        nfts[_tokenId].amount.increment();
        MintCount[msg.sender].push(_tokenId);

        if (msg.value > 0) {
            nfts[_tokenId].creator.transfer(msg.value);
        }
    }

    // adminmint
    function adminMint(uint256 _tokenId, uint16 _amount) public onlyAdmin {
        if (nfts[_tokenId].tokenMax == 0) revert("_tokenId is not exists");
        if (nfts[_tokenId].amount.current() + 1 > nfts[_tokenId].tokenMax)
            revert("tokenId had reached max count");

        _mint(nfts[_tokenId].creator, _tokenId, _amount, "");

        for (uint16 i = 0; i < _amount; i++) {
            nfts[_tokenCounter.current()].amount.increment();
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return nfts[_id].uri;
    }

    function setUri(uint256 _id, string memory _uri) public onlyAdmin {
        nfts[_id].uri = _uri;
    }

    function name(uint256 _id) public view returns (string memory) {
        return nfts[_id].name;
    }

    function setName(uint256 _id, string memory _name) public onlyAdmin {
        nfts[_id].name = _name;
    }

    function tokenMax(uint256 _id) public view returns (uint16) {
        return nfts[_id].tokenMax;
    }

    function setTokenMax(uint256 _id, uint16 _tokenMax) public onlyAdmin {
        nfts[_id].tokenMax = _tokenMax;
    }

    function minimumPrice(uint256 _id) public view returns (uint256) {
        return nfts[_id].minimumPrice;
    }

    function setTokenMax(uint256 _id, uint256 _minimumPrice) public onlyAdmin {
        nfts[_id].minimumPrice = _minimumPrice;
    }

    function creator(uint256 _id) public view returns (address) {
        return nfts[_id].creator;
    }

    function setCreator(uint256 _id, address payable _creator)
        public
        onlyAdmin
    {
        nfts[_id].creator = _creator;
    }

    function amount(uint256 _id) public view returns (uint256) {
        return nfts[_id].amount.current();
    }

    function pause(bool _state) public onlyAdmin {
        paused = _state;
    }

    function burn(uint256 _id, uint256 _amount) public {
        _burn(msg.sender, _id, _amount);
    }

    function withdraw() public payable onlyAdmin {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(os);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}