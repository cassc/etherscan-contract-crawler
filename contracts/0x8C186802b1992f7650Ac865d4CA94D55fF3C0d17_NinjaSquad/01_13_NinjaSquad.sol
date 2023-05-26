// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// :::::::::::::////++++++oooooossssyyhhhdddmmNNNNMNNNNNNNmmmmdddmmmmmNNNNNNNNMMMMNNNNNNNNNNNNNNNNNNNNN
// ::::::::::::::::::::::/::::::::::::::::::://////////////:::::::::///////////////////////////////////
// :::::::::::::::::::::+s+::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// ::::::::::::::::::::/os+:::::::::::::::::/::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// :::::::::::::::::::::oo/://:::::::::ohddmmmdys+/:::::::::::::::::::::::::::::::::/+/::::::::::::::::
// :::::::::+/:::::::::::/::+o/::::::::+mNNNNNNNNNh/::/+shddmdhs+/::::::::::::::::::+so/::::::/::::::::
// :::::::/hNmhyo/:::::::::::/::::::::::/yhNMNmNMMd//sdNNNNNNNNNNms/::::::::::::::::///::::::+o+/::::::
// :::::::/ydNNNNmds+/::::::::::::::::/+++oNMmNMMmo/yNNNNmmmmmmmmNNh/::::::::::::::::::::::::/oso/:::::
// :::::::::/+shmNNNNmy+/:::::::::::+hmNNNNNNmmNNNNmNNNMMNNNmmmmmmmNd/::::::::::::::::::::::::/oso/::::
// :::::::::::::/ohmNNNNmy+/::::::::ymNNNNNNmNMNNNmmmmmMm+hddmNNNNNNN+:::::::::::::::::::::://:/ss+::::
// ::::::::::::::::/ohmNNNNds+/::::::/oyhymNNNNNNNNNmmmNm/mmy:+ssyNmN///:::::::::::::::::::/oo/:+so/:::
// :::::::::::::::::::/sdNNNNNhs+/::////++shmNNNmmmMNmmmNyossydNNhymd+hdy+/:::::::::::::::::oso:///::::
// ::::::::::::::::::::::+ymNNMMNdshdmNNNNNNNNNNMMNMMmmmmNNNNNNNNNMNooNNNNh+::::::::::::::::://::::::::
// ::::::::::::::::::::::::/odNNMMMNNNmmmmmmmmmmmmmmNmmmmmmmmmmmmNMy//dNNNNNs/:::::::::::::::::::::::::
// :::::::::::::::::::::::::::+NMNmmNNMMmdddmNNNNmmmmmmmmmmmmmmmmNNNmhshMMNNMh/::::::::::::::::::::::::
// :::::::::::::::::::::::::::/ymMNMMMMMs::::/oydMNNmmmmmmmmmmmmmmmmNNNNNNmmNMy::::::::::::::::::::::::
// ::::::::::::::::::::::::::::::///yhy+:::::::::/yNMNmmmmmmmmmmmNNmmmmmmmmmmMN/:::::::::::::::::::::::
// ::::::::::::::::::::::::::::::::::::::::::::::::+mMNmmmmmmmmmmNMmNNMNNNNMMMd+/::::::::::::::::::::::
// :::::::::::::::::::::::::::::::::::::::::::::::::+NMmmmmmmmmmmNNhmMMMNNNNNNMMd+:::::::::/o+:::::::::
// :::::::::::::::::::::::::::::::::::::::::::::::::+NMNmmmmmmmmmmNNNmmmmmmmmmmMMd/::::::::///:::::::::
// ::::::::::::::::::::::::::::::::::::::::::::::::+dMNmmmmmmmmmmmmmmmmmmmmmmmmNMN/::::::::::::::::::::
// :::::/+/::::::::::::::::::::::::::::::::::::::+hNMNmmmmmmmmmmmmmmmmmmmmmmmmmNMd/::::::::::::://:::::
// :::/oso/::::::::::::::::::::::::::::::::::::+hNNNmmmmmmmmmmmmmmNmmmmmmmmmmmNMd+::::::://+osydmd/::::
// ::/os+/:::::::::::::::::::/:::::::::::::::/yNNNmmmmmmmmmmmmNNmmMMNmmmmmmmNNNy/::/++oshdmNNNNNMy:::::
// ::/+/::::::::::::::::::::+o+::::::::::::/omMNmmmmmmmmmmmNNNds+hMNmmmmmmNNmyoosyhmmNNNNNmmmmmNm/:::::
// :::::://:::::::::::::::::/o+::::::::::/odNNmmmmmmmmmmNNNmy+/:yMNmmmNNNNhohdNMMNNNmmmmmmmmmmNMs::::::
// ::::::+o/::::::::::::::::::::::::::::odNNmmmmmmmmmNNNmho/:::/dMmNNddmh+:/ydNNNNNmmmmmmmmmmmMm/::::::
// :::::::::::::::::::::::::::::::::::/oNNmmmmmmmmNNMNms/:::::::omNNM+:::::::/+yNMNmmmmmmmmmmNMs:::::::
// :::::::::::::::::::::::::::::::::+hmNNmmmmmmmNMNmy+/::::::::::/ohm+::::::/+hNNmmmmmmmmmmmmMm/:::::::
// ::::::::::::::::::::::::::::::/:/hMNmmmmmmNNNNho/:::::::::///::::/::::::+hNNmmmmmmmNNNNmmNMy::::::::
// ::::::::::::::::::::::::::::+hmyoMNmmNNmmmds//::::::::::::os+::::::::/ohNNmmmmmmmNmosNMNNMm+::::::::
// ::::::::::::::::::::::::::+dNNNMMMNmNMs:::::::::::::::::::+s+::::::+yNMNmmmmmmNNms/::/dMMm+:::::::::
// :::::::::::::::::::::::/smMNmmmmNNMNMh/:::::::::::::::::::::::::/sdMMNmmmmmNNMms/:::::/sy/::::::::::
// :::::::::::::::::::::/smMNmmmmmmmmmmNmo/::::::::::::::::::::::+yNMNNmmmmmNMNdo/:::::::::::::::::::::
// :::::::::::::::::::+hNMNmmNNNNMNmmmmmNNms/:::::::::::::::::/sdNMNNmmmmmNMMdo/:::::::::::::::::::::::
// :::::::::::::::::+yNNNmmNNNh++sdNNNmmmmNNmy+::::::::::::/ohNMMNmmmmmNNMNh+/:::::::::::::::::::::::::
// ::::::::::::::/ohmNmmmNNds+/:::/+hNNNmmmmNNNh+::::::::+hNMMNNmmmmNNMMNy+::::::::::::::::::::::::::::
// :::::::::::/ohmNNmmNNNh+/::::::::/+ymMNNmmmmNNdo/::/ohNNNNmmmmmNNMMms/::::::::::::::::::::::::::::::
// ::::::::/+hmNNNNNNNdy+::::::::::::::/smMNNmmmmNNmhhmNNNmmmmmmNMMNho/::::::::::::::::::::::::::::::::
// ::::::/+hNNNNNNNds+/::::::::::::::::::+ymMMNmmmmNNNNmmmmmmNNMNmy+/:::::::::::::::://::::::::::::::::
// :::::odNNmNNNds+/:::::::::::///:::::::::/sdNMNmmmmmmmmmmNNMmyo/::::::::::::::::::/oo/:::/o+/::::::::
// ::::sNNmNmhs+:::::::::::::::oso/::::::::::/+ymMNNmmmmmNMNds/:::::::::::::::::::::/oss/::/oso/:::::::
// :::+NNmds/::::::::::::::::::oso/:::::::::::::/sdNNNNNNmy+/::::::::::::::::::::::::/oss/::/oo/:::::::
// :::+yo+/::::::::::::::::::::/+/::::::::::::::::/odNmy+/::::::::::::::::::::::::::::/oss/:::/:::::::/
// :::::::::/+/:::::::::::::::::::::::::::::::::::::/+/::::::::::::::::::::::::::::::::/os+:::::::::::o
// ::::::::+ss+:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::///:::::::::::s
// ::::::::///::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::s
// dhhhhhhyyyssooo++++/////+++oooo++++/////:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::s

/// @creator:     NinjaSquad
/// @author:      peker.eth - twitter.com/peker_eth

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NinjaSquad is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    bytes32 public root;
    
    address proxyRegistryAddress;

    string BASE_URI = "https://api.ninjasquadnt.io/metadata/";
    
    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_SALE_ACTIVE = false;
    
    uint constant TOTAL_SUPPLY = 8888;
    uint constant INCREASED_MAX_TOKEN_ID = TOTAL_SUPPLY + 2;
    uint constant MINT_PRICE = 0.088 ether; 

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_TX = 10;
    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 20;
    
    mapping (address => uint) addressToMintCount;
    
    
    address FOUNDER_1 = 0x72d0455D25Db9c36af5869BBF426312bA923C643;
    address FOUNDER_2 = 0x5EE559349f01E5032324d6804d9AE4fD89041795;
    address TECH_LEAD = 0xA800F34505e8b340cf3Ab8793cB40Bf09042B28F;
    address COMMUNITY_WALLET = 0x47153260c7d8EaF5F609632F43d6eDc73D71B0De;
    address TEAM_1 = 0xD74403920Ec684F14554F2600f27F69C2C8dE2F8;
    address TEAM_2 = 0xaee4BDcF9d164d9ADBBcBfD846623fbE133a6018;
    address TEAM_3 = 0xD45c3821f49621F98AE8f61809481Be12299C94E;
    address TEAM_4 = 0x4BB18777DFFeB4A815A1aFf53C4B1da49d70D97c;
    address TEAM_5 = 0xA14b76E61561633BAcf4B9aF1ffB626Af4E9bEF4;
    address TEAM_6 = 0x8c3F461cFaAe1e05857d28B0e22BA3da097a2Be3;
    address TEAM_7 = 0xd44bDAA20832Ddfc953153c4Ee2CBeEf83F1953d;
    address TEAM_8 = 0x0B41ca9Dd8Cf98910C6dc48bFc8AF924c4F1268D;
    address TEAM_9 = 0x7fA9Eb848015208a443d2De2EABE5Bd478ae8F8E;
    address TEAM_10 = 0x660E5Dac34b916B8f060b817cBE8660ba02Bbc4F;
    address TEAM_11 = 0x0B16dD061aD33B866341Dc3bF17264bd6111f10D;
    

    constructor(string memory name, string memory symbol, bytes32 merkleroot, address _proxyRegistryAddress)
    ERC721(name, symbol)
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;
        _tokenIdCounter.increment();
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function togglePublicSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function togglePreSale() public 
    onlyOwner 
    {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function presaleMint(address account, uint numberOfTokens, uint256 allowance, string memory key, bytes32[] calldata proof)
    public
    payable
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre-sale haven't started");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");

        string memory payload = string(abi.encodePacked(Strings.toString(allowance), ":", key));

        require(_verify(_leaf(msg.sender, payload), proof), "Invalid merkle proof");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= allowance, "Exceeds allowance");

        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint numberOfTokens) 
    public 
    payable
    onlyAccounts
    {
        require(IS_SALE_ACTIVE, "Sale haven't started");
        require(numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_TX, "Too many requested");
        require(msg.value >= numberOfTokens * MINT_PRICE, "Not enough ethers sent");
        
        uint current = _tokenIdCounter.current();
        
        require(current + numberOfTokens < INCREASED_MAX_TOKEN_ID, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        
        addressToMintCount[msg.sender] += numberOfTokens;

        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }

    function getCurrentMintCount(address _account) public view returns (uint) {
        return addressToMintCount[_account];
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER_1, (balance * 230) / 1000);
        _withdraw(FOUNDER_2, (balance * 230) / 1000);
        _withdraw(TECH_LEAD, (balance * 50) / 1000);
        _withdraw(COMMUNITY_WALLET, (balance * 200) / 1000);
        _withdraw(TEAM_1, (balance * 80) / 1000);
        _withdraw(TEAM_2, (balance * 65) / 1000);
        _withdraw(TEAM_3, (balance * 50) / 1000);
        _withdraw(TEAM_4, (balance * 20) / 1000);
        _withdraw(TEAM_5, (balance * 15) / 1000);
        _withdraw(TEAM_6, (balance * 15) / 1000);
        _withdraw(TEAM_7, (balance * 10) / 1000);
        _withdraw(TEAM_8, (balance * 10) / 1000);
        _withdraw(TEAM_9, (balance * 10) / 1000);
        _withdraw(TEAM_10, (balance * 10) / 1000);
        _withdraw(TEAM_11, (balance * 5) / 1000);
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _leaf(address account, string memory payload)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}