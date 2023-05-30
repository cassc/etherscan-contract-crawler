// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Full.sol";
import "./MarsGenesisAuction.sol";
import "./MarsGenesisWallet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title MarsGenesis main ERC721 contract
/// @author MarsGenesis
/// @notice Encapsulates the ERC721 methods and main features of MarsGenesis
contract MarsGenesisCore is ERC721Full {

    using Counters for Counters.Counter;

    /// @dev Maximum number of public minted lands
    uint16 private constant MAX_LANDS = 10000;

    /// @dev Maximum number of promotinal lands (400 from the v1 migration, 100 for marketing purposes)
    uint16 private constant MAX_PROMO_LANDS = 500;

    /// @dev Interface for auction contract
    bytes4 private constant InterfaceSignature_MarsGenesisAuction =
            bytes4(keccak256('landIdIsForSale(uint256 tokenId)')) ^
            bytes4(keccak256('landNoLongerForSale(uint256)'));

    Counters.Counter private _promoTokenIdTracker;
    Counters.Counter private _tokenIdTracker;

    /// @dev Address of the deployer account
    address private _deployerAddress;

    /// @dev Auction contract address
    MarsGenesisAuction public auctionContract;

    /// @dev Auction contract address
    MarsGenesisWallet private _walletContract;
    

    /*** EVENTS ***/

    /// @dev The Discovery event is fired whenever a new land comes into existence.
    event Discovery(address _owner, uint256 _tokenId, string _tokenURI, uint256 _cardId);
    
    
    /*** LANDS ***/

    /// @dev The main Land struct.
    struct Land {      
        string topLeftLatLong;
        string bottomRightLatLong;
        string metadataURI;
    }

    /// @dev An array containing the Land struct for all lands in existence. The ID
    ///  of each land is actually an index into this array.
    Land[] private _lands;

    /// @dev A mapping to check if certain lat#lng exists.
    ///  Used internally when minting a new land to avoid duplicates
    mapping (string => bool) private _coordinatesExists;
    
    /// @dev A mapping to keep track of token media hashes used
    mapping(string => uint8) private _hashes;
    
    /*** INIT ***/

    /// @notice Inits the main MarsGenesis contract ERC721 compatible
    /// @dev Contract starts paused. An admin needs to unpause to allow any transfer of lands
    constructor(address payable _walletAddress) ERC721Full("MarsGenesis", "MARS") {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _walletContract = MarsGenesisWallet(_walletAddress);

        pause();
    }

    /*** EXTERNAL ***/

    /// @notice Mints a new land
    /// @dev The method includes a signature that was provided by the MarsGenesis backend, to ensure data integrity
    /// @param isPromo Flag that indicates if the land is created for a promotion (callable only by contract admins) or a migration from the v1 release
    /// @param topLeftLatLong The lat long pair of the top left corner of the rectangle that defines a land
    /// @param bottomRightLatLong The lat long pair of the bottom right corner of the rectangle that defines a land
    /// @param signature The signature provided by the backend to ensure data integrity
    /// @param ipfsHash The hash on the IPFS of this land card
    /// @param metadataURI The URI of the IPFS where the metadata of this land card is recorded
    /// @param cardId The ID of this card on the MarsGenesis backend, for internal use (dont confuse it with tokenId, the one in the backend)
    /// @return uint, the tokenId of the minted land
    function mintLand(bool isPromo, string memory topLeftLatLong, string memory bottomRightLatLong, bytes memory signature, string memory ipfsHash, string memory metadataURI, uint cardId, address promoOwner) external payable returns (uint) {
        if (isPromo == true) {
            require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
            require(_hashes[ipfsHash] != 1, "HASH_EXISTS");
            require(_promoTokenIdTracker.current() < MAX_PROMO_LANDS, "LIMIT_REACHED");
            _promoTokenIdTracker.increment();
        } else {
            require(msg.value >= _currentPrice(), "PAYMENT_TOO_LOW");
            require(_hashes[ipfsHash] != 1, "HASH_EXISTS");
            bytes32 hash = keccak256(abi.encodePacked(topLeftLatLong, bottomRightLatLong, address(this), cardId, msg.sender));
            address signer = _recoverSigner(hash, signature);
            require(signer == _deployerAddress, "INVALID_SIGNATURE");
        }
        address landOwner;
        if (isPromo == true) {
            landOwner = promoOwner;
        } else {
            landOwner = _msgSender();
        }

        uint newTokenId = _mintLand(landOwner, topLeftLatLong, bottomRightLatLong, ipfsHash, metadataURI, cardId);
        return newTokenId;
    }

    /// @notice Sets a land for sale
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the land
    /// @param minSalePriceInWei The minimum price for the sale, in Wei
    function offerLandForSale(uint tokenId, uint minSalePriceInWei) external {
        approve(address(auctionContract), tokenId);
        auctionContract.offerLandForSale(tokenId, minSalePriceInWei);
    }

    /// @notice Accepts a bid for a land
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the land
    /// @param minPrice The minimum accepted price, in Wei
    function acceptBidForLand(uint tokenId, uint minPrice) external {
        approve(address(auctionContract), tokenId);
        auctionContract.acceptBidForLand(tokenId, minPrice);
    }

    /// @notice Retrieves the tokenURI for a given land
    /// @param tokenId The id of the land
    /// @return string The land's metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return _lands[tokenId].metadataURI;
    }


    /// Deployer methods

    /// @notice Sends free balance to the main wallet 
    /// @dev Only callable by the deployer
    function sendBalanceToWallet() external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        require(address(this).balance > 0, "No Balance to send");
        
        (bool success,) = address(_walletContract).call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Updates the auction contract address
    /// @param _address The address of the auction contract
    /// @dev Only callable by admin
    function setAuctionAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        
        MarsGenesisAuction candidateContract = MarsGenesisAuction(_address);
        require(candidateContract.supportsInterface(InterfaceSignature_MarsGenesisAuction), "NOT_SUPPORTED");

        auctionContract = candidateContract;
    }

    /// @notice Updates the wallet contract address
    /// @param _address The address of the wallet contract
    /// @dev Only callable by admin
    function setWalletAddress(address payable _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        _walletContract = MarsGenesisWallet(_address);
    }


    /// @notice Returns the URI of the contract metadata
    /// @return URI of contract metadata
    function contractURI() public pure returns (string memory) {
        return "https://marsgenesis-web3.herokuapp.com/metadata/MarsGenesis.json";
    }

    /*** INTERNAL ***/

    function _mintLand(address to, string memory topLeftLatLong, string memory bottomRightLatLong, string memory ipfsHash, string memory metadataURI, uint cardId) private returns (uint) {
        require(_tokenIdTracker.current() < MAX_LANDS, "MAX_LANDS_REACHED");

        string memory coordinatesString = string(abi.encodePacked(topLeftLatLong, "#", bottomRightLatLong));
        require(_coordinatesExists[coordinatesString] != true, "COORDINATES_EXISTS");

        uint newLandId = _tokenIdTracker.current();
        Land memory newLand = Land({topLeftLatLong: topLeftLatLong, bottomRightLatLong: bottomRightLatLong, metadataURI: metadataURI});
        _lands.push(newLand);
        tokenIdToFirstOwner[newLandId] = to;

        _mint(to, newLandId);

        _tokenIdTracker.increment();
        _coordinatesExists[coordinatesString] = true;
        _hashes[ipfsHash] = 1;

        emit Discovery(to, newLandId, tokenURI(newLandId), cardId);

        return newLandId;
    }

    function _currentPrice() private view returns (uint256) {
        uint256 current = totalSupply();
        if (current <= 3000) {
            return 0.15 ether;
        } else if (current <= 5000) {
            return 0.2 ether;
        } else if (current <= 8000) {
            return 0.3 ether;
        } else if (current < 9000) {
            return 0.4 ether;
        } else {
            return 0.5 ether;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Full) {
      super._beforeTokenTransfer(from, to, tokenId);

      require(address(auctionContract) != address(0), "AUCTION_ADDRESS_NOT_SET");
      if(auctionContract.landIdIsForSale(tokenId)) {
          auctionContract.landNoLongerForSale(tokenId);
      }
    }

    /// Signing helpers

    function _recoverSigner(bytes32 _message, bytes memory _sig) private pure returns (address) {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = _splitSignature(_sig);
       return ecrecover(_message, v, r, s);
    }

    function _splitSignature(bytes memory _sig) private pure returns (uint8, bytes32, bytes32) {
        require(_sig.length == 65);
        
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
        return (v, r, s);
    }
}