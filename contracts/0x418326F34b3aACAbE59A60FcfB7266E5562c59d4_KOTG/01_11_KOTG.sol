/*

     ▄████       ,████     ,╓███████▄,     ╒█████████████████╕    ,▄██████▄,       
      ████     ,████▀    ▄██████▀███████   ▐██▀▀▀▀█████▀▀▀▀▀▀▌ ,██████▀▀██████     
      ████   ,████▀    ,████`        ████▄         ███        ▄███▀        ████,   
      ████ ,████▀      ████           ▀███L        ███       ╒███▀          ████   
      █████████,      ▐███             ████        ███       ████   ▄█       ▀     
      ████  ▀████     ████             ████        ███       ████  ▐████████████╖  
      ████    ▀███╕   ╘███▌            ███▌        ███       ████   ▀▀████████████ 
      ████      ████   ▀███▄         ╓████         ███        ████,        ,██   █ 
      ████       ▀███▄  ╙█▀▀██▄,,,╓█████▀          ███         █████▄,,⌐▄█████   █ 
      ████         ████,    '████████▀"            ███           ▀███████▀  ▀███▀  
          _ )\ \  /  _ \ __|   \   |   _ _|  \  | _ \ _ \   __|__ __|__| _ \
          _ \ \  /     / _|   _ \  |     |  |\/ | __/(   |\__ \   |  _|    /
         ___/  _|   _|_\___|_/  _\____|___|_|  _|_| \___/ ____/  _| ___|_|_\

Creator: REALIMPOSTER
Instagram: @realimposter
URL: https://kotg.com/about
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract KOTG is ERC721AQueryable, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Public vars
    string public baseTokenURI;

    // Immutable vars
    uint256 public immutable maxSupply = 2000;

    // Constructor
    constructor() ERC721A("KOTG", "KOTG") {}

    // Validate authorized mint addresses
    address private signerAddress;

    mapping (address => uint256) public totalMintsPerAddress;

    // Public sale vars
    bool public isPublicMintActive = false;
    uint256 public price = 0.5 ether;

    // Airdrop vars
    bool public isAirdropActive = false;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * To be updated by contract owner to allow updating the mint price
     */
    function setPublicMintPrice(uint256 _newMintPrice) public onlyOwner {
        require(price != _newMintPrice, "NEW_PRICE_IDENTICAL_TO_OLD_PRICE");
        price = _newMintPrice;
    }

    /**
     * Enable/disable public sale
     */
    function setPublicMintState(bool _publicMintActiveState) public onlyOwner {
        require(isPublicMintActive != _publicMintActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isPublicMintActive = _publicMintActiveState;
    }

    /**
     * Enable/disable airdrop minting
     */
    function setAirdropState(bool _airdropActiveState) public onlyOwner {
        require(isAirdropActive != _airdropActiveState, "NEW_STATE_IDENTICAL_TO_OLD_STATE");
        isAirdropActive = _airdropActiveState;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
     * Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender, uint256 maximumAllowedMints) private pure returns (bytes32) {
        return keccak256(abi.encode(sender, maximumAllowedMints));
    }

    /**
     * @notice Allow for airdrop minting of properties up to the maximum allowed for a given address.
     * The address of the sender and the number of mints allowed are verified by signature
     */
    function claimAirdrop(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 mintNumber,
        uint256 maximumAllowedMints
    ) external virtual nonReentrant {
        require(isAirdropActive, "AIRDROP_IS_NOT_ACTIVE");
        require(totalMintsPerAddress[msg.sender] + mintNumber <= maximumAllowedMints, "MINT_TOO_LARGE");
        require(hashMessage(msg.sender, maximumAllowedMints) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");

        uint256 currentSupply = totalSupply();

        require(currentSupply + mintNumber <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");

        totalMintsPerAddress[msg.sender] += mintNumber;

        _safeMint(msg.sender, mintNumber);

        if (currentSupply + mintNumber >= maxSupply) {
            isAirdropActive = false;
        }
    }

    /**
     * @notice Allow for public sale of tokens.
     */
    function publicMint(uint256 mintNumber) external payable virtual nonReentrant {
        require(isPublicMintActive, "PUBLIC_SALE_IS_NOT_ACTIVE");
        // Check for correct price within margin. Front-end should utilize BigNumber for safe precision
        require(msg.value >= ((price * mintNumber) - 0.0001 ether) && msg.value <= ((price * mintNumber) + 0.0001 ether), "INVALID_PRICE");

        uint256 currentSupply = totalSupply();

        require(currentSupply + mintNumber <= maxSupply, "NOT_ENOUGH_MINTS_AVAILABLE");

        _safeMint(msg.sender, mintNumber);

        if (currentSupply + mintNumber >= maxSupply) {
            isPublicMintActive = false;
        }
    }

    /**
     * @notice Allow owner to send `mintNumber` tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 mintNumber) external onlyOwner {
        require((totalSupply() + (receivers.length * mintNumber)) <= maxSupply, "MINT_TOO_LARGE");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }

    /**
     * @notice Allow contract owner to withdraw funds.
     */
    function withdraw(address transferTo, uint256 amount) external onlyOwner {
        payable(transferTo).transfer(amount);
    }

}