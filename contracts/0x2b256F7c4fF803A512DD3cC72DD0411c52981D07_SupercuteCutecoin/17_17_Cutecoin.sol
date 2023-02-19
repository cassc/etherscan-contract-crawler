//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
//ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

error TooManyMints();
error InvalidSignature();
error AlreadyMinted();
error SignatureExpired();
contract SupercuteCutecoin is ERC1155Supply, Ownable,OperatorFilterer,ERC2981 {
    using ECDSA for bytes32;
     mapping(uint => string) public uris;
     mapping(address => bool) private admins;
     mapping(uint=>mapping(address=>bool)) public hasMintedAtExpirationTimestamp;
     uint public nonce;
     bool public operatorFilteringEnabled;

     address private signer = 0x6E7A41a6BeA61b3e6ae027FD7Ea63ee81A562fE5;

    constructor(
    ) ERC1155("Supercute Cutecoin") {
        setURI(0,"https://supercuteworld-poap.s3.amazonaws.com/metadata/0.json");
        _registerForOperatorFiltering();    
        operatorFilteringEnabled = true;
        // at 7.5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 750);
        
        
    }
    modifier onlyAdmin {
        require(admins[msg.sender] || msg.sender == owner(), "Not an admin");
        _;
    }
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        return uris[_id];
        }
    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
    }
    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }


    function setURI(uint256 _id, string memory _uri) public onlyAdmin {
        uris[_id] = _uri;
    }

    function setURIs(uint256[] memory _ids, string[] memory _uris) public onlyAdmin {
        require(_ids.length == _uris.length, "Array length mismatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            uris[_ids[i]] = _uris[i];
        }
    }
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }
    function emergencyChangeNonce(uint _nonce) public onlyOwner {
        nonce = _nonce;
    }

    function getSupplies(uint256[] memory _ids) public view returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            supplies[i] = totalSupply(_ids[i]);
        }
        return supplies;
    }

    function airdrop(address recipient,uint256[] calldata ids, uint[] calldata amounts) public onlyAdmin {
        _mintBatch(recipient, ids, amounts, "");
    }
    function massAirdrop(address[]calldata recipients,uint[][] calldata ids,uint[][]calldata amounts)  external onlyAdmin{
        unchecked {
            for(uint i=0;i<recipients.length;i++){
                _mintBatch(recipients[i], ids[i], amounts[i], "");
            }
        }
    }
    function mint(uint256 _id, bytes memory signature,uint expirationTimestamp,uint256 maxSupply) external  {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _id, maxSupply,expirationTimestamp,nonce));
        if(block.timestamp > expirationTimestamp) revert SignatureExpired();
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert InvalidSignature();
        if(hasMintedAtExpirationTimestamp[expirationTimestamp][msg.sender]) revert AlreadyMinted();
        uint _totalSupply = totalSupply(_id);
        if(_totalSupply + 1 > maxSupply) revert TooManyMints();
        hasMintedAtExpirationTimestamp[expirationTimestamp][msg.sender] = true;
        _mint(msg.sender, _id, 1, "");

            
    }


    //************* CLOSEDSEA **********//
    function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
{
    super.setApprovalForAll(operator, approved);
}

function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
}

function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) public override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
}

function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override (ERC1155, ERC2981)
    returns (bool)
{
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC1155: 0xd9b67a26
    // - IERC1155MetadataURI: 0x0e89341c
    // - IERC2981: 0x2a55205a
    return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
}

function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
}

function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
}

function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
}

function _isPriorityOperator(address operator) internal pure override returns (bool) {
    // OpenSea Seaport Conduit:
    // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
}


}