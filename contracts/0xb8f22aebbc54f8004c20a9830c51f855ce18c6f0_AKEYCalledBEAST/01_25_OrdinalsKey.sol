// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract AKEYCalledBEAST is Initializable, ERC721Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private currentSupply;
    uint256 public MAX_KEYS;

    mapping(uint => uint256) public genesisMinted;
    bool public hasClaimStarted = false;
    bool public unlockFound = false;

    string public baseURI;
    address public uriManagerAddr;
    address public akcbAddr;

    uint public UNLOCK_COST;
    event Unlock(uint indexed tokenId, string indexed adr);

    modifier onlyURIManager () {
        require(uriManagerAddr == msg.sender, "URI Manager: caller is not the ipfs manager");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("a KEY called BEAST", "KEYBEAST");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        uriManagerAddr = msg.sender;
        akcbAddr = 0x77372a4cc66063575b05b44481F059BE356964A4;
        baseURI = "ipfs://QmXNv3qZbrVdgKr1tQX6eu7dNiFL4MiRwcDQS1q8ihYVi7/";
        MAX_KEYS = 10000;
        UNLOCK_COST = 0 ether;
    }

    // OpenSea Operator Filter Registry Functions https://github.com/ProjectOpenSea/operator-filter-registry
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function beastsHaveClaimed(uint256[] memory genesisIds) external view returns (bool[] memory) {
        bool[] memory hasClaimed = new bool[](genesisIds.length);

        for (uint256 index = 0; index < genesisIds.length; index++) {
            if (genesisMinted[genesisIds[index]] > 0) {
                hasClaimed[index] = true;
            }
        }

        return hasClaimed;
    }

    function totalSupply() public view returns (uint) {
        return currentSupply.current();
    }

    function mintGenesis(uint genesisId) external {
        require(genesisMinted[genesisId] == 0, "This BEAST has already been claimed for this collection.");
        require(hasClaimStarted, "Claim hasn't started");
        require(totalSupply() < MAX_KEYS, "Max Mint Supply has been reached");

        currentSupply.increment();
        uint tokenId = currentSupply.current();

        genesisMinted[genesisId] = tokenId;

        _safeMint(IERC721(akcbAddr).ownerOf(genesisId), tokenId);
    }

    function mintGenesisBatch(uint[] memory genesisIds) external {
        require(hasClaimStarted, "Claim hasn't started");
        require(currentSupply.current() <= MAX_KEYS - genesisIds.length, "Max Mint Supply has been reached");
        IERC721 akcbContract = IERC721(akcbAddr);

        for (uint256 i = 0; i < genesisIds.length; i++) {
            require(genesisMinted[genesisIds[i]] == 0, "One of the BEASTs has already been claimed for this collection.");

            currentSupply.increment();
            uint tokenId = currentSupply.current();

            genesisMinted[genesisIds[i]] = tokenId;

            _safeMint(akcbContract.ownerOf(genesisIds[i]), tokenId);
        }
    }

    function mintGenesisHeld(uint genesisId) external onlyOwner {
        require(genesisMinted[genesisId] == 0, "This BEAST has already been claimed for this collection.");
        require(IERC721(akcbAddr).ownerOf(genesisId) == akcbAddr, "Only Genesis that have been sent to the CA can be minted here.");

        currentSupply.increment();
        uint tokenId = currentSupply.current();

        genesisMinted[genesisId] = tokenId;

        _safeMint(owner(), tokenId);
    }

    function setBaseURI(string memory _newBaseURI) public onlyURIManager {
        baseURI = _newBaseURI;
    }

    function setClaimStarted(bool _state) external onlyOwner {
        hasClaimStarted = _state;
    }

    function setUnlockFound(bool _state) external onlyOwner {
        unlockFound = _state;
    }

    function stillPaired(uint256[] memory genesisIds) external view returns (bool[] memory) {
        bool[] memory isPaired = new bool[](genesisIds.length);
        IERC721 akcbContract = IERC721(akcbAddr);

        for (uint256 index = 0; index < genesisIds.length; index++) {
            if (akcbContract.ownerOf(genesisIds[index]) == ownerOf(genesisMinted[genesisIds[index]])) {
                isPaired[index] = true;
            }
        }

        return isPaired;
    }

    function unlock(uint tokenId, string memory adr) external payable {
        require(unlockFound, "Key hole not found");
        require(msg.value >= UNLOCK_COST, "Insufficient funds");
        address holder = ownerOf(tokenId);
        require(holder == msg.sender, "ERC721: Can only called by owner");
        _transfer(holder, 0x000000000000000000000000000000000000dEaD, tokenId);
        emit Unlock(tokenId, adr);
    }

    function withdraw(uint amount) external onlyOwner {
        require(payable(msg.sender).send(amount));
    }

    function setURIManager(address _uriManagerAddr) external onlyOwner {
        require(_uriManagerAddr != address(0), "URI Manager: new owner is the zero address");
        uriManagerAddr = _uriManagerAddr;
    }

    function setUnlockCost(uint cost) external onlyOwner {
        UNLOCK_COST = cost;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}