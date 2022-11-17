/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc1155/ERC1155Tradable.sol";
import "./VerifySignature.sol";

interface IAntonym {
    function ownerOf(uint256) external returns (address);
}
/**
 * @title Materia
 */
contract Materia is ERC1155Tradable {

    uint256 private constant MAX_MATERIA = 10000-52;
    uint256 private constant MAX_PRIMA_MATERIA = 52;

    uint256 private _end;
    uint256 private _royaltyBasisPoints;

    bool private _allowMinting;

    address private _royaltyAddress;

    address private _signer;
    address private _antonym;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(uint256 => uint256) private _isAntonym1of1Token;
    mapping(uint256 => uint256) public isAntonymTokenUsed;

    modifier canMint() {
        require(_allowMinting, "Minting is Paused");
        require(_end > block.timestamp, "Minting already ended");
        _;
    }

    constructor(
        string memory _name,    
        string memory _symbol,
        string memory _metadataURI,
        uint256 end,
        address signer,
        address antonym,
        uint256[] memory antonym1of1Tokens
    ) ERC1155Tradable(_name, _symbol, _metadataURI) {
        require(signer != address(0), "Wrong signer");
        require(antonym != address(0), "Wrong NFT");
        require(antonym1of1Tokens.length == MAX_PRIMA_MATERIA, "Wrong array size");
        _end = end;
        _signer = signer;
        _antonym = antonym;
        for(uint256 t; t < antonym1of1Tokens.length; t++) {
            _isAntonym1of1Token[antonym1of1Tokens[t]] = 1;
        }

    }

    /// @notice mints tokens and 1of1 tokens
    /// @param tokenIds array of Antonym Token Ids
    /// @param signature signature of Antonym Token Ids array
    // //TODO: fronend, backend: filter for tokens already used
    function mint(
        uint256[] memory tokenIds, 
        bytes memory signature
    ) external canMint {
        address account = _msgSender();
        require(_verifySignature(account, tokenIds, signature), "Wrong Materia Signature");
       
        uint256 tokenIdsLength = tokenIds.length;
        require(tokenIdsLength > 0, "No tokens specified");
        uint256 materiaTokens;
        uint256 primaTokens;

        for(uint256 t; t < tokenIdsLength; t++) {
            uint256 antonymTokenId = tokenIds[t];
            require(isAntonymTokenUsed[antonymTokenId] == 0, "Token already used");
            require(IAntonym(_antonym).ownerOf(antonymTokenId) == account, "Not token owner");
            isAntonymTokenUsed[antonymTokenId] = 1;
            if(_isAntonym1of1Token[antonymTokenId] == 1) primaTokens += 1;
            else materiaTokens += 1;
        }
        if(materiaTokens > 0) {
            require(tokenSupply[1] + materiaTokens <= MAX_MATERIA, "Amount Materia exceeded");
            _mintTokens(account, 1, materiaTokens);
        }
        if(primaTokens > 0) {
            require(_exists(1), "A Materia should be created first");
            require(tokenSupply[2] + primaTokens <= MAX_PRIMA_MATERIA, "Amount Prima Materia exceeded");
            _mintTokens(account, 2, primaTokens);
        }
    }


    function _mintTokens(address to, uint8 tokenId, uint256 quantity) private {
        if (!_exists(tokenId)) {
            _create(to, quantity);
        } else {
            _mint(to, tokenId, quantity);
        }
    }

    function _verifySignature(address account, uint256[] memory tokenIds, bytes memory signature) private view returns (bool) {
        return VerifySignature._verify(_signer, account, tokenIds, signature); 
    }

    function messageHash(address account, uint256[] memory tokenIds) public pure returns (bytes32) {
        return VerifySignature._getMessageHash(account, tokenIds);
    }

    /** OnlyOwner Functions */
    function allowMinting(bool allow) external onlyOwner {
        _allowMinting = allow;
    }

    function setSigner(address signer) external onlyOwner {
        require(signer != address(0), "Wrong signer");
        _signer = signer;
    }

    function setDeadline(uint256 end) external onlyOwner {
        require(end > block.timestamp, "Wrong end deadline");
        _end = end;
    }

    function setRoyaltyAddress(address royaltyAddress) external onlyOwner {
        _royaltyAddress = royaltyAddress;
    }

    function setRoyaltyRate(uint256 royaltyBasisPoints) external onlyOwner {
        _royaltyBasisPoints = royaltyBasisPoints;
    }

    ///@notice mints batches of materia and prima materia after minting deadline is over
    ///@param to the batch tokens receiver
    ///@param amountMateria amount to mint
    ///@param amountPrimaMateria amount of prima materia to mint
    function mintBatchMateria(address to, uint256 amountMateria, uint256 amountPrimaMateria) external onlyOwner {
        require(_allowMinting, "Minting is Paused");
        require(_end < block.timestamp, "Deadline not yet over");
        require(tokenSupply[1] + amountMateria <= MAX_MATERIA, "Amount Materia exceeded");
        require(tokenSupply[2] + amountPrimaMateria <= MAX_PRIMA_MATERIA, "Amount Prima Materia exceeded");

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amountMateria;
        amounts[1] = amountPrimaMateria;

        _batchMint(to, tokenIds, amounts);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "INVALID_TOKENID");
        return (_royaltyAddress, (_salePrice * _royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Tradable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }



    /********************************************* */
}