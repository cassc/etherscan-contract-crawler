// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC1155} from "./ramendao-1155-base.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RamenDAO is ERC1155, Ownable {

    struct Token {
        string uri; // uri for this token
        uint256 totalMinted; // how many exist
        uint256 maxSupply; // how many CAN exist
        uint256 price; // how much does it cost
    }

    mapping(uint256 => Token) public tokens;
    
    //ICryptoNomadsClub private immutable CNC = ICryptoNomadsClub(0x951416CB5A9c5379Ae696AcB07CB8E25aEfAD370); //CNC address

    address signer;
    uint256 latestNonce;

    // Events
    event ChangedSigner(address indexed newSigner);
    event TokensEdited(uint256[] indexed id, string[] uris, uint256[] maxSupply, uint256[] price);
    event Withdraw(address indexed to, uint256 indexed amount, uint256 indexed timestamp);

    // Custom errors
    error LengthMismatch();
    error TransferFailed();
    error SoldOut();
    error IncorrectMintFunction();
    error InsufficientEth();
    error Unauthorized();
    error NoReplay();

    // allows the owner to change the signer address used for specialmint
    function changeSigner(address newSigner) onlyOwner external {
        signer = newSigner;
        emit ChangedSigner(newSigner);
    }

    // retrieves the uri of a specific token
    function uri(uint256 id) public view override returns (string memory){
        return tokens[id].uri;
    }

    // allows the owner to create or edit tokens to be minted
    function editTokens(uint256[] calldata id, string[] calldata uris, uint256[] calldata maxSupply, uint256[] calldata price) external onlyOwner {

        uint256 idsLength = id.length;

        if (idsLength != uris.length || idsLength != maxSupply.length || idsLength != price.length) {
            revert LengthMismatch();
        }

        for (uint256 i = 0; i < idsLength; ) {
            tokens[id[i]].uri = uris[i];
            tokens[id[i]].maxSupply = maxSupply[i];
            tokens[id[i]].price = price[i];

            unchecked {
                ++i;
            }
        }

        emit TokensEdited(id, uris, maxSupply, price);

    }

    // allows the owner to withdraw all eth in contract
    function withdraw() onlyOwner external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        
        if (!success) {
            revert TransferFailed();
        }
 
        emit Withdraw(msg.sender, address(this).balance, block.timestamp);
    }

    // Mint functions // 

    function mint(uint256 id, uint256 amount) payable external {

        if (tokens[id].totalMinted + amount > tokens[id].maxSupply) {
            revert SoldOut();
        }

        if (id >= 1000) {
            revert IncorrectMintFunction();
        }

        if (msg.value < amount * tokens[id].price) {
            revert InsufficientEth();
        }

        // increment count for total minted
        tokens[id].totalMinted += amount;

        _mint(msg.sender, id, amount, "");        
    }

    // special mint function. This should use offchain logic to verify ownership
    // it should use signature verification, checking against the stored "Signer" address
    function specialMint(uint256 id, uint256 amount, uint256 nonce, bytes calldata signature) payable external {
        
        if (_verify(_hash(msg.sender, id, amount, nonce), signature) != signer) {
            revert Unauthorized();
        }

        if(nonce <= latestNonce) {
            revert NoReplay();
        }

        if (tokens[id].totalMinted + amount > tokens[id].maxSupply) {
            revert SoldOut();
        }

        if (id < 1000) {
            revert IncorrectMintFunction();
        }

        if (msg.value < amount * tokens[id].price ) {
            revert InsufficientEth();
        }

        // increment count for total minted
        tokens[id].totalMinted += amount;

        // update latest nonce
        latestNonce = nonce;

        _mint(msg.sender, id, amount, "");
    }

    // Signature functions //

    // forms the message digest made up of whitelisted address and token Id whitelisted for the token
    function _hash(address whitelistedWallet, uint256 tokenId, uint256 amount, uint256 nonce)
        internal pure returns (bytes32)
        {
            return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(whitelistedWallet, tokenId, amount, nonce)));
    }

    //Returns the address that signed the `digest` to produce `signature`
    function _verify(bytes32 digest, bytes calldata signature)
        internal pure returns (address)
        {
            return ECDSA.recover(digest, signature);
    }

}