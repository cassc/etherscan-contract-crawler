// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Unikong is ERC721A, Ownable, Pausable {
    using Address for address;
    using Strings for uint256;
    using MerkleProof for bytes32[];

    address proxyRegistryAddress;

    //the merkle root
    bytes32 public ogRoot =
        0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public wlRoot =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    string public _contractBaseURI = "https://gateway.pinata.cloud/ipfs/QmRujq9iTHGjqxKTjGfoaavBUsjRDfdaV2iw9yfWXg3m1f";
    string public _contractURI = "https://unikong.io/";

    uint256 public ogTokenPrice = 0.05 ether; //price per og token
    uint256 public wlTokenPrice = 0.06 ether; //price per wl token
    uint256 public publicTokenPrice = 0.07 ether; //price per public token

    uint256 public ogSaleStartTime = 1647194400;
    uint256 public ogSaleEndTime = 1647205199;
    uint256 public whitelistSaleStartTime = 1647205200;
    uint256 public whitelistSaleEndTime = 1647266400;
    uint256 public publicSaleStartTime = 1647270000;

    uint256 public ogMaxMintAllowed = 2;
    uint256 public wlMaxMintAllowed = 1;

    mapping(address => uint256) public ogUsedAddresses; //used addresses for whitelist
    mapping(address => uint256) public wlUsedAddresses; //used addresses for whitelist

    bool public locked; //baseURI & contractURI lock
    uint256 public maxSupply = 5554; //tokenIDs start from 0

    constructor() ERC721A("Unikong", "UNIKONG", 5) {
        _safeMint(msg.sender, 1); //mints 1 nft to the owner for configuring opensea
    }

    /**
     * @dev whitelist buy
     */
    function whitelistBuy(
        uint256 qty,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        require(totalSupply() + qty <= maxSupply, "WhitelistBuy:: Out of stock");
        require(qty <= wlMaxMintAllowed, "WhitelistBuy:: Max limit reached");
        require(wlTokenPrice * qty == msg.value, "WhitelistBuy:: Invalid Amount");
        require(
            wlUsedAddresses[msg.sender] + qty <= wlMaxMintAllowed,
            "WhitelistBuy:: Max per wallet reached"
        );
        require(
            block.timestamp > whitelistSaleStartTime &&
                block.timestamp < whitelistSaleEndTime,
            "WhitelistBuy:: Too early or too late"
        );
        require(
            isTokenWLValid(msg.sender, tokenId, proof),
            "WhitelistBuy:: Invalid merkle proof"
        );
        wlUsedAddresses[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function ogBuy(
        uint256 qty,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external payable whenNotPaused {
        require(totalSupply() + qty <= maxSupply, "OgBuy:: Out of stock");
        require(qty <= ogMaxMintAllowed, "OgBuy:: Max limit reached");
        require(ogTokenPrice * qty == msg.value, "OgBuy:: Invalid Amount");
        require(
            ogUsedAddresses[msg.sender] + qty <= ogMaxMintAllowed,
            "OgBuy:: Max limit reached"
        );
        require(
            block.timestamp > ogSaleStartTime &&
                block.timestamp < ogSaleEndTime,
            "OgBuy:: Too early or too late"
        );
        require(
            isTokenOGValid(msg.sender, tokenId, proof),
            "OgBuy:: Invalid merkle proof"
        );
        ogUsedAddresses[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    /**
     * @dev everyone can mint freely
     */
    function buy(uint256 qty) external payable whenNotPaused {
        require(publicTokenPrice * qty == msg.value, "Buy:: Invalid amount");
        require(qty <= 5, "Buy:: Max limit is 5");
        require(totalSupply() + qty <= maxSupply, "Buy:: Out of stock");
        require(block.timestamp > publicSaleStartTime, "Buy:: Too early");
        _safeMint(msg.sender, qty);
    }

    /**
     * @dev can airdrop tokens
     */
    function adminMint(address to, uint256 qty) external onlyOwner {
        require(totalSupply() + qty <= maxSupply, "AdminMint:: Out of stock");
        _safeMint(to, qty);
    }

    /**
     * @dev verification function for merkle root
     */
    function isTokenOGValid(
        address _to,
        uint256 _tokenId,
        bytes32[] memory _proof
    ) public view returns (bool) {
        // construct Merkle tree leaf from the inputs supplied
        bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));
        // verify the proof supplied, and return the verification result
        return _proof.verify(ogRoot, leaf);
    }

    function isTokenWLValid(
        address _to,
        uint256 _tokenId,
        bytes32[] memory _proof
    ) public view returns (bool) {
        // construct Merkle tree leaf from the inputs supplied
        bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));
        // verify the proof supplied, and return the verification result
        return _proof.verify(wlRoot, leaf);
    }

    function setOGMerkleRoot(bytes32 _ogRoot) external onlyOwner {
        ogRoot = _ogRoot;
    }

    function setWLMerkleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    //----------------------------------
    //----------- other code -----------
    //----------------------------------
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json")
            );
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!locked, "SetBaseURI:: Unlock before set");
        _contractBaseURI = newBaseURI;
    }

    function setContractURI(string memory newuri) external onlyOwner {
        require(!locked, "SetContractURI:: Unlock before set");
        _contractURI = newuri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function setOGSaleStartTime(uint256 newStartTime, uint256 newEndTime) external onlyOwner {
        ogSaleStartTime = newStartTime;
        ogSaleEndTime = newEndTime;
    }

    function setWhitelistSaleStartTime(uint256 newStartTime, uint256 newEndTime) external onlyOwner {
        whitelistSaleStartTime = newStartTime;
        whitelistSaleEndTime = newEndTime;
    }

    function setPublicSaleStartTime(uint256 newStartTime) external onlyOwner {
        publicSaleStartTime = newStartTime;
    }

    //change the price per token
    function setOGCost(uint256 newPrice) external onlyOwner {
        ogTokenPrice = newPrice;
    }

    //change the price per token
    function setWLCost(uint256 newPrice) external onlyOwner {
        wlTokenPrice = newPrice;
    }

    //change the price per token
    function setPublicCost(uint256 newPrice) external onlyOwner {
        publicTokenPrice = newPrice;
    }

    //change the max supply
    function setmaxMintAmount(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    //blocks staking but doesn't block unstaking / claiming
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    //sets the opensea proxy
    function setProxyRegistry(address _newRegistry) external onlyOwner {
        proxyRegistryAddress = _newRegistry;
    }

    // and for the eternity!
    function lockBaseURIandContractURI() external onlyOwner {
        locked = true;
    }

    // earnings withdrawal
    function withdraw() public payable onlyOwner {
        uint256 _total_owner = address(this).balance;

        (bool all1, ) = payable(0x0E664f613f062d52e3FC9aE65270584ad660B2CB)
            .call{value: (_total_owner * 1) / 3}(""); //l
        require(all1);
        (bool all2, ) = payable(0x0E664f613f062d52e3FC9aE65270584ad660B2CB)
            .call{value: (_total_owner * 1) / 3}(""); //sc
        require(all2);
        (bool all3, ) = payable(0x0E664f613f062d52e3FC9aE65270584ad660B2CB)
            .call{value: (_total_owner * 1) / 3}(""); //sp
        require(all3);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}

//opensea removal of approvals
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}