// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./ERC721A.sol";
import "./interfaces/IOwnershipable.sol";
import "./ERC721ATokenUriDelegate.sol";
import "./ERC721AOperatorFilter.sol";

contract StudioUnoFrases is ERC721A, ERC2981, Pausable, Ownable, ERC721AOperatorFilter, ERC721ATokenUriDelegate {
    using SignatureChecker for address;
    using Strings for uint256;

    IOwnershipable public palabras;

    string public apiBaseURI;
    string public ipfsBaseURI;

    uint256 public lastIpfsTokenId;

    address public signer;

    address public trustedWallet_A;
    address public trustedWallet_B;

    uint256 public tokenId;

    mapping(uint256 => bool) public claimedPalabrasTokens;

    event FundsTransferred(address _wallet, uint256 _amount);
    event Minted(address _buyer, uint256 _paid, uint256 _tokenId, uint256 _artworkId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(
      address _trustedWallet_A,
      address _trustedWallet_B,        
      address _signer,
      address _palabrasContractAddress
    ) ERC721A("StudioUno Frases", "S1FRASES") {
        trustedWallet_A = _trustedWallet_A;
        trustedWallet_B = _trustedWallet_B;

        lastIpfsTokenId = 0;
        signer = _signer;
        palabras = IOwnershipable(_palabrasContractAddress);

        _pause();
    }

    function mint(address _receiver) internal {
      if(msg.value > 0) {
          payment();
      }

      _safeMint(_receiver, 1);
    }

    function publicMint(
        uint256[] memory _palabrasTokenIds,
        uint256 _artworkId,
        uint256 _mintPrice,
        bytes memory _signature
    ) external payable whenNotPaused {
        require(msg.value >= _mintPrice, "S1: value sent is lower");
        require(verifySignature(_palabrasTokenIds, _artworkId, _mintPrice, _signature), "S1: signature not valid");

        unchecked {
            for (uint i = 0; i < _palabrasTokenIds.length; i++) {
                uint256 _tokenId = _palabrasTokenIds[i];
                require(palabras.ownerOf(_tokenId) == msg.sender, "S1: Not owner");
                require(claimedPalabrasTokens[_tokenId] == false, "S1: Claimed token");
                claimedPalabrasTokens[_tokenId] = true;
            }
            tokenId++;
            mint(msg.sender);
            emit Minted(msg.sender, msg.value, tokenId, _artworkId);
        }
    }

    /// @dev Returns if signature is whitelisted to mint tokens.
    function verifySignature(
        uint256[] memory _palabrasTokenIds,
        uint256 _artworkId,
        uint256 _mintPrice,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_palabrasTokenIds, _artworkId, _mintPrice));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    /// @dev Split value paid for a token
    /// Emits two {FundsTransfered} events.
    function payment() internal {
        uint256 amount = (msg.value * 95) / 100;
        (bool success, ) = trustedWallet_A.call{value: amount}("");
        require(success, "S1: Transfer A failed");
        emit FundsTransferred(trustedWallet_A, amount);

        amount = msg.value - amount;
        (success, ) = trustedWallet_B.call{value: amount}("");
        require(success, "S1: Transfer B failed");
        emit FundsTransferred(trustedWallet_B, amount);
    }

    /// @dev Pause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates address of 'signer'
     * @param _signer  New address for 'signer'
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @dev Updates address of 'trustedWallet_A'
     * @param _trustedWallet  New address for 'trustedWallet_A'
     */
    function setTrustedWallet_A(address _trustedWallet) external onlyOwner {
        trustedWallet_A = _trustedWallet;
    }

    /**
     * @dev Updates address of 'trustedWallet_B'
     * @param _trustedWallet  New address for 'trustedWallet_B'
     */
    function setTrustedWallet_B(address _trustedWallet) external onlyOwner {
        trustedWallet_B = _trustedWallet;
    }

    function setLastIpfsTokenId(uint256 _newLastIpfsTokenId) external onlyOwner {
        lastIpfsTokenId = _newLastIpfsTokenId;
    }

    function setApiBaseURI(string memory _newApiBaseURI) external onlyOwner {
        apiBaseURI = _newApiBaseURI;
    }

    function setIpfsBaseURI(string memory _newIpfsBaseURI) external onlyOwner {
        ipfsBaseURI = _newIpfsBaseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721ATokenUriDelegate, ERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = "";
        if(_tokenId <= lastIpfsTokenId) {
            baseURI = ipfsBaseURI;
        } else {
            baseURI = apiBaseURI;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : '';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            _interfaceId == 0x7f5828d0 ||
            super.supportsInterface(_interfaceId);
    }

    // ERC2981 functions
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 _tokenId) external onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    )
        internal
        virtual
        override(ERC721A, ERC721AOperatorFilter)
    {
        super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
    }
}