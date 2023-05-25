//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IGMGN.sol";
import "./IGMGNDetonation.sol";

contract DegenToonzDetonation is ERC721A, Ownable, IERC721Receiver, ReentrancyGuard {
    using Strings for uint256;

    uint8 constant DETONATION_TYPES = 2;
    uint256 constant INITIAL_MINT_LIMIT = 752;
    IERC721 constant GENESIS_TOKEN_CONTRACT = IERC721(address(0x19b86299c21505cdf59cE63740B240A9C822b5E4));
    IGMGN constant GMGN_DYNAMITE_CONTRACT = IGMGN(address(0x390416aE4324494338293974EE6388E777faC34b));
    address constant GMGN_DETONATION_CONTRACT_ADDRESS = address(0x43A15a4189D0E6B2267bE93A5bcF6013bF423534);
    IGMGNDetonation constant GMGN_DETONATION_CONTRACT = IGMGNDetonation(GMGN_DETONATION_CONTRACT_ADDRESS);

    error DetonationNotEnabled();
    error InvalidDetonationType();
    error YouMustOwnTheGenesisToon();
    error NotEnoughDynamite();
    error AlreadyDetonated();
    error UriQueryForNonexistentToken();
    error InitialMintLimitExceeded();
    error InvalidTokenSender();

    event Detonation(uint256 indexed genesisTokenId, uint256 indexed detonationType, uint256 indexed detonatedTokenId, address owner);

    struct TokenData {
        uint256 genesisTokenId;
        uint256 detonationType;
    }

    struct DetonationStatus {
        uint256 tokenId;
        bool normal;
        bool radioactive;
    }

    string public uriPrefix = '';
    string public uriSuffix = '.json';

    bool public canDetonate = false;

    mapping (uint256 => TokenData) public tokenData;
    mapping (uint256 => bool[DETONATION_TYPES]) public hasBeenDetonated;

    constructor() ERC721A("Detonated Toonz", "DTNT") {
    }

    function detonate(uint256 _genesisTokenId, uint256 _detonationType) public nonReentrant {
        if (!canDetonate) {
            revert DetonationNotEnabled();
        }

        if (_detonationType >= DETONATION_TYPES) {
            revert InvalidDetonationType();
        }

        if (GENESIS_TOKEN_CONTRACT.ownerOf(_genesisTokenId) != msg.sender) {
            revert YouMustOwnTheGenesisToon();
        }

        if (GMGN_DYNAMITE_CONTRACT.balanceOf(msg.sender, _detonationType) < 1) {
            revert NotEnoughDynamite();
        }

        if (hasBeenDetonated[_genesisTokenId][_detonationType]) {
            revert AlreadyDetonated();
        }

        hasBeenDetonated[_genesisTokenId][_detonationType] = true;
        tokenData[_currentIndex] = TokenData(_genesisTokenId, _detonationType);

        emit Detonation(_genesisTokenId, _detonationType, _currentIndex, msg.sender);

        GMGN_DYNAMITE_CONTRACT.burn(msg.sender, _detonationType, 1);
        _safeMint(msg.sender, 1);
    }

    function initialMint(uint256 endIndex) public onlyOwner {
        uint256 startIndex = _currentIndex;

        if (endIndex > INITIAL_MINT_LIMIT) {
            revert InitialMintLimitExceeded();
        }

        for (uint256 currentTokenId = startIndex; currentTokenId < endIndex; currentTokenId++) {
            (uint256 genesisTokenId, uint256 detonationType) = GMGN_DETONATION_CONTRACT.tokenData(currentTokenId);

            hasBeenDetonated[genesisTokenId][detonationType] = true;
            tokenData[currentTokenId] = TokenData(genesisTokenId, detonationType);
        }

        _safeMint(address(this), endIndex - startIndex);
    }

    function getDetonationStatus(uint256 _tokenId) public view returns(DetonationStatus memory) {
        if (_tokenId < 1 || _tokenId > 8888) {
            revert UriQueryForNonexistentToken();
        }

        return DetonationStatus(_tokenId, hasBeenDetonated[_tokenId][0], hasBeenDetonated[_tokenId][1]);
    }

    function walletDetonationStatus(
        address _owner,
        uint256 _startId,
        uint256 _endId,
        uint256 _startBalance
    ) public view returns(DetonationStatus[] memory) {
        uint256 ownerBalance = GENESIS_TOKEN_CONTRACT.balanceOf(_owner) - _startBalance;
        DetonationStatus[] memory tokensData = new DetonationStatus[](ownerBalance);
        uint256 currentOwnedTokenIndex = 0;

        for (uint256 i = _startId; currentOwnedTokenIndex < ownerBalance && i <= _endId; i++) {
            if (GENESIS_TOKEN_CONTRACT.ownerOf(i) == _owner) {
                tokensData[currentOwnedTokenIndex] = getDetonationStatus(i);

                currentOwnedTokenIndex++;
            }
        }

        assembly {
            mstore(tokensData, currentOwnedTokenIndex)
        }

        return tokensData;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setCanDetonate(bool _canDetonate) public onlyOwner {
        canDetonate = _canDetonate;
    }

    function unlockStuckToken(uint256 _tokenId, address _to) public onlyOwner {
        GMGN_DETONATION_CONTRACT.safeTransferFrom(address(this), owner(), _tokenId);
        this.safeTransferFrom(address(this), _to, _tokenId);
    }

    function transferInitialTokenManually(uint256 _tokenId, address _to) public onlyOwner {
        this.safeTransferFrom(address(this), _to, _tokenId);
    }

    function withdrawOldTokenManually(uint256 _tokenId) public onlyOwner {
        GMGN_DETONATION_CONTRACT.safeTransferFrom(address(this), owner(), _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert UriQueryForNonexistentToken();
        }

        string memory currentBaseURI = uriPrefix;

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external nonReentrant returns (bytes4) {
        bool isNotCalledBySelf = msg.sender != address(this);

        if ((msg.sender != GMGN_DETONATION_CONTRACT_ADDRESS) && isNotCalledBySelf) {
           revert InvalidTokenSender();
        }

        if (isNotCalledBySelf) {
            GMGN_DETONATION_CONTRACT.safeTransferFrom(address(this), owner(), tokenId);
            this.safeTransferFrom(address(this), from, tokenId);
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}