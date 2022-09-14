// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author @SahilAujla15 ( sahilaujla.com )

/*
                                     \       ,
                                     |\.--._/|
                                    /\ )  )\\/
                                   /(   \  / \
                                  /(   J `(   \
                                 / ) | _\     /
                                /|)  \  eJ    L
                               |  \ L \   L   L
                              /  \  J  `. J   L
                              |  )   L   \/   \
                             /  \    J   (\   /
           _....___         |  \      \   \```
    ,.._.-'        '''--...-||\     -. \   \
  .'.=.'                    `         `.\ [ Y
 /   /                                  \]  J
Y / Y                                    Y   L
| | |          \                         |   L
| | |           Y                        A  J
|   I           |                       /I\ /
|    \          I             \        ( |]/|
J     \         /._           /        -tI/ |
 L     )       /   /'-------'J           `'-:.
 J   .'      ,'  ,'           `'-.__          \
  \ T      ,'  ,'                   '''---7   /
   \|    ,'L  Y                          /   /
    J   Y  |  J                     ,--.(   /
     L  |  J   L                   /  |    /\
     |  J.  L  J                  |    \ .' /
     J   L`-J   L                 |  _.-'   |
      L  J   L  J                  ``  J    |
      J   L  |   L                     J    |
       L  J  L    \                    L    \
       |   L  ) _.'\                    ) _.'\
       L    \('`    \                  ('`    \
        ) _.'\`-....'                   `-....'
       ('`    \
        `-.___/ 
 */

contract Horses is Ownable, ERC721AQueryable {
    // ============ State Variables ============

    mapping(uint256 => bool) public usedGunslingers;

    string public _baseTokenURI;
    uint256 public maxTokenIds = 7777;
    bool public _paused = true;
    string public hiddenMetadataUri;
    bool public revealed;
    uint256 public price = 0.01 ether;
    string private _name;
    string private _symbol;
    string public uriSuffix = ".json";
    bool public publicMintStarted;

    IERC721 Gunslingers;


    // ============ Errors ============

    error ContractPaused();
    error NonEOA();
    error SupplyExceeded();
    error NotOwnerOfGunslinger();
    error PublicSaleNotStarted();
    error NonExistentTokenQuery();
    error WithdrawFailed();
    error UsedGunslingersToken();
    error MoreETHRequired();

    // ============ Modifiers ============

    modifier onlyWhenNotPaused() {
        if(_paused) revert ContractPaused();
        _;
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NonEOA();
        _;
    }

    // ============ Constructor ============

    constructor(string memory __name, string memory __symbol, string memory _hiddenMetadataUri, address GunslingersAddress) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        hiddenMetadataUri = _hiddenMetadataUri;
        Gunslingers = IERC721(GunslingersAddress);
    }

    // ============ Core functions ============

    function claimHorse(uint256 gunslingerTokenId) external payable onlyWhenNotPaused callerIsUser {
        if(_nextTokenId() > maxTokenIds) revert SupplyExceeded();
        if (usedGunslingers[gunslingerTokenId]) revert UsedGunslingersToken();
        if(Gunslingers.ownerOf(gunslingerTokenId) != msg.sender) revert NotOwnerOfGunslinger();
        usedGunslingers[gunslingerTokenId] = true;
        _mint(msg.sender, 1);
    }

    function claimHorses(uint256[] memory gunslingerTokenIds) external payable onlyWhenNotPaused callerIsUser {
        for (uint256 i; i < gunslingerTokenIds.length; ) {
            if (usedGunslingers[gunslingerTokenIds[i]]) revert UsedGunslingersToken();
            if(Gunslingers.ownerOf(gunslingerTokenIds[i]) != msg.sender) revert NotOwnerOfGunslinger();
            usedGunslingers[gunslingerTokenIds[i]] = true;

            unchecked {
                i++;
            }
        }

        _mint(msg.sender, gunslingerTokenIds.length);
    }

    function mintHorses(uint256 quantity) external payable onlyWhenNotPaused callerIsUser {
        if(!publicMintStarted) revert PublicSaleNotStarted();
        if(_totalMinted() + quantity > maxTokenIds) revert SupplyExceeded();
        if(msg.value < price * quantity) revert MoreETHRequired();
        _mint(msg.sender, quantity);
    }

    function mintMany(address[] calldata _to, uint256[] calldata _amount) external payable onlyOwner {
        for (uint256 i; i < _to.length; ) {
            if(_totalMinted() + _amount[i] > maxTokenIds) revert SupplyExceeded();
            _mint(_to[i], _amount[i]);

            unchecked {
                i++;
            }
        }
    }

    function checkIfGunslingerUsed(uint256 tokenId) external view returns (bool) {
        return usedGunslingers[tokenId];
    }

    function mintForAddress(address _to, uint256 _quantity) external payable onlyOwner {
        if(_totalMinted() + _quantity > maxTokenIds) revert SupplyExceeded();
        _mint(_to, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        if(!_exists(tokenId)) revert NonExistentTokenQuery();

        if (revealed == false) {
            return string(abi.encodePacked(hiddenMetadataUri, _toString(tokenId), uriSuffix));
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : hiddenMetadataUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        if(!sent) revert WithdrawFailed();
    }

    function name() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _symbol;
    }

    // ============ Setters (OnlyOwner) ============

    function setPublicMintStarted(bool val) public onlyOwner {
        publicMintStarted = val;
    }

    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    function setURISuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setNameAndSymbol(string memory __name, string memory __symbol) external onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    receive() external payable {}

    fallback() external payable {}
}