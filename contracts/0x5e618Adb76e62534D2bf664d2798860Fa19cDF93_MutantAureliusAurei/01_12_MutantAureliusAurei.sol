//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

from [email protected] and [email protected]

  creators of the NFT mechanics:
    - "owner managed tokens" - tokens that can be moved to wallets exclusively by owner, and a momento is left behind. Inspired by https://theworm.wtf/
    - "shitlist" - an updatable list of wallets that cannot mint or own. sometimes there are consequences. 

if you'd like to understand the full development stack, find the whole coding suite at: https://github.com/femmedecentral

*/

contract MutantAureliusAurei is ERC721 {

    // counters is a safe way of counting that can only be +/- by one
    // https://docs.openzeppelin.com/contracts/4.x/api/utils#Counters
    using Counters for Counters.Counter;
    Counters.Counter private _aureindexCounter;
    Counters.Counter private _mementosIssuedCounter;
    Counters.Counter private _totalAureiMinted; 

    // traditionally we'd include SafeMath here, but safemath is no longer necessary in solidity 0.8.0+
    // https://docs.openzeppelin.com/contracts/4.x/api/utils
    // using SafeMath for uint256;

    uint256 private MAX_MINTABLE_AT_ONCE = 1; 

    // The fixed amount of Aurei tokens stored in an unsigned integer type variable.
    uint256 public totalAureiSupply = 888;
    uint256 public initialOwnerManagedTokens = 7;

    // these are private because we write getters for them, no need to make them readable as-is
    string private _baseTokenURI;

    // bool to pause contract; set to pause immediately after initial owner controlled tokens are minted to prevent premature public minting
    bool private _contractIsPaused;
    bool private _allowListActive;
    address private _ownerAddress;
    mapping (address => bool) private _shitlist;
    mapping (address => bool) private _allowlist;
    mapping (address => bool) private _extendedownerlist;	

    constructor() ERC721("Mutant Aurelius Aurei", "MAA") {
        
        _baseTokenURI = "ipfs://QmVEN6zbeyo2mhVKwm6bd2DWBLFFnGLXQGuKyQEtLCVWwV/";
        _ownerAddress = msg.sender; // deployer is owner

        // shitlist addresses at time of contract deploy
        _shitlist[0x7d4c4d5380Ca2F9C7A091bb622B80613da7Eae8C] = true; // soby.eth
        _shitlist[0x385375FD99D6019c630b1315D3815BB162Aa039e] = true; // soby.eth
        _shitlist[0x7683eBB2190a3BCCab1203773E0df54283Df1D5C] = true; // soby.eth
        _shitlist[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = true; // for testing purposes

        // it's a little hacky to do this like this, but I didn't want to build a frontend or spend more on gas
        _allowlist[0xf5324Be5dB41Ba9e464E14F3940ECCDE98993682] = true; 
        _allowlist[0xbD6907023e8129C6219536C1Bf2e7FB9e0CEd8E1] = true; 
        _allowlist[0x0BffF40545a2250c3f11993e7B75dbbcB11e36ac] = true; 
        _allowlist[0xef21C2D39f4d7d7A2Ea698043AFFa888c1295cD3] = true; 
        _allowlist[0xb0C63F8e0264A05421F2f4FC7F68B578c5e700D6] = true; 
        _allowlist[0x866F74c2c65D230CB6a4ceA159daa5996377F81d] = true; 
        _allowlist[0xe5e06284E9041428Dc3D4506Aeea5D59e91dd514] = true; 
        _allowlist[0xDf6d32981752C438a8AdFc801576e4e4dAc204C0] = true; 
        _allowlist[0x68D4A6fAD7b5682dB97C0a4455e282cE4f193bE6] = true; 
        _allowlist[0xfdF3df1c1bBE75E33C33B3335A305Ff7233479Fa] = true; 
        _allowlist[0x205443BF37BA94c0cD58F0B53611E17A5502085D] = true; 
        _allowlist[0x3EB62c8aa2aC0315f7967C765b62DBbc30DA771b] = true; 
        _allowlist[0x5Bf3E69eA5359F739f8239278210b371Bc220582] = true; 
        _allowlist[0x8C062bC26b5f976D3F59c1251e8B6EbcB120f091] = true; 
        _allowlist[0x407d6475Bf21BC1c328e2D48003B86cc4F5FF51F] = true; 
        _allowlist[0x6444D68647760C75df9Da50176eEED944628046C] = true; 
        _allowlist[0x0707D3b48f7d810C96C4B348DC4A1d8086e576ef] = true; 
        _allowlist[0xaD8ae856E7cA9E62BdCdC2c1E812ff46C9dcea1f] = true; 
        _allowlist[0x3376b95e03C1B03bC408DbCb4e9734f4456932df] = true; 
        _allowlist[0x1afa798e2185e38411084BB6D7E5DAb975f032c8] = true; 
        _allowlist[0xE5242F38F1A0C6497ed202C7276B3E4398A07f93] = true; 

        // list of folks who can manage owner-managed tokens	
        _extendedownerlist[_ownerAddress] = true;	
        _extendedownerlist[0x5A97d44De4fE69E194541a4d78db37218872D859] = true;

        _contractIsPaused = false;
        _allowListActive = true;

        // Tokens ID #1-7 & #888 are to be initially owned by contract owner
        _mintOwnerManaged();

        // after initial mint, ensure we deploy as paused
        _contractIsPaused = true;

    }

    // public function to mint aurei; mints the next available Aureus
    // NOTE: this function should be made payable if you want to have a non-free mint
    function mint() public {
        
        // require that contract isn't paused when minting
        require(!_contractIsPaused, "SOON");

        // require that user is on allowlist if allowlist is enabled
        if (_allowListActive) {
            require(_allowlist[msg.sender] == true, "You're not on the list.");
        }

        // using tokenId = 0 to specify that we just want the next one, since solidity doens't offer optional params
        _mintAureiWithChecks(msg.sender, 0);
    }

    // public function to mint a favorite Aureus, provided it hasn't been claimed yet; only available in allowlist phase
    function mintFavorite(uint256 tokenId) public {
        // require that contract isn't paused when minting
        require(!_contractIsPaused, "SOON");

        // require that allowlist phase is on
        require(_allowListActive, "Allowlisting isn't enabled. Picking favorites is a thing of the past.");

        // require that user is on allowlist
        require(_allowlist[msg.sender] == true, "You're not on the list.");

        // require that favorite token is within range
        require(tokenId <= 888, "You're trying to mint an Aureus outside the set");

        // require that tokenID isn't already minted()
        require(!_exists(tokenId), "You have great taste; someone else has already minted your favorite.");

        _mintAureiWithChecks(msg.sender, tokenId);
    }

    // for minting aurei w/ contract specific checks
    function _mintAureiWithChecks(address _mintAddress, uint256 tokenId) internal {

        // ensure we aren't minting beyond the limit
        require(getTotalAureiMinted() < totalAureiSupply, "Many have come before you. Too many, in fact.");

        // ensure only one per wallet; current balance is zero aurei in the wallet, only enabling as courtesy
        require(balanceOf(msg.sender) < MAX_MINTABLE_AT_ONCE, "Always leave 'em wanting more.");

        // check to make sure they're not on our shitlist
        require(_shitlist[_mintAddress] != true, "NONE FOR YOU");

        // increment before minting
        // must ensure that the counter is aligned to next available slot, since we're allowing folks to mint out of order
        while (_exists(getIndexedAureiCount()) == true) { 
            _aureindexCounter.increment();
        }

        // provided all basic checks are cleared, mint it!
        _totalAureiMinted.increment(); // increment total minted
        if (tokenId == 0) {
            _mint(_mintAddress, getIndexedAureiCount()); // if tokenId is unspecified
        } else {
            _mint(_mintAddress, tokenId); // mint a specific token
        }

    }

    // for minting the initial Owner Managed tokens
    function _mintOwnerManaged() internal {
        // require that contract isn't paused when minting
        require(!_contractIsPaused, "SOON");

        // Tokens ID 1 - 7 and #888 are to be initially owned by contract owner
        for (uint256 mt = 1; mt <= initialOwnerManagedTokens; mt++) {
            _aureindexCounter.increment();
            _totalAureiMinted.increment();
            _mint(_ownerAddress, mt);
        }
        // minting [email protected] token; don't incremental tokens because it'll cause numbers to start @ 8 instead of 7 issued tokens
        _totalAureiMinted.increment();
        _mint(_ownerAddress, 888);
    }

    ////// Transfer modifications

    // override the _beforeTokenTransfer hook to check our local paused variable, check the shitlist, and if owner managed
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {

        // check that contract isn't paused
        require(!_contractIsPaused, "SOON");

        /// check to make sure they're not on our shitlist 
        require(_shitlist[to] != true, "NONE FOR YOU");

        // check to make sure only extendedownerlist can transfer owner managed coins	
        if(_isOwnerManaged(tokenId)) {	
            require(_extendedownerlist[msg.sender] == true, "Only Mutant Aurelius can bestow owner his favor upon the masses.");	
        } 

        super._beforeTokenTransfer(from, to, tokenId);

    }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // simple getters

    // this overrides the inherited _baseURI(), which is used to construct the token uri. honestly, this seems like a
    // weird way to do this but seems to be a good solution without making the entire contract inherit ERC721URIStorage
    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    // override on tokenURI function because we need to have the same metadata for all momentos, regardless of tokenID
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        if (tokenId <= 888) {
            return super.tokenURI(tokenId);
        } else if (_exists(tokenId)) {
            return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), "memento")) : "";
        } else {
            require(_exists(tokenId), "ERC721: invalid token ID");
        }
    }

    function getIndexedAureiCount() public view returns (uint256) {
        return _aureindexCounter.current(); 
    }

    function getContractIsPaused() public view returns (bool) {
        return _contractIsPaused;
    }

    function getIssuedMementoCount() public view returns (uint256) {
        return _mementosIssuedCounter.current();
    }

    // returns if address is on the shitlist
    function isOnShitlist(address questionedAddress) public view returns (bool) {
        return _shitlist[questionedAddress]; 
    }

    // returns if address is on the _extendedownerlist	
    function isOnExtendedOwnerList(address questionedAddress) public view returns (bool) {	
        return _extendedownerlist[questionedAddress]; 	
    }

    // returns total minted aurei
    function getTotalAureiMinted() public view returns (uint256) {
        return _totalAureiMinted.current();
    }

    // this is necessary to be able to edit the collection on opensea; it's a simple way to enable this functionality
    // without making the entire contract inherit ERC721Ownable, which has a bunch of functions we don't need
    function owner() public view returns (address) {
        return _ownerAddress;
    }

    // returns 888 as total number of Aurei, but the contract technically mints more via Mementos	
    function totalSupply() public view returns (uint256) {	
        return 888;	
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///// Owner general management funtions

    modifier ownerOnlyACL() {
        require(msg.sender == _ownerAddress, "Impostors to the throne embarrass only themselves.");
        _;
    }

    // extending OwnerOnlyACL in some cases to include a slightly broader set of folks	
    modifier extendedOwnerOnlyACL() {	
        // only MA affiliated addresses can call this function	
        require(_extendedownerlist[msg.sender] == true, "Impostors to the throne embarrass only themselves.");	
        _;	
    }	

    // Update the extended Owner list 	
    function updateExtendedOwnerList(address _extendedOwnerAddress, bool isExtendedOwner) public ownerOnlyACL {	
        _extendedownerlist[_extendedOwnerAddress] = isExtendedOwner; 	
    } 	

    // change who the owner is
    function updateOwner(address _newOwnerAddress) public ownerOnlyACL {
        _ownerAddress = _newOwnerAddress; 
    }

    // set paused state
    function ownerSetPausedState(bool contractIsPaused) public ownerOnlyACL {
        _contractIsPaused = contractIsPaused;
    }

    // set allowlist state
    function ownerSetAllowlistActive(bool allowlistActivityLevel) public ownerOnlyACL {
        _allowListActive = allowlistActivityLevel;
    }

    // set a new base token URI, in case metadata/image provider changes
    function ownerSetBaseTokenURI(string memory newBaseTokenURI) public ownerOnlyACL {
        _baseTokenURI = newBaseTokenURI;
    }

    // Adds a new address to the shitlist
    function ownerAddToShitlist(address _shittyAddress) public ownerOnlyACL {
        _shitlist[_shittyAddress] = true; 
    }

    // Sets a prior shitty address to false, so it can mint again #allIsForgiven... or at least enough is forgiven
    function ownerRemoveFromShitlist(address _shittyAddress) public ownerOnlyACL {
        _shitlist[_shittyAddress] = false; 
    }

    // Adds a new address to the allowlist
    function ownerAddToAllowlist(address _allowAddress) public ownerOnlyACL {
        _allowlist[_allowAddress] = true; 
    }

    // Sets a prior allowed address to false, so they can't mint as part of allowlist
    function ownerRemoveFromAllowlist(address _allowAddress) public ownerOnlyACL {
        _allowlist[_allowAddress] = false; 
    }

    // simplified withdraw function callable by only the owner that withdraws to the owner address. there are no
    // internal state changes here, and it can only be called by owner, so this should(?) be safe from reentrancy
    function ownerWithdrawContractBalance() public ownerOnlyACL {

        uint256 balance = address(this).balance;
        require(balance > 0, "don't waste your gas trying to withdraw a zero balance");

        // withdraw
        (bool withdrawSuccess, ) = msg.sender.call{value: balance}("");

        // this should never happen? but including in case so all state is reverted
        require(withdrawSuccess, "withdraw failed, reverting");

    }

    // Allows owner to change the per-wallet mint limit
    function ownerUpdateWalletLimit(uint256 new_limit) public ownerOnlyACL {
        MAX_MINTABLE_AT_ONCE = new_limit; 
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///// Owner managed token: specific management functions 

    // setting this to public but requiring it to be on the ownerManageList, so only affiliated addresses can manage these functions	
    function ownerSetNewTokenOwner(uint256 tokenId, address newOwner) public extendedOwnerOnlyACL {
        
        // only tokens designated as owner managed can be managed by owner
        require(_isOwnerManaged(tokenId), "Check your token ID again. Something isn't right.");

        // lookup current owner
        address currentOwner = ownerOf(tokenId);

        // only leave a memento in non-owner wallets
        if (currentOwner != _ownerAddress) {
            // do a leave-behind for current owner, so they 'member 
            _mementosIssuedCounter.increment();
            _mint(currentOwner, totalAureiSupply + getIssuedMementoCount());

        }

        // transfer ownership to new address; using _transfer because owner should be able to do this directly
        _transfer(currentOwner, newOwner, tokenId);

    }

    function _isOwnerManaged(uint256 tokenId) internal view returns (bool) {
        // check to see if token ID is # 1-7 or #888
        if (tokenId > 0 && tokenId <= initialOwnerManagedTokens || tokenId == 888) {
            return true;
        } else return false; 
    }
}