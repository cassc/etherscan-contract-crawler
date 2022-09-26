// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Contract for DTTD Genesis NFT
/// @author irreverent.eth @ DTTD
/// @notice https://dttd.io/

//    ___    _____   _____    ___   
//   |   \  |_   _| |_   _|  |   \  
//   | |) |   | |     | |    | |) | 
//   |___/   _|_|_   _|_|_   |___/  
// _|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

contract DTTDGenesisContract is ERC721A, Ownable {
    uint256 constant public MAX_SUPPLY = 10000;
    string private baseTokenURI;

    address public authority;

    uint256 constant public PID_MAX_MINT = 1;

    mapping(bytes32 => bool) public tidMinted;
    mapping(bytes32 => uint256) public pidMinted;

    constructor(address _authority) ERC721A("DTTD Genesis", "DTTDGENESIS") {
        authority = _authority;
        baseTokenURI = "https://dot.dttd.group/DTTDGENESIS/";
        _mint(msg.sender, 1);
    }

    // Modifiers

    modifier maxSupplyCheck() {
        require(totalSupply() < MAX_SUPPLY, "Insufficient remaining supply");
        _;
    }

    modifier tidCheck(bytes32 tid) {
        require (tidMinted[tid] == false, "Already minted: tid");
        _;
    }

    modifier pidCheck(bytes32 pid) {
        require (pidMinted[pid] < PID_MAX_MINT, "Max mint reached: pid");
        _;
    }

    //  Signature related

    function signatureCheck(bytes32 tid, bytes32 pid, address minter, bytes memory signature) public view returns (bool) {
        return SignatureChecker.isValidSignatureNow(authority, getEthSignedMessageHash(tid, pid, minter), signature);
    }

    function getEthSignedMessageHash(bytes32 tid, bytes32 pid, address minter) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(tid, pid, minter))));
    }

    // Token URI

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // Authority

    function setAuthority(address newAuthority) public onlyOwner {
        authority = newAuthority;
    }
    
    // Minting

    function mint(bytes32 tid, bytes32 pid, bytes memory signature) external tidCheck(tid) pidCheck(pid) maxSupplyCheck {
        require(signatureCheck(tid, pid, msg.sender, signature), "Invalid signature");
        tidMinted[tid] = true;
        pidMinted[pid] += 1;
        _mint(msg.sender, 1);
    }
}