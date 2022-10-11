// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/ITraded.sol";

/// @title Collectible contract - Royalty
contract Collectibles is ERC721URIStorage, IERC2981, ITraded {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    /// @dev To store royalty for each token
    mapping(uint256 => uint256) private royalties;
    /// @dev To store royaltyReceiver for each token
    mapping(uint256 => address) private royaltyReceivers;
    /// @dev To check if the token has ever been traded or not
    mapping(uint256 => bool) public override isTraded;

    /// @dev To return data in specific format
    struct tokenStruct {
        uint256 tokenId;
        uint256 royalty;
        string tokenURI;
        address owner;
        address royaltyReceiver;
    }

    /// @notice Constructor
    /// @param _name Name of the collectible
    /// @param _symbol Symbol of the collectible
    /// @dev Used to connect with the interface
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) { }

    /// @notice Transfer of royalty rights
    event RoyaltyRightsTransferred(
        address indexed _prevRoyaltyReceiver,
        address indexed _newRoyaltyReceiver,
        uint256 indexed _tokenId
    );

    /// @notice Mints new token
    /// @param tokenURI URI holding the token details (IPFS address)
    /// @param _royaltyPercent Percentage of royalty * 100
    /// @custom:modifier Royalty percent must not exceed 30
    function mintToken(string memory tokenURI, uint256 _royaltyPercent)
        external
    {
        require(_royaltyPercent <= 3000, "Royalty percent exceeds limit");

        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        royalties[newItemId] = _royaltyPercent;
        royaltyReceivers[newItemId] = msg.sender;
    }

    /// @notice To update the check royalty info flag to true
    /// @param _tokenId Id of the token traded
    /// @custom:modifier Only contract address can change the value
    function traded(uint256 _tokenId)
        external
        override
    {
        require(Address.isContract(msg.sender), 'Non contract address trying to modify traded data');

        isTraded[_tokenId] = true;
        emit UpdatedTraded(_tokenId);
    }


    /// @notice Provides information about royalties
    /// @param _tokenId Id of the token to sold
    /// @param _salePrice Total amount of the sold token
    /// @return receiver Address of the royalty recepient
    /// @return royaltyAmount Total amount of royalty to be paid to the recepient
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            royaltyReceivers[_tokenId],
            ((royalties[_tokenId] * _salePrice) / 10000)
        );
    }

    /// @notice Check if specific interface is supported or not
    /// @dev type(InterfaceName).interfaceId is used to get interface.
    /// @param _interfaceID Interface id to check if the interface is supported
    /// @return bool Boolean value
    function supportsInterface(bytes4 _interfaceID)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            (_interfaceID == 0x2a55205a) || // IERC2981
            (_interfaceID == 0xc87b56dd) || // ERC721URIStorage
            (_interfaceID == 0x40d8d24e) || // ITraded
            super.supportsInterface(_interfaceID);
    }

    /// @notice Changes the original minter address, new address receives royalty
    /// @param _newRoyaltyReceiver Address of the new royalty rights owner/receiver
    /// @param _tokenId Id of the token for royalty rights to be transferred
    /// @custom:modifier Only existing royalty receiving account can transfer the rights
    function transferRoyaltyRights(address _newRoyaltyReceiver, uint256 _tokenId)
        external
    {
        require(
            msg.sender == royaltyReceivers[_tokenId],
            "Only royalty owner can transfer the rights"
        );

        royaltyReceivers[_tokenId] = _newRoyaltyReceiver;
        emit RoyaltyRightsTransferred(msg.sender, _newRoyaltyReceiver, _tokenId);
    }

    /// @notice Returns all existing token with details
    /// @dev For easier data fetching in frontend
    /// @return Array of structure containing tokenId, tokenURI and token owner
    function getAllTokens() external view returns (tokenStruct[] memory) {
        tokenStruct[] memory allTokens = new tokenStruct[](tokenIds.current());

        for (uint256 i = 0; i < tokenIds.current(); i++) {
            uint256 index = i + 1;

            allTokens[i].tokenId = index;
            allTokens[i].royalty = royalties[index];
            allTokens[i].tokenURI = tokenURI(index);
            allTokens[i].owner = ownerOf(index);
            allTokens[i].royaltyReceiver = royaltyReceivers[index];
        }

        return allTokens;
    }
}