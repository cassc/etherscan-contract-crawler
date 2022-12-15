//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981.sol";

/// @title Meighta Mint Pass
/// @author La Guilde
/// @notice This contract is used to mint and airdrop MintPass NFTs.
contract MintPass is ERC721AQueryable, Ownable, ERC2981 {

    using SafeMath for uint256;

    //////////////////////////
    //       Variables      //
    //////////////////////////

    /// @notice Define royalty rate (1/1000)
    uint96 public constant ROYALTY_RATE = 500 ;

    /// @notice Define max mintable supply of NFTs.
    uint256 public constant MAX_SUPPLY = 500;

    /// @notice Define URI of metadata api.
    string public BASE_URI = "ipfs://QmPNFGvB9EwaDRG4TMCRqtSiDtii1n3qt2KBoovJ5pUsW1/";

    /// @notice Define address of wallet used for signature verification.
    address private signatureWallet;

    /// @notice Define address of wallet used to secondary treasury funds.
    address payable public royaltyWallet;

    /// @notice Define whether presale is active.
    bool public preMintActive;

    /// @notice Define whether public sale is active.
    bool public openMintActive;

    //////////////////////////
    //        Events        //
    //////////////////////////
    /// @notice Is emitted when the presale is Open
    event PreMintOpen();

    /// @notice Is emitted when the public sale is Open
    event OpenMintOpen();

    //////////////////////////
    //       Modifiers      //
    //////////////////////////
    /// @dev Check whether a user can mint a given quantity.
    /// Quantity + current supply must not exceed total supply.
    /// Quantity + amount minted by user must not exceed maxPerUser.
    modifier canMint() {
        require(
            _numberMinted(msg.sender) == 0, 
            "exceeds per user limit"
        );
        require(
            totalSupply() + 1 <= MAX_SUPPLY, 
            "Exceeds supply"
        );
        _;
    }

    //////////////////////////
    //     Constructor      //
    //////////////////////////
    /// @dev Constructor to deploy contract
    /// @param _signatureWallet, the address of the signer.
    /// @param _royaltyWallet, adress to store the royalties
    constructor(
        address _signatureWallet, 
        address payable _royaltyWallet
    ) ERC721A("Meighta Mint Pass", "MMP") {
        signatureWallet = _signatureWallet;
        royaltyWallet = _royaltyWallet;
        _setDefaultRoyalty(royaltyWallet, ROYALTY_RATE);
    }

    //////////////////////////
    //        External      //
    //////////////////////////
    /// @notice View amount minted by user.
    /// @param _minter, the address of the minter.
    /// @return _minted, a uint256
    function numberMinted(address _minter) external view returns(uint256) {
        return _numberMinted(_minter);
    }

    /// @notice Set the address of the wallet used for signature verification.
    /// @param _signatureWallet, the address used for verification.
    /// @dev   is only accessible to owner of contract.
    function setSignatureWallet(address _signatureWallet) external onlyOwner {
        signatureWallet = _signatureWallet;
    }

    /// @notice Set the address of the wallet used for royalty payments
    /// @param _royaltyWallet, the address to which royalties are sent
    /// @dev   is only accessible to owner of contract.
    function setRoyaltyWallet(address payable _royaltyWallet) external onlyOwner {
        royaltyWallet = _royaltyWallet;
        _setDefaultRoyalty(_royaltyWallet, ROYALTY_RATE);
    }

    /// @notice Set active state of the public sale.
    /// @param _activeState, the bool state of the public sale.
    /// @dev   is only accessible to owner of contract.
    function setOpenMintActiveState(bool _activeState) external onlyOwner {
        openMintActive = _activeState;
        if(openMintActive) {
            emit OpenMintOpen();
        }
    }
    
    /// @notice Set active state of the private sale.
    /// @param _preMintActiveState, the bool state of the private sale.
    /// @dev   is only accessible to owner of contract.
    function setPreMintActiveState(bool _preMintActiveState) external onlyOwner {
        preMintActive = _preMintActiveState;
        if(preMintActive) {
            emit PreMintOpen();
        }
    }

    /// @notice mint NFTs as a whitelisted presale user, only if presale active and sale inactive.
    /// @param _signature, the signature that proves user is whitelisted
    /// @dev can only be run during presale
    function preMint(
        bytes calldata _signature
    ) external canMint() {
        require(preMintActive, "Premint disabled");
        // verify whitelisted signature valid for premint user
        require(_verifySignature(_signature, 0) == signatureWallet, "Not whitelisted");
        // mint
        _mint(1);   
    }

    /// @notice mint NFTs as a whitelisted presale user, only if presale active and sale inactive.
    /// @param _signature, the signature that proves user is whitelisted
    /// @dev can only be run during presale
    function openMint(
        bytes calldata _signature
    ) external canMint() {
        require(openMintActive, "Open mint disabled");
        // verify whitelisted signature valid for openmint user
        require(_verifySignature(_signature, 1) == signatureWallet, "Not openlisted");
        // mint
        _mint(1);   
    }


    //////////////////////////
    //        Public        //
    //////////////////////////
    /// @notice airdrop NFTs to a recipient
    /// @param _recipient, the wallet address to mint NFTs to
    /// @param _quantity, the amount of NFTs to mint
    /// @dev is only accessible to owner of contract
    function airDrop(address _recipient, uint256 _quantity) public onlyOwner {
        // check that will not exceed supply
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds supply");
        // call safemint as we don"t need to keep track of how many were minted
        _safeMint(_recipient, _quantity);
    }

    /// @notice Return the URI of a token
    /// @param _tokenId, the id of the token whose URI we want 
    /// @return tokenURI, a string,
    ///         concatenated from baseURI and tokenID
    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721Metadata) returns(string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json"));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override (
        ERC2981, ERC721A, IERC165
    ) returns (bool) {
        return 
            ERC2981.supportsInterface(interfaceId) || 
            ERC721A.supportsInterface(interfaceId);
    }

    //////////////////////////
    //        Internal      //
    //////////////////////////
    /// @param _quantity, the amount of NFTs to mint
    /// @dev SafeMint quantity to sender of transaction
    function _mint(uint256 _quantity) internal {
        _safeMint(msg.sender, _quantity);
    }

    /// @param _signature, the encoded byte that ensures wallet belongs to proper list
    /// @param _mintType, a uin256 that defines which list the wallet should belong to:
    ///        0 for a presale wallet,
    ///        1 for an open wallet
    /// @return signatureAddress, the address that encrypted the signature, to be compared
    ///         with the signatureWallet.
    function _verifySignature(
        bytes memory _signature, 
        uint256 _mintType
    ) internal view returns(address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(
                    msg.sender,
                    address(this),
                    _mintType
                )
            )
        ), _signature);
    }
}