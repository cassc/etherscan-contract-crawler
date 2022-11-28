// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ClosedSea.sol";

pragma solidity ^0.8.17;                                                                                
/*                                                                               
                                    ..                                          
                                 :+**+:..                                       
                                -#%%@@+:::                                      
                              .=#%%%@@%%%+-:.                                   
                             .##%#**##****#+**=.                                
                             -%%%#===---+#%+*%##+:                              
                          .==*#%%%##*++*%%#**%%%%#+.                            
                        .*%##%*#%#%#***##**#%%%%###*:                           
                      .=#####*++%%###****#%%%%%%%%%#*:                          
                    .+%#####+-. *%%%%#%%%%%%%%%###%%#+                          
                  .=####+=:.    =%%%%%%%%%%%#*******#*                          
                :=####=.    .-+%%%%%%%%%%%%%%#*+===--=                          
               -####+:.:-=*#%%%%%%%%#%%%%%%####*==-:**                          
  :-=++++*******%%%###%%%%%%%%%%%%%%##%%%%#*###*===*%*:                         
     :=%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##**##+=+**%#+                         
     =%%%%%%%%%%%%%%%%%%%%%%%%%%%%##%%%%########**#=#%=:                        
   :#%%#+-+%%%%%%%%%%%%%%%%%%%%%#****##%#%%%##**%%%*%**+                        
  -%#=. -#%%%%%%%%%%%%%%%%%%%##********#***####%%%%%%***=                       
 .*-  .---*%%%%%%%%%%%%%%%%**#******#%@%#*#%#%%%%%%%#***#=                      
 :      -%%%%%%%%%%%%%%%%#*##******%%%%@%####%%%%%%%##**%#=.                    
       +#+-+%%%%%%%%%%%%#*#******#%%%%%%%#%%#**%%%%%#%##%##=.                   
       .  :#%%%%%%%%%%%%*+#*****%%%%%%%%##%%%#%%%%%%%%#%%###+.                  
          +%%%%%%%%%%%%%+.*****%#%###%%#**#%%%%%#%%%%%%%%%%#*+.                 
          #%%%##%%%%%%%%#+****%%%###%%%*-:=%%%%*%%%%%#%%%%%%#==.                
          +-.:=**+*###%%%###%%#=:.-==-.    .=%*#%%%%%#%%%%%%%+=+                
             .   :=*####**+-:.              #**%%%%%#%%%%%%%%*+=:               
                 .+###*+++.                *#*%%%%%%#%%%%%%%%#+=*               
              ...-*#**=#%+----------======*%*%%%%%%#%%%%%%%%%%*+#+              
 ..........::::-+##**=+#+====++++++++++++*%#%%%%%%%#%%%%%%%%%%#*##*=.           
....:::::-------*%%####+===++++++++++++++##%%%%%%%%%%%%%%%%%%%%######*-.        
...::::-------==###%%*+==++++++++++++++++#%%%%%%%%%%%%%%%%%%%%%%%#######*-      
.::::::-----===*##%%+========++++++++++++#%%%%%%%%%%%%%%%%%%%%%%%%%#######+:    
.:::::::-----=*#%%*=============+++++++++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%#####+.   
:::::::.....:*#%%*-..::::----===+++++++++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%###*-   
::---===---=*#%%#+-           .::-+++++*****#%%%%%%%%%%%%%%#%%%%%%%%%%%%##+.    
.::-====+*%%%%#**=.               .:-==++++**#%%%%%%%###%%%%%#####%%%#*=-.      
 ..::-=+#%%%##+.                       ...::--==+**########%%*=----::.          
   .  .:-=+==:                                       .......       
*/


contract ERC721Namable is ERC721 {

    mapping(uint256 => string) public bio;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    event NameChange (uint256 indexed tokenId, string newName);
    event BioChange (uint256 indexed tokenId, string bio);

    error MustOwnNFT();
    error InvalidNewName();
    error NameMustBeDifferent();
    error NameAlreadyReserved();

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function changeBio(uint256 _tokenId, string memory _bio) public virtual {
        address owner = ownerOf(_tokenId);
        if (_msgSender() != owner) revert MustOwnNFT();

        bio[_tokenId] = _bio;
        emit BioChange(_tokenId, _bio);
    }

    function changeName(uint256 tokenId, string memory newName) public virtual {
        address owner = ownerOf(tokenId);

        if (_msgSender() != owner) revert MustOwnNFT();
        if (!validateName(newName)) revert InvalidNewName();
        if (sha256(bytes(newName)) == sha256(bytes(_tokenName[tokenId]))) revert NameMustBeDifferent(); 
        if (isNameReserved(newName)) revert NameAlreadyReserved();

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

     /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

abstract contract BattlespeciesWithdrawer is Ownable {
    address[] private _team = [
        0xbB868756898868d1B903aB1a6Fac5Fe974409f09,
        0x9434b3E11fcbA9167000626fD8f0e1428ad7c1C8,
        0x45E0A249B3f017C6F3AE2fbEBedE2293f4aA0418
    ];

    event Withdrawed(address indexed recipient, uint256 amount);

    function withdraw(uint256 amount) external onlyOwner {
        if (amount > address(this).balance)
            amount = address(this).balance;
        uint256 share = (amount * 3333333) / 10000000;
        _widthdraw(_team[2], share);
        _widthdraw(_team[1], share);
        _widthdraw(_team[0], amount - share - share);
    }

    function _widthdraw(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
        emit Withdrawed(recipient, amount);
    }
}

interface IHyperwarpManager {
    function tryHyperwarp(uint256 _jumpClone, uint256 _assist) external returns(bool);
    function tryManifest(uint256 _tokenId) external view returns(bool);
    function battlerHasUtility(uint256 _tokenId) external view returns(bool);
}

interface IUtilityHub {
    function burn(address _from, uint256 _amount, uint256 _rewardTokenIndex) external;
    function transferReward(address _from, address _to, uint256 _rewardTokenIndex) external;
    function getReward(address _user, uint256 _rewardTokenIndex) external;
}

contract BattleSpecies is ERC721Namable, ERC721Enumerable, BattlespeciesWithdrawer, OperatorFilterer {

    struct Battler {
        uint256 bornAt;
        bool isManifested;
    }

    IHyperwarpManager hyperwarpManager;
    IUtilityHub utilityHub;

    error NotInWhitelist();
    error MustOwnBothNfts();
    error CannotHyperwarpUtilitySpecies();
    error InvalidOwner();
    error BattlerAlreadyManifested();
    error SaleIsClosed();
    error MaxTokenAllotment();
    error InsuffientEthPaid();

    event BattlerHyperwarped(uint256 indexed tokenId, uint256 jumpClone, uint256 assist);

    event BattlerManifested(uint256 indexed tokenId);

    mapping(uint256 => Battler) public battlers;

    mapping(address => uint256) public rewardableBalanceOf;

    uint256 public constant maxMintsPerWalletBeforeTranscendance = 5;

    uint256 public constant maxMintsPerWalletAfterTranscendance = 10;

    uint256 public constant mintPrice = 55000000 gwei; //0.055 ETH

    uint256 public constant mintWhitelistPrice = 35000000 gwei; //0.35 ETH

    uint256 public constant autoManifestPrice = 10000000 gwei; //0.01 ETH

    uint256 public constant maxBattlers = 4500;

    uint256 public hyperwarpPrice = 600 ether;

    uint256 public nameChangePrice = 60 ether;

    uint256 public bioChangePrice = 10 ether;

    uint256 public rewardTokenIndex = 0;

    string private baseURI;

    string private _contractURI;

    string public provenanceHash;

    bytes32 public wlRoot;

    bool public saleIsActive;

    bool public operatorFilteringEnabled = true;

    constructor(address _hyperwarpManager, address _utilityHub, bytes32 _wlRoot) ERC721Namable("Battlespecies", "BATTLE") {
        setHyperwarpManager(_hyperwarpManager);
        setUtilityHub(_utilityHub);
        setWlRoot(_wlRoot);
        _registerForOperatorFiltering();
        baseURI = "https://api.battlespecies.net/metadata/";
        _contractURI = "https://ipfs.battlespecies.net/ipfs/QmPfhRyvtnRgyv5XYbvtWckYttdHbu86C4SCh1ox8ksBNz";
        for (uint i = 1; i < 31;) {
            _mint(msg.sender, i);
            battlers[i] = Battler(block.timestamp, false);
            rewardableBalanceOf[msg.sender] = 30;
            unchecked {
                ++i;
            }
        }
    }

    /**
     *  ADMIN
     */

    function setProvenanceHash(string calldata hash) external onlyOwner {
        provenanceHash = hash;
    }

    function setWlRoot(bytes32 _wlRoot) public onlyOwner {
        wlRoot = _wlRoot;
    }

    function updateURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function updateContractURI(string memory newURI) public onlyOwner {
        _contractURI = newURI;
    }

    function setHyperwarpManager(address _manager) public onlyOwner {
        hyperwarpManager = IHyperwarpManager(_manager);
    }

    function setUtilityHub(address _hub) public onlyOwner {
        utilityHub = IUtilityHub(_hub);
    }

    function setRewardToken(uint256 _rewardTokenIndex) public onlyOwner {
        rewardTokenIndex = _rewardTokenIndex;
    }

    function flipSaleState() external onlyOwner {
      saleIsActive = !saleIsActive;
    }

    function changHyperwarpPrice(uint256 _price) external onlyOwner {
        hyperwarpPrice = _price;
    }

    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function changeBioPrice(uint256 _price) external onlyOwner {
        bioChangePrice = _price;
    }

    function _baseMint(uint numberOfTokens, bool autoManifest, uint256 _mintPrice) internal {

        if (!saleIsActive) revert SaleIsClosed();

        uint256 _totalSupply = totalSupply();

        if (hyperwarpManager.battlerHasUtility(_totalSupply + numberOfTokens)) {
            if (balanceOf(_msgSender()) + numberOfTokens > maxMintsPerWalletBeforeTranscendance) revert MaxTokenAllotment();
        }
        else {
            if (balanceOf(_msgSender()) + numberOfTokens > maxMintsPerWalletAfterTranscendance) revert MaxTokenAllotment();
        }

        if (_totalSupply + numberOfTokens > maxBattlers) revert MaxTokenAllotment();

        if (autoManifest) {
            if ((_mintPrice * numberOfTokens) + (autoManifestPrice * numberOfTokens) > msg.value) revert InsuffientEthPaid();
        }
        else {
            if (_mintPrice * numberOfTokens > msg.value) revert InsuffientEthPaid();
        }

        for(uint256 i = 1; i <= numberOfTokens;) {
            uint256 mintIndex = _totalSupply + i;
            _mint(_msgSender(), mintIndex);
            battlers[mintIndex] = Battler(block.timestamp, autoManifest);
            if (autoManifest) {
                emit BattlerManifested(mintIndex);
            }
            unchecked {
                ++i;
            }
        }

        assert(totalSupply() == _totalSupply + numberOfTokens);
    }

    /**
     * Public
     */

    function inWhitelist(bytes32[] calldata _wlProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(_wlProof, wlRoot, leaf);
    }

    function mint(uint numberOfTokens, bool autoManifest) public payable {
        _baseMint(numberOfTokens, autoManifest, mintPrice);
    }

    function mintWhitelist(uint numberOfTokens, bool autoManifest, bytes32[] calldata _wlProof) public payable {
        if (!inWhitelist(_wlProof)) revert NotInWhitelist();
        _baseMint(numberOfTokens, autoManifest, mintWhitelistPrice);
    }

    function hyperwarp(uint256 _jumpClone, uint256 _assist) external returns (uint256 mintIndex) {
        if (ownerOf(_jumpClone) != _msgSender() || ownerOf(_assist) != _msgSender()) revert MustOwnBothNfts();
        hyperwarpManager.tryHyperwarp(_jumpClone, _assist);
        utilityHub.burn(_msgSender(), hyperwarpPrice, rewardTokenIndex);
        mintIndex = totalSupply() + 1;
        //we have to make sure the index isn't an utility species
        if (hyperwarpManager.battlerHasUtility(mintIndex)) revert CannotHyperwarpUtilitySpecies();
        battlers[mintIndex] = Battler(block.timestamp, false);
        _mint(_msgSender(), mintIndex);
        emit BattlerHyperwarped(mintIndex, _jumpClone, _assist);
    }

    function manifest(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != _msgSender() && owner() != _msgSender()) revert InvalidOwner();
        Battler storage battler = battlers[_tokenId];
        if (battler.isManifested) revert BattlerAlreadyManifested();
        battler.isManifested = hyperwarpManager.tryManifest(_tokenId);
        emit BattlerManifested(_tokenId);
    }

    function changeName(uint256 tokenId, string memory newName) public override {
        utilityHub.burn(_msgSender(), nameChangePrice,  rewardTokenIndex);
        super.changeName(tokenId, newName);
    }

    function changeBio(uint256 tokenId, string memory _bio) public override {
        utilityHub.burn(_msgSender(), bioChangePrice, rewardTokenIndex);
        super.changeBio(tokenId, _bio);
    }

    function getReward() external {
        utilityHub.getReward(_msgSender(), rewardTokenIndex);
    }

    function getReward(uint256 _rewardTokenIndex) external {
        utilityHub.getReward(_msgSender(), _rewardTokenIndex);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * Overrides
     */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (tokenId > uint(30) && hyperwarpManager.battlerHasUtility(tokenId)) {
            utilityHub.transferReward(from, to, rewardTokenIndex);
            if (from != address(0)) {
                rewardableBalanceOf[from]--;
            }
            if (to != address(0)) {
                rewardableBalanceOf[to]++;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * OperatorFilterer related
     */

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool enabled) public onlyOwner {
        operatorFilteringEnabled = enabled;
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }
}