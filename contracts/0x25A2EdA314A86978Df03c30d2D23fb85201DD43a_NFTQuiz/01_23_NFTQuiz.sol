// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Randomize.sol";
import "./MintList.sol";

contract NFTQuiz is ERC721, ReentrancyGuard, Ownable {

    string  folderURI;
    uint256 public totalSupply;
    uint256 public totalLeft;
    mapping (address => uint256) public replayNonce;
    mapping (address => bool) public whitelist;


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(string memory _folderURI,uint256 _limit) ERC721("NFTQuiz","NFTQuiz") {
        setTotalSupply(_limit);
        folderURI =   _folderURI;
    }


    /**
     * @dev Safely mints a token. Increments 'tokenId' by 1 and calls super._safeMint()
     *
    */

    function mint(uint256 newItemId) public onlyOwner returns(uint256){
        return safeMint(newItemId);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        setTotalSupply(_limit);
    }


    function setFolderURI(string memory _folderURI) public onlyOwner {
        folderURI = _folderURI;
    }

    function safeMint(uint256 newItemId) internal returns(uint256){
        _mint(msg.sender, newItemId);
        return newItemId;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return folderURI;
    }


    function setTotalSupply(uint256 newLimit) internal {
        totalSupply = newLimit;
        totalLeft = newLimit;
    }


    function metaTransfer(bytes memory signature, address from, uint256 token_id, uint256 nonce) public {
        bytes32 metaHash = metaTransferHash(from,token_id,nonce);
        address signer = getSigner(metaHash,signature);
        require(signer!=address(0),"Invalid signer");
        require(nonce == replayNonce[signer], "Invalid nonce");
        require(totalLeft > 0, "Not valid transfers");
        require(whitelist[signer] == false, "You already claim");
        replayNonce[signer]++;
        whitelist[signer] = true;
        _mint(signer, totalLeft);
        totalLeft--;
    }

    function metaTransferHash(address from, uint256 token_id, uint256 nonce) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this),"metaTransfer", from, token_id, nonce));
    }

    function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s);
        }
    }
}