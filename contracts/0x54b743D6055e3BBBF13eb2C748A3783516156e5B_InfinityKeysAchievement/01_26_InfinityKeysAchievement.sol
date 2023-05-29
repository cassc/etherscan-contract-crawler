// SPDX-License-Identifier: UNLICENSED
// Infinity Keys 2022
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VerifySigner.sol";
import "./NonblockingReceiver.sol";
import "./CheckExternalNFT.sol";
import "./AbstractIKTraverseChains.sol";

contract InfinityKeysAchievement is 
    NonblockingReceiver, 
    AbstractIKTraverseChains,
    VerifySigner, 
    CheckExternalNFT
{
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    string public name;
    string public symbol; 

    mapping(uint256 => Token) private tokens;

    /** 
    @dev for token gating claims.
    */
    enum GateState {
        noGate,
        internalGate,
        externalGate
    }

    struct Token {
        bool claimable;
        GateState gate;
        uint256[] internalGateIDs;
        address externalGateContract;
        string tokenURI;
        mapping(address => bool) claimed;
    }

    event Claimed(uint indexed _tokenID, address indexed _account);

    constructor(
        string memory _name, 
        string memory _symbol,
        address _signer,
        string memory _secret,
        address _endpoint
    ) ERC1155("https://www.infinitykeys.io") {
        name = _name;
        symbol = _symbol;
        setSecret(_secret);
        setSigner(_signer);

        endpoint = ILayerZeroEndpoint(_endpoint);
        transferOwnership(0xe2e06703D00790D6Af7cC9198CDBa8aAa41a30Ff);
    }

    /**
    @dev Fallback function.
    */
    fallback() external payable {}

    /**
    @dev Receive function.
    */
    receive() external payable virtual {}

    /**
    @dev Returns a token.
     */
    function getToken( uint256 _tokenID ) external view returns ( 
        bool, GateState, uint256[] memory, address, string memory 
    ) {
        require(exists(_tokenID), "getToken: Token ID does not exist");
        return (tokens[_tokenID].claimable, tokens[_tokenID].gate, tokens[_tokenID].internalGateIDs, tokens[_tokenID].externalGateContract, tokens[_tokenID].tokenURI);
    }

    /**
    @dev Adds a new token.
    */
    function addToken(
        bool _claimable,
        GateState _gateState,
        uint256[] memory _internalGateIDs,
        address _externalGateContract,
        string memory _tokenURI
    ) public onlyAuthorized {
        Token storage t = tokens[counter.current()];
        t.claimable = _claimable;
        t.gate = _gateState;
        t.internalGateIDs = _internalGateIDs;
        t.externalGateContract = _externalGateContract;
        t.tokenURI = _tokenURI;

        counter.increment();
    }    

    /**
    @dev Add token caller for default states on gate IDs.
    */
    function addTokenUngated( bool _claimable, string memory _tokenURI ) public onlyAuthorized {
        addToken(_claimable, GateState.noGate, new uint[](0), address(0), _tokenURI);
    }   

    /**
    @dev Edits an existing token.
    */
    function editToken(
        uint256 _tokenID,
        bool _claimable,
        GateState _gateState,
        uint256[] memory _internalGateIDs,
        address _externalGateContract,
        string memory _tokenURI
    ) external onlyAuthorized {
        require(exists(_tokenID), "EditToken: Token ID does not exist");

        Token storage t = tokens[_tokenID];
        t.claimable = _claimable; 
        t.gate = _gateState;
        t.internalGateIDs = _internalGateIDs;
        t.externalGateContract = _externalGateContract;
        t.tokenURI = _tokenURI;  
    }

    /**
    @dev Edits token uri.
     */
    function editTokenURI( uint256 _tokenID, string memory _tokenURI ) external onlyAuthorized {
        require(exists(_tokenID), "EditTokenURI: Token ID does not exist");
        Token storage t = tokens[_tokenID];
        t.tokenURI = _tokenURI;  
    }

    /**
    @dev Sets token claim state.
     */
    function setTokenClaimable( uint256 _tokenID, bool _claimable ) external onlyAuthorized {
        require(exists(_tokenID), "setTokenClaimable: Token ID does not exist");
        Token storage t = tokens[_tokenID];
        t.claimable = _claimable;  
    }

    /**
    @dev Send specified token to specified address.
     */
    function airdrop ( uint256 _tokenID, address _address ) external onlyAuthorized {
        require( exists(_tokenID), "airdrop: token does not exist" );

        _mint(_address, _tokenID, 1, "");
    }

    /**
    @dev Handle token claims.
    */
    function claim ( uint256 _tokenID, bytes memory _signature ) external payable {
        require( exists(_tokenID), "claim: token does not exist" );
        require( isSaleOpen(_tokenID), "claim: sale is closed" );
        require( !checkIfClaimed(_tokenID, msg.sender), "claim: NFT already claimed by address" );
        require( verify(_tokenID, _signature), "claim: Server Verification Failed." );
        require( gateCheck(_tokenID, msg.sender), "claim: Address does not own requisite NFT" );
        
        tokens[_tokenID].claimed[msg.sender] = true;

        _mint(msg.sender, _tokenID, 1, "");

        emit Claimed(_tokenID, msg.sender);
    }

    /**
    @dev Return whether claims are open for a certain tokenID.
    */
    function isSaleOpen( uint256 _tokenID ) public view returns ( bool ) {
        require( exists(_tokenID), "isSaleClosed: token does not exist" );
        return tokens[_tokenID].claimable;
    }

    /**
    @dev Check if specified address has claimed specified tokenID.
    */
    function checkIfClaimed ( uint256 _tokenID, address _address ) public view returns ( bool ) {
        require( exists(_tokenID), "checkIfClaimed: token does not exist" );
        if (tokens[_tokenID].claimed[_address]) return true;
        return false;
    }

    /**
    @dev Return array of totalSupply for all tokens.
    */
    function totalSupplyAll() external view returns ( uint[] memory ) {
        uint[] memory result = new uint[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }
    
    /**
    @dev Check if msg.sender can claim NFT based on:
    * An Internal Gate (must own another token on this contract)
    * An External Gate (must own a partner NFT)
    */
    function gateCheck ( uint256 _tokenID, address _address ) private view returns ( bool ) {
        GateState gate = tokens[_tokenID].gate;

        if (gate == GateState.noGate) {
            return true;
        } else if (gate == GateState.internalGate) {
            return checkInternalNFTs(_address, tokens[_tokenID].internalGateIDs);
        } else if (gate == GateState.externalGate) {
            return checkExternalNFT(_address, tokens[_tokenID].externalGateContract);
        }
        return false;
    }

    /**
    @dev Checks if specified address owns specified NFT(s) on this contract 
    */
    function checkInternalNFTs ( address _address, uint256[] memory _internalIDs ) internal view returns ( bool ) {
        for (uint256 i; i < _internalIDs.length; ++i) {
            if (balanceOf(_address, _internalIDs[i]) == 0) {
                return false;
            }
        }
        return true;
    }

    /**
    @dev Indicates whether a token exists with a given tokenID.
    */
    function exists( uint256 _tokenID ) public view override returns ( bool ) {
        return counter.current() > _tokenID;
    }  

    /**
    @dev Return URI for existing tokenID.
    */
    function uri( uint256 _tokenID ) public view override returns ( string memory ) {
        require( exists(_tokenID), "URI: nonexistent token" );
        return tokens[_tokenID].tokenURI;
    }

    /**
    @dev onlyOwner- release ETH to given address (onlyOwner)
    */
    function release ( address payable _address, uint256 _amount ) public onlyOwner {
        require( _amount <= address(this).balance, "release: Inavlid amount." );
        Address.sendValue(_address, _amount);
    }

    /**
    @dev onlyOwner- release given ERC20 to given address (onlyOwner)
    */
    function release ( IERC20 _token, address _address, uint256 _amount ) public onlyOwner {
        require( _amount <= _token.balanceOf(address(this)), "release: insufficient tokens ERC20 called." );
        SafeERC20.safeTransfer(_token, _address, _amount);
    }
}