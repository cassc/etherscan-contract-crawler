// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "stl-contracts/royalty/DerivedERC2981Royalty.sol";
import "stl-contracts/ERC/ERC5169.sol";

import "stl-contracts/security/VerifyLinkAttestation.sol";
import "stl-contracts/tokens/extensions/SharedHolders.sol";
import "stl-contracts/tokens/extensions/ParentContracts.sol";
import "stl-contracts/tokens/extensions/Minter.sol";
import "stl-contracts/access/UriChanger.sol";
import "stl-contracts/security/VerifySignature.sol";
import "./libs/interfaces.sol";

contract BrandExtenderSuitUp is
    Ownable,
    ERC721struct,
    ERC5169,
    VerifySignature,
    IERC721Enumerable,
    ERC721Enumerable,
    ERC721URIStorage,
    UriChanger,
    DerivedERC2981Royalty,
    SharedHolders,
    ParentContracts,
    Minter
{
    using Strings for uint256;
    using Address for address;

    mapping(uint256 => ERC721s) internal _parents;

    // relation of combined contract_and_id to tokenIds, kind of Enumerable
    mapping(uint256 => uint256[]) internal _childrenArr;
    mapping(uint256 => uint256) internal _childrenIndex;
    mapping(uint256 => uint256) internal _childrenCounter;

    string constant _METADATA_URI = "https://resources.smarttokenlabs.com/";

    address _royaltyReceiver;

    uint256 _mintStartTimestamp;
    uint256 _mintEndTimestamp;

    event BaseUriUpdated(string uri);
    event MintStartUpdated(uint256 timestamp);
    event MintEndUpdated(uint256 timestamp);
    event RoyaltyContractUpdated(address indexed newAddress);
    event PermanentURI(string _value, uint256 indexed _id);
    event MintedDerived(
        address indexed parentContract,
        uint256 indexed parentId,
        uint256 indexed mintedId,
        string tmpUri,
        uint256 currentOriginIndex
    );

    function _authorizeSetScripts(string[] memory) internal override onlyOwner {}

    function _authorizeSetSharedHolder(address[] calldata newAddresses) internal override onlyOwner {}

    function _authorizeAddParent(address newContract) internal override onlyUriChanger {}

    function _authorizeUpdateUriChanger(address newAddress) internal override onlyOwner {}

    // Base URI
    string private __baseURI;

    using Strings for uint256;

    struct MintRequestData {
        address erc721;
        uint256 tokenId;
        uint256 ticketId;
        bytes signature;
        string tokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, Minter) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
        Minter._beforeTokenTransfer(from, to, tokenId);
    }

    constructor(
        address _rr,
        address _newUriChanger
    ) ERC721("EDCON2023 Suit Up Collection", "EDCON2023") UriChanger(_newUriChanger) Ownable() {
        updateUriChanger(_newUriChanger);
        _setRoyaltyContract(_rr);

        // TODO set correct roaylty amount
        _setRoyalty(600); // 100 = 1%
    }

    function setRoyalty(uint256 amount) external onlyOwner {
        _setRoyalty(amount);
    }


    function _validateMintRequest(MintRequestData calldata data) internal view returns (bool) {
        address erc721 = data.erc721;
        require(isAllowedParent(data.erc721), "Contract not supported");

        bytes memory toSign = abi.encodePacked(
            address(this),
            msg.sender,
            erc721,
            data.tokenId,
            block.chainid,
            data.ticketId,
            data.tokenURI
        );

        require(verifyEthHash(keccak256(toSign), data.signature) == uriChanger(), "Wrong metadata signer");

        return true;
    }

    function mintDerived(MintRequestData[] calldata data) external virtual {
        uint256 i;
        for (i = 0; i < data.length; i++) {
            require(_validateMintRequest(data[i]), "Invalid mint request");
            _mintDerivedMulti(data[i].erc721, data[i].tokenId, msg.sender, data[i].ticketId);
            emit MintedDerived(
                data[i].erc721,
                data[i].tokenId,
                data[i].ticketId,
                data[i].tokenURI,
                // -1 to show already used value
                tokenOfOriginCounter(data[i].erc721, data[i].tokenId) - 1
            );
        }
    }

    function _mintDerivedMulti(address erc721, uint256 tokenId, address to, uint256 ticketId) internal {
        require(block.timestamp >= _mintStartTimestamp, "Minting has not started");
        if (_mintEndTimestamp > 0) {
            require(block.timestamp <= _mintEndTimestamp, "Minting finished");
        }

        require(_isSharedHolderTokenOwner(erc721, tokenId), "Shared Holder not owner");

        _parents[ticketId] = ERC721s(erc721, tokenId);

        // Get unique 256 bit pointer to specific originating Token (masked address + tokenId)
        uint256 pointer = _getPonter(erc721, tokenId);
        // How many tokens are currently dervied from the specific originating Token
        uint256 newTokenIndex = _childrenCounter[pointer];

        _childrenIndex[ticketId] = _childrenArr[pointer].length;
        _childrenArr[pointer].push(ticketId); // create mapping of derived tokenIds for each originating Token
        _childrenCounter[pointer] = newTokenIndex + 1;

        _safeMint(to, ticketId);
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_METADATA_URI, "contract/edcon_suitup.json"));
    }

    function _contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId);

        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length > 0) {
            return string(abi.encodePacked(base, "/", tokenId.toString()));
        } else {
            return
                string(
                    abi.encodePacked(
                        _METADATA_URI,
                        block.chainid.toString(),
                        "/",
                        _contractAddress(),
                        "/",
                        tokenId.toString()
                    )
                );
        }
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyUriChanger {
        _setBaseURI(baseURI_);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        emit BaseUriUpdated(baseURI_);
        __baseURI = baseURI_;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyUriChanger {
        _setTokenURI(tokenId, _tokenURI);
        emit PermanentURI(_tokenURI, tokenId);
    }

    function setMintStartTime(uint256 timestamp) external onlyOwner {
        _setMintStartTime(timestamp);
    }

    function _setMintStartTime(uint256 timestamp) internal {
        emit MintStartUpdated(timestamp);
        _mintStartTimestamp = timestamp;
    }

    function getMintStartTime() external view returns (uint256) {
        return _mintStartTimestamp;
    }

    function setMintEndTime(uint256 timestamp) external onlyOwner {
        _setMintEndTime(timestamp);
    }

    function _setMintEndTime(uint256 timestamp) internal {
        emit MintEndUpdated(timestamp);
        _mintEndTimestamp = timestamp;
    }

    function getMintEndTime() external view returns (uint256) {
        return _mintEndTimestamp;
    }

    // Form combination of address & tokenId for unique pointer to NFT - Address is 160 bits (20*8) + TokenId 96 bits
    function _getPonter(address c, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(c, tokenId)));
    }

    function tokenOfOriginByIndex(address erc721, uint256 tokenId, uint256 index) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        require(index < _childrenArr[pointer].length, "Index out of bounds");
        return _childrenArr[pointer][index];
    }

    function tokenOfOriginCount(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        return _childrenArr[pointer].length;
    }

    function tokenOfOriginCounter(address erc721, uint256 tokenId) public view returns (uint256) {
        uint256 pointer = _getPonter(erc721, tokenId);
        return _childrenCounter[pointer];
    }

    // required to solve inheritance
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721s memory parent = getParent(tokenId);
        uint256 pointer = _getPonter(parent.erc721, parent.tokenId);

        uint256 tokenIndex = _childrenIndex[tokenId];

        uint256 lastTokenIndex = _childrenArr[pointer].length - 1;

        //If required, swap the token to be burned and the token at the head of the stack
        //then use pop to remove the head of the _childrenArr stack mapping
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _childrenArr[pointer][lastTokenIndex];

            _childrenArr[pointer][tokenIndex] = lastTokenId;

            _childrenIndex[lastTokenId] = tokenIndex;
        }

        _childrenArr[pointer].pop();
        delete _childrenIndex[tokenId];

        delete _parents[tokenId];
        ERC721URIStorage._burn(tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved and not owner");
        _burn(tokenId);
    }

    // required to solve inheritance
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC5169, IERC165, ERC721, DerivedERC2981Royalty, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            ERC721.supportsInterface(interfaceId) ||
            ERC5169.supportsInterface(interfaceId) ||
            DerivedERC2981Royalty.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Token doesnt exist.");
        receiver = _royaltyReceiver;
        royaltyAmount = (_getRoyalty() * salePrice) / 10000;
    }

    function setRoyaltyContract(address newAddress) external onlyOwner {
        _setRoyaltyContract(newAddress);
    }

    function _setRoyaltyContract(address newAddress) internal {
        // require(newAddress.isContract(), "Only Contract allowed");
        emit RoyaltyContractUpdated(newAddress);
        _royaltyReceiver = newAddress;
    }

    // function _isTokenOwner(address _contract, uint256 tokenId) internal view returns (bool) {
    //     ERC721 t = ERC721(_contract);
    //     return _msgSender() == t.ownerOf(tokenId);
    // }

    function getParent(uint256 tokenId) public view returns (ERC721s memory) {
        require(_exists(tokenId), "Non-existent token");
        return _parents[tokenId];
    }
}