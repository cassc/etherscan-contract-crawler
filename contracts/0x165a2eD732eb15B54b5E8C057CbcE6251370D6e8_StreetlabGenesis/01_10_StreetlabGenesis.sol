// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・・.・✫・゜・。✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・・.・✫・゜

                                                 _,.-------.,_
                                             ,;~'             '~;,
                                           ,;                     ;,
                                          ;                         ;
                                         ,'                         ',
                                        ,;                           ;,
                                        ; ;      .           .      ; ;
                                        | ;   ______       ______   ; |
                                        |  `/~"     ~" . "~     "~\'  |
                                        |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
                                         |   |        }:{        |   |
                                         |   l       / | \       !   |
                                         .~  (__,.--" .^. "--.,__)  ~.
                                         |     ---;' / | \ `;---     |
                                          \__.       \/^\/       .__/
                                           V| \                 / |V
                                            | |T~\___!___!___/~T| |
                                            | |`IIII_I_I_I_IIII'| |
                                            |  \,III I I I III,/  |
                                             \   `~~~~~~~~~~'    /
                                               \   .       .   /
                                                 \.    ^    ./
                                                   ^~~~^~~~^

	 _______ __                     __   __         __         _______                           __
	|     __|  |_.----.-----.-----.|  |_|  |.---.-.|  |--.    |     __|.-----.-----.-----.-----.|__|.-----.
	|__     |   _|   _|  -__|  -__||   _|  ||  _  ||  _  |    |    |  ||  -__|     |  -__|__ --||  ||__ --|
	|_______|____|__| |_____|_____||____|__||___._||_____|    |_______||_____|__|__|_____|_____||__||_____|


.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・・.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・・.・✫・゜・。*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StreetlabGenesis is ERC721A, Ownable {

    event SalePhaseToggled(string phase, bool value);
    event PriceChanged(uint256 value);

    using ECDSA for bytes32;

    mapping(uint256 => bool) internal _presaleNonces;
    mapping(uint256 => bool) internal _giveawayNonces;

    address private _openSeaProxyRegistryAddress;
    address internal constant _crossMintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    uint256 public giveaway = 116;
    uint256 public price = 0.077 ether;

    uint256 public maxSupply = 4444;
    uint256 public maxTokensPerMint = 10;

    uint256 public startingIndex;

    bool private _isOpenSeaProxyRegistryEnabled = true;
    bool public isGiveawayStarted;
    bool public isPresaleStarted;
    bool public isSaleStarted;

    string public provenanceHash = "";
    string public baseURI = "https://metadata-6e9t2e4f6v9jp.streetlab.io/";

    constructor(
        string memory name,
        string memory symbol,
        address openSeaProxyRegistryAddress
    ) ERC721A(name, symbol) {
        _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
    }

    // =============== MINTING RELATED FUNCTIONS ===============

    function _mintPayable(address to, uint256 amount) internal {
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply - giveaway, "Not enough Tokens left.");
        require(amount * price <= msg.value, "Inconsistent amount sent!");

        _safeMint(to, amount);
    }

    function mintGiveaway(
        uint256 amount,
        uint256 nonce,
        bytes memory sig
    ) external whenGiveawayStarted {
        require(!_giveawayNonces[nonce], "Giveaway nonce already used.");
        uint256 giveaway_ = giveaway;
        require(amount <= giveaway_, "cannot exceed max giveaway.");
        _giveawayNonces[nonce] = true;
        giveaway = giveaway_ - amount;
        _validateSig("giveaway", msg.sender, amount, nonce, sig);

        _safeMint(msg.sender, amount);
    }

    function mintPresale(
        uint256 amount,
        uint256 maxToken,
        uint256 nonce,
        bytes memory sig
    ) external payable whenPresaleStarted {
        require(amount <= maxToken, "Cannot mint more than maxTokens.");
        require(!_presaleNonces[nonce], "Presale nonce already used.");
        _presaleNonces[nonce] = true;

        _validateSig("presale", msg.sender, maxToken, nonce, sig);

        _mintPayable(msg.sender, amount);
    }

    function mintPresaleWithGiveaway(
        uint256 amountGiveaway,
        uint256 nonceGiveaway,
        uint256 amountPresale,
        uint256 maxTokenPresale,
        uint256 noncePresale,
        bytes memory sigGiveaway,
        bytes memory sigPresale
    ) external payable {
        if(amountPresale > 0) {
            require(isPresaleStarted, "Presale not started");
            require(amountPresale <= maxTokenPresale, "Cannot mint more than maxTokens.");
            require(!_presaleNonces[noncePresale], "Presale nonce already used.");
            _presaleNonces[noncePresale] = true;

            _validateSig("presale", msg.sender, maxTokenPresale, noncePresale, sigPresale);
            uint256 supply = totalSupply();
            require(supply + amountPresale <= maxSupply - giveaway, "Not enough Tokens left.");
            require(amountPresale * price <= msg.value, "Inconsistent amount sent!");
        }
        if(amountGiveaway > 0) {
            require(isGiveawayStarted, "Giveaway not started");
            require(!_giveawayNonces[nonceGiveaway], "Giveaway nonce already used.");
            uint256 giveaway_ = giveaway;
            require(amountGiveaway <= giveaway_, "cannot exceed max giveaway.");
            _giveawayNonces[nonceGiveaway] = true;
            giveaway = giveaway_ - amountGiveaway;
            _validateSig("giveaway", msg.sender, amountGiveaway, nonceGiveaway, sigGiveaway);
        }

        _safeMint(msg.sender, amountGiveaway + amountPresale);
    }

    function mintWithGiveaway(
        uint256 amountPublic,
        uint256 amountGiveaway,
        uint256 nonceGiveaway,
        bytes memory sigGiveaway
    ) external payable {
        if(amountPublic > 0) {
            require(amountPublic <= maxTokensPerMint, "maxTokensPerMint exceeded!");
            uint256 supply = totalSupply();
            require(supply + amountPublic <= maxSupply - giveaway, "Not enough Tokens left.");
            require(amountPublic * price <= msg.value, "Inconsistent amount sent!");
        }
        if(amountGiveaway > 0) {
            require(isGiveawayStarted, "Giveaway not started");
            require(!_giveawayNonces[nonceGiveaway], "Giveaway nonce already used.");
            uint256 giveaway_ = giveaway;
            require(amountGiveaway <= giveaway_, "cannot exceed max giveaway.");
            _giveawayNonces[nonceGiveaway] = true;
            giveaway = giveaway_ - amountGiveaway;
            _validateSig("giveaway", msg.sender, amountGiveaway, nonceGiveaway, sigGiveaway);
        }

        _safeMint(msg.sender, amountGiveaway + amountPublic);
    }

    function mintTo(address to, uint256 amount) external payable whenSaleStarted {
        require(msg.sender == _crossMintAddress, "This function is for Crossmint only.");
        require(amount <= maxTokensPerMint, "maxTokensPerMint exceeded!");
        _mintPayable(to, amount);
    }

    function mint(uint256 amount) public payable whenSaleStarted {
        require(amount <= maxTokensPerMint, "maxTokensPerMint exceeded!");
        _mintPayable(msg.sender, amount);
    }

    function claimGiveaway(uint256 amount, address receiver) external onlyOwner {
        require(amount <= giveaway, "cannot exceed max giveaway.");

        giveaway = giveaway - amount;
        _safeMint(receiver, amount);
    }

    function _validateSig(string memory phase, address sender, uint256 amount, uint256 nonce, bytes memory sig) internal view {
        bytes32 hash = keccak256(abi.encode(phase, sender, amount, nonce, address(this)));
        address signerAddress = hash.toEthSignedMessageHash().recover(sig);
        require(signerAddress == owner(), "Invalid signature!");
    }

    // ================== FUNCTION OVERRIDES ===================

    // Override isApprovedForAll to allow user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if(_isOpenSeaProxyRegistryEnabled) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier whenPresaleStarted {
        require(isPresaleStarted, "Presale not started");
        _;
    }

    modifier whenSaleStarted() {
        require(isSaleStarted, "Sale not started");
        _;
    }

    modifier whenGiveawayStarted() {
        require(isGiveawayStarted, "Giveaway not started");
        _;
    }

    // ============== OWNER-ONLY ADMIN FUNCTIONS ===============

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        require(payable(owner()).send(balance), "Balance transfer failed.");
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    // Make it possible to change the price between presale and public sale
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    // This should be set before sales open.
    function setProvenanceHash(string memory provenanceHash_) public onlyOwner {
        provenanceHash = provenanceHash_;
    }

    function setOpenSeaProxyRegistryEnabled(bool enabled) external onlyOwner {
        _isOpenSeaProxyRegistryEnabled = enabled;
    }

    function toggleGiveawayStarted() external onlyOwner {
        bool status = isGiveawayStarted;
        isGiveawayStarted = !status;

        if (isGiveawayStarted && startingIndex == 0) {
            setStartingIndex();
        }
        emit SalePhaseToggled('giveaway', !status);
    }

    function togglePresaleStarted() external onlyOwner {
        bool status = isPresaleStarted;
        isPresaleStarted = !status;

        if (isPresaleStarted && startingIndex == 0) {
            setStartingIndex();
        }
        emit SalePhaseToggled('presale', !status);
    }

    function toggleSaleStarted() external onlyOwner {
        bool status = isSaleStarted;
        isSaleStarted = !status;
        if (!status) {
          isPresaleStarted = false;
          emit SalePhaseToggled('presale', false);
        }

        if (isSaleStarted && startingIndex == 0) {
            setStartingIndex();
        }
        emit SalePhaseToggled('public', !status);
    }

    // ================= PUBLIC VIEW FUNCTIONS =================

    function validGiveawayNonce(uint256 nonce) external view returns(bool) {
      return !_giveawayNonces[nonce];
    }

    function validPresaleNonce(uint256 nonce) external view returns(bool) {
      return !_presaleNonces[nonce];
    }


    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");

        // BlockHash only works for the most 256 recent blocks.
        uint256 blockShift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        blockShift =  1 + (blockShift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < blockShift) {
            blockShift = 1;
        }

        uint256 blockRef = block.number - blockShift;
        startingIndex = uint(blockhash(blockRef)) % maxSupply;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}