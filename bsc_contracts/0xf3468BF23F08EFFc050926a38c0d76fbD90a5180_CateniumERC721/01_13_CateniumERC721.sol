// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC721.sol";
import "IERC721.sol";
import "Counters.sol";

contract CateniumERC721 is Ownable, ERC721 {
    using ECDSA for bytes32;
    
    mapping(address => bool) public signers;
    mapping(uint256 => bool) nonces;
    mapping(uint256 => string) uris;

    uint256 public nextTokenId;
    address public feeCollector;

    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, uint256 _tokenId);

    constructor(address _feeCollector) ERC721("Catenium", "CAT") {
        address _msgSender = msg.sender;
        signers[_msgSender] = true;
        emit SignerAdded(_msgSender);
        feeCollector = _feeCollector;
    }

    function addSigner(address _address) external onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) external onlyOwner {
        signers[_address] = false;
        emit SignerRemoved(_address);
    }

    function mint(
        uint256 _nonce,
        string memory _uri,
        bytes memory _signature,
        uint256 mintPrice
    ) public payable {
        address _msgSender = msg.sender;
        uint256 _id = nextTokenId;

        require(
            nonces[_nonce] == false,
            "CateniumERC721: Invalid nonce"
        );
        require(msg.value >= mintPrice, "CateniumERC1155: You should send enough funds for mint");
        require(bytes(_uri).length > 0, "CateniumERC721: _uri is required");
        
        address signer = keccak256(
            abi.encodePacked(_msgSender, _nonce, _uri, address(this), mintPrice)
        ).toEthSignedMessageHash().recover(_signature);
        require(signers[signer], "CateniumERC721: Invalid signature");

        payable(feeCollector).transfer(mintPrice);

        _mint(_msgSender, _id);

        emit TokenMinted(_nonce, _id);

        nonces[_nonce] = true;
        uris[_id] = _uri;
        nextTokenId += 1;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }
}