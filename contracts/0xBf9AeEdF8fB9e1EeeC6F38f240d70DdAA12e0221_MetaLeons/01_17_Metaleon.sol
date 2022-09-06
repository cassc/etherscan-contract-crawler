//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981.sol";

/// @title MetaLeons NFT
/// @author La Guilde
/// @notice This contract is used to mint and airdrop NFTs as well as freeze Metadata.
contract MetaLeons is ERC721AQueryable, Ownable, ERC2981 {

    using SafeMath for uint256;

    //////////////////////////
    //       Variables      //
    //////////////////////////

    /// @notice Define royalty rate (1/1000)
    uint96 public constant ROYALTY_RATE = 600 ;
    
    /// @notice Define required price for public sale mint.
    uint256 public mintPrice = 0.095 ether;

    /// @notice Define required price for presale mint.
    uint256 public presaleMintPrice = 0.09 ether;

    /// @notice Define required price for Investor mint.
    uint256 public investorMintPrice = 0.08 ether;

    /// @notice Define max mintable nfts for normal user.
    uint256 public maxPerUser = 5;

    /// @notice Define max mintable nfts for WL user.
    uint256 public maxPerWhitelisted = 8;

    /// @notice Define max mintable nfts for investor users.
    uint256 public maxPerInvestor = 22;

    /// @notice Define amount of NFTs at which a user gets gifted a free NFT.
    uint256 public giftThreshold = 10;

    /// @notice Defines max amount of figted NFTs
    uint256 public maxGifted = 2;

    /// @notice Define max mintable supply of NFTs.
    uint256 public maxSupply = 5000;

    /// @notice Define URI of metadata api.
    string public baseURI = "https://api.metaleonsociety.io/api/v1/nfts/";

    /// @notice Define address of wallet used for signature verification.
    address public signatureWallet;

    /// @notice Define address of wallet used to withdraw treasury funds.
    address payable public withdrawalWallet;

    /// @notice Define address of wallet used to secondary treasury funds.
    address payable public secondaryWallet;

    /// @notice Define address of wallet used for payouts/
    address payable public paymentSplitter;

    /// @dev Associate tokenID to whether it has been frozen.
    mapping (uint256 => bool) frozenTokens;

    /// @notice Associate tokenID to unique tokenURI (decentralised).
    mapping (uint256 => string) tokenURIs;

    /// @notice Define whether presale is active.
    bool public presaleActive;

    /// @notice Define whether public sale is active.
    bool public saleActive;

    //////////////////////////
    //        Events        //
    //////////////////////////
    /// @notice Is emitted when an NFT URI is frozen, returns tokenId and frozen URI.
    /// @return tokenId, a uint256.
    /// @return tokenURI, a string.
    event Frozen(uint256 tokenId, string tokenURI);

    /// @notice Is emitted when an NFT URI is unfrozen.
    /// @return tokenId, a uint256.
    event UnFrozen(uint256 tokenId);

    /// @notice Is emitted when the presale is Open
    event PresaleOpen();

    /// @notice Is emitted when the public sale is Open
    event PublicSaleOpen();

    //////////////////////////
    //       Modifiers      //
    //////////////////////////
    /// @dev Check whether tokenId belongs to msg.sender.
    /// @param _tokenId, the id of the NFT.
    modifier isOwnerOrApproved(uint256 _tokenId) {
        require(
            msg.sender == ownerOf(_tokenId) ||
            isApprovedForAll(ownerOf(_tokenId), msg.sender) ||
            getApproved(_tokenId) == msg.sender,
            "Not your NFT"
        );
        _;
    }

    /// @dev Check whether a user can mint a given quantity.
    /// Quantity + current supply must not exceed total supply.
    /// Quantity + amount minted by user must not exceed maxPerUser.
    /// @param _quantity, the amount of NFTs to mint.
    modifier canMint(uint256 _quantity, uint256 max) {
        require(
            _numberMinted(msg.sender) + _quantity <= max, 
            "exceeds per user limit"
        );
        require(
            totalSupply() + _quantity <= maxSupply, 
            "Exceeds supply"
        );
        _;
    }

    /// @dev Check whether the presale is active and public sale is inactive.
    ///       Applys to InvestorMint and presaleMint.
    modifier presaleOnly {
        require(presaleActive && !saleActive, 'Presale disabled');
        _;
    }

    /// @dev Ensure values for giftThreshold and maxGifted are coherent with maxPerInvestor.
    ///      The last gift threshold must be less or equal to the max per investor minus
    ///      the amount of tokens gifted.
    ///      For example for:
    ///      - maxPerInvestor = 10
    ///      - giftThreshold = 5
    ///      - maxGifted = 2
    ///      2 * 5 > 8: I can never reach the second gift threshold as it would exceed
    ///      maxPerInvestor.
    ///      But for:
    ///     - maxPerInvestor = 24
    ///     - giftThreshold = 5
    ///     - maxGifted = 4
    ///     4 * 5 <= 24: I can give a free gift every 5 and remain <= maxPerInvestor limit of
    ///     24
    modifier coherentValuesForInvestor (
        uint256 _maxPerInvestor, 
        uint256 _maxGifted, 
        uint256 _giftThreshold
    ) {
        require(
            _maxGifted * _giftThreshold <= _maxPerInvestor - _maxGifted,
            "Improper values for investor settings"
        );
        _;
    }

    //////////////////////////
    //     Constructor      //
    //////////////////////////
    /// @dev We could define more things in the constructor, remains to be defined.
    constructor(
        address _signatureWallet, 
        address payable _withdrawalWallet,
        address payable _paymentSplitter,
        address payable _secondaryWallet
    ) ERC721A("Metaleons", "MLS") {
        signatureWallet = _signatureWallet;
        withdrawalWallet = _withdrawalWallet;
        paymentSplitter = _paymentSplitter;
        secondaryWallet = _secondaryWallet;

        _setDefaultRoyalty(secondaryWallet, ROYALTY_RATE);
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

    /// @notice View amount gifted to user.
    /// @param _minter, the address of the minter.
    /// @return _gifted, a uint256
    function numberGifted(address _minter) external view returns(uint256) {
        return uint256(_getAux(_minter));
    }

    /// @notice Set the address of the withdrawal wallet.
    /// @param _withdrawalWallet, the payable address to withdraw treasury funds to.
    /// @dev   is only accessible to owner of contract.
    function setWithdrawalWallet(address payable _withdrawalWallet) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
    }

    /// @notice Set the address of the payout wallet.
    /// @param _paymentSplitter, the payable address to withdraw payout funds to.
    /// @dev   is only accessible to owner of contract.
    function setPaymentSplitter(address payable _paymentSplitter) external onlyOwner {
        paymentSplitter = _paymentSplitter;
    }

    /// @notice Set the address of the wallet used for signature verification.
    /// @param _signatureWallet, the address used for verification.
    /// @dev   is only accessible to owner of contract.
    function setSignatureWallet(address _signatureWallet) external onlyOwner {
        signatureWallet = _signatureWallet;
    }

    /// @notice Set the address of the wallet used for royalty payments
    /// @param _secondaryWallet, the address to which royalties are sent
    /// @dev   is only accessible to owner of contract.
    function setRoyaltyWallet(address payable _secondaryWallet) external onlyOwner {
        secondaryWallet = _secondaryWallet;
        _setDefaultRoyalty(_secondaryWallet, ROYALTY_RATE);
    }

    /// @notice Set active state of the public sale.
    /// @param _activeState, the bool state of the public sale.
    /// @dev   is only accessible to owner of contract.
    function setSaleActiveState(bool _activeState) external onlyOwner {
        saleActive = _activeState;
        if(saleActive) {
            emit PublicSaleOpen();
        }
    }
    
    /// @notice Set active state of the private sale.
    /// @param _presaleActiveState, the bool state of the private sale.
    /// @dev   is only accessible to owner of contract.
    function setPresaleActiveState(bool _presaleActiveState) external onlyOwner {
        presaleActive = _presaleActiveState;
        if(presaleActive) {
            emit PresaleOpen();
        }
    }

    /// @notice Set public sale mint price.
    /// @param _mintPrice, the price in ethers of an NFT for a regular user.
    /// @dev included as last resort, might need to be removed,
    ///      is only accessible to owner of contract.
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Set private sale mint price.
    /// @param _presaleMintPrice, the price in ethers of an NFT for a presale user.
    /// @dev refer to dev comment on setMintPrice,
    ///      is only accessible to owner of contract.
    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyOwner {
        presaleMintPrice = _presaleMintPrice;
    }

    /// @notice Set investor mint price.
    /// @param _investorMintPrice, the price in ethers of an NFT for an investor user.
    /// @dev refer to dev comment on setMintPrice,
    ///      is only accessible to owner of contract.
    function setInvestorMintPrice(uint256 _investorMintPrice) external onlyOwner {
        investorMintPrice = _investorMintPrice;
    }

    /// @notice Set max mintable NFTs per wallet address.
    /// @param _quantity, the quantity of NFTs that can be minted by a wallet.
    function setMaxPerUser(uint256 _quantity) external onlyOwner {
        maxPerUser = _quantity;
    }

    /// @notice Set max mintable NFTs per wallet address.
    /// @param _quantity, the quantity of NFTs that can be minted by a wallet.
    function setMaxPerWhitelisted(uint256 _quantity) external onlyOwner {
        maxPerWhitelisted = _quantity;
    }

    /// @notice Set max mintable NFTs per investor.
    /// @param _quantity, the quantity of NFTs that can be minted by an investor wallet.
    /// @dev must be coherent with max gifted and gift threshold,
    ///      is only accessible to owner of contract.
    function setMaxPerInvestor(
        uint256 _quantity
    ) external coherentValuesForInvestor(
        _quantity,
        maxGifted,
        giftThreshold
    ) onlyOwner {
        maxPerInvestor = _quantity;
    }

    /// @notice Set threshold at which free NFT is minted.
    /// @param _quantity, the threshold at which a free NFT is minted.
    /// @dev must be coherent with max gifted and gift threshold,
    ///      is only accessible to owner of contract.
    function setGiftThreshold(
        uint256 _quantity
    ) external coherentValuesForInvestor(
        maxPerInvestor,
        maxGifted,
        _quantity
    ) onlyOwner {
        giftThreshold = _quantity;
    }

    /// @notice Set max giftable NFTs.
    /// @param _quantity, the number of times NFTs will be minted when threshold is hit
    /// @dev must be coherent with max gifted and gift threshold,
    ///      is only accessible to owner of contract.
    function setMaxGifted(
        uint256 _quantity
    ) external coherentValuesForInvestor(
        maxPerInvestor,
        _quantity,
        giftThreshold
    ) onlyOwner {
        maxGifted = _quantity;
    }

    /// @notice Set the URI of the metadata api.
    /// @param _baseURI, the URI of the metadata api.
    /// @dev must end with '/' for proper concatenation,
    ///      is only accessible to owner of contract.
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice mint NFTs as a whitelisted presale user, only if presale active and sale inactive.
    /// @param _quantity, the amount of NFTs to mint
    /// @param _signature, the signature that proves user is whitelisted
    /// @dev can only be run during presale
    function presaleMint(
        uint256 _quantity, 
        bytes calldata _signature
    ) external payable canMint(_quantity, maxPerWhitelisted) presaleOnly {
        // check that sent value matches presale price
        require(msg.value >= presaleMintPrice * _quantity, "Not enough money");
        // verify whitelisted signature valid for presale user
        require(_verifySignature(_signature, 0) == signatureWallet, "Not whitelisted");
        // mint
        _mint(_quantity);   
    }

    /// @notice mint NFTs as a investor user, only if presale active and sale inactive,
    ///         gifts a free NFT if giftThreshold has been met,
    ///         saves that gifted NFT has been delivered to user
    /// @param _quantity, the amount of NFTs to mint
    /// @param _signature, the signature that proves user is investor
    /// @dev can only be run during presale,
    ///      the supply verifications are down after the NFT is gifted for better efficency
    function investorMint(
        uint256 _quantity,
        bytes calldata _signature
    ) external payable presaleOnly {
        // check that value matches investor price
        require(msg.value >= investorMintPrice * _quantity, "Not enough money");
        // verify that signature is valid for Investor user
        require(_verifySignature(_signature, 1) == signatureWallet, "Not investor");
        // how many minted by user
        uint256 _minted = _numberMinted(msg.sender);
         // get _userGifted
        uint256 _userGifted = uint256(_getAux(msg.sender));
        // how many actually paid by user
        uint256 _realMinted = _minted - _userGifted;
        // instantiate _toGift at 0
        uint256 _toGift;
        // gift free mints if thresholds exceeded
        for(uint i =_userGifted; i < maxGifted; i++) {
            if(_realMinted + _quantity >= (i + 1) * giftThreshold) {
                _toGift += 1;
            }
        }
        // add gifts to quantity
        _quantity += _toGift;
        // ensures _quantity does not exceed maxSupply and maxPerInvestor and max gifted
        require(_minted + _quantity <= maxPerInvestor, "exceeds per investor limit");
        require(totalSupply() + _quantity <= maxSupply, "Exceeds supply");
        require(_userGifted + _toGift <= maxGifted, "Exceeds max gifts");
        // gift free and trigger event
        _setAux(msg.sender, uint64(_userGifted + _toGift));
        // mint quantity
        _mint(_quantity);
    }

    /// @notice mint NFTs as a regular user, only when publicSale is active
    /// @param _quantity, the amount of NFTs to mint
    /// @dev can only be run during public sale
    function publicMint(uint256 _quantity) external payable canMint(_quantity, maxPerUser) {
        // check user minting and not CA
        require(tx.origin == msg.sender, "No bots alloweds");
        // check that public sale is active
        require(saleActive, "Sale disabled");
        // check that amount sent matches public price
        require(msg.value >= mintPrice * _quantity, "Not enough money");
        // mint quantity
        _mint(_quantity);
    }

    /// @notice airdrop NFTs to multiple recipients
    /// @param _recipients, the wallet address to mint NFTs to
    /// @param _quantities, the amount of NFTs to mint
    /// @dev is only accessible to owner of contract
    function airDropMultiple(
        address[] calldata _recipients, 
        uint256[] calldata _quantities
    ) external onlyOwner {
        require(_recipients.length == _quantities.length, "invalid array sizes");
        for(uint i = 0; i < _recipients.length; i++) {
            airDrop(_recipients[i], _quantities[i]);
        }
    }

    /// @notice Split funds 80/20 and transfer first to treasury wallet and second to
    ///         payout wallet.
    /// @dev is only accessible to owner of contract,
    ///      unsure whether it is necessary to make it nonReentrant.
    function withdrawAll() external onlyOwner {
        // treasury wallet receives 80% of funds
        uint256 commonTreasuryAmount = address(this).balance * 80 / 100;
        // payout wallet receives 20% of funds
        uint256 splitPaymentAmount = address(this).balance * 20 / 100;
        // call transfer function on both wallets
        (bool success, ) = withdrawalWallet.call{
            value: commonTreasuryAmount
        }("");
        (bool complete, ) = paymentSplitter.call{
            value: splitPaymentAmount
        }("");
        // revert if either transfer failed
        require(success && complete, 'Failed to send funds');
    }

    /// @notice Assign a unique URI to holders' NFT and define it as frozen
    /// @param _tokenId, the id of the token whose URI we want to freeze
    /// @param _tokenURI, the URI we wwant to assign to the NFT
    /// @param _signature, the signature that ensures validity of the URI for this token
    /// @dev Is only accessible to owner of token, URI must be valid as per checked 
    ///      with signature,
    ///      genTime is used to ensure signature only valid for URIValidFor
    function freezeMetadata(
        uint256 _tokenId, 
        string calldata _tokenURI,
        bytes calldata _signature,
        uint256 _validTime
    ) external isOwnerOrApproved(_tokenId) {
        require(
            _validTime >= block.timestamp,
            "URI expired"
        );
        require(
            _verifySignatureForURI(_signature, _tokenId, _tokenURI, _validTime) == signatureWallet,
            "Invalid URI"
        );
        // assign frozen true to NFT id in mapping of frozen NFTs.
        frozenTokens[_tokenId] = true;
        // assign URI to tokenId in mapping of URIs.
        tokenURIs[_tokenId] =  _tokenURI;
        // emit Frozen event
        emit Frozen(_tokenId, _tokenURI);
    }

    /// @notice Unfreeze the tokenURI of an NFT
    /// @dev Is only accessible to owner of token
    function unfreezeMetadata(uint256 _tokenId) external isOwnerOrApproved(_tokenId) {
        // assign frozen false to NFT in mapping of frozen NFTs.
        frozenTokens[_tokenId] = false;
        // meit UnFrozen event.
        emit UnFrozen(_tokenId);
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
        require(totalSupply() + _quantity <= maxSupply, "Exceeds supply");
        // call safemint as we don't need to keep track of how many were minted
        _safeMint(_recipient, _quantity);
    }

    /// @notice Return the URI of a token
    /// @param _tokenId, the id of the token whose URI we want 
    /// @return tokenURI, a string,
    ///         concatenated from baseURI and tokenID if metadata not frozen,
    ///         from tokenURIs mapping otherwise
    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721Metadata) returns(string memory) {
        // Ensure token has been minted and not burnt.
        require(_exists(_tokenId), "token does not exist");
        // Return URI from mapping if token frozen.
        if (frozenTokens[_tokenId]) {
            return tokenURIs[_tokenId];
        }
        // Return concatenated from baseURI and tokenId otherwise.
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
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
    ///        1 for an investor wallet
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

    /// @param _signature, the encoded byte that ensures wallet belongs to proper list
    /// @param _tokenId, the tokenID for which we want to assign a new URI
    /// @param _URI, the decentralised URI to be assigned to the NFT
    /// @param _validTime, the time of generation of the URI
    /// @return signatureAddress, the address that encrypted the signature, to be compared
    ///         with the signatureWallet.
    /// @dev We use the genTime to prevent reuse of signatures to backtrack metadata
    function _verifySignatureForURI(
        bytes memory _signature, 
        uint256 _tokenId,
        string memory _URI,
        uint256 _validTime
    ) internal view returns(address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(
                    address(this),
                    _tokenId,
                    _URI,
                    _validTime
                )
            )
        ), _signature);
    }
}