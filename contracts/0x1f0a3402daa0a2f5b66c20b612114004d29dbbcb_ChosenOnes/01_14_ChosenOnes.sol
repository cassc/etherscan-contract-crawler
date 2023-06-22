// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: digs
// Developed by Seek Innovation Labs, 2022

/**
                                .
                                ..
                    .         ...
                    ..       .''.         .
                        ..      .;,....',,::;;'.
            ..        ..   .,ldoodocc:;:c:'.
            .;'.       ';;lxkxol:;,,;:;,..
                ........',cool;'..',;;:;'.
                .,ll:;,......,:cl:,.
                .,col'.....;c:,,...
            .ldo:,'....''..       ,:'
            'll;.''..         .,:d00:
            ...            .:kOO0Kd.
                            .:okOkxdo.
                        .:x0OOOOxc;.
                        .:dOO0kox0Od:.
                    .'clldxo';OXXKo.
                    .:lc;,,'. .lxood:
                ;dxxo:,.   .lxdl,.
                ;dkkko'     ':dxx:.
                ,odc,.     ;kkdc,.
                            .cxdlo;.
                            :xdxol;
                        .xOdxdl'
                        ;OOxxl,.
                        ,dOK0c.
                        .,cOXk'
                        .;lOXd.
                        .;:od:
                        'lxd'
                        .lxo.          ..','.
                        ;dxo...';looodxkxo;.
                        .ckxoldxk0XNNNKx:'.
                        .,llcoOOxddxxo:.
                    ..,ldo::::codl,.
                .;;,,o0KOo:;'.         ...  ..
            .';ll:oKNKo;;,.        ..;'...,.
                ,;;;,:c;.             ,cc,.''.
                ;o;.                .,:cc::;,.
                                    .........
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ChosenOnes is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _supply;

    bytes32 private _merkleRoot;

    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_MINTS_PER_TRANSACTION = 5;

    string public baseURI;

    bool public preSaleActive;
    bool public publicSaleActive;
    bool public revealed;

    address public proxyRegistryAddress;

    mapping(address => uint) private addressToNumMinted;

    constructor(
        address _proxyRegistryAddress,
        string memory _initialBaseURI
    )
        ERC721("Chosen Ones by Seek One", "CHOSENONES")
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        baseURI = _initialBaseURI;
    }

    // Modifiers
    modifier _checkMint(uint256 _amount) {
        require(_amount > 0, "Must mint more than 0 tokens.");
        // We add + 1 to these constants because GTE and LTE checks add more gas
        // Source: https://medium.com/coinmonks/gas-optimization-in-solidity-part-i-variables-9d5775e43dde
        require(_amount < MAX_MINTS_PER_TRANSACTION + 1, "Mints per tx exceeded.");
        require(_supply.current() + _amount < MAX_SUPPLY + 1, "Not enough tokens.");

        require(msg.value == PRICE * _amount, "Insufficient funds supplied.");
        _;
    }

    // Internal/private functions
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _internalMint(address _recipient, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; i++) {
            _supply.increment();
            _safeMint(_recipient, _supply.current());
        }
    }

    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    // See the comment at the bottom of this file for more info on why this is needed.
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function mint(uint256 _amount) public payable _checkMint(_amount) nonReentrant {
        require(publicSaleActive, "Minting is disabled.");

        _internalMint(_msgSender(), _amount);
    }

    function totalSupply() public view returns (uint256) {
        return _supply.current();
    }

    function whitelistMint(uint256 _amount, uint256 _allowance, bytes32[] calldata _proof) public payable _checkMint(_amount) nonReentrant {
        require(preSaleActive, "Pre-sale minting is disabled.");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(_verify(_leaf(Strings.toString(_allowance), payload), _proof), "Invalid Merkle Tree proof supplied.");
        require(addressToNumMinted[_msgSender()] + _amount <= _allowance, "Exceeds token allowance.");

        addressToNumMinted[_msgSender()] += _amount;
        _internalMint(_msgSender(), _amount);
    }

    // Owner Getters
    function getAddressToNumMinted(address _address) public view onlyOwner returns (uint) {
        return addressToNumMinted[_address];
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function getCurrentTokenId() public view onlyOwner returns (uint256) {
        return _supply.current();
    }

    function getMerkleRoot() public view onlyOwner returns (bytes32) {
        return _merkleRoot;
    }

    // Owner Setters
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function setPreSaleActive(bool _state) external onlyOwner {
        preSaleActive = _state;
    }

    function setPublicSaleActive(bool _state) external onlyOwner {
        publicSaleActive = _state;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // Other owner functions
    function reserveTokens(uint256 _amount, address _address) public onlyOwner {
        _internalMint(_address, _amount);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}
/**
 * This portion of the contract was inspired by https://twitter.com/nftchance and his article "The Gas-Efficient Way of Building and Launching an ERC721 NFT Project For 2022".
 * It removes the following unneccessary gas fees for holders that list on OpenSea (https://support.opensea.io/hc/en-us/articles/1500006315941):
 *   #2 Token or Contract Approval (such as WETH, USDC)
 *      Suppose the item you are listing was not minted on OpenSea but through a custom NFT collection contract (like Bored Ape Yacht Club).
 *      In that case, you will need to pay a one-time approval fee authorizing transactions between that contract and your wallet.
 *
 * This method is also shown in the OpenSea docs https://docs.opensea.io/docs/1-structuring-your-smart-contract#opensea-whitelisting-optional:
 *   Additionally, the ERC721Tradable and ERC1155Tradable contracts whitelist the proxy accounts of OpenSea users so that they are automatically able to trade any item on OpenSea (without having to pay gas for an additional approval).
 *   On OpenSea, each user has a "proxy" account that they control, and is ultimately called by the marketplace contracts to trade their items.
 *   Note that this addition does not mean that OpenSea itself has access to the items, simply that the users can list them more easily if they wish to do so.
 *   It's entirely optional, but results in significantly less user friction. You can find this code in the overridden isApprovedForAll method, along with the factory mint methods.
 */
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}