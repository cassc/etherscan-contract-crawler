// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./util/ERC721Lockable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IViriumId.sol";
import "./IViriumDestate.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ViriumIdPrime is AccessControl, ERC721Lockable {
    uint256 public constant MAX_TOTAL_SUPPLY = 188;
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;
    Counters.Counter private _mintedCounter;
    IViriumId public viriumId;
    string public baseImageUri = "https://ipfs.virium.io/vip/image/";
    mapping(uint256 => uint256[]) vip2vids;

    address public constant PAYEE = 0xE5D299Aea7d7dC182439ccBB0285b5Ea779B9251;
    address public constant PROJECT_MANAGER = 0x1540602fA43D9b4237aa67c640DC8Bb8C4693dCD;
    bytes32 public constant MAINTAIN_ROLE = keccak256("MAINTAIN_ROLE");

    enum Status {
        Waiting,
        Live,
        Close
    }

    Status public status = Status.Live;

    enum Currency{
        ETH,
        USDT
    }

    struct CurrencyInfo {
        uint256 price;
        IERC20 erc20;
    }

    mapping(Currency => CurrencyInfo) public currencyInfos;

    event ViriumMerge(uint256);
    event ViriumMint(uint256, uint256[]);

    constructor() ERC721Lockable("ViriumIdPrime", "VIP"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, PROJECT_MANAGER);

        _grantRole(MAINTAIN_ROLE, msg.sender);
        _grantRole(MAINTAIN_ROLE, PROJECT_MANAGER);

        _mint(msg.sender, 0);
    }

    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock) public override(ERC721Lockable) onlyRole(MAINTAIN_ROLE) {
        return super.setTokenLockStatus(tokenIds, isLock);
    }

    function setViriumId(address viriumIdContractAddress) external onlyRole(MAINTAIN_ROLE) {
        viriumId = IViriumId(viriumIdContractAddress);
    }

    function setCurrencyInfo(Currency currency, uint256 price, address erc20ContractAddress) external onlyRole(MAINTAIN_ROLE) {
        currencyInfos[currency] = CurrencyInfo(price, IERC20(erc20ContractAddress));
    }

    function getCurrencyInfo(Currency currency) public view returns (CurrencyInfo memory){
        return currencyInfos[currency];
    }

    function setStatus(Status _status) external onlyRole(MAINTAIN_ROLE) {
        status = _status;
    }

    function setBaseImageUri(string memory newuri) external onlyRole(MAINTAIN_ROLE) {
        baseImageUri = newuri;
    }

    function merge(uint256[] memory tokenIds) external {
        require(Address.isContract(msg.sender) == false, "ViriumIdPrime: Prohibit contract calls");
        require(_mintedCounter.current() < MAX_TOTAL_SUPPLY, "ViriumIdPrime: Mint would exceed max supply");
        require(tokenIds.length == 10, "ViriumIdPrime: Incorrect token quantity");
        require(status == Status.Live, "ViriumIdPrime: Status mismatch");

        viriumId.burn(tokenIds);
        uint256 tokenId = findMinimum(tokenIds);
        vip2vids[tokenId] = tokenIds;
        _mint(msg.sender, tokenId);
        _mintedCounter.increment();
        emit ViriumMerge(tokenId);
    }

    function mint(Currency currency) external payable {
        require(Address.isContract(msg.sender) == false, "ViriumIdPrime: Prohibit contract calls");
        require(_mintedCounter.current() < MAX_TOTAL_SUPPLY, "ViriumIdPrime: Mint would exceed max supply");
        require(status == Status.Live, "ViriumIdPrime: Status mismatch");

        CurrencyInfo storage currencyInfo = currencyInfos[currency];
        if (currency == Currency.ETH) {
            require(currencyInfo.price <= msg.value, "ViriumIdPrime: Ether value sent is not correct");
        } else {
            currencyInfo.erc20.safeTransferFrom(msg.sender, PAYEE, currencyInfo.price);
        }

        uint256[] memory tokenIds = viriumId.softMint();
        uint256 tokenId = findMinimum(tokenIds);
        vip2vids[tokenId] = tokenIds;

        _mint(msg.sender, tokenId);
        _mintedCounter.increment();

        emit ViriumMint(tokenId, tokenIds);
    }

    function getVids(uint256 tokenId) public view returns (uint256[] memory){
        return vip2vids[tokenId];
    }

    function mintedCount() external view returns (uint256){
        return _mintedCounter.current();
    }

    function findMinimum(uint256[] memory tokenIds) private pure returns (uint256){
        uint256 minimumValue = tokenIds[0];
        for (uint i = 1; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId < minimumValue) {
                minimumValue = tokenId;
            }
        }
        return minimumValue;
    }

    function withdraw() external onlyRole(MAINTAIN_ROLE) {
        uint256 balance = address(this).balance;
        (bool sent,) = PAYEE.call{value : balance}("");
        require(sent, "ViriumIdPrime: Failed to send Ether");
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ViriumIdPrime: Token has not minted");

        string memory imageUrl = string.concat(baseImageUri, tokenId.toString());

        uint256[] storage vids = vip2vids[tokenId];
        string memory attribues = '[';
        for (uint256 i = 0; i < vids.length; i++) {
            attribues = string.concat(
                attribues,
                '{"trait_type":"',
                (i + 1).toString(),
                '","value":"',
                vids[i].toString(),
                '"');
            if (i == 9) {
                attribues = string.concat(attribues, '}');
            } else {
                attribues = string.concat(attribues, '},');
            }
        }
        attribues = string.concat(attribues, ']');

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "VIP #',
                    tokenId.toString(),
                    '", "description": "Virium ID Prime is an algorithmically generated Web3 identity on Ethereum allowing people to interact with Virium protocol. VIRIUM ID Prime is the supreme identity generated by merging 10 Virium ID. Holders will enjoy great privilege and receive exclusive gifts from Virium.", "image": "',
                    imageUrl,
                    '", "attributes":',
                    attribues,
                    '}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC721, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}