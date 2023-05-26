//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

 @@@@@@@  @@@        @@@@@@   @@@  @@@  @@@@@@@    @@@@@@       @@@@@@   @@@  @@@      @@@@@@@  @@@  @@@   @@@@@@   @@@  @@@  @@@   @@@@@@   
@@@@@@@@  @@@       @@@@@@@@  @@@  @@@  @@@@@@@@  @@@@@@@      @@@@@@@@  @@@@ @@@     @@@@@@@@  @@@  @@@  @@@@@@@@  @@@  @@@@ @@@  @@@@@@@   
[email protected]@       @@!       @@!  @@@  @@!  @@@  @@!  @@@  [email protected]@          @@!  @@@  @@[email protected][email protected]@@     [email protected]@       @@!  @@@  @@!  @@@  @@!  @@[email protected][email protected]@@  [email protected]@       
[email protected]!       [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!          [email protected]!  @[email protected]  [email protected][email protected][email protected]!     [email protected]!       [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected][email protected][email protected]!  [email protected]!       
[email protected]!       @!!       @[email protected]  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!  [email protected]@!!       @[email protected]  [email protected]!  @[email protected] [email protected]!     [email protected]!       @[email protected][email protected][email protected]!  @[email protected][email protected][email protected]!  [email protected]  @[email protected] [email protected]!  [email protected]@!!    
!!!       !!!       [email protected]!  !!!  [email protected]!  !!!  [email protected]!  !!!   [email protected]!!!      [email protected]!  !!!  [email protected]!  !!!     !!!       [email protected]!!!!  [email protected]!!!!  !!!  [email protected]!  !!!   [email protected]!!!   
:!!       !!:       !!:  !!!  !!:  !!!  !!:  !!!       !:!     !!:  !!!  !!:  !!!     :!!       !!:  !!!  !!:  !!!  !!:  !!:  !!!       !:!  
:!:        :!:      :!:  !:!  :!:  !:!  :!:  !:!      !:!      :!:  !:!  :!:  !:!     :!:       :!:  !:!  :!:  !:!  :!:  :!:  !:!      !:!   
 ::: :::   :: ::::  ::::: ::  ::::: ::   :::: ::  :::: ::      ::::: ::   ::   ::      ::: :::  ::   :::  ::   :::   ::   ::   ::  :::: ::   
 :: :: :  : :: : :   : :  :    : :  :   :: :  :   :: : :        : :  :   ::    :       :: :: :   :   : :   :   : :  :    ::    :   :: : :    


*/


import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CloudsOnChains is
    ERC721,
    IERC2981,
    Pausable,
    AccessControl
{
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint public constant MAX_SUPPLY = 421;         // +1 to save on gas cost of <= vs <
    uint public constant MAX_MINT_COUNT = 6;       // +1 to save on gas cost of <= vs <
    uint public constant ARTIST_PROOF_COUNT = 21;  // +1 to save on gas cost of <= vs <
    uint public constant ETH_PRICE = 0.222 ether;
    string public provenanceHash = 'fc4aea456c0f61e165670400d6792aa0ee75a579b24ad809c1edc16e3464ad3e';
    string private _baseURIextended = "https://cloudsonchains.xyz/api/metadata/";
    address payable private _withdrawalWallet = payable(0xFAd018e5555Fe9C25f92D11B86BdfaF3947E15e8);

    constructor() ERC721("CloudsOnChains", "CLOUDS") {
        _pause(); // start paused
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, 0xcb77c9A73E969D0d19CcaE16545eF635702baA85); // k ledger
        grantRole(MANAGER_ROLE, msg.sender);
        setWithdrawalWallet(msg.sender);
    }

    function setWithdrawalWallet(address withdrawalWallet_) public onlyRole(MANAGER_ROLE) {
        _withdrawalWallet = payable(withdrawalWallet_);
    }
    function withdraw() public onlyRole(MANAGER_ROLE) {
        _withdrawalWallet.transfer(address(this).balance);
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }
    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function setProvenanceHash(string memory provenanceHash_) public onlyRole(MANAGER_ROLE) {
        provenanceHash = provenanceHash_;
    }
    function setBaseURI(string memory baseURI_) public onlyRole(MANAGER_ROLE) {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function contractURI() public view returns (string memory) {
        string memory base = _baseURI();
        return string(abi.encodePacked(base, "metadata.json"));
    }

    function getLastTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= _tokenIds.current(), "Nonexistent token");
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function mint(uint count)
    public
    payable
    whenNotPaused
    returns (uint256)
    {
        require((ETH_PRICE * count) == msg.value, "Incorrect ETH sent; check price!");
        require(count < MAX_MINT_COUNT, "Tried to mint too many NFTs at once");
        require(_tokenIds.current() + count < MAX_SUPPLY, "SOLD OUT");
        for (uint i=0; i<count; i++) {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
        }
        return _tokenIds.current();
    }

    // Allows an admin to mint the artist proofs, and send it to an address
    // This can be run while the contract is paused
    function adminMint(uint count, address recipient)
    public
    onlyRole(MANAGER_ROLE)
    returns (uint256)
    {
        require(_tokenIds.current() + count < ARTIST_PROOF_COUNT, "Exceeded max proofs");
        require(_tokenIds.current() + count < MAX_SUPPLY, "SOLD OUT");
        for (uint i=0; i<count; i++) {
            _tokenIds.increment();
            _safeMint(recipient, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}