// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @author AC

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract StickmanERC721 is ERC721, Ownable {

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    /** uri methods */
    string private _uri = "https://gateway.pinata.cloud/ipfs/QmXTYJrQDat98hAMRchontp98Xi2mNCENWamkm4Rwpfgae/";
    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_uri, toString(id), ".json"));
    }

    function setURI(string memory uri) external onlyOwner {
        _uri = uri;
    }


    /** contract permissions */

    address private _crossmint_address;     /// TODO set this to the crossmint minter address
    function setCrossmintAddress(address addr) external onlyOwner {
        _crossmint_address = addr;
    }
    modifier onlyCrossmint() {
        require (msg.sender == _crossmint_address);
        _;
    }


    /** mint enabling */

    bool private allow_list_enabled;
    bool private mint_enabled;

    function enableAllowList() external onlyOwner {
        allow_list_enabled = true;
    }
    function enableMint() external onlyOwner {
        mint_enabled = true;
    }

    modifier allowListEnabled() {
        require (allow_list_enabled, "allow list not enabled.");
        _;
    }
    modifier mintEnabled() {
        require (mint_enabled, "minting not enabled.");
        _;
    }


    /** mint limits per-wallet */

    uint256 public constant MAX_PER_WALLET = 3;
    modifier enforceMintLimit(address to, uint256 num_to_mint) {
        require (balanceOf(to) + num_to_mint <= MAX_PER_WALLET, "too many tokens minted to this wallet.");
        _;
    }


    /** mint price */

    uint256 public constant PRICE = 55000000000000000; // 0.055 ether
    modifier ensurePayment(uint256 num_to_mint) {
        require (msg.value >= num_to_mint * PRICE, "not enough ether paid.");
        _;
    }


    /** minting allowlist logic */

    mapping (address => uint256) private _allowList;

    function setAllowList(address[] calldata vips) external {
        uint256 num_vips = vips.length;
        for (uint256 i; i < num_vips;) {
            _allowList[vips[i]] = MAX_PER_WALLET;

            unchecked {
                i++;
            }
        }
    }

    modifier enforcePremintLimit(address to, uint256 num_to_mint) {
        uint256 amount_left = _allowList[to];
        require (num_to_mint <= amount_left, "exceeding premint limit.");
        _;
        _allowList[to] = amount_left - num_to_mint;
    }


    /** reentrancy */

    uint256 private guard = 1;
    modifier reentrancyGuard() {
        require (guard == 1, "reentrancy failure.");
        guard = 2;
        _;
        guard = 1;
    }


    /** supply limits */

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public totalSupply;

    function _internal_mint(address to, uint256 num_to_mint) internal {
        uint256 total_supply = totalSupply;
        require (total_supply + num_to_mint <= MAX_SUPPLY, "minting error, attempting to exceed supply.");

        for (uint256 i; i < num_to_mint;) {
            _safeMint(to, ++total_supply);

            unchecked {
                i++;
            }
        }
        totalSupply = total_supply;
    }


    /** public mint functions */

    function allowlistMint(uint256 num_to_mint) external payable allowListEnabled enforcePremintLimit(msg.sender, num_to_mint) ensurePayment(num_to_mint) reentrancyGuard {
        _internal_mint(msg.sender, num_to_mint);
    }

    function mint(uint256 num_to_mint) external payable mintEnabled enforceMintLimit(msg.sender, num_to_mint) ensurePayment(num_to_mint) reentrancyGuard {
        _internal_mint(msg.sender, num_to_mint);
    }

    function crossmintTo(address to, uint256 _count) external onlyCrossmint enforceMintLimit(to, _count) reentrancyGuard {
        if (!mint_enabled) {
            require (allow_list_enabled, "allow list and minting both not enabled, crossmint disabled.");

            uint256 amount_left = _allowList[to];
            require (_count <= amount_left, "attempting to mint too many during allow list mint.");
            _allowList[to] = amount_left - _count;
        }

        _internal_mint(to, _count);
    }




    /** developer payment */

    address payable constant A = payable(0xAd75E32b0603D4a2b7E89A23eDD3228E5cD0699A); /** TODO set this to the atc address */
    address payable constant T = payable(0xAECE4959fa2e70e9210D6755B25F73A225C4F956); /** TODO set this to the atc address */
    address payable constant C = payable(0x0E25e1A23378ece3C304b930b5B42727E6D249F9); /** TODO set this to the atc address */
    function disburse() external onlyOwner {
        uint256 total = address(this).balance;

        uint256 ATC = (total * 8) / 100;
        A.transfer(ATC / 3);
        T.transfer(ATC / 3);
        C.transfer(ATC / 3);

        payable(owner()).transfer(total - ((total * 8) / 100));
    }
}










function toString(uint256 value) pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
        return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
}