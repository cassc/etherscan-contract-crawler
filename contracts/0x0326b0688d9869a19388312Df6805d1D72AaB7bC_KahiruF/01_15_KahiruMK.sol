// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract KahiruF is ERC721A, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;  
    using Address for address;
    using ECDSA for bytes32;
    
    // Starting and stopping sale // Empezar y parar etapas
    bool public saleActive = false;
    bool public whitelistActive = false;
    bool public raffleActive = false;

    // Reserved for the team, customs, giveaways, collabs and so on // Reservado para equipo y otros
    uint256 public reserved = 222;

    // Price of each token // Precio inicial mint
    uint256 public Wl_price = 0.12 ether; // Price of Whitelisted Mints
    uint256 public Raffle_price = 0.14 ether; // Price of Raffled Mints

    // Public Sale Key // Key para verificación extra
    string publicKey; // Will change to hash instead of int

    // Maximum limit of tokens that can ever exist // Número de Tokens
    mapping(address => uint256) private mintCountMap;
    mapping(address => uint256) private allowedMintCountMap;
    
    uint256 public constant MAX_SUPPLY = 7222;
    uint256 public constant MAX_WL_SUPPLY = 5000;
    uint256 public constant MINT_LIMIT_PER_WALLET = 1;

    function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
    }

    function allowedMintCount(address minter) public view returns (uint256) {
        if (saleActive || whitelistActive || raffleActive) {
        return (
            max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
            mintCountMap[minter]
        );
        }

        return allowedMintCountMap[minter] - mintCountMap[minter];
    }

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    // The base link that leads to the image / video of the token // URL del arte-metadata
    //string public baseTokenURI = "https://api.kahiru.io/";
    string public baseTokenURI = "https://www.721.so/api/example/metadata/";

    // Team addresses for withdrawals // Carteras de retirada de balance
    address public a1;

    // List of addresses that have a number of reserved tokens for whitelist // Lista de direcciones para Whitelist y Raffle
    bytes32 private _whitelistMerkleRoot = 0xa55ed0edb0fc32171feb79ad2dc5b1551a4765612ce344057f1166c7ddcb7111;
    bytes32 private _whitelistNeutralMerkleRoot = 0x52551a51441048412a12edf749d65363e41af37ba1969a62caba0e45e39792bf;
    bytes32 private _raffleMerkleRoot = 0x420041bc817938d28f6ec183b5057d7189de1a99a5b6d3f6b33980a92b153d06;

    constructor () ERC721A ("Kahiru", "KAHIRU") {
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead // Reemplazar URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Exclusive whitelist minting // Función mint con Whitelist
    Counters.Counter private supplyCounter;

    function mintWhitelist(bytes32[] memory proof, string memory _pass) public payable nonReentrant {
        uint256 quantity = 1;
        uint256 supply = totalSupply();
        require( whitelistActive,                   "Whitelist isn't active" );
        require(
            MerkleProof.verify(
                proof,
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Whitelist validation failed"
        );
        require( keccak256(abi.encodePacked(publicKey)) == keccak256(abi.encodePacked(_pass)), "Key error"); // Key verifying web3 call // Key que "Verifica" la llamada al contract desde la web3
        require( supply + quantity <= MAX_WL_SUPPLY,    "Can't mint more than WL supply" );
        require( supply + quantity <= MAX_SUPPLY,    "Can't mint more than max supply" );
        require( msg.value == Wl_price * quantity,      "Wrong amount of ETH sent" );
        if (allowedMintCount(msg.sender) >= 1) {
        updateMintCount(msg.sender, 1);
        } else {
        revert("Minting limit exceeded");
        }
        _safeMint( msg.sender, quantity);
        
    }

    // Exclusive Neutral whitelist minting // Función mint con Neutral Whitelist

    function mintNeutralWhitelist(bytes32[] memory proof, uint256 quantity, string memory _pass) public payable nonReentrant {
        uint256 supply = totalSupply();
        require( whitelistActive,                   "Whitelist isn't active" );
        require(
            MerkleProof.verify(
                proof,
                _whitelistNeutralMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Neutral Whitelist validation failed"
        );
        require( keccak256(abi.encodePacked(publicKey)) == keccak256(abi.encodePacked(_pass)), "Key error"); // Key verifying web3 call // Key que "Verifica" la llamada al contract desde la web3
        require( quantity > 0,            "Can't mint less than one" );
        require( quantity <= 2,            "Can't mint more than reserved" );
        require( supply + quantity <= MAX_WL_SUPPLY,    "Can't mint more than WL supply" );
        require( supply + quantity <= MAX_SUPPLY,    "Can't mint more than max supply" );
        require( msg.value == Wl_price * quantity,      "Wrong amount of ETH sent" );
        if (allowedMintCount(msg.sender) >= 1) {
        updateMintCount(msg.sender, 1);
        } else {
        revert("Minting limit exceeded");
        }
        _safeMint( msg.sender, quantity);
    }

    // Exclusive raffle minting // Función mint con Whitelist
    function mintRafflelist(bytes32[] memory proof, string memory _pass) public payable nonReentrant {
        uint256 quantity = 1;
        uint256 supply = totalSupply();
        require( raffleActive,                   "Raffle isn't active" );
        require(
            MerkleProof.verify(
                proof,
                _raffleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Raffle validation failed"
        );
        require( keccak256(abi.encodePacked(publicKey)) == keccak256(abi.encodePacked(_pass)), "Key error"); // Key verifying web3 call // Key que "Verifica" la llamada al contract desde la web3
        require( supply + quantity <= MAX_SUPPLY-reserved,    "Can't mint more than max supply" );
        require( msg.value == Raffle_price * quantity,      "Wrong amount of ETH sent" );
        if (allowedMintCount(msg.sender) >= 1) {
        updateMintCount(msg.sender, 1);
        } else {
        revert("Minting limit exceeded");
        }
        _safeMint( msg.sender, quantity);
    
    }

    // Standard mint function // Mint normal sin restricción de dirección

    function mintToken() public payable nonReentrant {
        uint256 supply = totalSupply();
        require( saleActive,                "Sale isn't active" );
        require( msg.value >= Raffle_price,      "Wrong amount of ETH sent" );
        require( supply + 1 <= MAX_SUPPLY,    "Can't mint more than max supply" );
        _safeMint( msg.sender, 1 );

    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways // Función de minteo de los admins
    function mintReserved(uint256 quantity) public onlyOwner {
        // Limited to a publicly set amount
        uint256 supply = totalSupply();
        require( quantity <= reserved, "Can't reserve more than set amount" );
        require( supply + quantity <= MAX_SUPPLY,    "Can't mint more than max supply" );
        reserved -= quantity;
        _safeMint( msg.sender, quantity );
    }


    function setMerkleRaffle(bytes32 root1) public onlyOwner {
        _raffleMerkleRoot = root1;
    }

    function setMerkleWL(bytes32 root2) public onlyOwner {
        _whitelistMerkleRoot = root2;
    }

    function setMerkleWN(bytes32 root3) public onlyOwner {
        _whitelistNeutralMerkleRoot = root3;
    }

    // Start and stop whitelist // Función que activa y desactiva el minteo por Whitelist
    function setWhitelistActive(bool val) public onlyOwner {
        whitelistActive = val;
    }

    // Start and stop raffle // Función que activa y desactiva el minteo por Raffle
    function setRaffleActive(bool val) public onlyOwner {
        raffleActive = val;
    }

    // Start and stop sale // Función que activa y desactiva el minteo por venta genérica
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set new baseURI // Función para setear baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set public key // Función para cambio de key publica
    function setPublicKey(string memory newKey) public onlyOwner {
        publicKey = newKey;
    }

    function setWithdrawAdress(address ledger) external onlyOwner nonReentrant {
        a1 = ledger;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = a1.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function ownerDetails(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownerships[tokenId];
    }

    // ROYALTIES //

    function royaltyInfo(uint256, uint256 salePrice) external view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 600) / 10000);
  }

}

// Developed by Thanic® Tech Labs