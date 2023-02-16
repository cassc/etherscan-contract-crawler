//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IBTVEncapsulator.sol";

import {Base64} from "../libraries/Base64.sol";

/**
 * @dev Implementation of the BTV Encapsulator for as many unique ERC-20/NFT pairs as possible.
 */
contract BTVEncapsulator is IBTVEncapsulator, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _currentId;

    bool public _locked;
    address private _owner;
    string public metadataBaseLink;

    struct TokenType {
        IERC20 token;
        Counters.Counter count;
        string[] uri;
    }

    mapping(uint256 => TokenType) public types;

    // Mapping from token Id to type ID
    mapping(uint256 => uint256) public typeOf;
    // Mapping from token Id to token Number e.g 1/1000
    mapping(uint256 => uint256) _tokenNumber;

    event tokenMinted(address _from, uint256 _typeId, uint256 amount);
    event tokenUnminted(address _from, uint256 _tokenId);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only owner");
        _;
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "Invalid tokenId");
        _;
    }

    constructor() ERC721("BTV Museum", "BTVM") {
        _owner = msg.sender;
        _locked = false;
    }

    function lock() public onlyOwner {
        _locked = true;
    }

    /**
     * @dev Sets base link for metadata
     * @param link {baseLink}/img
     */
    function setBaseLink(string memory link) external onlyOwner {
        require(!_locked, "Locked");
        metadataBaseLink = link;
    }

    /**
     * @dev Creates a type with corresponding data
     * @param typeId A non-assigned id to be associated with the asset
     * @param _contract Address of the ERC20 token
     * @param _uri Should contain [name, image, desccription, creation]
     */
    function createType(
        uint256 typeId,
        IERC20 _contract,
        string[] memory _uri
    ) public onlyOwner {
        require(
            types[typeId].token == IERC20(address(0)),
            "Type ID already assigned"
        );
        require(_uri.length >= 3, "Not enough data");
        Counters.Counter memory newCounter;
        TokenType memory newType = TokenType(_contract, newCounter, _uri);

        types[typeId] = newType;
    }

    function createTypes(
        uint256[] calldata typeIds,
        IERC20[] memory contracts,
        string[][] memory uris
    ) external {
        uint256 length = typeIds.length;
        require(length == contracts.length && uris.length == length);

        for (uint i = 0; i < length; ) {
            createType(typeIds[i], contracts[i], uris[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the address of the BtV Asset Contract
     * @param typeId Id of the type
     */
    function tokenContractOf(uint256 typeId)
        public
        view
        override
        returns (address)
    {
        return (address(types[typeId].token));
    }

    /**
     * @dev Mints {amount} of NFTs of {type ID}.
     * @param typeId is the index of the item type.
     * @param amount of NFTs to be mintedLe compteur est
     * @param to of NFTs to be mintedLe compteur est */
    function swapForNFT(
        uint256 typeId,
        uint256 amount,
        address to
    ) public override {
        _swapForNftFrom(typeId, amount, to, msg.sender);
    }

    /**
     * @dev Mints {amount} of NFTs of {type ID}.
     * @param typeId is the index of the item type.
     * @param amount of NFTs to be minted.
     * @param to is the owner of minted NFT.
     * @param from is the owner of ERC-20 used.
     */
    function _swapForNftFrom(
        uint256 typeId,
        uint256 amount,
        address to,
        address from
    ) internal {
        IERC20 typeContract = types[typeId].token;

        require(
            typeContract != IERC20(address(0)),
            "Token Type Id does not exist"
        );
        require(
            typeContract.allowance(from, address(this)) >= amount,
            "Contract not allowed to spend ERC-20"
        );
        require(
            typeContract.transferFrom(from, address(this), amount),
            "Getting tokens from erc-20 failed"
        );

        for (uint256 i = 0; i < amount; i++) {
            typeOf[_currentId.current()] = typeId;
            _tokenNumber[_currentId.current()] = types[typeId].count.current();
            types[typeId].count.increment();
            _mint(to, _currentId.current());
            _currentId.increment();
        }
        emit tokenMinted(to, typeId, amount);
    }

    /**
     * @dev Swap a NFT for a corresponding ERC-20.
     * @param tokenId is the id of the NFT
     */
    function swapForToken(uint256 tokenId)
        public
        onlyOwnerOf(tokenId)
        exists(tokenId)
    {
        require(
            types[typeOf[tokenId]].token.transfer(msg.sender, 1),
            "Giving back token failed"
        );

        _burn(tokenId);
        emit tokenUnminted(msg.sender, tokenId);
    }

    /**
     * @dev Mint NFT once approval is received from ERC20.
     * @param amount of NFTs to be minted
     * @param tokenContract of the corresponding ERC20
     * @param typeData is encoded typeId
     */
    function receiveApproval(
        address,
        uint256 amount,
        address tokenContract,
        bytes calldata typeData
    ) public {
        uint256 typeId = abi.decode(typeData, (uint256));

        if (address(types[typeId].token) == tokenContract) {
            _swapForNftFrom(typeId, amount, tx.origin, tx.origin);
        } else revert("Approval from invalid");
    }

    /**
     * @dev Returns number of tokens minted
     */
    function totalMints() public view returns (uint256) {
        return _currentId.current();
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for type of `typeId`.
     */
    function typeURI(uint256 typeId) public view returns (string memory) {
        string[] memory uri = types[typeId].uri;
        string memory typeIdStr = Strings.toString(typeId);

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"',
                                    uri[0],
                                    '","image":"',
                                    metadataBaseLink,
                                    "museum/",
                                    typeIdStr,
                                    '.png","description":"',
                                    uri[1],
                                    '", "animation_url":"',
                                    metadataBaseLink,
                                    "#/museum/",
                                    typeIdStr,
                                    '/0","attributes": [{"display_type":"date","trait_type":"Origin","value":"',
                                    uri[2],
                                    '}]}'
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for type of `tokenId`.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        exists(tokenId)
        returns (string memory)
    {
        string[] memory uri = types[typeOf[tokenId]].uri;
        string memory typeId = Strings.toString(typeOf[tokenId]);
        string memory numbering = Strings.toString(_tokenNumber[tokenId]);

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"',
                                    uri[0],
                                    '","image":"',
                                    metadataBaseLink,
                                    "museum/",
                                    typeId,
                                    '.png","description":"',
                                    uri[1],
                                    '", "animation_url":"',
                                    metadataBaseLink,
                                    "#/museum/",
                                    typeId,
                                    "/",
                                    numbering,
                                    '","attributes": [{"display_type":"date","trait_type":"Origin","value":',
                                    uri[2],
                                    '},{"display_type":"number","trait_type":"Numbering","value":',
                                    numbering,
                                    "}]}"
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) of the contract.
     */
    function contractURI() public view returns (string memory) {
        return (
            string(abi.encodePacked(metadataBaseLink, "museum/collection.json"))
        );
    }
}