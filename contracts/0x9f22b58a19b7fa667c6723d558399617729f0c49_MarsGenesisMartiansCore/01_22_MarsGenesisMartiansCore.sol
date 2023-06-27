// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Full.sol";
import "./MarsGenesisMartiansAuction.sol";
import "./MarsGenesisMartiansWallet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title MarsGenesis Martians main ERC721 contract
/// @author MarsGenesis (@DarthCryptoPepe)
/// @notice Encapsulates the ERC721 methods and main features of MarsGenesis Martians
contract MarsGenesisMartiansCore is ERC721Full {

    using Counters for Counters.Counter;

    /// @dev IPFS image containing the 10,000 martians
    string public constant ALL_MARTIANS = "ipfs://QmTCXS2i632kcYgMoVrgNydb9o39Hzt7H9WG3TBXTmaAGq";

    /// @dev Maximum number of public minted martians
    uint16 private constant MAX_MARTIANS = 10000;

    /// @dev Number of reserved martians for the pre-release land owners (initial is 10,000)
    uint16 private _reservedMartians = 10000;

    /// @dev Interface for auction contract
    // bytes4 private constant InterfaceSignature_MarsGenesisMartiansAuction =
    //         bytes4(keccak256('martianIdIsForSale(uint256 tokenId)')) ^
    //         bytes4(keccak256('martianNoLongerForSale(uint256)'));

    /// @dev Martian ID tracker
    Counters.Counter private _tokenIdTracker;

    /// @dev Address of the deployer account
    address private _deployerAddress;

    /// @dev Auction contract address
    MarsGenesisMartiansAuction private _auctionContract;

    /// @dev Wallet contract address
    MarsGenesisMartiansWallet private _walletContract;

    /// @dev MarsGenesisCore lands contract address
    ERC721 private _marsGenesisCoreContract;
    

    /*** EVENTS ***/

    /// @dev The Discovery event is fired whenever a new martian comes into existence.
    event Discovery(address _owner, uint256 _tokenId, uint256 _martianId, uint256 _landId);
    
    
    /*** MARTIANS ***/

    /// @dev A mapping containing the Martian IDs for all martians in existence
    mapping(uint => uint) public tokenToMartianId;

    /// @dev A mapping to keep track of martianIds minted
    mapping(uint => bool) private _mintedIds;

    /// @dev A mapping to keep track redeemed lands
    mapping(uint256 => bool) public landTokenIdRedeemed;
    
    /*** INIT ***/

    /// @notice Inits the main MarsGenesisMartians contract ERC721 compatible
    /// @dev Contract starts paused. An admin needs to unpause to allow any transfer of martians
    constructor(address payable _walletAddress, address _marsCoreAddress) ERC721Full("MarsGenesisMartians", "MRTN") {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _walletContract = MarsGenesisMartiansWallet(_walletAddress);
        _marsGenesisCoreContract = ERC721(_marsCoreAddress);

        pause();
    }

    /*** EXTERNAL ***/

    /// @notice Mints multiple new martians
    /// @dev The method includes a signature that was provided by the MarsGenesis backend, to ensure data integrity
    /// @param signatures The signatures provided by the backend to ensure data integrity
    /// @param martianIds The IDs of the martians to be minted
    /// @param landTokenIds The IDs of the MarsGenesis parcels to be redeemed
    /// @param promoOwner Any promo martian address
    /// @return true
    function mintMartians(bytes[] memory signatures, uint[] memory martianIds, uint[] memory landTokenIds, address promoOwner) external payable returns (bool) {                
        uint total = martianIds.length;
        require(landTokenIds.length <= total, "F");

        if (landTokenIds.length > 0) {
            require(_reservedMartians >= uint16(landTokenIds.length));
            
            for(uint i = 0; i < total; i++) {
                require(_marsGenesisCoreContract.ownerOf(landTokenIds[i]) == msg.sender || (msg.sender == _deployerAddress && _marsGenesisCoreContract.ownerOf(landTokenIds[i]) == promoOwner), "E");
                require(landTokenIdRedeemed[landTokenIds[i]] == false, "D");
                landTokenIdRedeemed[landTokenIds[i]] = true;
            }
            _reservedMartians -= uint16(landTokenIds.length);
        }

        require(_tokenIdTracker.current() + total + _reservedMartians <= MAX_MARTIANS, "MAX");

        address martianOwner;
        if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            martianOwner = promoOwner;
        } else {
            require(msg.value >= 0.08 ether * (total - landTokenIds.length), "$");
            martianOwner = _msgSender();
        }

        for(uint i = 0; i < total; i++) {
            require(_mintedIds[martianIds[i]] == false, "C");

            bytes32 hash = keccak256(abi.encodePacked(address(this), martianIds[i], msg.sender));
            address signer = _recoverSigner(hash, signatures[i]);
            require(signer == _deployerAddress, "SGN");

            uint newTokenId = _mintMartian(martianOwner, martianIds[i]);

            if (i < landTokenIds.length) {
                emit Discovery(martianOwner, newTokenId, martianIds[i], landTokenIds[i]);
            } else {
                emit Discovery(martianOwner, newTokenId, martianIds[i], 10001);
            }
        }
        
        return true;
    }

    /// @notice Sets a martian for sale
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the martian
    /// @param minSalePriceInWei The minimum price for the sale, in Wei
    function offerMartianForSale(uint tokenId, uint minSalePriceInWei) external {
        approve(address(_auctionContract), tokenId);
        _auctionContract.offerMartianForSale(tokenId, minSalePriceInWei);
    }

    /// @notice Accepts a bid for a martian
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the martian
    /// @param minPrice The minimum accepted price, in Wei
    function acceptBidForMartian(uint tokenId, uint minPrice) external {
        approve(address(_auctionContract), tokenId);
        _auctionContract.acceptBidForMartian(tokenId, minPrice);
    }

    /// @notice Retrieves the tokenURI for a given martian
    /// @param tokenId The id of the martian
    /// @return string The martian's metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmSqdF2Wdmn6Skme3RtgkGSQnGyX6irdbR1TSNACYJbJL5/", _intToString(tokenToMartianId[tokenId])));
    }

    /// Deployer methods

    /// @notice Sends free balance to the main wallet 
    /// @dev Only callable by the deployer
    function sendBalanceToWallet() external { 
        require(msg.sender == _deployerAddress);        
        (bool success,) = address(_walletContract).call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Updates the auction contract address
    /// @param _address The address of the auction contract
    /// @dev Only callable by admin
    function setAuctionAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _auctionContract = MarsGenesisMartiansAuction(_address);
    }

    /// @notice Updates the wallet contract address
    /// @param _address The address of the wallet contract
    /// @dev Only callable by admin
    function setWalletAddress(address payable _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _walletContract = MarsGenesisMartiansWallet(_address);
    }

    /// @notice Updates the martians reserve
    /// @param amount The amount of pending martians reserved
    /// @dev Only callable by admin
    function setReservedMartiansAmount(uint16 amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _reservedMartians = amount;
    }

    /// @notice Returns the URI of the contract metadata
    /// @return URI of contract metadata
    function contractURI() public pure returns (string memory) {
        return "https://marsgenesis-web3.herokuapp.com/metadata/MarsGenesisMartians.json";
    }

    function owner() public view virtual returns (address) {
        return _deployerAddress;
    }

    /*** INTERNAL ***/

    function _mintMartian(address to, uint martianId) private returns (uint) {
        uint newTokenId = _tokenIdTracker.current();
        _mint(to, newTokenId);
        _tokenIdTracker.increment();

        tokenToMartianId[newTokenId] = martianId;
        _mintedIds[martianId] = true;

        return newTokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Full) {
      super._beforeTokenTransfer(from, to, tokenId);

      require(address(_auctionContract) != address(0), "B");
      if(_auctionContract.martianIdIsForSale(tokenId)) {
          _auctionContract.martianNoLongerForSale(tokenId);
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

    function _intToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}