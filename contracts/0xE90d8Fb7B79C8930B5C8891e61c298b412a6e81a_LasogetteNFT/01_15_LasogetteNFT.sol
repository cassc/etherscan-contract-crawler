// SPDX-License-Identifier: MIT
// LasogetteNFT
/** 
====================================================================================================
..,    @@%       [email protected]@    ..(%&@(@@@                .   .         (,   ,,&&&(&&@   .(*,#%.  %&&@@@@,  
,...  @@&*  .   /@@@@/     %&@@#(.   #@@@@@%   [email protected]@@@@%   ,%@@@@@@(  #@@@@@@@@%  ,&@@@&&%  @&@/&.   .
,.,.  @@&.     /@. %@@       @@@*   %@@./@@@  [email protected]@*  &@,  ,@@@@@@&.     %&@@      [email protected]@@     &,    ..  
,*,  /@@@     *@(   @&&*      &@@&  &@@  &@&  /@@ #@@@.  [email protected]@@           @@@,      @@@.    @@@&@&&,..
/,,  @@@@     &@     @@@.   &@@@@#  &@@  #@@. /@@, @@@,   @@@/,,&.     .&@&       @&@,   [email protected]@        
 ,.  @@@@&@&&&&@.   #@&@@.&@&(# .   &@&&&&@@  /@@(,@@@#   @@@@@@@@      @@%       @&&%   &@&@@@&&&  
,..  .                                ,,  ..   [email protected]%&#&%    ,                       ..  .     .  .   .
====================================================================================================
*/
/**
 *
 * Bonjour, et bienvenue sur le contrat lasogette NFT. Regarde autour de toi!
 *
 * Hello, and welcome to the lasogette NFT contract. Have a look around!
 *
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./IEPSPortal.sol";

contract LasogetteNFT is ERC721, Ownable, ERC721Burnable, VRFConsumerBaseV2 {
  using Strings for uint256;

  // ===================================
  // CONSTANTS and IMMUTABLES
  // ===================================

  string public constant INSURANCE =
    "Interaction with this contract serves as an insurance against roko's basilisk.";

  // EPS minting rights index for delegated rights:
  // Indice des droits de frappe EPS pour les droits délégués:
  uint256 public constant EPS_MINTING_RIGHTS_INDEX = 2;

  // EPS portal lookup:
  // Recherche sur le portail EPS:
  IEPSPortal public immutable EPS;

  // Total supply of lasogettes:
  // Approvisionnement total en lasogettes:
  uint256 public immutable maxNumberOfLasogettes;

  // Mint price (note eligible community holders can mint one for free in freeMint())
  // Prix ​​​​à la menthe (notez que les détenteurs éligibles de la communauté peuvent en créer un gratuitement dans freeMint())
  uint256 public immutable publicMintPrice;

  // URI used for all tokens pre-reveal. Reveal is set through the calling of chainlink VRF to
  // set the random offset.
  // URI utilisé pour la pré-révélation de tous les jetons. La révélation est définie par l'appel de chainlink VRF à
  // définit le décalage aléatoire.
  string public placeholderURI;

  // Base URI used post-reveal, i.e. the folder location for individual token .json with
  // associated metadata including the link to an image. Note that NO ONE can know what lasogette
  // you will get post-reveal. Your lasogette is the combination of your token ID and a random
  // number from chainlink VRF. The order to the metadata is fixed before mint, but the VRF
  // result is not known until called in this contract, and it can only be called once. This works
  // as follows:
  // * You have tokenID 1291. Pre-reveal you see the same metadata and image as everyone else
  //   as the contract is using the placeholderURI
  // * At the reveal the token owner calls getURIOffset(). This makes a requests to chainlink
  //   for verficiable randonemess (VRF).
  // * Chainlink will then submit a random number to this contract, that we used to determine
  //   a number between 1 and the total collection size. Let's imagine this is number 2034
  // * The URI returned for your token is now your tokenId plus the VRF random number -1 (as
  //   the collection is 0 indexed with a token 0). In our example our token is now pointing
  //   at metadata 3,324 (1,291 + 2,034 - 1).
  // * With this method there is no way for anyone to know which lasogette each token will get
  //   prior to the reveal
  // * As the metadata is uploaded prior to minting the order cannot have been tampered with.
  // URI de base utilisé après la révélation, c'est-à-dire l'emplacement du dossier pour le jeton individuel .json avec
  // métadonnées associées incluant le lien vers une image. Notez que PERSONNE ne peut savoir ce qu'est la lasogette
  // vous obtiendrez après la révélation. Votre lasogette est la combinaison de votre identifiant de jeton et d'un
  // numéro de chainlink VRF. L'ordre des métadonnées est fixé avant la menthe, mais le VRF
  // le résultat n'est pas connu tant qu'il n'est pas appelé dans ce contrat, et il ne peut être appelé qu'une seule fois. Cela marche
  // comme suit:
  // * Vous avez le tokenID 1291. Avant la révélation, vous voyez les mêmes métadonnées et la même image que tout le monde
  //   car le contrat utilise le placeholderURI
  // * Lors de la révélation, le propriétaire du jeton appelle getURIOffset(). Cela fait une demande à chainlink
  //   pour le désordre vérifiable (VRF).
  // * Chainlink soumettra ensuite un nombre aléatoire à ce contrat, que nous avons utilisé pour déterminer
  //   un nombre compris entre 1 et la taille totale de la collection. Imaginons que c'est le numéro 2034
  // * L'URI renvoyé pour votre jeton est maintenant votre tokenId plus le nombre aléatoire VRF -1 (comme
  //   la collection est 0 indexée avec un jeton 0). Dans notre exemple, notre jeton pointe maintenant
  //   aux métadonnées 3 324 (1 291 + 2 034 - 1).
  // * Avec cette méthode, il n'y a aucun moyen pour quiconque de savoir quelle lasogette chaque jeton obtiendra
  //   avant la révélation
  // * Comme les métadonnées sont téléchargées avant la frappe, la commande ne peut pas avoir été falsifiée.
  string public baseURI;

  // ===================================
  // STORAGE
  // ===================================

  // Storage for the incrementing token counter:
  // Stockage pour le compteur de jetons incrémentiel :
  uint256 public tokenCounter;

  // Storage to track burned tokens:
  // Stockage pour le compteur de jetons incrémentiel :
  uint256 public burnCounter;

  // Treasury address
  // Adresse du Trésor
  address payable public treasuryAddress;

  // Token URI offset, assigned by a callback from chainlink VRF
  // Décalage d'URI de jeton, attribué par un rappel du VRF de chainlink
  uint256 public tokenURIOffset;

  // Bool to declare minting open
  bool public mintingOpen = false;

  // Mapping to record that this address has minted:
  // Mappage pour enregistrer que cette adresse a frappé :
  mapping(address => bool) public addressHasFreeMinted;

  // Mapping to record that this token has been used to claim eligibility:
  // Mappage pour enregistrer que ce jeton a été utilisé pour revendiquer l'éligibilité :
  mapping(bytes32 => bool) private tokenHasFreeMinted;

  /**
   * @dev Chainlink config.
   */
  // See https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet for details of VRF
  // corrdinator addresses.
  // Current values as follows:
  // Voir https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet pour plus de détails sur VRF
  // adresses des coordonnateurs.
  // Valeurs actuelles comme suit :
  // --------------------------
  // * Rinkeby: 0x6168499c0cFfCaCD319c818142124B7A15E857ab
  // * Mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
  VRFCoordinatorV2Interface public vrfCoordinator;

  // The subscription ID must be set to a valid subscriber before the VRF call can be made:
  // L'ID d'abonnement doit être défini sur un abonné valide avant que l'appel VRF puisse être effectué :
  uint64 public vrfSubscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // Current values as follows:
  // La voie d'essence à utiliser, qui spécifie le prix maximum de l'essence à atteindre.
  // Pour une liste des voies gaz disponibles sur chaque réseau,
  // voir https://docs.chain.link/docs/vrf-contracts/#configurations
  // Valeurs actuelles comme suit :
  // --------------------------
  // * Rinkeby: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc   (30 gwei keyhash valid for all testing)
  // * Mainnet:
  // * 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef (200 gwei)
  // * 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92 (500 gwei)
  // * 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805 (1000 gwei)
  bytes32 public vrfKeyHash;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  // Dépend du nombre de valeurs demandées que vous souhaitez envoyer au
  // Fonction fillRandomWords(). Stocker chaque mot coûte environ 20 000 gaz,
  // donc 100 000 est une valeur par défaut sûre pour cet exemple de contrat. Tester et ajuster
  // cette limite basée sur le réseau que vous sélectionnez, la taille de la requête,
  // et le traitement de la demande de rappel dans le fillRandomWords()
  // fonction.
  uint32 public vrfCallbackGasLimit = 150000;

  // The default is 3, but you can set this higher.
  // La valeur par défaut est 3, mais vous pouvez la définir plus haut.
  uint16 public vrfRequestConfirmations = 3;

  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  // Ne peut pas dépasser VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public vrfNumWords = 1;

  // ===================================
  // ERROR DEFINITIONS
  // ===================================
  error TokenURIOffsetAlreadySet();
  error URIQueryForNonexistentToken(uint256 tokenId);
  error AddressHasAlreadyMinted(address minter);
  error CallerIsNotBeneficiaryOfSelectedNFT(
    address collection,
    uint256 tokenId
  );
  error TokenHasAlreadyBeenUsedInFreeMint(address collection, uint256 tokenId);
  error InvalidCollection(address collection);
  error IncorrectETHPayment(uint256 paid, uint256 required);
  error SupplyOfLasogettedExceeded(uint256 available, uint256 requested);
  error OnlyOwnerCanFundContract();
  error NoFallback();
  error TransferFailed();
  error QuantityMustBeGreaterThanZero();
  error PlaceholderURISet();
  error BaseURISet();
  error MintingNotOpen();

  // ===================================
  // CONSTRUCTOR
  // ===================================
  constructor(
    uint256 maxSupply_,
    uint256 publicMintPrice_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    address payable treasuryAddress_,
    address eps_,
    string memory placeholderURI_,
    string memory baseURI_
  ) ERC721("Lasogette NFT", "LASOG") VRFConsumerBaseV2(vrfCoordinator_) {
    maxNumberOfLasogettes = maxSupply_;
    publicMintPrice = publicMintPrice_;
    vrfKeyHash = vrfKeyHash_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    treasuryAddress = treasuryAddress_;
    EPS = IEPSPortal(eps_);
    placeholderURI = placeholderURI_;
    baseURI = baseURI_;
  }

  // ===================================
  // SETTERS (owner only)
  // ===================================

  /**
   *
   * @dev setTreasuryAddress: Allow the owner to set the treasury address.
   *      setTreasuryAddress : permet au propriétaire de définir l'adresse de trésorerie.
   *
   */
  function setTreasuryAddress(address payable treasuryAddress_)
    external
    onlyOwner
  {
    treasuryAddress = treasuryAddress_;
  }

  /**
   *
   * @dev openMinting: Allow the owner to open minting. Mint will run until minted out.
   *
   */
  function openMinting() external onlyOwner {
    mintingOpen = true;
  }

  /**
   *
   * @dev setPlaceHolderURI: Allow the owner to set the placeholder URI IF it is blank (i.e. only set once).
   *
   */
  function setPlaceholderURI(string memory placeholderURI_) external onlyOwner {
    if (bytes(placeholderURI).length != 0) {
      revert PlaceholderURISet();
    }
    placeholderURI = placeholderURI_;
  }

  /**
   *
   * @dev setBaseURI: Allow the owner to set the base URI IF it is blank (i.e. only set once).
   *
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    if (bytes(baseURI).length != 0) {
      revert BaseURISet();
    }
    baseURI = baseURI_;
  }

  /**
   *
   * @dev setVRFCoordinator
   *
   */
  function setVRFCoordinator(address vrfCoord_) external onlyOwner {
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoord_);
  }

  /**
   *
   * @dev setVRFKeyHash
   *
   */
  function setVRFKeyHash(bytes32 vrfKey_) external onlyOwner {
    vrfKeyHash = vrfKey_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfGasLimit_) external onlyOwner {
    vrfCallbackGasLimit = vrfGasLimit_;
  }

  /**
   *
   * @dev setVRFRequestConfirmations
   *
   */
  function setVRFRequestConfirmations(uint16 vrfConfs_) external onlyOwner {
    vrfRequestConfirmations = vrfConfs_;
  }

  /**
   *
   * @dev setVRFNumWords
   *
   */
  function setVRFNumWords(uint32 vrfWords_) external onlyOwner {
    vrfNumWords = vrfWords_;
  }

  /**
   *
   * @dev setVRFSubscriptionId
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubId_) external onlyOwner {
    vrfSubscriptionId = vrfSubId_;
  }

  // ===================================
  // MINTING
  // ===================================

  /**
   *
   * @dev freeMint(): free mint for holders of eligible assets
                      menthe gratuite pour les détenteurs d'actifs éligibles
   *
   */
  function freeMint(
    address collection_,
    uint256 tokenId_,
    bool useDelivery_
  ) external {
    if (!mintingOpen) {
      revert MintingNotOpen();
    }

    _checkSupply(1);

    // Check if this address has already minted. If so, revert and tell the user why:
    // Vérifie si cette adresse a déjà été émise. Si c'est le cas, revenez en arrière et dites à l'utilisateur pourquoi :
    if (addressHasFreeMinted[msg.sender]) {
      revert AddressHasAlreadyMinted({minter: msg.sender});
    }

    // Make a hash of the collection and token Id to uniquely identify this token:
    // Créez un hachage de la collection et de l'identifiant du jeton pour identifier de manière unique ce jeton :
    bytes32 tokenIdHash = keccak256(abi.encodePacked(collection_, tokenId_));

    // Check if this token has already been used to claim a free mint.
    // If so, revert and tell the user why:
    // Vérifie si ce jeton a déjà été utilisé pour réclamer un atelier gratuit.
    // Si c'est le cas, revenir en arrière et dire à l'utilisateur pourquoi :
    if (tokenHasFreeMinted[tokenIdHash]) {
      revert TokenHasAlreadyBeenUsedInFreeMint({
        collection: collection_,
        tokenId: tokenId_
      });
    }

    // Check if this is a valid collection for free minting:
    // Vérifiez s'il s'agit d'une collection valide pour la frappe gratuite :
    if (!isValidCollection(collection_)) {
      revert InvalidCollection({collection: collection_});
    }

    // Check that the calling user is the valid beneficiary of the token
    // That has been passed. A valid beneficiary can be:
    // 1) The owner of the token (most common case)
    // 2) A hot wallet that holds the token in a linked EPS cold wallet
    // 3) A wallet that has an EPS minting rights rental on the token
    // (for details see eternalproxy.com)
    // Vérifier que l'utilisateur appelant est le bénéficiaire valide du jeton
    // Cela a été adopté. Un bénéficiaire valide peut être :
    // 1) Le propriétaire du jeton (cas le plus courant)
    // 2) Un portefeuille chaud qui contient le jeton dans un portefeuille froid EPS lié
    // 3) Un portefeuille qui a une location de droits de frappe EPS sur le jeton
    // (pour plus de détails, voir éternelleproxy.com)
    if (!isValidAssetBeneficiary(collection_, tokenId_, msg.sender)) {
      revert CallerIsNotBeneficiaryOfSelectedNFT({
        collection: collection_,
        tokenId: tokenId_
      });
    }

    // Set where assets should be delivered. This defaults to the
    // sender address, looking up the EPS delivery address of the
    // sender has selected that option in the minting UI:
    // Définir où les actifs doivent être livrés. C'est par défaut le
    // adresse de l'expéditeur, recherche de l'adresse de livraison EPS du
    // l'expéditeur a sélectionné cette option dans l'interface utilisateur :
    address deliveryAddress = _getDeliveryAddress(useDelivery_, msg.sender);

    // We made it! Perform the mint:
    // Nous l'avons fait! Effectuez la menthe:
    _performMint(deliveryAddress);

    // Record that this address has minted:
    // Enregistrez que cette adresse a été frappée :
    addressHasFreeMinted[msg.sender] = true;

    // Record that this token has been used to claim a free mint:
    // Enregistrez que ce jeton a été utilisé pour réclamer un atelier gratuit :
    tokenHasFreeMinted[tokenIdHash] = true;
  }

  /**
   *
   * @dev _checkSupply
   *
   */
  function _checkSupply(uint256 quantity_) internal view {
    if ((tokenCounter + quantity_) > maxNumberOfLasogettes) {
      revert SupplyOfLasogettedExceeded({
        available: maxNumberOfLasogettes - tokenCounter,
        requested: quantity_
      });
    }
  }

  /**
   * @dev _performMint
   */
  function _performMint(address delivery_) internal {
    _safeMint(delivery_, tokenCounter);

    tokenCounter += 1;
  }

  /**
   *
   * @dev isValidAssetBeneficiary
   *
   */
  function isValidAssetBeneficiary(
    address collection_,
    uint256 tokenId_,
    address caller_
  ) public view returns (bool) {
    // Get the registered beneficiary for this asset from EPS:
    // Obtenez le bénéficiaire enregistré pour cet actif auprès d'EPS :
    return (EPS.beneficiaryOf(
      collection_,
      tokenId_,
      EPS_MINTING_RIGHTS_INDEX
    ) == caller_);
  }

  /**
   *
   * @dev isEligibleForFreeMint: check the eligibility of a collection, token and caling address
   * Note this duplicates the checks in the free mint, which instead call revert with
   * suitable custom errors. This function is for external calls.
   *                            vérifier l'éligibilité d'une collecte, d'un jeton et d'une adresse d'appel
   * Notez que cela duplique les chèques de la menthe gratuite, qui appellent à la place revenir avec
   * erreurs personnalisées appropriées. Cette fonction est réservée aux appels externes.
   *
   */
  function isEligibleForFreeMint(
    address collection_,
    uint256 tokenId_,
    address caller_
  ) external view returns (bool, string memory) {
    if (addressHasFreeMinted[caller_]) {
      return (false, "Address has already free minted");
    }

    bytes32 tokenIdHash = keccak256(abi.encodePacked(collection_, tokenId_));

    if (tokenHasFreeMinted[tokenIdHash]) {
      return (false, "Token has already been used in free mint");
    }

    if (!isValidCollection(collection_)) {
      return (false, "Invalid collection");
    }

    if (!isValidAssetBeneficiary(collection_, tokenId_, caller_)) {
      return (false, "Caller is not beneficiary of selected NFT");
    }

    return (true, "");
  }

  /**
   *
   * @dev isValidCollection
   *
   */
  function isValidCollection(address collection_) public pure returns (bool) {
    return (collection_ == 0x1D20A51F088492A0f1C57f047A9e30c9aB5C07Ea || // wassies by wassies
      collection_ == 0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6 || // cryptoadz
      collection_ == 0x79FCDEF22feeD20eDDacbB2587640e45491b757f || // mfers
      collection_ == 0x5Af0D9827E0c53E4799BB226655A1de152A425a5 || // milady
      collection_ == 0x62eb144FE92Ddc1B10bCAde03A0C09f6FBffBffb || // adworld
      collection_ == 0xA16891897378a82E9F0ad44A705B292C9753538C || // pills
      collection_ == 0x91680cF5F9071cafAE21B90ebf2c9CC9e480fB93 || // frank frank
      collection_ == 0xEC0a7A26456B8451aefc4b00393ce1BefF5eB3e9 || // all stars
      collection_ == 0x82235445a7f634279E33702cc004B0FDb002fDa7 || // sakura park
      collection_ == 0x42069ABFE407C60cf4ae4112bEDEaD391dBa1cdB); // CryptoDickbutts
  }

  /**
   *
   * @dev publicMint(): public mint for everyone
   *                    monnaie publique pour tous
   *
   */
  function publicMint(uint256 quantity_, bool useDelivery_) external payable {
    if (!mintingOpen) {
      revert MintingNotOpen();
    }

    _checkSupply(quantity_);

    if (quantity_ == 0) {
      revert QuantityMustBeGreaterThanZero();
    }

    if (msg.value != (quantity_ * publicMintPrice)) {
      revert IncorrectETHPayment({
        paid: msg.value,
        required: (quantity_ * publicMintPrice)
      });
    }

    address deliveryAddress = _getDeliveryAddress(useDelivery_, msg.sender);

    for (uint256 i = 0; i < quantity_; i++) {
      _performMint(deliveryAddress);
    }
  }

  /**
   *
   * @dev _getDeliveryAddress
   *
   */
  function _getDeliveryAddress(bool useEPSDelivery_, address caller_)
    internal
    view
    returns (address)
  {
    if (useEPSDelivery_) {
      (, address delivery, ) = EPS.getAddresses(caller_);
      return delivery;
    } else {
      return caller_;
    }
  }

  // ===================================
  // URI HANDLING
  // ===================================

  /**
   *
   * @dev getURIOffset: Requests randomness.
   *                    Demande le hasard.
   *
   */
  function getURIOffset() public onlyOwner returns (uint256) {
    if (tokenURIOffset != 0) {
      revert TokenURIOffsetAlreadySet();
    }
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   * @dev fulfillRandomWords: Callback function used by VRF Coordinator.
   *                          Fonction de rappel utilisée par le coordinateur VRF.
   *
   */
  function fulfillRandomWords(uint256, uint256[] memory randomWords_)
    internal
    override
  {
    if (tokenURIOffset != 0) {
      revert TokenURIOffsetAlreadySet();
    }
    tokenURIOffset = (randomWords_[0] % maxNumberOfLasogettes) + 1;
  }

  /**
   *
   * @dev tokenURI
   *
   *
   */
  function tokenURI(uint256 tokenId_)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    if (!_exists(tokenId_)) {
      revert URIQueryForNonexistentToken({tokenId: tokenId_});
    }

    if (tokenURIOffset == 0) {
      return string(placeholderURI);
    } else {
      return
        string(
          abi.encodePacked(baseURI, _getTokenURI(tokenId_).toString(), ".json")
        );
    }
  }

  /**
   *
   * @dev _getTokenURI: get the token URI based on the random offset
                        obtenir l'URI du jeton en fonction du décalage aléatoire
   *
   */
  function _getTokenURI(uint256 tokenId_) internal view returns (uint256) {
    uint256 tempTokenURI = tokenId_ + (tokenURIOffset - 1);

    // If the returned URI range exceeds the collection length, it wraps to be beginning:
    if (tempTokenURI > maxNumberOfLasogettes - 1) {
      tempTokenURI = tempTokenURI - (maxNumberOfLasogettes);
    }

    return tempTokenURI;
  }

  // ===================================
  // OPERATIONAL
  // ===================================

  /**
   *
   * @dev totalSupply(): totalSupply = tokens minted (tokenCounter) minus burned
   *                     totalSupply = jetons frappés (tokenCounter) moins brûlés
   *
   */
  function totalSupply() public view returns (uint256) {
    return tokenCounter - burnCounter;
  }

  /**
   *
   * @dev burn: Burns `tokenId`. See {ERC721-_burn}.
   *            Brûle `tokenId`. Voir {ERC721-_burn}.
   *
   */
  function burn(uint256 tokenId) public override {
    super.burn(tokenId);
    burnCounter += 1;
  }

  /**
   *
   * @dev withdrawAll: onlyOwner withdrawal to the beneficiary address
   *                   Retrait uniquement du propriétaire à l'adresse du bénéficiaire
   *
   */
  function withdrawAll() external onlyOwner {
    (bool success, ) = treasuryAddress.call{value: address(this).balance}("");
    if (!success) {
      revert TransferFailed();
    }
  }

  /**
   *
   * @dev withdrawAmount: onlyOwner withdrawal to the treasury address, amount to withdraw as an argument
                          Retrait du propriétaire uniquement à l'adresse du bénéficiaire, envoi
   * le montant à retirer en argument
   *
   */
  function withdrawAmount(uint256 amount_) external onlyOwner {
    (bool success, ) = treasuryAddress.call{value: amount_}("");
    if (!success) {
      revert TransferFailed();
    }
  }

  /**
   *
   * @dev receive: Reject all direct payments to the contract except from  owner.
                   Rejeter tous les paiements directs au contrat, sauf du propriétaire.
   *
   */
  receive() external payable {
    if (msg.sender != owner()) {
      revert OnlyOwnerCanFundContract();
    }
  }

  /**
   *
   * @dev fallback: none
   *                rien
   *
   */
  fallback() external payable {
    revert NoFallback();
  }
}