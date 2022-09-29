// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./DegenFlipTypes.sol";

contract DegenFlipCoinNFT is Ownable, ERC721, ERC721Enumerable {
    using Strings for uint;

    struct CoinTypeTotal {
        uint16 Unrevealed; uint16 Crown; uint16 Banana; uint16 Diamond; uint16 Ape;
    }

    struct ContractData {
        uint16 totalSupply; bool maxSupplyLocked; string baseURI; address minter; CoinTypeTotal total;
    }

    uint16 public CURRENT_ID;
    string public BASE_URI;
    address public MINTER;
    bool public MAX_SUPPLY_LOCKED;
    mapping(uint16 => CoinType) private TYPES;
    mapping(CoinType => uint16) public TOTAL;

    event BaseURIChanged(string newBaseURI, uint timestamp);
    event MaxSupplyLocked(uint timestamp);
    event Minted(address indexed minter, uint16 tokenId, uint16 currentSupply, uint timestamp);
    event Burned(address indexed burner, uint16 tokenId, uint16 currentSupply, uint timestamp);

    constructor(
        string memory name, string memory symbol,
        string memory assetBaseURI, address minter
    ) ERC721(name, symbol) {
        BASE_URI = assetBaseURI;
        MINTER = minter;
    }

    // overrides //
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(abi.encodePacked(BASE_URI, tokenId.toString()), ".json"));
    }

    // onlyOwner //
    function lockMaxSupply() external onlyOwner {
        MAX_SUPPLY_LOCKED = true;
        MINTER = address(0);

        emit MaxSupplyLocked(block.timestamp);
    }

    function setBaseURI(string memory assetBaseURI) external onlyOwner {
        BASE_URI = assetBaseURI;

        emit BaseURIChanged(assetBaseURI, block.timestamp);
    }

    function setCoinsType(CoinType coinType, uint16[] calldata tokens) external onlyOwner {
        for (uint16 _index = 0; _index < tokens.length; _index++) {
            TOTAL[TYPES[tokens[_index]]] -= 1;
            TOTAL[coinType] += 1;
            TYPES[tokens[_index]] = coinType;
        }
    }

    // public //
    function mint(address account, uint amount) external {
        require(!MAX_SUPPLY_LOCKED, "Max supply already locked");
        require(_msgSender() == MINTER, "Only minting contract is allowed to mint");

        for (uint8 _index = 0; _index < amount; _index++) {
            CURRENT_ID += 1;
            _mint(account, CURRENT_ID);
            TOTAL[CoinType.Unrevealed] += 1;

            emit Minted(account, CURRENT_ID, uint16(totalSupply()), block.timestamp);
        }
    }

    function burn(uint16 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner nor approved");
        _burn(tokenId);

        emit Burned(_msgSender(), tokenId, uint16(totalSupply()), block.timestamp);
    }

    function batchTransfer(address recipient, uint[] calldata tokens) external {
        address _sender = _msgSender();
        for (uint16 _index = 0; _index < tokens.length; _index++) {
            safeTransferFrom(_sender, recipient, tokens[_index]);
        }
    }

    // views //
    function getTokens(uint16[] calldata tokens) external view returns (Token[] memory) {
        Token[] memory _tokens = new Token[](tokens.length);

        uint16 _tokenId;
        for (uint16 _index = 0; _index < tokens.length; _index++) {
            _tokenId = tokens[_index];
            _tokens[_index] = Token({
                tokenId : _tokenId, coinType : TYPES[_tokenId], owner : ownerOf(_tokenId)
            });
        }

        return _tokens;
    }

    function accountData(address account) public view returns (AccountTokenData memory) {
        uint16 _balance = uint16(balanceOf(account));
        Token[] memory _tokens = new Token[](_balance);

        uint16 _tokenId;
        for (uint _index = 0; _index < _balance; _index++) {
            _tokenId = uint16(tokenOfOwnerByIndex(account, _index));
            _tokens[_index] = Token({tokenId : _tokenId, coinType : TYPES[_tokenId], owner: account});
        }

        return AccountTokenData({balance : _balance, tokens : _tokens});
    }

    function myData() external view returns (AccountTokenData memory) {
        return accountData(_msgSender());
    }

    function contractData() external view returns (ContractData memory) {
        return ContractData({
            totalSupply : uint16(totalSupply()),
            baseURI : BASE_URI,
            maxSupplyLocked : MAX_SUPPLY_LOCKED,
            minter : MINTER,
            total : CoinTypeTotal({
                Unrevealed : TOTAL[CoinType.Unrevealed],
                Crown : TOTAL[CoinType.Crown],
                Banana : TOTAL[CoinType.Banana],
                Diamond : TOTAL[CoinType.Diamond],
                Ape : TOTAL[CoinType.Ape]
            })
        });
    }
}