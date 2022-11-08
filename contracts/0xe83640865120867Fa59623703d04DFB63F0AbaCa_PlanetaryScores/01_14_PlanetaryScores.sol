// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: Planetary Scores™ Smart Contract using ERC721A.
/// @author: @madebymozart | madebymozart.eth

/// Local Imports
import "./IPlanetaryScores.sol";
import "./PlanetaryTokenVerifier.sol";

/// Npm Imports
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
         ':;;;;;;;;;;;;;;;;;;;;;;;;,,'....                                      ..,;clodxxxkkxxxxxdddolcc;,..           
        'kKKKKKKKKKKKKKKKKKKKKKKKKKKK000Okdoc;'.                            .;cdk0KKKKKKKKKKKKKKKKKKKKKKKKK0Oxl;.       
        ;OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Odc,.                     .cdOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOd:.    
        lKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kc.                .;d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKKKOo,  
       .dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOl.             ;xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc. 
       'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKx'          .o0KKKKKKKKKKKKKKKKXXKKKXKKKKXKKKKKKKKKKKKKKKKKOl.   
       :0KKKKKKKKKK0xllllllllllooodxkO0KKKKKKKKKKKKKKKKKx.        .xKKKKKKKKKKKKKK0xdlcc::::::cclodkOKKKKKKKKKKKOl.     
      .lKKKKKKKKKKKk'               ...,cdOKKKKKKKKKKKKK0l       .dKKKKKKKKKKKK0d;..                .,lk0KKKKK0o'       
      .xKKKKKKKKKKKd.                     .o0KKKKKKKKKKKKx.      ;0XKKKKKKKKKKO:                       .'clool'         
      ,OKKKKKKKKKK0c                       .oKKKKKKKKKKKKx.      lKKKKKKKKKKKKo.                                        
      c0KKKKKKKKKKO,                        lKKKKKKKKKKKKd.     .oKKKKKKKKKKKKk:.                                       
     .oKKKKKKKKKKKx.                       .xKKKKKKKKKKK0c       :0KKKKKKKKKKKK0kdl:;'...                               
     .xKKKKKKKKKKKo.                      'dKKKKKKKKKKKKk'       .oKKKKKKKKKKKKKKKKKKK0Okxdolc:;,'...                   
     ;OKKKKKKKKKK0:                    .;oOKKKKKKKKKKKKO:         .l0KKKKKKXKKKKKKKKKKKKKKKKKKKKKK0Okxoc:,..            
     cKKKKKKKKKKKO:.............'',:coxOKKKKKKKKKKKKKKO:            'lkKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXKKKK0ko:'.        
    .dKKKKKKKKKKKKOOOOOOOOOOOO000KKKKKKKKKKKKKKKKKKKKx,               .,cdO0KXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kl'      
    'kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkc.                    ..;:loxkO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o.    
    ;0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0x:.                             ...',;:clodxkO0KKKXKKKKKKKKKKKKKKKk,   
    lKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOdc'.                                           ...';:ldOKKKKKKKKKKKKKKx'  
   .dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Oxoc,.                                                       .;d0KKKKKKKKKKK0c  
   ,OKKKKKKKKKKK0OOOOOOOOOOOkkkxxdolc:,'.                                                              .oKKKKKKKKKKKKo. 
   :0KKKKKKKKKKO:..............                                                                         lKKKKKKKKKKKKl  
  .oKKKKKKKKKKKx.                                                  .,;;'.                             .cOKKKKKKKKKKX0;  
  .xKKKKKKKKKKKo.                                                .;xKKK0Odc,..                     .,lkKKKKKKKKKKKKKo.  
  ,OKKKKKKKKKK0:                                               .;xKKKKKKKKKK0kdlc:;,''.......',;cldOKKKKKKKKKKKKKKKd.   
  c0KKKKKKKKKKO,                                             .,d0KKKKKKKKKKKKKKKKKKKK000000000KKKKKKKKKKKKKKKKKKKOc.    
 .oKKKKKKKKKKKd.                                           ,cd0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o'      
 'kKKKKKKKKKKKl                                           .lxOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOl'        
 ;OKKKKKKKKKK0;                                              .:dOKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKko;.          
 lKKKKKKKKKKKk'                                                 .,cdk0KKXKKKKKKKKKKKKKKKKKKKKKKKKKKKK0ko:,.             
 ;ooooooooooo:.                                                     ..,:codxkkO00000KKKKKKKK00Okxol:,..                 
                                                                             .....'''''','''....                                                                                                                         
 */
contract PlanetaryScores is
    IPlanetaryScores,
    PlanetaryTokenVerifier,
    ERC721A,
    ERC2981,
    Ownable
{
    /// @dev States that dictate the minting a token from this colleciton.
    enum MintStates {
        EARLY_DISCORVEY,
        GENERAL,
        OWNER,
        CLOSED
    }

    /// @dev Event for client site to receive notice of a mint.
    event TokensMinted(
        address indexed receiver,
        uint256 tokenId,
        uint256 quantity
    );

    /// @dev Amount of tokens reserved for the owner.
    uint256 public constant PS_RESERVED_TOKENS = 14;

    /// @dev Maximum amount of tokens that an address is allowed to mint.
    uint256 public constant PS_WALLET_MINT_MAX = 3;

    /// @dev Total supply of tokens minable in this contract.
    uint256 public constant PS_MAX_SUPPLY = 254;

    /// @dev Cost to mint a token from this contract when
    uint256 public constant PS_MINT_COST = 0.25 ether;

    MintStates private _mintState;
    bool private _assetsLocked = true;
    string private _placeholderUri;
    string private _baseTokenUri;

    /// @notice constructor.
    ///
    /// @param _name Name of the project.
    /// @param _symbol The Symbol of this project.
    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
        PlanetaryTokenVerifier(address(0))
    {
        /// @dev 10% royalty fee on all token via ERC2981
        _setDefaultRoyalty(owner(), 1000);

        /// @dev Mint reserved tokens for te owner.
        _mintERC2309(owner(), PS_RESERVED_TOKENS);

        /// @dev Contract starts off with a closed mint state.
        _mintState = MintStates.CLOSED;
    }

    /// @notice Pre-requisites for minting a token.
    /// @param _quantity The quantity of tokens to be minted.
    modifier mintsPreCheck(uint256 _quantity) {
        if (_msgSenderERC721A() != tx.origin) revert NonEOA();
        if (_totalMinted() + _quantity > PS_MAX_SUPPLY) revert SupplyExceeded();
        if (_numberMinted(_msgSenderERC721A()) + _quantity > PS_WALLET_MINT_MAX)
            revert WalletLimitExceeded();
        if (msg.value < PS_MINT_COST * _quantity) revert NotEnoughFunds();
        _;
    }

    /// @notice Mints 1 token for an early discovery minter.
    /// @param _salt random salt used to generate signature
    /// @param _token Generated token needed for validation
    /// @dev When this is called, we also check if the calling address is
    //       able to mint via thier address and token provided. Once a user
    //       is verified, we use the aux to acknowledge that the caller has
    //       claimed and early discovery token.
    function earlyDiscoveryMint(string calldata _salt, bytes calldata _token)
        external
        payable
        mintsPreCheck(1)
    {
        if (_msgSenderERC721A() != tx.origin) revert NonEOA();
        if (_mintState != MintStates.EARLY_DISCORVEY) revert InvalidMintState();
        if (_getAux(msg.sender) != 0) revert EarlyDiscoveryTokenClaimed();
        if (!_verifyTokenForAddress(_salt, _token, _msgSenderERC721A()))
            revert InvalidToken();

        _setAux(_msgSenderERC721A(), 1);
        _mint(_msgSenderERC721A(), 1);
        emit TokensMinted(_msgSenderERC721A(), _totalMinted(), 1);
    }

    /// @notice Mints A number of tokens based on the amount given.
    /// @param _quantity The _quantity of tokens to be minted.
    function generalMint(uint256 _quantity)
        public
        payable
        mintsPreCheck(_quantity)
    {
        if (_mintState != MintStates.GENERAL) revert InvalidMintState();
        _mint(_msgSenderERC721A(), _quantity);
        emit TokensMinted(_msgSenderERC721A(), _totalMinted(), _quantity);
    }

    /// @notice Overrides and retrieves the unlocked base uri.
    function _baseURI() internal view virtual override returns (string memory) {
        return _assetsLocked ? _placeholderUri : _baseTokenUri;
    }

    /// @notice Overrides the start token id from 0 to 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Returns true if this contract supports a specific interface.
    /// @param _interfaceId given interface to check.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(_interfaceId) ||
            ERC721A.supportsInterface(_interfaceId);
    }

    /// @notice Provides the tokenURI from this contract for the given token.
    ///         The owner has the ability to change the base URI and placeholder
    ///         URI in-case of any issues to fixes on assets.
    /// @param _id Token id for constructing the Uri.
    /// @return A constructed URL
    function tokenURI(uint256 _id)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (_assetsLocked) return _placeholderUri;
        return ERC721A.tokenURI(_id);
    }

    /// @notice Gets the `mintState` value.
    function getAssetLockedState() external view returns (bool) {
        return _assetsLocked;
    }

    /// @notice Gets the `mintState` value.
    function getMintState() external view returns (MintStates) {
        return _mintState;
    }

    /// @notice Sets the base uri for this contract.
    function setBaseUri(string calldata _uri) external onlyOwner {
        _baseTokenUri = _uri;
    }

    /// @notice Sets the placeholder uri for this contract.
    function setPlaceholderUri(string calldata _uri) external onlyOwner {
        _placeholderUri = _uri;
    }

    /// @notice Sets a new signer for early discovery mints.
    /// @param _newSigner Newly desired `_signer` value.
    function setSigner(address _newSigner) external onlyOwner {
        _setSigner(_newSigner);
    }

    /// @notice Function used to change the current `mintState` value.
    /// @param _state The new `mintState` value.
    /// @dev 0 = EARLY_DISCORVEY
    ///      1 = GENERAL
    ///      2 = CLOSED
    function setMintState(uint256 _state) external onlyOwner {
        if (_state > uint256(MintStates.CLOSED)) revert InvalidMintState();
        _mintState = MintStates(_state);
    }

    /// @notice Allows the owner to mint token for an address.
    function ownerMint(address _receiver, uint256 _quantity)
        external
        onlyOwner
    {
        if (_totalMinted() + _quantity > PS_MAX_SUPPLY) revert SupplyExceeded();
        _mint(_receiver, _quantity);
        emit TokensMinted(_receiver, _totalMinted(), _quantity);
    }

    /// @notice Unlocks the contract assets for token owners to view the provided
    ///         assets with the token.
    function lockUnlockAssets() external onlyOwner {
        _assetsLocked = !_assetsLocked;
    }

    /// @notice Transfer the ownership of this contract to another address. This
    ///         Will also assure all the royalties go to this new owner.
    function transferOwnership(address _address)
        public
        virtual
        override(Ownable)
        onlyOwner
    {
        _setDefaultRoyalty(_address, 1000);
        super.transferOwnership(_address);
    }

    /// @notice Withdraws all of the eth on this contract to the callers wallet.
    function withdrawContractEth() external onlyOwner {
        (bool success, ) = _msgSenderERC721A().call{
            value: address(this).balance
        }("");
        if (!success) revert EtherWithdrawFailed();
    }
}