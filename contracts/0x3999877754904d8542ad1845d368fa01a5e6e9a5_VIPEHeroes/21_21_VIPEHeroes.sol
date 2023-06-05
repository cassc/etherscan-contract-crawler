// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ISignatureManager} from "./Signature/ISignatureManager.sol";

/* 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@.................................................[email protected]@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@@@[email protected]@@@@[email protected]@@*[email protected]@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@[email protected]@@*[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@
@@@@@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@@
@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@@[email protected]@@[email protected]@@@
@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@[email protected]@@@@([email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@[email protected]@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@[email protected]@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@@@@@@@[email protected]@@@[email protected]@[email protected]@@&[email protected]@@[email protected]@@@@@@@[email protected]@@[email protected]@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@[email protected]@@[email protected]@@[email protected]@[email protected]@@@
@@@@@[email protected]@@@[email protected]@@[email protected]@[email protected]@@@@[email protected]@@@[email protected]@@@@[email protected]@@[email protected]@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   
 
*/


contract VIPEHeroes is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    AccessControl,
    ERC721Burnable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    uint256 immutable maxSupply = 5000;
    address payable receiver;
    bool public isExtensibleURI;
    string baseURIExtensible;
    string baseURI;
    ISignatureManager public signatureManager;
    uint8 public phase;
    mapping(uint256 => uint256) public phasePrice;

    error PaymentError();
    error MaxSupplyError();
    error NotYetMinteable();
    error SignatureError();
    error PhaseError();
    error LengthError();

    constructor(
        address _receiver,
        address _signatureManager,
        string memory _initBaseURI
    ) ERC721("VIPE Heroes", "VPH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        receiver = payable(_receiver);
        signatureManager = ISignatureManager(_signatureManager);
        baseURI = _initBaseURI;
        phasePrice[1] = 0.01 ether;
        phasePrice[2] = 0.02 ether;
        phasePrice[3] = 0.02 ether;
        phasePrice[4] = 0.03 ether;
        phasePrice[5] = 0.03 ether;
    }

    function setPhase(uint8 _phase) public onlyRole(SETTER_ROLE) {
        phase = _phase;
    }

    function setReceiver(address payable _receiver)
        public
        onlyRole(SETTER_ROLE)
    {
        receiver = _receiver;
    }

    function setSignatureManager(address _signatureManager)
        public
        onlyRole(SETTER_ROLE)
    {
        signatureManager = ISignatureManager(_signatureManager);
    }

    function setPhasePrice(uint8 _phase, uint256 _price)
        public
        onlyRole(SETTER_ROLE)
    {
        phasePrice[_phase] = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setExtensibleBaseURI(
        string calldata _baseURIExtensible
    ) public onlyRole(SETTER_ROLE) {
        baseURIExtensible = _baseURIExtensible;
    }

    function enableExtensibleBaseURI(
        bool isEnabled
    ) public onlyRole(SETTER_ROLE) {
        isExtensibleURI = isEnabled;
    }

    function setBaseURI(
        string calldata _newBaseURI
    ) public onlyRole(SETTER_ROLE) {
        baseURI = _newBaseURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(
        string memory _uri,
        uint8 _phase,
        uint256 _tokenId,
        bytes calldata _signature
    ) public payable whenNotPaused nonReentrant {
        if (_phase != phase) {
            revert PhaseError();
        }

        if (phase == 0) {
            revert NotYetMinteable();
        }

        if (
            _tokenIdCounter.current() >= maxSupply
        ) {
            revert MaxSupplyError();
        }

        if (msg.value != phasePrice[phase]) {
            revert PaymentError();
        }

        if (
            !signatureManager.verify(
                _msgSender(),
                _tokenId,
                _uri,
                _phase,
                _signature
            )
        ) {
            revert SignatureError();
        }

        (bool successTxPayment, ) = receiver.call{value: phasePrice[phase]}(
            ""
        );

        if (!successTxPayment) {
            revert PaymentError();
        }

        _safeMint(_msgSender(), _tokenId);
        _setTokenURI(_tokenId, _uri);
        _tokenIdCounter.increment();
    }

    function privateSafeMint(
        address _to,
        uint256[] memory _tokenId,
        string[] memory _uri
    ) public onlyRole(MINTER_ROLE) {
        if (_tokenIdCounter.current() >= maxSupply) {
            revert MaxSupplyError();
        }
        if (_tokenId.length != _uri.length) {
            revert LengthError();
        }
        for (uint256 i = 0; i < _tokenId.length; i++) {
            _safeMint(_to, _tokenId[i]);
            _setTokenURI(_tokenId[i], _uri[i]);
            _tokenIdCounter.increment();
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (isExtensibleURI) {
            return (
                string(
                    abi.encodePacked(
                        baseURIExtensible,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
            );
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}