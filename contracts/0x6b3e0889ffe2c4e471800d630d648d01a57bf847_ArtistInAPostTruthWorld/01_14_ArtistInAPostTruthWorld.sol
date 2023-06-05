// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../interfaces/IAutographNFT.sol";
import "../libraries/OnChainMetadata.sol";

contract ArtistInAPostTruthWorld is ERC721A, ERC2981, IAutographNFT {

    string private constant _signedImage = "ipfs://QmbsTuezHG6e6uj19xHZL6CqKQJWhoxLFmavYoEuFXB5JZ";
    string private constant _unsignedImage = "ipfs://QmcRzuifx3usrBxNYpUVAopNHZ9ZMUQpKNBWJnunhTjEDB";

    uint256 private _maxSupply = 1000;
    uint256 private _mintStart = 1685700000; // June 2nd 10AM UTC
    uint256 private _mintEnd = 1685959200; // June 5th 10AM UTC
    string private _unsignedWebapp = "https://ipfs.idea.tf/ipfs/QmUw5rjZh7YJRdWnbU5wqhyEj1u2oGXLxTTkqo4VEBDBW7/";
    address public owner;

    address private _apiWallet = 0x2c5B98F69c80dE0FFd445cDAcD689dcDa0B4bFE7;
    mapping(uint256 => uint256) private _signedTimestamp;

    constructor() ERC721A("Artist in a Post-Truth World", "APTW") {
        owner = msg.sender;

        _mint(0xB5905DbE33bb3193ED25dBE86C9436981E7cF54c, 1);
        _setDefaultRoyalty(0x9b3DC230BC76c2af3DFfEf82Ea3b344bf41df465, 500);
    }

    modifier onlyContractOwner() {
        if (msg.sender != owner) {
            revert NotContractOwner();
        }
        _;
    }

    modifier onlyAPI() {
        if (msg.sender != _apiWallet) {
            revert InvalidSigner();
        }
        _;
    }

    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    function freeMint() external {
        if (block.timestamp < _mintStart || block.timestamp > _mintEnd) {
            revert MintClosed();
        }
        if (_numberMinted(msg.sender) > 0) {
            revert AlreadyMinted();
        }
        if (_nextTokenId() > _maxSupply) {
            revert SoldOut();
        }
        _mint(msg.sender, 1);
    }

    function setSigner(address signer) external onlyContractOwner {
        _apiWallet = signer;
    }

    function setWebApp(string calldata uri) external onlyContractOwner {
        _unsignedWebapp = uri;
    }

    function setMintDates(uint256 start, uint256 end) external onlyContractOwner {
        if (end < start) {
            revert InconsistentDates();
        }
        _mintStart = start;
        _mintEnd = end;
    }

    function sign(uint256 _tokenId) external onlyAPI {
        if (!_exists(_tokenId)) {
            revert NonExistentToken();
        }
        if (_signedTimestamp[_tokenId] > 0) {
            revert AlreadySigned();
        }
        _signedTimestamp[_tokenId] = block.timestamp;
        emit MetadataUpdate(_tokenId);
    }

    function mintDates() external view returns (uint256, uint256) {
        return (_mintStart, _mintEnd);
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory) {
        if (!_exists(_tokenId)) {
            revert NonExistentToken();
        }
        if (_signedTimestamp[_tokenId] == 0) {
            return OnChainMetadata.unsignedTokenURI(
                _tokenId,
                _unsignedImage,
                _unsignedWebapp
            );
        }
        return OnChainMetadata.signedTokenURI(
            _tokenId,
            _signedTimestamp[_tokenId],
            _signedImage
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f ||
            interfaceId == 0x780e9d63 ||
            interfaceId == 0x2a55205a;
    }
}