// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT. Mintable User NFT Collection
pragma solidity 0.8.16;

import "ERC721URIStorage.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "Subscriber.sol";


contract EnvelopUsers721Swarm is ERC721URIStorage, Ownable, Subscriber {
    using ECDSA for bytes32;

    
    //address public subscriptionManager;
    string private _baseTokenURI;
    
    // Oracle signers status
    mapping(address => bool) public oracleSigners;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl,
        uint256 _code
    ) 
        ERC721(name_, symbol_) 
        Subscriber(_code) 
    {
        _baseTokenURI = _baseurl;

    }

    function mintWithURI(
        address _to, 
        uint256 _tokenId, 
        string calldata _tokenURI, 
        bytes calldata _signature
    ) public {
        // If signature present - lets checkit
        if (_signature.length > 0) {
            bytes32 msgMustWasSigned = keccak256(abi.encode(
                msg.sender,
                _tokenId,
                _tokenURI
            )).toEthSignedMessageHash();

            // Check signature  author
            require(oracleSigners[msgMustWasSigned.recover(_signature)], "Unexpected signer");

        // If there is no signature then sender must have valid status
        } else {
            require(
                _checkAndFixSubscription(msg.sender),
                "Has No Subscription"
            );

        }
        _mintWithURI(_to, _tokenId, _tokenURI);
    }

    function mintWithURIBatch(
        address[] calldata _to, 
        uint256[] calldata _tokenId, 
        string[] calldata _tokenURI, 
        bytes[] calldata _signature
    ) external {
        for (uint256 i = 0; i < _to.length; i ++){
            mintWithURI(_to[i], _tokenId[i], _tokenURI[i], _signature[i]);
        }
    }

    //////////////////////////////
    //  Admin functions        ///
    //////////////////////////////
    function setSignerStatus(address _signer, bool _status) external onlyOwner {
        oracleSigners[_signer] = _status;
    }

    function setSubscriptionManager(address _manager) external onlyOwner {
        _setSubscriptionManager(_manager);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseTokenURI = _newBaseURI;
    }
    
    ///////////////////////////////
    function _mintWithURI(address _to, uint256 _tokenId, string memory _tokenURI) internal {
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return _baseTokenURI;
    }
}