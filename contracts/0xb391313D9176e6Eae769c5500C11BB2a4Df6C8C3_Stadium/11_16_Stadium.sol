// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/StadiumUtils.sol";
import "./interfaces/IUniqueTokenRegistry.sol";
import "./interfaces/IReferee.sol";

contract Stadium is OwnableUpgradeable, ERC721AUpgradeable {
    mapping(uint => uint8) _tokenTypes;
    mapping(uint => string) _tokenIpfsCids;
    mapping(uint => bytes32) _tokenStadiumIds;

    IUniqueTokenRegistry internal registry;
    IReferee internal referee;
    string internal stadiumTokenURI;
    string internal ipfsURI;

    mapping(address => uint) _playerCards;
    mapping(uint => bool) _tokenTransferrable;
    
    event FullWithdraw(address receiver);
    event RefereeUpdated(address referee);
    error NoIpfsHashError(uint tokenId);
    error NoStadiumIdError(uint tokenId);
    error OnePlayerPerAddressError(address player);
    error InvalidPrice(uint _given, uint _needed);

    function initialize(
        address _registry,
        address _referee,
        string memory _ipfsURI,
        string memory _stadiumTokenURI
    ) public initializerERC721A initializer {
        __Context_init();
        __ERC721A_init("STADIUM", "STADIUM");
        registry = IUniqueTokenRegistry(_registry);
        referee = IReferee(_referee);
        ipfsURI = _ipfsURI;
        stadiumTokenURI = _stadiumTokenURI;
    }

    function updateReferee(address _referee) public onlyOwner {
        referee = IReferee(_referee);
        emit RefereeUpdated(_referee);
    }

    function updateTokenURIs(string memory _ipfsURI, string memory _stadiumTokenURI) public onlyOwner {
        ipfsURI = _ipfsURI;
        stadiumTokenURI = _stadiumTokenURI;
    }

    function withdraw(
        address payable receiver,
        bytes32 nonce,
        bytes memory signature
    ) public {
        referee.check(
            abi.encode(receiver, nonce),
            signature
        );
        
        receiver.transfer(address(this).balance);
        emit FullWithdraw(receiver);
    }

    function mint(
        uint8 oType,
        string memory ipfsHash,
        bytes32 stadiumId,
        uint price,
        uint nonce,
        uint quantity,
        bytes memory signature
    ) public payable returns (uint[] memory tokenIds) {
        require(msg.value == price);
        referee.check(
            abi.encode(
                oType,
                price,
                nonce,
                quantity,
                stadiumId,
                ipfsHash
            ),
            signature
        );

        tokenIds = _mintBase(oType, ipfsHash, stadiumId, _msgSender(), quantity);
    }
    
    function mintNamed(
        uint8 oType,
        string memory name,
        string memory ipfsHash,
        bytes32 stadiumId,
        uint price,
        uint nonce,
        bytes memory signature
    ) public payable returns (uint[] memory tokenIds) {
        if(msg.value != price){
            revert InvalidPrice(msg.value, price);
        }
        referee.check(
            abi.encode(
                oType,
                name,
                price,
                nonce,
                stadiumId,
                ipfsHash
            ),
            signature
        );

        if (oType == StadiumUtils.O_PLAYER) {
            address sender = _msgSender();
            if (_playerCards[sender] != 0) {
                revert OnePlayerPerAddressError(sender);
            }
            _playerCards[sender] = _nextTokenId();
        }

        registry.reserveTokenName(oType, name, _nextTokenId());
        tokenIds = _mintBase(oType, ipfsHash, stadiumId, _msgSender(), 1);
    }

    function getTokenName(uint tokenId) public view returns (string memory) {
        return registry.getNameByTokenId(_tokenTypes[tokenId], tokenId);
    }

    function getTokenType(uint tokenId) public view returns (uint8) {
        return _tokenTypes[tokenId];
    }

    function getIpfsHash(uint tokenId) public view returns (string memory) {
        unchecked {
            do {
                if (bytes(_tokenIpfsCids[tokenId]).length > 0) {
                    return _tokenIpfsCids[tokenId];
                }
            } while (tokenId-- > 0);
        }
        revert NoIpfsHashError(tokenId);
    }

    function getStadiumId(uint tokenId) public view returns (string memory) {
        unchecked {
            do {
                bytes memory tId = abi.encodePacked(_tokenStadiumIds[tokenId]);
                if (tId.length > 0) {
                    return string(tId);
                }
            } while (tokenId-- > 0);
        }
        revert NoStadiumIdError(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(stadiumTokenURI, getIpfsHash(tokenId)));
    }

    function getIpfsTokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(ipfsURI, getIpfsHash(tokenId)));
    }

    function _startTokenId() internal pure virtual override returns (uint) {
        return 69;
    }

    function _mintBase(uint8 oType, string memory ipfsHash, bytes32 stadiumId, address receiver, uint quantity) internal returns (uint[] memory) {
        uint tokenId = _nextTokenId();
        _mint(receiver, quantity);
        
        _tokenIpfsCids[tokenId] = ipfsHash;
        _tokenStadiumIds[tokenId] = stadiumId;
        _tokenTransferrable[tokenId] = false;

        uint[] memory tokenIds = new uint[](quantity);
        for (uint i = 0; i < quantity; i++) {
            _tokenTypes[tokenId + i] = oType;
            tokenIds[i] = (tokenId + i);
        }

        return tokenIds;
    }

    function getCardFromType(address _cardOwner, uint256 _type) public view returns (uint256) {
        uint256 tokenId = 0;
        if(_type == StadiumUtils.O_PLAYER){
            tokenId = _playerCards[_cardOwner];
        }
        
        return tokenId;
    }

    function retired(uint tokenId) public view returns (bool transferrable) {
        transferrable = _tokenTransferrable[tokenId];
        return transferrable;
    }

    function changeRetiry(uint tokenId, bool transferrable, bytes memory signature) public {
        referee.check(
            abi.encode(
                tokenId,
                transferrable
            ),
            signature
        );

        _tokenTransferrable[tokenId] = transferrable;
    }

    //@dev restrict transfers if not retired
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        //ignore mint
        if(from == address(0)) return;

        bool transferrable = _tokenTransferrable[startTokenId];
        require(transferrable, "Card is not transferrable");
    }

    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        _playerCards[from] = 0;
        _playerCards[to] = startTokenId;

    }
}