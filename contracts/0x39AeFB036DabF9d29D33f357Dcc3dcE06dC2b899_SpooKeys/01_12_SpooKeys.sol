// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//  .-')     _ (`-.                           .-. .-')                     .-. .-')                              .-')    
// ( OO ).  ( (OO  )                          \  ( OO )                    \  ( OO )                            ( OO ).  
// (_)---\_)_.`     \ .-'),-----.  .-'),-----. ,--. ,--.   ,--.   ,--.       ;-----.\  .-'),-----.   ,--.   ,--.(_)---\_) 
// /    _ |(__...--''( OO'  .-.  '( OO'  .-.  '|  .'   /    \  `.'  /        | .-.  | ( OO'  .-.  '   \  `.'  / /    _ |  
// \  :` `. |  /  | |/   |  | |  |/   |  | |  ||      /,  .-')     /         | '-' /_)/   |  | |  | .-')     /  \  :` `.  
//  '..`''.)|  |_.' |\_) |  |\|  |\_) |  |\|  ||     ' _)(OO  \   /          | .-. `. \_) |  |\|  |(OO  \   /    '..`''.) 
// .-._)   \|  .___.'  \ |  | |  |  \ |  | |  ||  .   \   |   /  /\_         | |  \  |  \ |  | |  | |   /  /\_  .-._)   \ 
// \       /|  |        `'  '-'  '   `'  '-'  '|  |\   \  `-./  /.__)        | '--'  /   `'  '-'  ' `-./  /.__) \       / 
//  `-----' `--'          `-----'      `-----' `--' '--'    `--'             `------'      `-----'    `--'       `-----'  

// Created By: Lorenzo
contract SpooKeys is ERC1155, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    
    string private baseURI;
    address private spookyBoyMansionPartyContract;

    mapping(address => bool) claimed;

    uint256 public constant BRONZE_KEY_ID = 1;
    uint256 public constant SILVER_KEY_ID = 69;
    uint256 public constant GOLD_KEY_ID = 420;

    mapping(uint256 => bool) validKeyIds;

    string private signVersion;
    address private signer;

    constructor(string memory _uri, string memory _signVersion) ERC1155(_uri) {
        baseURI = _uri;
        validKeyIds[BRONZE_KEY_ID] = true;
        validKeyIds[SILVER_KEY_ID] = true;
        validKeyIds[GOLD_KEY_ID] = true;
        signVersion = _signVersion; 
        signer = msg.sender;
    }

    function setSpookyBoyMansionPartyContract(address contractAddress) external onlyOwner{
        spookyBoyMansionPartyContract = contractAddress;
    }

    function mintKeys(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(owner(), ids, amounts, "");
    }

    function updateSignVersion(string calldata _signVersion) external onlyOwner {
        signVersion = _signVersion;
    }
    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verify(address sender, uint256 keyId, bytes memory signature) internal view returns (bool) {

        return keccak256(abi.encodePacked(sender, signVersion, keyId))
            .toEthSignedMessageHash()
            .recover(signature) == signer;
    }

    function claimKeys(uint256 _keyId, bytes memory _signature) external {
        // ckeck key id is in allowed keys?
        require(claimed[msg.sender] == false, "These keys have already been claimed.");
        require(_verify(msg.sender, _keyId, _signature), "This is not a valid signatire.");

        claimed[msg.sender] = true;
        _mint(msg.sender, _keyId, 1, "");
    }


    function burnKey(address userAddress, uint256 keyId, uint256 amount) external {
        require(msg.sender == spookyBoyMansionPartyContract, "Invalid burner address");
        require(validKeyIds[keyId], "You may not burn this key type");
        _burn(userAddress, keyId, amount);
            
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function uri(uint256 keyId) public view override returns (string memory) {
        require(validKeyIds[keyId], "This key type does not exist.");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, keyId.toString()))
                : baseURI;
    }
}