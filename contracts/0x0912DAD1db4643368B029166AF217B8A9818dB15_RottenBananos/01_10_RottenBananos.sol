/*

 $$$$$$\   $$$$$$\  $$$$$$$\        $$\   $$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\        $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\       $$ |  $$ |$$  __$$\\__$$  __|$$  _____|$$  __$$\       $$$\  $$ |$$  _____|\__$$  __|$$  _____|$$  _____|$$  __$$\ 
$$ /  \__|$$ /  $$ |$$ |  $$ |      $$ |  $$ |$$ /  $$ |  $$ |   $$ |      $$ /  \__|      $$$$\ $$ |$$ |         $$ |   $$ |      $$ |      $$ /  \__|
$$ |$$$$\ $$ |  $$ |$$ |  $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |   $$$$$\    \$$$$$$\        $$ $$\$$ |$$$$$\       $$ |   $$$$$\    $$$$$\    \$$$$$$\  
$$ |\_$$ |$$ |  $$ |$$ |  $$ |      $$  __$$ |$$  __$$ |  $$ |   $$  __|    \____$$\       $$ \$$$$ |$$  __|      $$ |   $$  __|   $$  __|    \____$$\ 
$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$\   $$ |      $$ |\$$$ |$$ |         $$ |   $$ |      $$ |      $$\   $$ |
\$$$$$$  | $$$$$$  |$$$$$$$  |      $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ \$$$$$$  |      $$ | \$$ |$$ |         $$ |   $$$$$$$$\ $$$$$$$$\ \$$$$$$  |
 \______/  \______/ \_______/       \__|  \__|\__|  \__|  \__|   \________| \______/       \__|  \__|\__|         \__|   \________|\________| \______/ 
                                                                                                                                                       
                                                                                                                                                                                                                                                                                        
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256); 
    function tokensOfOwner(address owner) external view returns (uint256[] memory); 
    function ownerOf(uint256 tokenId) external view returns (address owner);

}


contract RottenBananos is ERC1155, Ownable {

    // Public Constants
    uint256 public constant MAX_SUPPLY_WL_PHASE_1 = 1000;
    uint256 public constant MAX_SUPPLY = 4696;
    uint256 public constant MAX_MINTS_WL_PHASE_1 = 1;
    uint256 public constant MAX_MINTS_WL_PHASE_2 = 5;
    uint256 public constant MAX_MINTS_PUBLIC = 5;
    uint256 public constant BANANA_PRICE_WL_PHASE1 = 0 ether;
    uint256 public constant BANANA_PRICE_WL_PHASE2 = 0.069 ether;
    uint256 public constant BANANA_PRICE_PUBLIC = 0.069 ether;
    string public name;
    string public symbol;

    // Variables
    string private baseURI;
    uint256 public _minted = 0;
    address SuperBanana;

    // Sale controllers
    bool public WhitelistPhase1Paused = true;
    bool public WhitelistPhase2Paused = true;
    bool public PublicPaused = true;


    // Mappings
    mapping(uint256 => bool) public dvdaTokenIDBlacklisted; 
    mapping (uint256 => bool) public AlreadyClaimedDVDA; 
    mapping (address => uint256) public AmountClaimedWLPhase2;
    mapping (address => uint256) public AmountClaimedPublic;

    IERC721 DVDA = IERC721(0xC084a29DD0C9436568435938B1C6c5af4F5C035f); 
    IERC721 GHN = IERC721(0xE6d48bF4ee912235398b96E16Db6F310c21e82CB); 
    IERC1155 BNNO = IERC1155(0x50BEfFd8A0808314d3cc81B3cbF7f1AFA3A6B56c);
    IERC721 AHC = IERC721(0x9370045CE37F381500ac7D6802513bb89871e076);

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
        ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }
  
    function MintWhitelistPhase1(uint256 DVDA_ID) public payable {
        require(!WhitelistPhase1Paused, "Whitelist Phase 1 sale is paused"); 
        require(MAX_MINTS_WL_PHASE_1 + _minted <= MAX_SUPPLY_WL_PHASE_1, "Bananos: Exceed WL max supply");
        address _owner = DVDA.ownerOf(DVDA_ID); 
        require(_owner == msg.sender, "Must be Owner of DVDA TOKEN ID to mint"); 
        require(msg.value == MAX_MINTS_WL_PHASE_1 * BANANA_PRICE_WL_PHASE1, "Invalid funds provided"); 
        require(!dvdaTokenIDBlacklisted[DVDA_ID], "DVDA Token ID Blacklisted"); 
        require(!AlreadyClaimedDVDA[DVDA_ID], "Banano already claimed with this DVDA Token ID.");
        _minted += MAX_MINTS_WL_PHASE_1;
        AlreadyClaimedDVDA[DVDA_ID] = true; 
        _mint(msg.sender, 0, MAX_MINTS_WL_PHASE_1, "");
        delete _owner;
    }

    function MintWhitelistPhase2(uint256 amount) public payable {
        require(!WhitelistPhase2Paused, "Whitelist Phase 2 sale is paused"); 
        require(MAX_MINTS_WL_PHASE_2 + _minted <= MAX_SUPPLY, "Bananos: Exceed max supply"); 
        require (isHolderGHNFTeesEcosystem(msg.sender), "Require at least 1 NFT from GodHatesNFTees ecosystem (1 GodHates or 1 Ape or 1 Banano or 1 DVDA)");
        require(amount > 0 && amount <= MAX_MINTS_WL_PHASE_2, "Invalid mint amount");
        require(msg.value == amount * BANANA_PRICE_WL_PHASE2, "Invalid funds provided"); 
        require(AmountClaimedWLPhase2[msg.sender] < MAX_MINTS_WL_PHASE_2, "Already minted 5 Bananos");
        AmountClaimedWLPhase2[msg.sender]+=amount;
        _minted += amount;
        _mint(msg.sender, 0, amount, "");
    }



    function MintPublic(uint256 amount) public payable {
        require(!PublicPaused, "Paused");
        require(amount + _minted <= MAX_SUPPLY, "Banana: Exceed max supply");
        require(amount > 0 && amount <= MAX_MINTS_PUBLIC, "Invalid mint amount");
        require(msg.value == amount * BANANA_PRICE_PUBLIC, "Invalid funds provided");
        require(AmountClaimedPublic[msg.sender] < MAX_MINTS_PUBLIC, "Already minted 5 Bananos");
        AmountClaimedPublic[msg.sender]+=amount;
        _minted += amount;
        _mint(msg.sender, 0, amount, "");
    }


    function setWhitelistPhase1Pause(bool _state) public onlyOwner {
        WhitelistPhase1Paused = _state;
    }
   function setWhitelistPhase2Pause(bool _state) public onlyOwner {
        WhitelistPhase2Paused = _state;
    }
    function setPublicPause(bool _state) public onlyOwner {
        PublicPaused = _state;
    }
    
    function CheckifDVDAClaimed(uint256 NftID) public view returns (bool){
        return AlreadyClaimedDVDA[NftID];
    }

    function burnBanana(address burnTokenAddress) external {
        require(msg.sender == SuperBanana , "Invalid caller, must be called from SuperBanana Smart Contract");
        _burn(burnTokenAddress, 0, 1);
    }

    function setSuperBananaAddress(address SuperBananaAddress) external onlyOwner {
        SuperBanana = SuperBananaAddress;
    }

    function HowManyDVDAs(address account) public view returns (uint256){
            uint256 numberdvdas = DVDA.balanceOf(account);
            return numberdvdas;
        }


  function HowManyClaimedWLPhase2(address account) public view returns (uint256){
            return AmountClaimedWLPhase2[account];
        }


  function HowManyClaimedPublic(address account) public view returns (uint256){
            return AmountClaimedPublic[account];
        }

    function DVDA_TOKENS_IDs(address account) public view returns (uint256[] memory){
            uint256[] memory tokendvdas = DVDA.tokensOfOwner(account);
            return tokendvdas;
        }

    function isHolderGHNFTeesEcosystem(address account) public view returns (bool){
                bool HolderGHNFTeesEcosystem;
                if (DVDA.balanceOf(account)>0 || GHN.balanceOf(account)>0 || AHC.balanceOf(account)>0 || BNNO.balanceOf(account,0) > 0){
                    HolderGHNFTeesEcosystem = true;
                }
                return HolderGHNFTeesEcosystem;
            }


    function updateUri(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
    }

    function addDVDATokenIDToBlackList(uint256 tokenid) public onlyOwner {
        dvdaTokenIDBlacklisted[tokenid] = true;
    }

    function addDVDATokenIDsArrayToBlackList(uint256[] memory tokenids) public onlyOwner {
        for (uint256 i=0;i< tokenids.length;i++)
            dvdaTokenIDBlacklisted[tokenids[i]] = true; 
    }

    function removeDVDATokenIDFromBlackList(uint256 tokenid) public onlyOwner {
        dvdaTokenIDBlacklisted[tokenid] = false;
    }

    function isDVDATokenIDInWhitelist(uint256 tokenid) private view returns (bool) {
        return dvdaTokenIDBlacklisted[tokenid] ;
    }

   function MintAdmin(uint256 amount) external onlyOwner  {
        require(amount + _minted <= MAX_SUPPLY, "Banana: Exceed max supply");
        _minted += amount;
        _mint(msg.sender, 0, amount, "");
    }

    function withdrawMoney() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

     function withdrawMoneyTo(address payoutAddress) external onlyOwner {
    (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

}