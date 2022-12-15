// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC721A} from "ERC721A/contracts/ERC721A.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IDelegationRegistry} from "delegation-registry/src/IDelegationRegistry.sol";

interface MetadataInterface {
    function _baseURI() external view returns (string memory);
}

contract KongFu is ERC721A, Ownable, ReentrancyGuard {
    address public megaKongsContract = 0x0D7cbFa90a214fc0D8EA692779626fC3dfEbBE08;
    address public delegateContract = 0x00000000000076A84feF008CDAbe6409d2FE638B;
    uint256 public price = 0.025 ether;
    uint256 public maxSupply = 16000;
    uint256 public initialSaleSupply = 10000;
    uint256 public claimedNFTs = 0;
    address public treasury = 0xdaC0F92a43F2E9B9c2207b1bEe3b3942e2B1618f;
    string public contractURI = "ipfs://QmZCVDBsKvJYfNFDY7trYJ61vHv348XpXYREZ75AU65J5K";
    string public baseURI = "https://api.kongfu.megapont.com/metadata/";
    string public rarityProvenance = "450fa4812a680c5003e055736b109bf823e3c72d590da33e65b8bc3b906be6f2";

    bool public claimActive = false;
    bool public saleActive = false;
    bool public initialSaleFinished = false;
    bool public ascendActive = false;
    mapping(uint256 => bool) public ascended;

    /**
     * @notice Indicates if transfers are permitted by proxy through most marketplaces.
     * This is a naive way to stop approvals until the contratc either mints out or one week
     * has passed since the initial sale.
     */
    bool public transferPermitted = false;
    uint256 public mintTimestamp;

    mapping(uint256 => bool) public claimed;

    IDelegationRegistry delegateCash = IDelegationRegistry(delegateContract);

    constructor() ERC721A("KongFu", "KF") {}

    MetadataInterface public metadataInterface;

    event Ascended(uint256 indexed tokenId);

    modifier ascensionNotActive() {
        require(!ascendActive, "Ascension is active");
        _;
    }

    /**
     * @notice Returns the current maximum supply of tokens.
     *
     * If the initial sale has finished, the maximum supply will be returned from
     * the `maxSupply` state variable. Otherwise, the initial sale supply will be
     * returned from the `initialSaleSupply` state variable.
     *
     * @return the current maximum supply of tokens
     */
    function getCurrentMaxSupply() public view returns (uint256) {
        uint256 _maxSupply;

        if (initialSaleFinished) {
            _maxSupply = maxSupply;
        } else {
            _maxSupply = initialSaleSupply + claimedNFTs;
        }
        return _maxSupply;
    }

    function mint(uint256 quantity) public payable nonReentrant ascensionNotActive {
        require(saleActive, "Sale is not active");
        require(quantity > 0, "Quantity must be greater than 0");
        require(totalSupply() + quantity <= getCurrentMaxSupply(), "Mint amount exceeds max supply");
        require(msg.value >= price * quantity, "Ether value sent is not correct");
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Mints a single token to the given address.
     *
     * This function is only callable by the contract owner and is intended to be
     * used to mint the initial token to the contract owner. Useful for setting up
     * marketplaces to avoid url routing issues with scammers.
     */
    function firstMint() public onlyOwner {
        require(totalSupply() == 0, "Already minted");
        _safeMint(msg.sender, 1);
    }

    function _claim(uint256[] memory tokenIds, address _kongOwner, address _mintAddress) internal {
        require(claimActive, "Claim is not active");
        uint256 claimQuantity = tokenIds.length;
        require(totalSupply() + claimQuantity <= maxSupply, "Mint amount exceeds max supply");
        for (uint256 i = 0; i < claimQuantity; i++) {
            require(IERC721(megaKongsContract).ownerOf(tokenIds[i]) == _kongOwner, "You do not own this MegaKong");
            require(!claimed[tokenIds[i]], "This MegaKong has already claimed");
            claimed[tokenIds[i]] = true;
        }
        claimedNFTs += claimQuantity;
        _safeMint(_mintAddress, claimQuantity);
    }

    function claim(uint256[] memory tokenIds) public nonReentrant ascensionNotActive {
        _claim(tokenIds, msg.sender, msg.sender);
    }

    function delegateClaim(uint256[] memory tokenIds, address _vaultAddress) public nonReentrant ascensionNotActive {
        require(
            delegateCash.checkDelegateForAll(msg.sender, _vaultAddress)
                || delegateCash.checkDelegateForContract(msg.sender, _vaultAddress, megaKongsContract),
            "No valid delegation found"
        );
        _claim(tokenIds, _vaultAddress, msg.sender);
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function isAscended(uint256 tokenId) public view returns (bool) {
        return ascended[tokenId];
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Treasury cannot be 0 address");
        treasury = _treasury;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMegaKongsContract(address _megaKongsContract) public onlyOwner {
        require(_megaKongsContract != address(0), "MegaKongs contract cannot be 0 address");
        megaKongsContract = _megaKongsContract;
    }

    function setDelegateContract(address _delegateContract) public onlyOwner {
        require(_delegateContract != address(0), "Delegate contract cannot be 0 address");
        delegateContract = _delegateContract;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setInitialSaleSupply(uint256 _initialSaleSupply) public onlyOwner {
        initialSaleSupply = _initialSaleSupply;
    }

    function setClaimActive(bool _claimActive) public onlyOwner ascensionNotActive {
        claimActive = _claimActive;
    }

    function setSaleActive(bool _saleActive) public onlyOwner ascensionNotActive {
        saleActive = _saleActive;
        if (_saleActive && mintTimestamp == 0) {
            mintTimestamp = block.timestamp;
        }
    }

    /**
     * @notice Sets the `initialSaleFinished` state variable to the given value.
     *
     * If the given value is `true`, the `claimActive` state variable will be set
     * to `false` to indicate that the initial sale has finished and claims are no
     * longer active.
     *
     * @param _initialSaleFinished the new value for the `initialSaleFinished` state variable
     */
    function setInitialSaleFinished(bool _initialSaleFinished) public onlyOwner ascensionNotActive {
        initialSaleFinished = _initialSaleFinished;
        if (_initialSaleFinished) {
            claimActive = false;
        }
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setAscendActive() public onlyOwner {
        claimActive = false;
        initialSaleFinished = true;
        ascendActive = true;
    }

    function setMetadataInterface(MetadataInterface _metadataInterface) public onlyOwner {
        metadataInterface = _metadataInterface;
    }

    function withdraw() public onlyOwner {
        payable(treasury).transfer(address(this).balance);
    }

    /**
     * @notice Sets the `transferPermitted` state variable to `true` if the
     * contract has either minted out or one week has passed since the initial
     * sale.
     */
    function setTransferPermitted() public {
        if (totalSupply() == maxSupply || block.timestamp - mintTimestamp > 1 weeks) {
            transferPermitted = true;
        }
    }

    /**
     * @notice Sets the `transferPermitted` state variable to `true`.
     *
     * This function is only callable by the contract owner and is intended to be
     * used to override the `transferPermitted` state variable if the contract
     * has not minted out or one week has not passed since the initial sale.
     */
    function adminOverrideTransferPermitted() public onlyOwner {
        transferPermitted = true;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(transferPermitted, "Transfers are not permitted");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override {
        require(transferPermitted, "Transfer is not permitted");
        super.approve(operator, tokenId);
    }

    function ascend(uint256[] memory tokenIds) public nonReentrant {
        require(ascendActive, "Ascend is not active");
        require(tokenIds.length == 5, "Must ascend with 5 tokens");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "You do not own this token");
            require(!ascended[tokenIds[i]], "You cannot ascend this token");
            _burn(tokenIds[i]);
        }
        uint256 ascendedId = _safeMintAscended(msg.sender);
        emit Ascended(ascendedId);
        ascended[ascendedId] = true;
    }

    /**
     * @notice Returns the base URI for the contract.
     *
     * If the metadata interface is set, the base URI will be fetched from the
     * metadata interface using the `_baseURI` function. Otherwise, the base URI
     * will be returned from the co ntract's `baseURI` state variable.
     *
     * @return the base URI for the contract
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (address(metadataInterface) != address(0)) {
            return metadataInterface._baseURI();
        } else {
            return baseURI;
        }
    }
}