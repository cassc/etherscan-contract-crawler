/*
             ____________________
           //                    \\
         //                        \\ 
       //                            \\
     //      ██▀███   ██▓ ██▓███       \\
    ||      ▓██ ▒ ██▒▓██▒▓██░  ██▒      ||
    ||      ▓██ ░▄█ ▒▒██▒▓██░ ██▓▒      ||
    ||      ▒██▀▀█▄  ░██░▒██▄█▓▒ ▒      ||
    ||      ░██▓ ▒██▒░██░▒██▒ ░  ░      ||
    ||      ░ ▒▓ ░▒▓░░▓  ▒▓▒░ ░  ░      ||
    ||        ░▒ ░ ▒░ ▒ ░░▒ ░           ||
    ||        ░░   ░  ▒ ░░░             ||
    ||         ░      ░                 ||
    ||           __  __  _  _           ||
    ||          (  \/  )( \/ )          ||
    ||           )    (  \  /           ||
    ||          (_/\/\_) (__)           ||
    ||                                  ||
    ||   /$$   /$$ /$$$$$$$$ /$$$$$$$$  ||
    ||  | $$$ | $$| $$_____/|__  $$__/  ||
    ||  | $$$$| $$| $$         | $$     ||
    ||  | $$ $$ $$| $$$$$      | $$     ||
    ||  | $$  $$$$| $$__/      | $$     ||
    ||  | $$\  $$$| $$         | $$     ||
    ||  | $$ \  $$| $$         | $$     ||
    ||  |__/  \__/|__/         |__/     ||
    ||                                  ||
____v__\/_,__\/,_v_,_\/_v_,_vV__\/,_V_v_V_____

made by mossy
mossydotcom.com

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ERC721Contract {
    function balanceOf(address addr) public view returns (uint) {}
    function ownerOf(uint256 tokenId) public view returns (address) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public {}
}

contract ERC1155Contract {
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data) public {}
    function balanceOf(address account, uint256 id) public view returns (uint256) {}
}

contract RIPmyNFT is ERC721, Pausable, Ownable {
    using ECDSA for bytes32; 
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address public burnAddr;
    address public signAddr;
    mapping(uint => string) tokenMetadata;
    uint public maxMintsPerAddress = 10;
    uint maxSupply = 666;

    constructor(address _burnAddr, address _signAddr) ERC721("RIP my NFT", "RIP") {
        burnAddr = _burnAddr;
        signAddr = _signAddr;
    }

    // Called when someone transfers an ERC721 token to this contract
    function onERC721Received(address, address from, uint256 id, bytes calldata data) whenNotPaused external returns (bytes4) {
        handleTokenReceived(from, id, data, false);
        return IERC721Receiver.onERC721Received.selector;
    }

    // Called when someone transfers an ERC721 token to this contract
    function onERC1155Received(address, address from, uint256 id, uint256 amount, bytes calldata data) whenNotPaused external returns (bytes4) {
        require(amount == 1, 'TOO_MANY');
        handleTokenReceived(from, id, data, true);
        return this.onERC1155Received.selector;
    }

    // Burns tokens transferred to this contract then mints a new one
    function handleTokenReceived(
        address transferFrom, 
        uint256 transferTokenId, 
        bytes calldata data,
        bool is1155) 
        whenNotPaused private {
        (address owner, 
        address tokenContract,
        uint tokenId,
        string memory metadata,
        uint deadline,
        bytes memory signature) = abi.decode(data, (address, address, uint, string, uint, bytes));
        require(_tokenIdCounter.current() < maxSupply, 'SOLD_OUT');
        // Need to have parameters signed by our server
        require(verifyMessage(
            owner, tokenContract, tokenId, metadata, deadline, signature
            ), 'BAD_SIG');
        require(balanceOf(owner) < maxMintsPerAddress, 'ADDRESS_MAXED');
        // Needs to be submitted within 15 minutes of the initial creation
        require(deadline >= block.timestamp, 'DEADLINE_PASSED');
        // Owner at time of selection on site must be same now
        require(owner == transferFrom, 'NOT_OWNER'); 
        // Contract needs to match what was selected on site
        require(msg.sender == tokenContract, 'NOT_CONTRACT');
        // Id of token needs to match waht was selected on site
        require(transferTokenId == tokenId, 'NOT_ID');
        // This contract must be the owner of the token so it can be burned
        require(doWeOwnIt(tokenContract, tokenId, is1155), 'NOT_TRANSFERED'); 
        // Usher this token into the great beyond
        burnToken(tokenContract, tokenId, is1155); 

        // Now raise it from the ashes
        tokenMetadata[_tokenIdCounter.current()] = metadata;
        _safeMint(owner, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // Makes sure the message was signed by our server
    function verifyMessage(
        address p1, // owner
        address  p2, // contractAddr
        uint p3, // tokenId
        string memory p4, // metadata
        uint p5, // deadline
        bytes memory signature
        ) private view  returns( bool) {
        // Hash those params!
        bytes32 messagehash =  keccak256(abi.encodePacked(p1, p2, p3, p4, p5));
        // See who's the signer
        address thisSigner = messagehash.toEthSignedMessageHash().recover(signature);
        if (signAddr==thisSigner) {
            // Checks out!
            return (true);
        } else {
            // Looks bogus.
            return (false);
        }
    }

    // Checks if this contract owns a given token
    function doWeOwnIt(address contractAddr, uint tokenId, bool is1155) private view returns (bool) {
        if(is1155){
            ERC1155Contract cont = ERC1155Contract(contractAddr);
            if(cont.balanceOf(address(this), tokenId) > 0){
                return true;
            }
        }else{
            ERC721Contract cont = ERC721Contract(contractAddr);
            return (cont.ownerOf(tokenId) == address(this));
        }
        return false;
    }

    // Ushers a dead NFT into the great beyond
    function burnToken(address contractAddr, uint tokenId, bool is1155) private {
        if(is1155){
            ERC1155Contract cont = ERC1155Contract(contractAddr);
            cont.safeTransferFrom(address(this), burnAddr, tokenId, 1, ''); // RIP
        }else{
            ERC721Contract cont = ERC721Contract(contractAddr);
            cont.safeTransferFrom(address(this), burnAddr, tokenId); // RIP
        }
        
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string.concat('ipfs://', tokenMetadata[tokenId]);
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSigner(address newSigner) public onlyOwner {
        signAddr = newSigner;
    }

    function setMaxMintsPerAddress(uint newMax) public onlyOwner {
        maxMintsPerAddress = newMax;
    }
}