// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// --------------------------------------------------------------------------
// Bilbioteca de módulos verificados existentes
// --------------------------------------------------------------------------

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";


/**---------------------------------------------------------------------------
 * @title Latino Society Contract
 * @author Danny Sanchez 
 *         https://twitter.com/latino_society
 * @notice Main contract - Contrato principal 
 * Con la gran ayuda del equipo de Neftify en Puerto Rico 
 * Twitter --> https://twitter.com.neftify 
 ----------------------------------------------------------------------------*/

contract LatinoSociety is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// --------------------------------------------------------------------------
// Variables y declaraciones 
// - La idea es reutilizar el proceso merkleRoot con las 2 primeras fases 
// - El Image Hash de cada imagen determinará el hash del Provenance, 
//   garantizando que no se movieron/re-generaron
// - El equipo se reservará 300 tokens (ver Roadmap) - con un contador
//   público que será transparente.
// --------------------------------------------------------------------------

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public presaleClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  string public baseTokenURI;

  uint256 public cost;
  uint256 public immutable maxSupply = 10000;            // No hay más 
  uint256 public TempSupply;                             // Para ir implementando las fases
  uint256 public maxMintAmountPerTx;      
  
  bool public paused = true;  
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  uint256 public presaleBeginDate;                        // Unix Time 
  uint256 public presaleEndDate;                          // Unix Time 
  uint256 public startingIndex;
  uint256 public reservedMinted = 0;   
  uint256 public constant LS_MAX_RESERVED_COUNT = 300; 
  string public PROVENANCE;

  address public vault = msg.sender;
  address payable public royaltyAddress;
  uint256 public royaltyBps;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _TempSupply,                             
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    TempSupply = _TempSupply;                      
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= TempSupply, "Lo sentimos - Temp/Max supply exceeded!");
    require(totalSupply() + _mintAmount <= maxSupply, "Lo sentimos - Max Supply Exceeded");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 supply = totalSupply();
    require(msg.value >= cost * _mintAmount, "We are sorry, Not enough ETH | Lo sentimos, no tienes suficiente ETH.");
    _;
    } 


// --------------------------------------------------------------------------
// WhiteListMint - err.... Allowlist/Pre-Sale Pass Mint 
// - Casi las mismas funciones de chequeo que el mint 
// - Verifica que no haya minteado el wallet. Una transaccion por wallet 
// - El MerkleProof se hace antes de cada fase.  
// - Se verifica que cada fase se efectúe entre la fecha/hora definida 
// --------------------------------------------------------------------------

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify PreSale requirements
    require(whitelistMintEnabled, "Lo sentimos - The Pre-Sale is not enabled | La PreVenta no esta Activa");
           address minter = _msgSender();
    require(tx.origin == minter, "Nice try - Contracts are not allowed to mint");

    if (cost == 0) 
    {
       require(!whitelistClaimed[_msgSender()], "Lo sentimos - Address already claimed! | Esta direccion ya ha sido usada!");
       bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
       require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Lo sentimos - Invalid proof! | Firma equivocada");
       require(presaleBeginDate <= block.timestamp &&
               presaleEndDate >= block.timestamp, "Lo sentimos, Phase I Not Active"); 

       whitelistClaimed[_msgSender()] = true;
       _safeMint(_msgSender(), _mintAmount);

    } else if (cost > 0)                             // PreSale Phase Below  
    {
       require(!presaleClaimed[_msgSender()], "Lo sentimos - Address already claimed! | Esta direccion ya ha sido usada!");
       bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
       require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Lo sentimos - Invalid proof! | Firma equivocada");
       require(presaleBeginDate <= block.timestamp &&
               presaleEndDate >= block.timestamp, "Lo sentimos, Phase II Not Active"); 

       presaleClaimed[_msgSender()] = true;
       _safeMint(_msgSender(), _mintAmount);
    }

  }


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    address minter = _msgSender();
    require(!paused, "The contract is Paused | El Contrato esta en Pausa");
    require(tx.origin == minter, "Contracts are not allowed to mint");
    _safeMint(_msgSender(), _mintAmount);
  }
  

 // --------------------------------------------------------------------------
 // Funciones administrativas
 // --------------------------------------------------------------------------

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }
      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

 // --------------------------------------------------------------------------
 // El Provenance Hash garantiza que las imágenes no se hayan alterado desde
 // un principio. Cada imagen tiene un hash a la hora de generarla, 
 // y el Provenance Hash es el hash del hash de TODAS las imágenes.
 // --------------------------------------------------------------------------

 function setProvenance(string memory _provenance) public onlyOwner {
    PROVENANCE = _provenance;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPreSaleTimes(uint256 _PreSaleBeginDt, uint256 _PreSaleEndDt) public onlyOwner {
    presaleBeginDate = _PreSaleBeginDt;
    presaleEndDate = _PreSaleEndDt;
  }

   /*
     * Royalty setup - in BPS                      
     * En adelanto de lo que hagan los marketplaces - Por ahora lo hacemos
     * aqui publico en espera que se adopte el estándar. 
     * Este codigo sigue el ejemplo de VeeFriendsv2 de cierta forma. 
     *-----------------------------------------------------------------------*/
    function setDropRoyalties(
        address payable newRoyaltyAddress,
        uint256 newRoyaltyBps
    ) public onlyOwner {
        royaltyAddress = newRoyaltyAddress;
        royaltyBps = newRoyaltyBps;
        vault = newRoyaltyAddress;
    }

    function getFeeRecipients(uint256)
        public
        view
        returns (address payable[] memory)
    {
        address payable[] memory result = new address payable[](1);
        result[0] = royaltyAddress;
        return result;
    }

    function getFeeBps(uint256) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](1);
        result[0] = royaltyBps;
        return result;
    }

    /*
     *  Set Base URI - Para el Reveal, 
     *  y tambien HiddenMD como salvaguarda.  
     *----------------------------------------------------------*/

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setBaseTokenURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
  }


  function setUriPrefix(string memory _baseTokenURI) public onlyOwner {
    uriPrefix = _baseTokenURI;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), uriSuffix))
        : '';
  }


    /*
     *  Reservando tokens para el equipo         
     *  Esperamos que nos dejen... ;o)             *
     *---------------------------------------------*/

    function reserve(uint numberOfTokens) public onlyOwner {
      uint256 ts = totalSupply();

      require(ts + numberOfTokens <= TempSupply, "Aguas - Reserve amount would exceed max tokens for Phase!");
      require(ts + numberOfTokens <= maxSupply, "Aguas - Reserve amount would exceed max supply");
      require(numberOfTokens + reservedMinted <= LS_MAX_RESERVED_COUNT, "Sorry! Ya te pasaste con los tokens del equipo");

          _safeMint(msg.sender, numberOfTokens);
          reservedMinted = reservedMinted + numberOfTokens;
 
    }

    /*
     *  Gift - Allows us to regalar tokens a gente que nos apoya
     *  Y en efecto, cualquier regalo cuenta contra los reservados.        *
     *---------------------------------------------------------------------*/
    function gift(address receivers, uint256 mintNumber) external onlyOwner {
        require(totalSupply() +  mintNumber <= TempSupply, "MINT TOO LARGE - TE PASASTE");
        require(totalSupply() +  mintNumber <= maxSupply, "MINT WAY TOO LARGE - TE PASASTE EL LIMITE MAXIMO");
        require(mintNumber + reservedMinted <= LS_MAX_RESERVED_COUNT, "Sorry! Ya te pasaste con los tokens del equipo");

            _safeMint(receivers, mintNumber);
            reservedMinted = reservedMinted + mintNumber;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
    }

    /*
     * Allow contract owner to withdraw funds to its own account ONLY.     *
     *---------------------------------------------------------------------*/

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

  
    /*
     *  WithdrawAllToVault -Allow contract owner to withdraw to specific account(s) 
     *  Basicamente es un splitter - te permite hacer retiros a cuenta(s) especifica(s)  *
     *-----------------------------------------------------------------------------------*/
    function withdrawAllToVault() external onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(vault).send(balance));     
//      Les dejo este método por si quieren implementar un split en sus cuentas - 
//      Sólo tienen que declarar y definir acct1 y acct2 como address payable. 
//      Y los porcentajes, por supuesto.         
//        require(payable(acct1).send(balance / 100 * 50));     // 50% aquí
//        require(payable(acct2).send(balance / 100 * 50));     // 50% acá.  
    }

     function SetTempSupply(uint256 _supply) public onlyOwner {
        require (_supply <= maxSupply && _supply >= totalSupply(),"WARNING - Invalid parameters for Phase");
        TempSupply = _supply;
     } 


}