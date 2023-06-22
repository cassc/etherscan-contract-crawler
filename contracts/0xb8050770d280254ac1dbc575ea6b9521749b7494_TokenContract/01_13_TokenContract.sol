// SPDX-License-Identifier: UNLICENSED
// https://docs.openzeppelin.com/contracts/2.x/erc721
pragma solidity ^0.8.4;

import "./interfaces/IConfigContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TokenContract is ERC721, Ownable {

    address private _configContract;

    string private _baseTokenURI;

    constructor(address configContract, string memory contractName, string memory contractSymbol) ERC721(contractName, contractSymbol) {
        _configContract = configContract;
    }

    function mint(uint tokenId, bytes calldata signature) external returns (uint) {
        bytes32 generatedHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(address(this), tokenId, msg.sender)));
        address recoveredAddress = ECDSA.recover(generatedHash, signature);
        require(IConfigContract(_configContract).validateRecoveredSignatureAddress(recoveredAddress), "Signature invalid");
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function adminMint(address recipient, uint tokenId) external returns (uint) {
        require(IConfigContract(_configContract).canMint(msg.sender), "Sender cannot mint (not approved)");
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function adminBatchMint(address[] calldata recipients, uint[] calldata tokenIds) external {
        require(IConfigContract(_configContract).canMint(msg.sender), "Sender cannot mint (not approved)");
        require(recipients.length == tokenIds.length, "Arrays are not same size");
        for(uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], tokenIds[i]);
        }
    }

    function setConfigContract(address configContract) external onlyOwner {
        _configContract = configContract;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function destroyContract() external onlyOwner {
        require(IConfigContract(_configContract).getCanDestroyContract(), "Cannot destroy contract");
        selfdestruct(payable(owner()));
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return (IConfigContract(_configContract).getAddress("resale") == operator || super.isApprovedForAll(owner, operator));
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override(ERC721) {
        require(IConfigContract(_configContract).getIsEnabled(address(this)), "Transfer is not enabled");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}