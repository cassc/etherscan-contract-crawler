/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/*
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNXXXXXNNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXK0OkkxddlcccloddddxxkkO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdlc:::::cl:,'';looooooooooodxkOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMWX0kdoc;,'.......';cc:;:looooooooooooooodkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMWXOdllol:'',,,........,looloooooooooooooodoodddxOKNMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMNKxl:,:lo:'':oo:'.......,looooooooodddddddddddddddddk0NWMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMN0xc;'.':oo:';lool,......,coddddddddddddddddddddddddddddx0XWMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMWKxc;'....;loolloooo:'...':lddddddddddddddddddddddddddddddddx0NMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMWXkl;'.......;loddddddol::codddddddddddddddddddddddddddddddddddxkKWMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMW0d:,..........';clloooolc:;:lddddddddddddddddddddddddxxxxxxxxxxxxx0NMMMMMMMMMMMMMMW
WMMMMMMMMMMMNOo;'...............''',;'...,ldddddddddddddddxxxxxxxxxxxxxxxxxxxxxxxOXMMMMMMMMMMMMMW
WMMMMMMMMMMNOl;'.................',co:.'coddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOXWMMMMMMMMMMMW
WMMMMMMMMMNOo;'.............';:clodxxdlodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOXMMMMMMMMMMMW
WMMMMMMMMW0o;'............':odxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxxxxkkkONMMMMMMMMMMW
WMMMMMMMMKx:'............,ldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkk0WMMMMMMMMMW
WMMMMMMMNOl,............'cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxkkkkkkkkkkxxddoooooodxkkkkkOXMMMMMMMMMW
WMMMMMMMKx:'...........'cdollllllllclllllodxxxxkkkkkkkkkkkkkkkkxdoc:,''........:xkkkkk0WMMMMMMMMW
WMMMMMMW0o,............;ddc,'.............';coxkkkkkkkkkkkkkkxl;'..............'okkkkk0NMMMMMMMMW
WMMMMMMNOl'............'cxxd:.................,cdkkkkkkkkkkkd,.................'oOkOOOOXMMMMMMMMW
WMMMMMMXkc'.............';lxl'..................cxkkkkkkkkkkc..................;xOOOOOOXWMMMMMMMW
WMMMMMMXkc'................:o:.................:dkkkkkkkxkOOxc'...............;dOOOOOOOXWMMMMMMMW
WMMMMMMNkc'................,od:'............':okkkkxlc:;,lkOOkxl:,'........''cxOOOOOOOOXWMMMMMMMW
WMMMMMMNOl'.................,lxdl::;;;;:::coxkOOOkd:......ckOOOOOkxxxxdxxxxkkOOOOOOOOO0XMMMMMMMMW
WMMMMMMWKd,..................':xOOOkkkOOOkdloxOOOo;........ckOOOOOOOOOOOOOOOOOO0O000O0KNMMMMMMMMW
WMMMMMMMXk:'..................,dOkxxxkOOOd,..;dkx;..........:xOOOOOOO00000O0000OOO0000XWMMMMMMMMW
WMMMMMMMW0o,................';clc;,'',:okd;,,';oo'.....:,....cO00OOOO000OOkxolc:;;oO0KNMMMMMMMMMW
WMMMMMMMMXkc'..............':c,.........;okkdc;,'.....cxo,,;lxO00Oc,;::;;,'.......;k0XWMMMMMMMMMW
WMMMMMMMMWXx:'.............;l;...........'lkx;......'oO00OOO00000k;...............lOKWMMMMMMMMMMW
WMMMMMMMMMWKd;.............';'............,x0kd:,,;;oO00000000000k;..............;kKNMMMMMMMMMMMW
WMMMMMMMMMMWKd;...........................;k000x::coO000000000000x'.............,xKNMMMMMMMMMMMMW
WMMMMMMMMMMMWKx:'...........':;'..........:k000OdlcoxxdollclxO00k:.............;xXWMMMMMMMMMMMMMW
WMMMMMMMMMMMMWXOl,..........'oOdc,.........,:c::;;,,'........,::,.............cOXWMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMNKd:'........'o000ko,........................................,o0NWMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMWN0o;........,:lodl,......................................'lOXWMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMWX0o;'................................................'lOXWMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMWN0xc,............................................;o0NWMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMWWXOdc,......................................;lkXWWMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMWWX0xo:,'............................';cdOXWWMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKkdoc:,'................';:cok0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OkxxddddddddxxkOKXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
*/

import "@openzeppelin/contracts-4.5/access/Ownable.sol";
import "@openzeppelin/contracts-4.5/utils/Counters.sol";
import "@openzeppelin/contracts-4.5/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-4.5/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-4.5/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-4.5/interfaces/IERC165.sol";

/**
 * @title LunarColonyAlpha contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract LCAlpha is ERC721, IERC2981, Ownable {
    using Strings for uint256;

    enum SaleState {
        Paused,
        BoardingPass,
        Open
    }

    uint256 public constant mintPrice = 0.08 ether;
    uint256 public constant bpMintPrice = 0.06 ether;
    uint256 public constant maxPurchase = 20 + 1;
    uint256 public constant maxSupply = 10000 + 1;
    uint256 public constant reservedTokens = 50;
    bool private reservesTaken = false;
    bytes32 public merkleRoot;
    address public proxyRegistryAddress;
    string public baseURI;
    string public preRevealURI;

    SaleState public saleState = SaleState.Paused;

    uint256 public totalSupply;
    mapping(address => uint256) public bpMintsPerAddr;

    address public beneficiary;
    address public royaltyAddr;
    uint256 public royaltyPct;

    modifier validateEthAmount(uint256 price, uint256 amount) {
        require(price * amount == msg.value, "Incorrect ETH value sent");
        _;
    }

    modifier saleIsActive(SaleState state) {
        require(saleState == state, "Sale not active");
        _;
    }

    constructor(
        address _beneficiary,
        address _royaltyAddr,
        uint256 _royaltyPct,
        address _proxyRegistryAddress,
        string memory _preRevealURI
    ) ERC721("Lunar Colony Alpha", "LCA") {
        beneficiary = _beneficiary;
        royaltyAddr = _royaltyAddr;
        royaltyPct = _royaltyPct;
        proxyRegistryAddress = _proxyRegistryAddress;
        preRevealURI = _preRevealURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(beneficiary).transfer(balance);
    }

    /**
     * @notice reserve for DAO
     */
    function reserveTokens(address to) public onlyOwner {
        require(!reservesTaken, "Reserves can't be taken");
        for (uint256 i = 0; i < reservedTokens; i++) {
            _mintNext(to);
        }
        reservesTaken = true;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setPreRevealURI(string memory newPreRevealURI) public onlyOwner {
        preRevealURI = newPreRevealURI;
    }

    function setBeneficiary(address newBeneficiary) public onlyOwner {
        beneficiary = newBeneficiary;
    }

    function setRoyalties(address newRoyaltyAddr, uint256 newRoyaltyPct) public onlyOwner {
        royaltyAddr = newRoyaltyAddr;
        royaltyPct = newRoyaltyPct;
    }

    function setSaleState(SaleState newSaleState) public onlyOwner {
        saleState = newSaleState;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = newProxyRegistryAddress;
    }

    /**
     * @notice Mint for boarding pass holders
     */
    function bpMint(
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata proof
    ) public payable saleIsActive(SaleState.BoardingPass) validateEthAmount(bpMintPrice, amount) {
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, allowedAmount))
            ),
            "Invalid Merkle Tree proof supplied"
        );
        require(bpMintsPerAddr[msg.sender] + amount <= allowedAmount, "Exceeds allowed amount");

        bpMintsPerAddr[msg.sender] += amount;

        for (uint256 i = 0; i < amount; i++) {
            _mintNext(msg.sender);
        }
    }

    /**
     * @notice Public mint
     */
    function mint(uint256 amount)
        public
        payable
        saleIsActive(SaleState.Open)
        validateEthAmount(mintPrice, amount)
    {
        require(amount < maxPurchase, "Max purchase exceeded");
        require(totalSupply + amount < maxSupply, "Purchase would exceed max supply");

        for (uint256 i = 0; i < amount; i++) {
            _mintNext(msg.sender);
        }
    }

    function _mintNext(address to) private {
        _mint(to, totalSupply);
        unchecked {
            totalSupply++;
        }
    }

    function walletOfOwner(address ownerAddr) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(ownerAddr);
        uint256[] memory tokens = new uint256[](balance);
        uint256 tokenId;
        uint256 found;

        while (found < balance) {
            if (_exists(tokenId) && ownerOf(tokenId) == ownerAddr) {
                tokens[found++] = tokenId;
            }
            tokenId++;
        }

        return tokens;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory __baseURI = _baseURI();
        return
            bytes(__baseURI).length > 0
                ? string(abi.encodePacked(__baseURI, tokenId.toString()))
                : preRevealURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice / 100) * royaltyPct;
        return (royaltyAddr, royaltyAmount);
    }
}

contract OwnableDelegateProxy {}

/**
 * @notice Used to delegate ownership of a contract to another address,
 * to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}