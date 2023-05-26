// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@
// @@@                                                                                                                   @@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NiftyMusic721 is ERC721A, ERC721ABurnable, Ownable, PaymentSplitter {

    using Strings for uint256;

    // The total tokens minted to an address. Does not matter if tokens are transferred out
    mapping(address => uint256) public addressMintCount;
    mapping(address => bool) public freeMintClaimed;

    string public baseTokenURI; // Can be combined with the tokenId to create the metadata URI
    uint256 public mintPhase = 0; // 0 = closed, 1 = WL sale, 2 = public sale
    bool public allowBurn = false; // Admin toggle for allowing the burning of tokens
    uint256 public constant MINT_PRICE = 0.05 ether; // Public mint price
    uint256 public constant ALLOWLIST_MINT_PRICE = 0.045 ether; // Mint price for allowlisted addresses only
    uint256 public constant MAX_TOTAL_SUPPLY = 2500; // The maximum total supply of tokens
    uint256 public constant MAX_MINT_COUNT = 10; // The maximum number of tokens any one address can mint
    uint256 public maxWLMintCount = 20; // The maximum number of tokens a whitelisted address can mint
    bytes32 public wlRoot; // The merkle tree root. Used for verifying allowlist addresses
    bytes32 public freeMintRoot; // Merkle root for free mint list

    uint256 private constant MAX_TOKEN_ITERATIONS = 40; // Used to prevent out-of-gas errors when looping

    event SetBaseURI(address _from);
    event Withdraw(address _from, address _to, uint amount);
    event MintPhaseChanged(address _from, uint newPhase);
    event ToggleAllowBurn(bool isAllowed);

    constructor(string memory _baseUri, bytes32 _WLmerkleroot, bytes32 _freeMintMerkleroot, address[] memory _payees, uint256[] memory _shares) ERC721A("Moonshot", "MOON") PaymentSplitter(_payees, _shares) {
        baseTokenURI = _baseUri;
        wlRoot = _WLmerkleroot;
        freeMintRoot = _freeMintMerkleroot;
    }

    // Allows the contract owner to update the merkle root (allowlist)
    function setWLMerkleRoot(bytes32 _WLmerkleroot) external onlyOwner {
        wlRoot = _WLmerkleroot;
    }

    // Allows the contract owner to update the merkle root (free mint list)
    function setFreeMintMerkleRoot(bytes32 _freeMintMerkleroot) external onlyOwner {
        freeMintRoot = _freeMintMerkleroot;
    }

    // Allows the contract owner to set a new base URI string
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
        emit SetBaseURI(msg.sender);
    }

    // Allows the contract owner to set the wl cap
    function setWLCap(uint _newCap) external onlyOwner {
        maxWLMintCount = _newCap;
    }

    // Overrides the tokenURI function so that the base URI can be returned
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    function mint(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        uint256 mintCount = addressMintCount[msg.sender];
        require(mintPhase==2, "Public sale is not yet active");
        require(_amount > 0, "Mint amount can't be zero");
        require(mintCount + _amount <= MAX_MINT_COUNT, "Exceeded max mint count");
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max mint supply has been reached");
        require(_amount * MINT_PRICE == msg.value, "Check mint price");

        addressMintCount[msg.sender] = mintCount + _amount;
			
        _safeMint(msg.sender, _amount);
    }

    // Only accessible by the contract owner. This function is used to mint tokens for the team.
    function ownerMint(uint256 _amount, address _recipient) external onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0, "Mint amount can't be zero");
        require(_amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction"); // Used to avoid OOG errors.
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        
        _safeMint(_recipient, _amount);
    }

    // Minting function for addresses on the allowlist only
    function mintAllowList(uint256 _amount, bytes32[] calldata _proof) external payable {
        uint256 supply = totalSupply();
        uint256 mintCount = addressMintCount[msg.sender];
        require(_verify(_leaf(msg.sender), _proof, wlRoot), "Wallet not on allowlist");
        require(mintCount + _amount <= maxWLMintCount, "Exceeded whitelist allowance.");
        require(mintPhase==1, "Allowlist sale is not active");
        require(_amount > 0, "Mint amount can't be zero");
        require(_amount <= MAX_TOKEN_ITERATIONS, "You cannot mint this many in one transaction."); // Used to avoid OOG errors
        require(supply + _amount <= MAX_TOTAL_SUPPLY, "Max supply is reached");
        require(_amount * ALLOWLIST_MINT_PRICE == msg.value, "Incorrect price");

        addressMintCount[msg.sender] = mintCount + _amount;
        
        _safeMint(msg.sender, _amount);
    }

    // Minting function addresses on the OG list only
    function mintFreeMintList(bytes32[] calldata _proof) external {
        uint256 supply = totalSupply();
        require(!freeMintClaimed[msg.sender], "Free mint already claimed");
        require(_verify(_leaf(msg.sender), _proof, freeMintRoot), "Wallet not on free mint list");
        require(mintPhase==1, "Sale is not active");
        require(supply + 1 <= MAX_TOTAL_SUPPLY, "Max supply is reached");

        freeMintClaimed[msg.sender] = true;

        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, 1);
    }

    // An owner-only function which toggles the public sale on/off
    function changeMintPhase(uint256 _newPhase) external onlyOwner {
        mintPhase = _newPhase;
        emit MintPhaseChanged(msg.sender, _newPhase);
    }

    // An owner-only function which toggles the allowBurn variable
    function toggleAllowBurn() external onlyOwner {
        allowBurn = !allowBurn;
        emit ToggleAllowBurn(allowBurn);
    }

    // Used to construct a merkle tree leaf
    function _leaf(address _account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_account));
    }

    // Verifies a leaf is part of the tree
    function _verify(bytes32 leaf, bytes32[] memory _proof, bytes32 _root) pure
    internal returns (bool)
    {
        return MerkleProof.verify(_proof, _root, leaf);
    }

    // Overrides the ERC721A burn function
    function burn(uint256 _tokenId) public virtual override {
        require(allowBurn, "Burning is not currently allowed");
        _burn(_tokenId, true);
    }
}