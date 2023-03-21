// SPDX-License-Identifier: MIT
//A SOVRN Drop

/*                                                                             
 __      __   ____  ____  _  _  ____     ___  _____  __  __  ____  __  __  ____  ____ 
(  )    /__\ (_  _)( ___)( \( )(_  _)   / __)(  _  )(  )(  )(_  _)(  )(  )(  _ \( ___)
 )(__  /(__)\  )(   )__)  )  (   )(    ( (__  )(_)(  )(__)(   )(   )(__)(  )   / )__) 
(____)(__)(__)(__) (____)(_)\_) (__)    \___)(_____)(______) (__) (______)(_)\_)(____)                                                                                                                                                                                                          
*/
pragma solidity =0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract LATENTCOUTURE is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;  

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'ipfs://QmWoZ1Swpg9cMmV4GHp8W5Pd3rLUnshKtYuwjEEgz2TFem/';
  string public uriSuffix = '.json';
  
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  address public adminAddress;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public shuffled = false;
  //bool public revealed = false;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  address public defaultRoyaltyReceiver;
  mapping(uint256 => address) royaltyReceivers;
  uint256 public defaultRoyaltyPercentage;
  mapping(uint256 => uint256) royaltyPercentages;

  uint256[] private numberArr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555];

  string _tokenName = "LATENT COUTURE by Mikey Woodbridge";
  string _tokenSymbol = "LC";
  //uint256 _cost =100000000000000000;
  uint256 _maxSupply = 555;
  //uint256 _maxMintAmountPerTx = 1;
  address _defaultRoyaltyReceiver = 0x9dA5bb0d542E5ae28fcC5248Ee95F9Dd39b24257;
  uint256 _defaultRoyaltyAmount = 8; // In percent, for example 10 for 10%


  constructor() ERC721A(_tokenName, _tokenSymbol) {
    setCost(100000000000000000);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(1);
    defaultRoyaltyReceiver = _defaultRoyaltyReceiver;
    defaultRoyaltyPercentage = _defaultRoyaltyAmount;    
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier requireAdminOrOwner() {
  require(adminAddress == msg.sender || owner() == msg.sender,"Requires admin or owner privileges");
  _;
  }

  function setAdminAddress(address _adminAddress) public requireAdminOrOwner(){
        adminAddress = _adminAddress;
  }

  function mintForAdmin(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) requireAdminOrOwner() {
    _safeMint(_receiver, _mintAmount);
  }

  function testPayMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) requireAdminOrOwner() mintPriceCompliance(_mintAmount) {
    
    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, numberArr[_tokenId-1].toString(), uriSuffix))
        : '';
  }

  function shuffleArr() requireAdminOrOwner() external {
    require(!shuffled, 'the array has already been shuffled');

    for (uint256 i = 0; i < numberArr.length; i++) {
        uint256 n = i + uint256(keccak256(abi.encode(block.timestamp))) % (numberArr.length - i);
        uint256 temp = numberArr[n];
        numberArr[n] = numberArr[i];
        numberArr[i] = temp;
      }
      shuffled = true;
  }

  
  function setCost(uint256 _cost) public requireAdminOrOwner() {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public requireAdminOrOwner() {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }  

  function setUriPrefix(string memory _uriPrefix) public requireAdminOrOwner() {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public requireAdminOrOwner() {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public requireAdminOrOwner() {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public requireAdminOrOwner() {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public requireAdminOrOwner() {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    
    (bool hs, ) = payable(0xC9367730EDE93Bb941e0a5F6509618001b001fa4).call{value: address(this).balance * 15 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions START
  //////////////////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override 
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceivers[_tokenId] != address(0)
            ? royaltyReceivers[_tokenId]
            : defaultRoyaltyReceiver;
        royaltyAmount = royaltyPercentages[_tokenId] != 0 ? (_salePrice * royaltyPercentages[_tokenId]) / 100 : (_salePrice * defaultRoyaltyPercentage) / 100;
    }

    function setDefaultRoyaltyReceiver(address _receiver) external requireAdminOrOwner() {
        defaultRoyaltyReceiver = _receiver;
    }

    function setRoyaltyReceiver(uint256 _tokenId, address _newReceiver)
        external requireAdminOrOwner()
    {
        royaltyReceivers[_tokenId] = _newReceiver;
    }

    function setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)
        external requireAdminOrOwner()
    {
        royaltyPercentages[_tokenId] = _percentage;
    }

  /*//////////////////////////////////////////////////////////////////////////
                        ERC2981 Functions END
  //////////////////////////////////////////////////////////////////////////*/
}