// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICryptoPunksMarket.sol";
import "./DelegationRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title InscriptionRegistry v1.1
 * @author Arkaydeus
 * @notice A registry of ETH NFT inscriptions on ordinals
 * This registry stores a record of BTC inscriptions that ETH tokenholders
 * have authorised in relation to their tokens.
 * Please visit https://app.bitcoll.org/collect/ethbtcmint for more information.
 */

contract InscriptionRegistry is Ownable {
    /// @notice Mapping from token to inscription Id
    mapping(address => mapping(uint256 => string)) public inscriptionByToken;

    /// @notice Mapping from token id to registrant address
    mapping(address => mapping(uint256 => address)) public addressByToken;

    /// @notice CrypptoPunksMarket contract address
    address public punkContractAddress;

    /// @notice Delegate.Cash contract address
    address public delegateCashAddress;

    /// @notice Emitted when a user sets an inscription
    event SetInscription(
        uint256 indexed tokenId,
        address indexed contractAddress,
        string inscription,
        address indexed registrant
    );

    constructor(address _punkContractAddress, address _delegateCashAddress) {
        punkContractAddress = _punkContractAddress;
        delegateCashAddress = _delegateCashAddress;
    }

    /// @notice Sets an inscription for a token id and contract address
    /// @notice Private function to be called by other functions
    /// @param _tokenId The token id
    /// @param _contractAddress The contract address for the NFT
    /// @param _inscription The inscription id to set
    function setInscription(
        uint256 _tokenId,
        address _contractAddress,
        string memory _inscription
    ) private {
        require(
            bytes(inscriptionByToken[_contractAddress][_tokenId]).length == 0,
            "Inscription already set"
        );

        inscriptionByToken[_contractAddress][_tokenId] = _inscription;
        addressByToken[_contractAddress][_tokenId] = msg.sender;

        emit SetInscription(
            _tokenId,
            _contractAddress,
            _inscription,
            msg.sender
        );
    }

    /// @notice Sets an inscription where the sender owns an ERC721
    /// @param _tokenId The token id
    /// @param _contractAddress The contract address for the NFT
    /// @param _inscription The inscription id to set
    function setInscriptionWithToken(
        uint256 _tokenId,
        address _contractAddress,
        string memory _inscription
    ) external {
        if (_contractAddress == punkContractAddress) {
            require(
                isWithPunk(_tokenId, msg.sender),
                "Punk not owned by sender"
            );
        } else {
            require(
                isWithERC721(_tokenId, _contractAddress, msg.sender),
                "Token not owned by sender"
            );
        }

        setInscription(_tokenId, _contractAddress, _inscription);
    }

    /// @notice Sets an inscription where the sender has a token delegated
    /// @param _tokenId The token id
    /// @param _contractAddress The contract address for the NFT
    /// @param _inscription The inscription id to set
    /// @param _tokenHolderAddress The address with the token in
    function setInscriptionWithDelegation(
        uint256 _tokenId,
        address _contractAddress,
        string memory _inscription,
        address _tokenHolderAddress
    ) external {
        if (_contractAddress == punkContractAddress) {
            require(
                isWithPunk(_tokenId, _tokenHolderAddress),
                "Punk not owned by address"
            );
        } else {
            require(
                isWithERC721(_tokenId, _contractAddress, _tokenHolderAddress),
                "Token not owned by address"
            );
        }

        require(
            isWithDelegation(_tokenId, _contractAddress, _tokenHolderAddress),
            "Token not delegated to sender"
        );

        setInscription(_tokenId, _contractAddress, _inscription);
    }

    /// @notice Checks if a punk is owned by a given address
    /// @param _tokenId The token id
    /// @param _punkHolderAddress The address to check
    function isWithPunk(uint256 _tokenId, address _punkHolderAddress)
        private
        view
        returns (bool)
    {
        return
            ICryptoPunksMarket(punkContractAddress).punkIndexToAddress(
                _tokenId
            ) == _punkHolderAddress;
    }

    /// @notice Checks if an ERC721 is owned by a given address
    /// @param _tokenId The token id
    /// @param _contractAddress The contract address for the NFT
    /// @param _tokenHolderAddress The address to check
    function isWithERC721(
        uint256 _tokenId,
        address _contractAddress,
        address _tokenHolderAddress
    ) private view returns (bool) {
        return
            IERC721(_contractAddress).ownerOf(_tokenId) == _tokenHolderAddress;
    }

    /// @notice Checks if a token is delegated to a given address
    /// @param _tokenId The token id
    /// @param _contractAddress The contract address for the NFT
    /// @param _tokenHolderAddress The address to check
    function isWithDelegation(
        uint256 _tokenId,
        address _contractAddress,
        address _tokenHolderAddress
    ) private view returns (bool) {
        return
            IDelegationRegistry(delegateCashAddress).checkDelegateForToken(
                msg.sender,
                _tokenHolderAddress,
                _contractAddress,
                _tokenId
            );
    }
}