// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*

                               @
                             @@@@@@
                            @@@@@@@@
                             @@@@@@@@
                              @@@@@@@@
                              @@@@@@@@@@@,
                             @@@@@@@@@@@@@@@@@@
                         * @@@@@@@@@@@@@@@@@@@@@@@@#
                      /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                        @@,&@@@@@@@@@@@@@@@@@@@@@@@@@&
                        ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                          @@@%@@@@@@@@@@@@@@@@@@@@@@@@@@
                           @@@@@@@@@@@@@#@@@@@@@@@@@@@@@
                           @@@@@@@@@@@@@@@@@@@@@@@@@@&@@
                           /@@@@@@@@@@@@@@@@@@@@@@@@@@@@&
                            /@@@@&@@@@@@@@@@@@@%@##*%@@@@
                            @&@@@@@@@@@@@@@@&%@@@@@@@@@@
                            @@@@@@@&@@&&@@@@@#@@@%  @@@@
                            @@&@@@@@@@@@@&&@&&&@@@@@@#@@
                            @@@@@&@@@@@@@@@@@@@@@@@@@%@@
                            @@@@@@@@@@&@@@@@@@@@@@@@@%@@
                            @&@@@&@@@@@@@@@@@@@@@@@&@&@@
                            @&@@@@@@@@@@@@@@@@@@@@&&&%@@
                            %%@@ @@@@%@@@@@@@%@@&%&%%%@@
                             @@@@@@@&@@&//@@@@@@ &@&%@@@
                             @@@@&@@@@@@@@@@@@@@&&%&%&@@
                             &@@%@@@@(@@@@@@&&&&&&&%%@@@
                             @@@@@@@@@@&/@@@&@&&&@@&&@@@
                             @@@@@@@@@@@@@@@@@&&&&&@@@@@
                            %@@@@@@@@@@@@@@(@@&%&@&&&@@@
                            @@@@@@@@@@@@@@@@@@@@@&&&@@@@.
                            @@@@@@@@@@@@@@@@@@@&@@@@@@@@@
                           ,##(@@@@@@@@@@@@@@@@@@@@@@@@@@#
                           @@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@(
                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                     @@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
               ,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%%#
                      &@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@(
                                              /(#*

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MultisigOwnable.sol";
import "./ERC721A.sol";
import "./extensions/ERC721ABurnable.sol";
import "./extensions/ERC721AQueryable.sol";

contract LikeABrush is MultisigOwnable, ERC721A, ERC721ABurnable, ERC721AQueryable, PaymentSplitter {

    using Strings for uint;

    uint public WLSaleDate = 1663675200;
    uint public ALSaleDate = 1663696800;
    uint public SaleDate = 1663700400;
    uint public EndSaleDate = 1663711200;

    string public baseURI;
    string public unrevealedURI;

    uint private constant METADATAS_LENGTH = 3333;
    uint private constant MAX_TEAM = 333;
    uint private constant MAX_SUPPLY_AL = 3200;

    uint private constant MAX_MINT_PER_WI_ACCOUNT = 5;
    uint private constant MAX_MINT_PER_WL_ACCOUNT = 2;
    uint private constant MAX_MINT_PER_AL_ACCOUNT = 1;
    uint private amountOfWLDoubleOwner = 0;
    uint private constant MAX_WL_DOUBLE_OWNER = 500;
    uint private amountNFTonTM;

    mapping(address => uint) private amountNFTsperWLWallet;
    mapping(address => uint) private amountNFTsperALWallet;
    mapping(address => uint) private amountNFTsperFMWallet;
    mapping(address => uint) private amountNFTsperWIWallet;

    uint public presalePrice = 0.23 ether;
    uint public salePrice = 0.28 ether;
    uint public maxSupply = METADATAS_LENGTH;

    bytes32 public WLRoot;
    bytes32 public OGRoot;
    bytes32 public ALRoot;
    bytes32 public WIRoot;
    bytes32 public TMRoot;
    bytes32 public FreeRoot;
    bytes32 public IronRoot;
    bytes32 public BronzeRoot;
    bytes32 public SilverRoot;
    bytes32 public GoldRoot;
    bytes32 public PlatinumRoot;

    uint private teamLength;

    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        string memory _unrevealedURI,
        string memory _baseURI)
    ERC721A("Like a Brush by Julien Durix", "LIKEABRUSH")
    PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        unrevealedURI = _unrevealedURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Whitelist sale is not activated");
        require(block.timestamp < ALSaleDate, "Whitelist sale is not activated");
        require(isAuthorized(msg.sender, _proof, WLRoot), "Not whitelisted");
        require(amountOfWLDoubleOwner < MAX_WL_DOUBLE_OWNER || _quantity < 2, "No more double whitelist mint possible");
        require(amountNFTsperWLWallet[msg.sender] + _quantity < MAX_MINT_PER_WL_ACCOUNT + 1, "You can only get a maximum of 2 on the Whitelist Sale");
        require(totalSupply() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value == _quantity * presalePrice, "Wrong payment");
        amountNFTsperWLWallet[msg.sender] += _quantity;
        amountOfWLDoubleOwner += (amountNFTsperWLWallet[msg.sender] - 1);
        _mint(msg.sender, _quantity);
    }

    function ogMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "OG sale is not activated");
        require(block.timestamp < ALSaleDate, "OG sale is not activated");
        require(isAuthorized(msg.sender, _proof, OGRoot), "Not whitelisted");
        require(amountNFTsperWLWallet[msg.sender] + _quantity < MAX_MINT_PER_WL_ACCOUNT + 1, "You can only get a maximum of 2 on the OG Sale");
        require(totalSupply() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value == _quantity * presalePrice, "Wrong payment");
        amountNFTsperWLWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function winterMint(address _to, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Whitelist sale is not activated");
        require(block.timestamp < ALSaleDate, "Whitelist sale is not activated");
        require(isAuthorized(_to, _proof, WIRoot), "Not whitelisted");
        require(amountNFTsperWIWallet[msg.sender] + _quantity < MAX_MINT_PER_WI_ACCOUNT + 1, "You can only get a maximum of 5 on the Whitelist Winter Sale");
        require(totalSupply() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value == _quantity * presalePrice, "Wrong payment");
        _mint(_to, _quantity);
    }

    function allowlistMint(bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > ALSaleDate - 1, "AL sale is not activated");
        require(block.timestamp < SaleDate, "AL sale is not activated");
        require(isAuthorized(msg.sender, _proof, ALRoot), "Not whitelisted");
        require(amountNFTsperALWallet[msg.sender] + 1 < MAX_MINT_PER_AL_ACCOUNT + 1, "You can only get a maximum of 1 on the AL Sale");
        require(totalSupply() + 1 < MAX_SUPPLY_AL + 1, "Max supply for AL exceeded");
        require(msg.value == presalePrice, "Wrong payment");
        amountNFTsperALWallet[msg.sender] += 1;
        _mint(msg.sender, 1);
    }

    function publicMint(uint _quantity) external payable callerIsUser {
        require(block.timestamp > SaleDate - 1, "Public sale is not activated");
        require(block.timestamp < EndSaleDate, "Sale is done");
        require(totalSupply() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value == _quantity * salePrice, "Wrong payment");
        _mint(msg.sender, _quantity);
    }

    function winterPublicMint(address _to, uint _quantity) external payable {
        require(block.timestamp > SaleDate - 1, "Public sale is not activated");
        require(block.timestamp < EndSaleDate, "Sale is done");
        require(totalSupply() + _quantity < maxSupply + 1, "Max supply exceeded");
        require(msg.value == _quantity * salePrice, "Wrong payment");
        _mint(_to, _quantity);
    }

    function teamMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp < ALSaleDate, "Team mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, TMRoot), "Not allowed");
        require(amountNFTonTM + _quantity <= MAX_TEAM, "Max supply exceeded");
        require(msg.value == 0, "Wrong payment");
        amountNFTonTM += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMint(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, FreeRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 2, "You can only get 1 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMintIron(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, IronRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 3, "You can only get 2 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMintBronze(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, BronzeRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 4, "You can only get 3 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMintSilver(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, SilverRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 16, "You can only get 15 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMintGold(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, GoldRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 21, "You can only get 20 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function freeMintPlatinum(uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(block.timestamp > WLSaleDate - 1, "Free mint is not activated");
        require(block.timestamp < ALSaleDate, "Free mint is no longer activated");
        require(isAuthorized(msg.sender, _proof, PlatinumRoot), "Not allowed");
        require(amountNFTsperFMWallet[msg.sender] + _quantity < 39, "You can only get 38 free NFT");
        require(msg.value == 0, "Wrong payment");
        amountNFTsperFMWallet[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function setUris(string memory newBaseURI, string memory newUnrevealedURI) external onlyRealOwner {
        baseURI = newBaseURI;
        unrevealedURI = newUnrevealedURI;
    }

    function setRoots(bytes32 _WLRoot, bytes32 _OGRoot, bytes32 _ALRoot, bytes32 _WIRoot, bytes32 _TMRoot, bytes32 _FreeRoot, bytes32 _IronRoot, bytes32 _BronzeRoot, bytes32 _SilverRoot, bytes32 _GoldRoot, bytes32 _PlatinumRoot) external onlyOwner {
        WLRoot = _WLRoot;
        OGRoot = _OGRoot;
        ALRoot = _ALRoot;
        WIRoot = _WIRoot;
        TMRoot = _TMRoot;
        FreeRoot = _FreeRoot;
        IronRoot = _IronRoot;
        BronzeRoot = _BronzeRoot;
        SilverRoot = _SilverRoot;
        GoldRoot = _GoldRoot;
        PlatinumRoot = _PlatinumRoot;
    }

    function setDates(uint _WLSaleDate, uint _ALSaleDate, uint _SaleDate, uint _EndSaleDate) external onlyOwner {
        WLSaleDate = _WLSaleDate;
        ALSaleDate = _ALSaleDate;
        SaleDate = _SaleDate;
        EndSaleDate = _EndSaleDate;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function isAuthorized(address _account, bytes32[] calldata _proof, bytes32 _root) internal pure returns (bool) {
        return _verify(leaf(_account), _proof, _root);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof, bytes32 _root) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    uint public lastTokenRevealed = 0;
    uint256 public randomness = 0;

    function setRandomness(uint256 _randomness) external onlyOwner {
        require(randomness == 0, "Already a randomness");
        randomness = _randomness;
    }

    function getShuffledTokenId(uint id) view internal returns (uint) {
        return uint(keccak256(abi.encodePacked(randomness, id))) % METADATAS_LENGTH;
    }

    function batchReveal(uint256 batchSize) external onlyOwner {
        require(randomness != 0, "Need a randomness");
        require(lastTokenRevealed + batchSize < METADATAS_LENGTH + 1, "Over limit");
        lastTokenRevealed += batchSize;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (id >= lastTokenRevealed) {
            return string(abi.encodePacked(unrevealedURI, id.toString(), ".json"));
        } else {
            return string(abi.encodePacked(baseURI, getShuffledTokenId(id).toString(), ".json"));
        }
    }

    function releaseAll() external onlyRealOwner {
        for (uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }
}