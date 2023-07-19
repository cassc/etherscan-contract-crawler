// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721P/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EtherealWorlds is Ownable, ERC721Enumerable {
    using Strings for uint256;
    using ECDSA for bytes32;

    address constant private TREASURY = 0x17020cBf555670aB1c7f3e64a80dA61b0B4990c0;
    address constant private TAKOA = 0x4c65767a604011EA3Fb0974d8f1803CD48472FEa;
    address constant private PIONEER = 0xD632a4331229f0dC16418d6240731340855a8DA2;
    address constant private EXCEED = 0x0788C6B29E4951C853f1BD0BB55B3a1471fC8ad7;
    address constant private SUIKON = 0x1D8c8507C8046A5981f1aAD639E273CB4Eb2517B;
    address constant private DEV_1 = 0xb738bEadEE128cfa9E28BaA1609d08Ff1CBc9535;
    address constant private DEV_2 = 0xfE6420605CE05bbA3E6330EE8a983574a89afE6E;
    address constant private DEV_3 = 0x552b6aD871F27A9729162c18d769050363f2d57E;
    address constant private STAFF_1 = 0x3E3fD41aDD7dE67a12CBF9575d442826B067C71a;
    address constant private STAFF_2 = 0x419F2E40EacFB8e636E644A4e65f3A533c40679a;

    uint256 constant public MAX_WORLDS = 345;
    uint256 constant public WORLD_PRICE = 0.125 ether;

    mapping(uint256 => bool) private usedNonces;
    
    bool public isSaleActive;

    string public _baseTokenURI = "https://data.forgottenethereal.world/metadata/";
    address private _signer;

    constructor(address signer) ERC721("Forgotten Ethereal Worlds", "FEW") {
        _safeMint(TAKOA, 0);
        _safeMint(EXCEED, 1);
        _safeMint(PIONEER, 2);
        _safeMint(SUIKON, 3);
        _safeMint(DEV_1, 4);
        _safeMint(DEV_2, 5);
        _safeMint(DEV_3, 6);
        _safeMint(STAFF_1, 7);
        _safeMint(STAFF_2, 8);
        _signer = signer;
    }

    /**
     * @dev Only mints if sale is active, and that the signature is valid.
     *      Each signature is valid for 1 mint
     */
    function mint(bytes calldata _signature, uint256 _nonce) external payable {
        require(isSaleActive, "Worlds: Sale Inactive");
        require(WORLD_PRICE <= msg.value, "Worlds: Insufficient Funds");
        require(hashMessage(_nonce).recover(_signature) == _signer, "Worlds: Weird Hash");
        require(!usedNonces[_nonce], "Worlds: Reused Hash");
        uint256 currentSupply = totalSupply();
        require(currentSupply < MAX_WORLDS, "Worlds: Sold Out");
        usedNonces[_nonce] = true;

        _safeMint(msg.sender, currentSupply);
    }

    /**
     * @dev Mints all remaining NFT's into treasury in the event someone decides not to mint
     *      Should keep in mind gas limit in case there are a lot of no shows
     */
    function mintRemaining() external onlyOwner {
        uint256 currentSupply = totalSupply();

        while(currentSupply < MAX_WORLDS) {
            _safeMint(TREASURY, currentSupply++);
        }
    }

    /**
     * @dev Just a utility function so the mint code looks slightly cleaner
     */
    function hashMessage(uint256 _nonce) internal view returns(bytes32 _hash) {
        _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, _nonce))));
    }

    /**
     * @dev Turn's sale on if its off and vice versa
     */
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /**
    * @notice Set baseURI
    *
    * @param baseURI URI of the pet image server
    */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
    * @notice Base URI for computing {tokenURI}. If set, the resulting URI for each
    * token will be the concatenation of the `baseURI` and the `tokenId`.
    *
    * @return string Uri
    */
    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Unknown token");
        
	    string memory baseURI = _baseURI();
	    return bytes(baseURI).length > 0	? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}

    /**
     * @dev Not safe to have all the funds on the deployer's address
     */
    function withdrawAll() external {
        uint256 balance = address(this).balance;
        
        payable(TREASURY).transfer(balance * 5000 / 10000);
        payable(TAKOA).transfer(balance * 1150 / 10000);
        payable(EXCEED).transfer(balance * 800 / 10000);
        payable(PIONEER).transfer(balance * 1000 / 10000);
        payable(SUIKON).transfer(balance * 550 / 10000);
        payable(DEV_1).transfer(balance * 500 / 10000);
        payable(DEV_2).transfer(balance * 650 / 10000);
        payable(DEV_3).transfer(balance * 350 / 10000);
    }
}