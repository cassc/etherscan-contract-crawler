// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC1155.sol";
import "IERC1155.sol";


contract CateniumERC1155 is Ownable, ERC1155 {
    using ECDSA for bytes32;

    mapping(address => bool) public signers;
    mapping(uint256 => bool) nonces;
    mapping(uint256 => string) uris;

    uint256 public nextTokenId;
    address public feeCollector;
    
    event SignerAdded(address _address);
    event SignerRemoved(address _address);
    event TokenMinted(uint256 _nonce, uint256 _tokenId);

    constructor(address _feeCollector) ERC1155("") {
        address _msgSender = msg.sender;
        signers[_msgSender] = true;
        emit SignerAdded(_msgSender);
        feeCollector = _feeCollector;
    }

    function addSigner(address _address) public onlyOwner {
        signers[_address] = true;
        emit SignerAdded(_address);
    }

    function removeSigner(address _address) public onlyOwner {
        signers[_address] = false;
        emit SignerRemoved(_address);
    }

    function mint(
        uint256 _nonce,
        uint256 _amount,
        string memory _uri,
        bytes memory _signature,
        uint256 mintPrice
    ) public payable {
        address _msgSender = msg.sender;
        uint256 _id = nextTokenId;
        
        require(
            nonces[_nonce] == false,
            "CateniumERC1155: Invalid nonce"
        );
        require(msg.value >= mintPrice, "CateniumERC1155: You should send enough funds for mint");
        require(_amount > 0, "CateniumERC1155: Amount should be positive");
        require(bytes(_uri).length > 0, "CateniumERC1155: URI should be set");

        address signer = keccak256(
            abi.encodePacked(_msgSender, _nonce, _amount, _uri, address(this), mintPrice)
        ).toEthSignedMessageHash().recover(_signature);
        require(signers[signer], "Invalid signature");

        payable(feeCollector).transfer(mintPrice);

        _mint(_msgSender, _id, _amount, "");

        emit TokenMinted(_nonce, _id);

        nonces[_nonce] = true;
        uris[_id] = _uri;
        nextTokenId += 1;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }
}