//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './IERC1155.sol';


contract Catboticans is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _redeemIds;
    Counters.Counter private _tokenIds;

    bool public mintActive = false;
    string private baseURI;

    string private tokenSuffixURI;
    string private contractMetadata = 'contract.json';
    uint256 public constant RESERVED_TOKEN_ID_OFFSET = 12000; // Tokens reserved for replicats

    address[] private recipients;
    uint16[] private splits;
    uint16 public constant SPLIT_BASE = 10000;

    uint256 public descendicatMintPrice;

    mapping(address => bool) public proxyRegistryAddress;

    mapping(uint256 => uint16[]) descendicatMapping;

    event ReplicatMinted(address indexed owner, uint256 indexed id);
    event ReplicatBatchMinted(address indexed owner, uint256[] ids);
    event DescendicatMinted(address indexed owner, uint256 indexed id, uint256 indexed catbotId, uint8 mainLock, uint8 additionalLock);
    event ContractWithdraw(address indexed initiator, uint256 amount);
    event ContractWithdrawToken(address indexed initiator, address indexed token, uint256 amount);
    event WithdrawAddressChanged(address indexed previousAddress, address indexed newAddress);

    uint16 internal royalty = 1000; // base 10000, 10%
    uint16 public constant BASE = 10000;

    IERC721 cbotContract;

    IERC1155 nvContract;

    constructor(
        string memory _baseContractURI,
        string memory _tokenSuffixURI,
        address[] memory _recipients,
        uint16[] memory _splits,
        address _cbotContract,
        address _nvContract,
        address _proxyAddress
    ) ERC721('Catboticans', '3DCBOT') {
        baseURI = _baseContractURI;
        tokenSuffixURI = _tokenSuffixURI;
        recipients = _recipients;
        splits = _splits;
        cbotContract = IERC721(_cbotContract);
        nvContract = IERC1155(_nvContract);
        proxyRegistryAddress[_proxyAddress] = true;
    }

    function mintRelpicat(uint256 id) external nonReentrant {
        require(mintActive,'mint disabled');
        require(cbotContract.ownerOf(id) == msg.sender,'Catbot not owned');
        require(nvContract.balanceOf(msg.sender,1) > 0 ,'Not enough NV1');
        emit ReplicatMinted(msg.sender, id);
        _safeMint(msg.sender, id);
        nvContract.burn(msg.sender, 1, 1);
    }

    function batchMintRelpicat(uint256[] calldata ids) external nonReentrant {
        require(mintActive,'mint disabled');
        require(nvContract.balanceOf(msg.sender,1) >= ids.length ,'Not enough NV1');
        emit ReplicatBatchMinted(msg.sender, ids);
        for (uint256 i = 0; i < ids.length; i++) {
            require(cbotContract.ownerOf(ids[i]) == msg.sender,'Catbot not owned');
            _safeMint(msg.sender, ids[i]);
        }
        nvContract.burn(msg.sender, 1, ids.length);
    }

    function mintDescendicat(uint256 id, uint8 mainLock, uint8 additionalLock) external payable nonReentrant {
        require(mintActive,'mint disabled');
        require(cbotContract.ownerOf(id) == msg.sender,'Catbot not owned');
        require(msg.value >= descendicatMintPrice, 'Insufficient ETH');
        uint256 requiredNV2 = 1;
        if(additionalLock > 0) {
            requiredNV2 = 2;
        }
        require(nvContract.balanceOf(msg.sender,2) > requiredNV2 ,'Not enough NV2');
        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current()+RESERVED_TOKEN_ID_OFFSET;
        uint256 count = descendicatMapping[id].length;
        descendicatMapping[id][count] = uint16(currentTokenId);
        emit DescendicatMinted(msg.sender, currentTokenId, id, mainLock, additionalLock);
        _safeMint(msg.sender, currentTokenId);
        nvContract.burn(msg.sender, 2, requiredNV2);
    }

    function descendicatCount(uint256 id) external view returns (uint256){
        return descendicatMapping[id].length;
    }

    function setBaseURI(string memory baseContractURI) external onlyOwner {
        baseURI = baseContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseContractURI = _baseURI();
        return
            bytes(baseContractURI).length > 0
                ? string(abi.encodePacked(baseContractURI, tokenId.toString(), tokenSuffixURI))
                : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev returns the base contract metadata json object
     * this metadat file is used by OpenSea see {https://docs.opensea.io/docs/contract-level-metadata}
     *
     */
    function contractURI() public view returns (string memory) {
        string memory baseContractURI = _baseURI();
        return string(abi.encodePacked(baseContractURI, contractMetadata));
    }

    /**
     * @dev withdraws the contract balance and send it to the withdraw Addresses based on split ratio.
     *
     * Emits a {ContractWithdraw} event.
     */
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = payable(recipients[i]).call{value: (balance * splits[i]) / SPLIT_BASE}('');
            require(sent, 'Withdraw Failed.');
        }

        emit ContractWithdraw(msg.sender, balance);
    }


    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }

    /// @dev set the royalty
    /// @param _royalty the royalty in base 10000, 500 = 5%
    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);
        // transfer the token from address of Catbotica address
        uint256 balance = tokenContract.balanceOf(address(this));

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenContract.transfer(recipients[i], (balance * splits[i]) / SPLIT_BASE);
        }

        emit ContractWithdrawToken(msg.sender, _tokenContract, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows replacing an existing withdraw address
     *
     * Emits a {WithdrawAddressChanged} event.
     */
    function changeWithdrawAddress(address _recipient) external {
        require(_recipient != address(0), 'Cannot use zero address');
        require(_recipient != address(this), 'Cannot use this contract address');

        // loop over all the recipients and update the address
        bool _found = false;
        for (uint256 i = 0; i < recipients.length; i++) {
            // if the sender matches one of the recipients, update the address
            if (recipients[i] == msg.sender) {
                recipients[i] = _recipient;
                _found = true;
                break;
            }
        }
        require(_found, 'The sender is not a recipient.');
        emit WithdrawAddressChanged(msg.sender, _recipient);
    }

    /*
     * Function to allow receiving ETH sent to contract
     *
     */
    receive() external payable {}

    /**
     * Override isApprovedForAll to whitelisted marketplaces to enable gas-free listings.
     *
     */
    function isApprovedForAll(address _owner, address _operator) public view override(ERC721, IERC721) returns (bool isOperator) {
        // check if this is an approved marketplace
        if (proxyRegistryAddress[_operator]) {
            return true;
        }
        // otherwise, use the default ERC721 isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /*
     * Function to set status of proxy contracts addresses
     *
     */
    function setProxy(address _proxyAddress, bool _value) external onlyOwner {
        proxyRegistryAddress[_proxyAddress] = _value;
    }

    /*
     * Function to set Descendicat minting ETH price
     *
     */
    function setMintPrice(uint256 _price) external onlyOwner {
        descendicatMintPrice = _price;
    }

    /*
     * Function to activate and deactivate minting
     *
     */
    function flipMintActive() external onlyOwner {
        mintActive = !mintActive;
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
}